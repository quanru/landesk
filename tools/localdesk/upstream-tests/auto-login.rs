// The harness injects the actual guarded server method; only the OS state and
// input sink are replaced. No system keystrokes or real credentials are used.
mod platform {
    use std::sync::atomic::{AtomicUsize, Ordering};
    pub static STATE: AtomicUsize = AtomicUsize::new(0);
    pub fn is_logon_screen() -> bool {
        match STATE.load(Ordering::SeqCst) {
            0 => false,
            1 => true,
            _ => panic!("simulated OS query task failure"),
        }
    }
}
mod guarded_login_tests {
    use base::message_proto::{ControlKey, KeyEvent, KeyboardMode};
    use hbb_common::tokio;
    use std::{sync::{Mutex, atomic::{AtomicI64, Ordering}}, time::Duration};
    static CLICK_TIME: AtomicI64 = AtomicI64::new(0);
    static MOUSE_MOVE_TIME: AtomicI64 = AtomicI64::new(0);
    fn get_time() -> i64 { 1 }
    struct Connection { keys: Mutex<Vec<(KeyEvent, bool)>> }
    impl Connection {
        fn input_key(&self, key: KeyEvent, press: bool) {
            self.keys.lock().unwrap().push((key, press));
        }
        // GUARDED_PRODUCTION_METHOD
    }
    #[tokio::test]
    async fn unlocked_or_failed_screen_query_never_types_and_locked_types_once() {
        let connection = Connection { keys: Mutex::new(Vec::new()) };
        for state in [0, 2] {
            crate::platform::STATE.store(state, Ordering::SeqCst);
            connection.type_auto_login_password("synthetic-secret".into()).await;
            assert!(connection.keys.lock().unwrap().is_empty());
        }
        crate::platform::STATE.store(1, Ordering::SeqCst);
        connection.type_auto_login_password("synthetic-secret".into()).await;
        let keys = connection.keys.lock().unwrap();
        assert_eq!(keys.len(), 2);
        assert_eq!(keys[0].0.seq(), "synthetic-secret");
        assert!(!keys[0].1);
        assert_eq!(keys[1].0.control_key(), ControlKey::Return);
        assert!(keys[1].1);
    }
    #[test]
    fn os_login_keeps_existing_lan_wire_numbers() {
        use base::message_proto::{Message, OSLogin, LanClientHello, LanServerHello, PortForwardChannel};
        use hbb_common::protobuf::Message as _;
        let mut m = Message::new();
        m.set_lan_client_hello(LanClientHello::new());
        assert_eq!(m.write_to_bytes().unwrap(), [0x8a, 0x02, 0]);
        m.set_lan_server_hello(LanServerHello::new());
        assert_eq!(m.write_to_bytes().unwrap(), [0x92, 0x02, 0]);
        m.set_port_forward_channel(PortForwardChannel::new());
        assert_eq!(m.write_to_bytes().unwrap(), [0x9a, 0x02, 0]);
        m.set_os_login(OSLogin::new());
        assert_eq!(m.write_to_bytes().unwrap(), [0xa2, 0x02, 0]);
    }
}
