use regex::{Captures, Regex};
use std::cell::RefCell;
use std::sync::RwLock;

thread_local! {
    static FLATPAK: RefCell<bool> = const { RefCell::new(false) };
    static PASSWD: RefCell<Result<String, ()>> = RefCell::new(Ok(String::new()));
}
fn is_flatpak() -> bool { FLATPAK.with(|v| *v.borrow()) }
fn username() -> String { "sandbox-user".to_owned() }
fn get_active_user_id_name_from_cache() -> Option<(String, String)> { None }
fn get_values_of_seat0(_: &[usize]) -> Vec<String> { vec!["host-user".to_owned()] }
fn run_cmds(_: &str) -> Result<String, ()> { PASSWD.with(|v| v.borrow().clone()) }
mod config { pub static APP_DIR: super::RwLock<String> = super::RwLock::new(String::new()); }

// PRODUCTION

#[test]
fn greeter_detection_checks_only_known_shell_paths() {
    for shell in ["/bin/false", "/usr/bin/false", "/usr/sbin/nologin", "/sbin/nologin", "/usr/bin/nologin"] {
        PASSWD.with(|v| *v.borrow_mut() = Ok(format!("gdm:x:120:120::/var/lib/gdm:{shell}\n")));
        assert!(is_prelogin(), "missed {shell}");
    }
    for entry in ["user:x:1000:1000::/home/nologin-test:/bin/bash", "user:x:1000:1000::/home/user:/opt/custom/nologin"] {
        PASSWD.with(|v| *v.borrow_mut() = Ok(entry.to_owned()));
        assert!(!is_prelogin());
    }
    PASSWD.with(|v| *v.borrow_mut() = Err(()));
    assert!(!is_prelogin());
}

#[test]
fn flatpak_uses_its_own_user_without_treating_it_as_a_greeter() {
    FLATPAK.with(|v| *v.borrow_mut() = true);
    assert_eq!(get_active_username(), "sandbox-user");
    assert!(!is_prelogin());
    FLATPAK.with(|v| *v.borrow_mut() = false);
    assert_eq!(get_active_username(), "host-user");
}

#[test]
fn desktop_peer_loading_does_not_depend_on_documents_directory() {
    assert!(peer_config_path_ready());
}

#[test]
fn no_empty_audio_latency_defaults_are_invented() {
    let mut envs = vec![];
    append_audio_latency_envs(&mut envs, |_| Some(String::new()));
    assert!(envs.is_empty());
}

#[test]
fn selected_rust_sources_parse() {
    for (name, source) in SOURCES {
        syn::parse_file(source).unwrap_or_else(|error| panic!("{name}: {error}"));
    }
}

#[test]
fn dependency_updates_compile_together() {
    let data = bytes::Bytes::from_static(b"lan");
    assert_eq!(data.as_ref(), b"lan");
    let _guard = crossbeam_epoch::pin();
    let _time = rustls_pki_types::UnixTime::since_unix_epoch(std::time::Duration::ZERO);
    assert!(!webpki_roots::TLS_SERVER_ROOTS.is_empty());
    assert!(!webpki_root_certs::TLS_SERVER_ROOT_CERTS.is_empty());
}
