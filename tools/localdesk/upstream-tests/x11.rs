#![allow(non_camel_case_types, dead_code)]
use std::{cell::RefCell, ptr, rc::Rc};

// These FFI doubles retain allocations after free so a premature release is a
// deterministic assertion failure rather than undefined behaviour in the test.
#[derive(Clone, Copy)]
struct Monitor { name: u32, primary: u8, x: i16, y: i16, width: u16, height: u16 }
struct xcb_randr_get_monitors_reply_t { monitor: Monitor, freed: bool }
struct Screen { root: u32 }
struct xcb_screen_iterator_t { data: *mut Screen, rem: i32 }
type xcb_window_t = u32;
struct xcb_randr_monitor_info_iterator_t {
    data: *mut Monitor, rem: i32, reply: *mut xcb_randr_get_monitors_reply_t,
}
thread_local! {
    static REPLIES: RefCell<Vec<Box<xcb_randr_get_monitors_reply_t>>> = const { RefCell::new(vec![]) };
}
pub struct Server { screens: Vec<Screen> }
impl Server {
    fn setup(&self) -> &Self { self }
    fn raw(&self) {}
}
struct Rect { x: i16, y: i16, w: u16, h: u16 }
enum Pixfmt { BGRA }
pub struct Display { name: String }
impl Display {
    fn new(_: Rc<Server>, _: bool, _: Rect, _: u32, name: String, _: Pixfmt) -> Self {
        Self { name }
    }
}
unsafe fn xcb_setup_roots_iterator(server: &Server) -> xcb_screen_iterator_t {
    xcb_screen_iterator_t { data: server.screens.as_ptr() as *mut _, rem: server.screens.len() as i32 }
}
unsafe fn xcb_screen_next(it: &mut xcb_screen_iterator_t) {
    it.data = it.data.add(1); it.rem -= 1;
}
fn xcb_randr_get_monitors_unchecked(_: (), root: u32, _: u8) -> u32 { root }
unsafe fn xcb_randr_get_monitors_reply(_: (), root: u32, _: *mut ()) -> *mut xcb_randr_get_monitors_reply_t {
    REPLIES.with(|replies| {
        let mut replies = replies.borrow_mut();
        replies.push(Box::new(xcb_randr_get_monitors_reply_t {
            monitor: Monitor { name: root, primary: 1, x: 0, y: 0, width: 1920, height: 1080 }, freed: false,
        }));
        &mut **replies.last_mut().unwrap() as *mut _
    })
}
unsafe fn xcb_randr_get_monitors_monitors_iterator(reply: *mut xcb_randr_get_monitors_reply_t) -> xcb_randr_monitor_info_iterator_t {
    xcb_randr_monitor_info_iterator_t { data: &mut (*reply).monitor, rem: 1, reply }
}
unsafe fn xcb_randr_monitor_info_next(it: &mut xcb_randr_monitor_info_iterator_t) {
    assert!(!(*it.reply).freed, "monitor iterator read an already freed reply");
    it.rem -= 1;
}
mod libc {
    pub unsafe fn free(reply: *mut super::xcb_randr_get_monitors_reply_t) {
        assert!(!(*reply).freed, "double free");
        (*reply).freed = true;
    }
}
fn get_atom_name(_: (), name: u32) -> String { name.to_string() }
unsafe fn get_pixfmt(_: (), _: u32) -> Option<Pixfmt> { None }

// PRODUCTION

fn server() -> Rc<Server> {
    REPLIES.with(|r| r.borrow_mut().clear());
    Rc::new(Server { screens: vec![Screen { root: 1 }, Screen { root: 2 }] })
}
fn released() -> usize { REPLIES.with(|r| r.borrow().iter().filter(|r| r.freed).count()) }

#[test]
fn partial_iteration_keeps_reply_alive_until_drop() {
    let mut displays = unsafe { DisplayIter::new(server()) };
    assert_eq!(released(), 0);
    assert_eq!(displays.next().unwrap().name, "1");
    assert_eq!(released(), 0);
    drop(displays);
    assert_eq!(released(), 1);
}
#[test]
fn advancing_and_exhausting_releases_each_reply_once() {
    let mut displays = unsafe { DisplayIter::new(server()) };
    assert_eq!(displays.next().unwrap().name, "1");
    assert_eq!(displays.next().unwrap().name, "2");
    assert_eq!(released(), 1);
    assert!(displays.next().is_none());
    assert_eq!(released(), 2);
    drop(displays);
    assert_eq!(released(), 2);
}
#[test]
fn drop_without_reading_releases_the_initial_reply() {
    let displays = unsafe { DisplayIter::new(server()) };
    assert_eq!(released(), 0);
    drop(displays);
    assert_eq!(released(), 1);
}
