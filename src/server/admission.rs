//! LAN adaptation of RustDesk's unauthenticated connection budget (#16237).
use hbb_common::tokio::{
    sync::Notify,
    time::{self, Instant},
};
use std::{
    net::IpAddr,
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc, Mutex,
    },
    time::Duration,
};

pub(super) const MAX_UNAUTHORIZED_MESSAGE: usize = crate::lan_protocol::MAX_HANDSHAKE_MESSAGE;
const LOGIN_GRACE: Duration = Duration::from_secs(180);
const MAX_UNAUTHORIZED_CONNS: usize = 64;
const MAX_UNAUTHORIZED_CONNS_PER_ADDR: usize = 16;

lazy_static::lazy_static! {
    static ref UNAUTHORIZED_CONNS: Mutex<Vec<(i32, IpAddr, Arc<UnauthorizedShared>)>> = Default::default();
}

struct UnauthorizedShared {
    evicted: AtomicBool,
    notify: Notify,
}

pub(super) struct UnauthorizedID {
    shared: Arc<UnauthorizedShared>,
    deadline: Instant,
}

/// Count a connection before its handshake. A refused arrival never borrows an
/// occupied slot; only the oldest is asked to leave when the global room is full.
pub(super) fn admit_unauthorized(id: i32, ip: IpAddr) -> Option<UnauthorizedID> {
    let ip = match ip {
        IpAddr::V6(ip) => ip
            .to_ipv4_mapped()
            .map(IpAddr::V4)
            .unwrap_or(IpAddr::V6(ip)),
        other => other,
    };
    let mut conns = UNAUTHORIZED_CONNS.lock().unwrap();
    if conns.iter().filter(|(_, held, _)| *held == ip).count() >= MAX_UNAUTHORIZED_CONNS_PER_ADDR {
        return None;
    }
    if conns.len() >= MAX_UNAUTHORIZED_CONNS {
        if let Some((_, _, oldest)) = conns.first() {
            if !oldest.evicted.swap(true, Ordering::AcqRel) {
                oldest.notify.notify_one();
            }
        }
        return None;
    }
    let shared = Arc::new(UnauthorizedShared {
        evicted: AtomicBool::new(false),
        notify: Notify::new(),
    });
    conns.push((id, ip, shared.clone()));
    Some(UnauthorizedID {
        shared,
        deadline: Instant::now() + LOGIN_GRACE,
    })
}

impl UnauthorizedID {
    pub(super) async fn evicted(&self) {
        if self.shared.evicted.load(Ordering::Acquire) {
            return;
        }
        self.shared.notify.notified().await;
    }
}

impl Drop for UnauthorizedID {
    fn drop(&mut self) {
        // Native and web listeners can own different Server instances. Release
        // this guard alone even if their connection ID counters overlap.
        UNAUTHORIZED_CONNS
            .lock()
            .unwrap()
            .retain(|(_, _, held)| !Arc::ptr_eq(held, &self.shared));
    }
}

pub(super) async fn unauthorized_evicted(unauthorized: &Option<UnauthorizedID>) {
    match unauthorized {
        Some(guard) => guard.evicted().await,
        None => std::future::pending().await,
    }
}

pub(super) async fn login_deadline(unauthorized: &Option<UnauthorizedID>) {
    match unauthorized {
        Some(guard) => time::sleep_until(guard.deadline).await,
        None => std::future::pending().await,
    }
}

#[cfg(test)]
#[path = "admission_tests.rs"]
mod tests;
