use hbb_common::tokio;
use super::*;
use hbb_common::tokio::{
    io::AsyncWriteExt,
    net::{TcpListener, TcpStream},
    time::timeout,
};

static SERIAL: Mutex<()> = Mutex::new(());

fn count() -> usize {
    UNAUTHORIZED_CONNS.lock().unwrap().len()
}

#[test]
fn overlapping_listener_ids_do_not_release_another_connections_slot() {
    let _serial = SERIAL.lock().unwrap_or_else(|e| e.into_inner());
    let first = admit_unauthorized(1, "10.0.0.1".parse().unwrap()).unwrap();
    let second = admit_unauthorized(1, "10.0.0.2".parse().unwrap()).unwrap();
    assert_eq!(count(), 2);
    drop(first);
    assert_eq!(count(), 1);
    drop(second);
    assert_eq!(count(), 0);
}

#[test]
fn mapped_ipv4_and_native_ipv4_share_a_single_budget() {
    let _serial = SERIAL.lock().unwrap_or_else(|e| e.into_inner());
    let held: Vec<_> = (0..MAX_UNAUTHORIZED_CONNS_PER_ADDR as i32)
        .map(|id| admit_unauthorized(id, "192.168.1.10".parse().unwrap()).unwrap())
        .collect();
    assert!(admit_unauthorized(100, "::ffff:192.168.1.10".parse().unwrap()).is_none());
    assert!(held
        .iter()
        .all(|g| !g.shared.evicted.load(Ordering::Acquire)));
    assert!(admit_unauthorized(101, "192.168.1.11".parse().unwrap()).is_some());
    drop(held);
    assert_eq!(count(), 0);
}

#[tokio::test]
async fn full_room_refuses_arrivals_and_only_evicts_the_oldest_until_it_drops() {
    let _serial = SERIAL.lock().unwrap_or_else(|e| e.into_inner());
    let mut held: Vec<_> = (0..MAX_UNAUTHORIZED_CONNS as i32)
        .map(|id| admit_unauthorized(id, format!("10.0.0.{}", id + 1).parse().unwrap()).unwrap())
        .collect();
    for id in 100..110 {
        assert!(admit_unauthorized(id, "10.1.0.1".parse().unwrap()).is_none());
    }
    timeout(Duration::from_millis(100), held[0].evicted())
        .await
        .unwrap();
    assert!(held[1..]
        .iter()
        .all(|g| !g.shared.evicted.load(Ordering::Acquire)));
    assert_eq!(count(), MAX_UNAUTHORIZED_CONNS);
    drop(held.remove(0));
    let replacement = admit_unauthorized(200, "10.1.0.1".parse().unwrap()).unwrap();
    assert_eq!(count(), MAX_UNAUTHORIZED_CONNS);
    drop((held, replacement));
    assert_eq!(count(), 0);
}

#[tokio::test]
async fn login_deadline_ends_pending_connections_but_not_authorized_ones() {
    let _serial = SERIAL.lock().unwrap_or_else(|e| e.into_inner());
    let mut guard = admit_unauthorized(300, "10.0.0.1".parse().unwrap()).unwrap();
    guard.deadline = Instant::now() - Duration::from_millis(1);
    let mut pending = Some(guard);
    timeout(Duration::from_millis(100), login_deadline(&pending))
        .await
        .unwrap();
    drop(pending.take()); // The production authorization path releases the same guard.
    assert_eq!(count(), 0);
    assert!(timeout(Duration::from_millis(10), login_deadline(&pending))
        .await
        .is_err());
    assert!(
        timeout(Duration::from_millis(10), unauthorized_evicted(&pending))
            .await
            .is_err()
    );
}

async fn loopback_pair() -> (TcpStream, hbb_common::Stream) {
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let client = TcpStream::connect(listener.local_addr().unwrap())
        .await
        .unwrap();
    let (socket, addr) = listener.accept().await.unwrap();
    (client, hbb_common::Stream::from(socket, addr))
}

#[tokio::test]
async fn a_large_header_is_rejected_without_waiting_for_its_payload() {
    let _serial = SERIAL.lock().unwrap_or_else(|e| e.into_inner());
    let guard = admit_unauthorized(400, "127.0.0.1".parse().unwrap()).unwrap();
    let (mut client, mut stream) = loopback_pair().await;
    stream.set_max_packet_length(MAX_UNAUTHORIZED_MESSAGE);
    let handshake = hbb_common::tokio::spawn(async move {
        let _guard = guard;
        stream.next().await.unwrap().unwrap_err()
    });
    client
        .write_all(&((((MAX_UNAUTHORIZED_MESSAGE + 1) << 2) | 3) as u32).to_le_bytes())
        .await
        .unwrap();
    let error = timeout(Duration::from_secs(1), handshake)
        .await
        .unwrap()
        .unwrap();
    assert_eq!(error.kind(), std::io::ErrorKind::InvalidData);
    assert_eq!(count(), 0);
}

#[tokio::test]
async fn authorization_lifts_the_small_frame_limit_for_application_data() {
    let (mut client, mut stream) = loopback_pair().await;
    stream.set_max_packet_length(MAX_UNAUTHORIZED_MESSAGE);
    client.write_all(&[4, 42]).await.unwrap(); // One-byte frame, still unauthenticated.
    assert_eq!(stream.next().await.unwrap().unwrap().as_ref(), &[42]);
    stream.set_max_packet_length(usize::MAX);
    let n = MAX_UNAUTHORIZED_MESSAGE + 1;
    let writer = hbb_common::tokio::spawn(async move {
        client
            .write_all(&(((n << 2) | 3) as u32).to_le_bytes())
            .await
            .unwrap();
        client.write_all(&vec![7; n]).await.unwrap();
    });
    assert_eq!(
        timeout(Duration::from_secs(1), stream.next())
            .await
            .unwrap()
            .unwrap()
            .unwrap()
            .len(),
        n
    );
    writer.await.unwrap();
}
