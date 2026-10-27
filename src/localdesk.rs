//! Compile-time policy for the LocalDesk fork. Not a user-configurable option.
use std::net::{IpAddr, SocketAddr};

pub const ENABLED: bool = true;
pub const DEFAULT_PORT: u16 = 21118;

pub fn allowed_ip(ip: IpAddr) -> bool {
    match ip {
        IpAddr::V4(ip) => {
            let [a, b, _, _] = ip.octets();
            ip.is_private()
                || ip.is_loopback()
                || ip.is_link_local()
                || (a == 100 && (64..=127).contains(&b))
        }
        IpAddr::V6(ip) => {
            if let Some(v4) = ip.to_ipv4_mapped() {
                return allowed_ip(IpAddr::V4(v4));
            }
            let first = ip.segments()[0];
            ip.is_loopback() || (first & 0xfe00 == 0xfc00) || (first & 0xffc0 == 0xfe80)
        }
    }
}

pub fn target(peer: &str) -> Result<SocketAddr, &'static str> {
    let addr = peer.parse::<SocketAddr>().or_else(|_| {
        peer.parse::<IpAddr>().map(|ip| SocketAddr::new(ip, DEFAULT_PORT))
    }).map_err(|_| "LocalDesk requires a private IP address, optionally with a port; IDs and hostnames are disabled")?;
    if addr.port() == 0 || !allowed_ip(addr.ip()) {
        return Err("LocalDesk only connects to LAN, loopback, or private VPN IP addresses");
    }
    Ok(addr)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn accepts_lan_and_tailscale_with_explicit_ports() {
        assert_eq!(target("192.168.1.20").unwrap().port(), 21118);
        assert_eq!(target("100.64.0.10:21119").unwrap().port(), 21119);
        assert!(target("[fd7a:115c:a1e0::1]:21118").is_ok());
        assert!(target("::1").is_ok());
    }

    #[test]
    fn rejects_ids_servers_public_addresses_and_relay_suffixes() {
        for value in [
            "123456789",
            "host.local:21118",
            "1.1.1.1",
            "192.168.1.2/r",
            "123@server?key=x",
            "192.168.1.2:0",
            "[::ffff:8.8.8.8]:21118",
            "0.0.0.0",
        ] {
            assert!(target(value).is_err(), "accepted {value}");
        }
    }
}
