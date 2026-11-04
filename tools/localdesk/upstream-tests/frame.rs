use std::ops::Not;
use std::sync::atomic::{AtomicPtr, Ordering::SeqCst};
use std::time::{Duration, Instant};

// Only the logger is replaced. FrameRaw and would_block_if_equal are copied verbatim
// from production by test-upstream-backports.py, including when testing an older ref.
extern crate self as log;
#[macro_export]
macro_rules! trace { ($($arg:tt)*) => { let _ = format_args!($($arg)*); }; }

// PRODUCTION

#[test]
fn callback_buffer_can_be_reused_before_capture_takes_the_frame() {
    let mut frame = FrameRaw::new("video", Duration::from_secs(1));
    frame.set_enable(true);
    let mut source = vec![1, 2, 3, 4];
    frame.update(source.as_mut_ptr(), source.len());
    source.fill(9); // ImageReader has returned this memory to its producer.
    let mut dst = vec![];
    assert_eq!(frame.take(&mut dst, &mut vec![]), Some(()));
    assert_eq!(dst, [1, 2, 3, 4]);
    assert_eq!(frame.take(&mut dst, &mut vec![]), None);
}

#[test]
fn next_update_does_not_mutate_the_frame_being_encoded() {
    let mut frame = FrameRaw::new("audio", Duration::from_secs(1));
    frame.set_enable(true);
    let mut source = vec![1, 2, 3, 4];
    let mut dst = vec![];
    frame.update(source.as_mut_ptr(), source.len());
    frame.take(&mut dst, &mut vec![]);
    source.fill(5);
    frame.update(source.as_mut_ptr(), source.len());
    assert_eq!(dst, [1, 2, 3, 4]);
    source.fill(9);
    frame.take(&mut dst, &mut vec![]);
    assert_eq!(dst, [5, 5, 5, 5]);
}

#[test]
fn expired_disabled_and_invalid_frames_are_not_delivered() {
    let mut frame = FrameRaw::new("video", Duration::from_secs(1));
    let mut source = vec![1, 2, 3, 4];
    let mut dst = vec![];
    frame.update(source.as_mut_ptr(), source.len());
    assert_eq!(frame.take(&mut dst, &mut vec![]), None);
    frame.set_enable(true);
    frame.update(std::ptr::null_mut(), 4);
    assert_eq!(frame.take(&mut dst, &mut vec![]), None);
    frame.update(source.as_mut_ptr(), 0);
    assert_eq!(frame.take(&mut dst, &mut vec![]), None);
    frame.update(source.as_mut_ptr(), source.len());
    frame.last_update = Instant::now() - Duration::from_secs(2);
    assert_eq!(frame.take(&mut dst, &mut vec![]), None);
    frame.update(source.as_mut_ptr(), source.len());
    frame.set_enable(false);
    frame.set_enable(true);
    assert_eq!(frame.take(&mut dst, &mut vec![]), None);
}
