//! Product configuration around the upstream native direct-IP implementation.
//! No legacy SubnetDesk messages, credentials, or migration are loaded here.

use hbb_common::{config, ResultType};
use std::sync::Once;

pub fn initialize() {
    static INIT: Once = Once::new();
    INIT.call_once(|| {
        // The previous product used LocalDesk. This name isolates both the
        // desktop configuration and the mobile configuration filenames.
        *config::APP_NAME.write().unwrap() = "LanDesk".to_owned();
        #[cfg(target_os = "macos")]
        {
            *config::ORG.write().unwrap() = "dev.quanru".to_owned();
        }
        let mut fixed = config::OVERWRITE_SETTINGS.write().unwrap();
        for (key, value) in [
            ("direct-server", "Y"),
            ("allow-websocket", "N"),
            ("allow-auto-update", "N"),
            ("enable-tcp-punch", "N"),
            ("enable-udp-punch", "N"),
            ("enable-ipv6-punch", "N"),
            ("enable-webrtc", "N"),
            ("enable-trusted-devices", "N"),
            ("force-always-relay", "N"),
            ("api-server", ""),
            ("custom-rendezvous-server", ""),
            ("relay-server", ""),
        ] {
            fixed.insert(key.to_owned(), value.to_owned());
        }
        drop(fixed);
        let mut hard = config::HARD_SETTINGS.write().unwrap();
        for key in ["disable-account", "disable-ab"] {
            hard.insert(key.to_owned(), "Y".to_owned());
        }
        drop(hard);
        let mut builtins = config::BUILTIN_SETTINGS.write().unwrap();
        for key in ["hide-server-settings", "hide-proxy-settings",
                    "hide-websocket-settings", "disable-change-id"] {
            builtins.insert(key.to_owned(), "Y".to_owned());
        }
        builtins.insert("allow-deep-link-server-settings".to_owned(), "N".to_owned());
        builtins.insert("allow-deep-link-password".to_owned(), "N".to_owned());
        drop(builtins);
        config::OVERWRITE_LOCAL_SETTINGS.write().unwrap()
            .insert("enable-check-update".to_owned(), "N".to_owned());
    });
}

/// Forwarding must not turn an authenticated private peer into a public proxy.
/// The checked address is passed directly to connect, without DNS re-resolution.
pub async fn connect_forward(address: &str) -> std::io::Result<hbb_common::tokio::net::TcpStream> {
    let normalized = address.strip_prefix("localhost:")
        .map(|port| format!("127.0.0.1:{port}"));
    let address = normalized.as_deref().unwrap_or(address);
    let target = crate::landesk_native_policy::endpoint(address, 0)
        .map_err(|reason| std::io::Error::new(std::io::ErrorKind::PermissionDenied, reason))?;
    hbb_common::tokio::net::TcpStream::connect(target).await
}

pub async fn connect_peer(address: &str) -> ResultType<hbb_common::Stream> {
    let target = crate::landesk_native_policy::endpoint(address, 21118)
        .map_err(|reason| hbb_common::anyhow::anyhow!(reason))?;
    let socket = hbb_common::timeout(config::CONNECT_TIMEOUT,
        hbb_common::tokio::net::TcpStream::connect(target)).await??;
    socket.set_nodelay(true)?;
    let local = socket.local_addr()?;
    Ok(hbb_common::Stream::from(socket, local))
}

pub fn direct_port() -> u16 {
    config::Config::get_option("direct-access-port").parse::<u16>()
        .ok().filter(|port| *port != 0).unwrap_or(21118)
}

pub fn online_service_disabled<T>() -> ResultType<T> {
    hbb_common::bail!("Online services are disabled in LanDesk")
}

// iOS is an outgoing-only client. The desktop interface API is unavailable there.
#[cfg(target_os = "ios")]
pub fn local_endpoints() -> Vec<String> { Vec::new() }

/// Addresses advertised to the user, independently of the internal peer ID.
#[cfg(not(target_os = "ios"))]
pub fn local_endpoints() -> Vec<String> {
    let mut addresses = Vec::new();
    let port = direct_port();
    for interface in default_net::get_interfaces() {
        for network in interface.ipv4 {
            let ip = std::net::IpAddr::V4(network.addr);
            if !ip.is_loopback() && crate::landesk_native_policy::allowed_ip(ip) {
                addresses.push(std::net::SocketAddr::new(ip, port).to_string());
            }
        }
        for network in interface.ipv6 {
            let ip = std::net::IpAddr::V6(network.addr);
            // Link-local IPv6 needs an interface scope, which the input does not yet expose.
            if network.addr.segments()[0] & 0xfe00 == 0xfc00 {
                addresses.push(std::net::SocketAddr::new(ip, port).to_string());
            }
        }
    }
    addresses.sort();
    addresses.dedup();
    addresses
}

static LISTENING: std::sync::atomic::AtomicBool = std::sync::atomic::AtomicBool::new(false);

pub fn set_listening(value: bool) {
    LISTENING.store(value, std::sync::atomic::Ordering::Relaxed);
}

pub fn listening() -> i64 {
    i64::from(LISTENING.load(std::sync::atomic::Ordering::Relaxed))
}

/// The GUI hosts the native server directly; it still needs its own status item.
#[cfg(target_os = "macos")]
pub fn start_macos_tray(args: &[String]) {
    if args.is_empty() && !crate::check_process("--tray", true) {
        if let Err(err) = crate::run_me(vec!["--tray"]) {
            hbb_common::log::error!("Failed to start LanDesk menu-bar icon: {err}");
        }
    }
}
