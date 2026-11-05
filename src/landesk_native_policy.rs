//! Private-network endpoint policy for native direct connections.
//! Callers must use
//! the returned socket address directly, without a second DNS lookup or proxy.

use std::net::{IpAddr, Ipv4Addr, SocketAddr};

fn private_v4(ip: Ipv4Addr) -> bool {
    let [a, b, _, _] = ip.octets();
    ip.is_private() || ip.is_loopback() || ip.is_link_local()
        || (a == 100 && (64..=127).contains(&b))
}

pub fn allowed_ip(ip: IpAddr) -> bool {
    match ip {
        IpAddr::V4(ip) => private_v4(ip),
        IpAddr::V6(ip) => {
            if let Some(v4) = ip.to_ipv4_mapped() {
                return private_v4(v4);
            }
            let first = ip.segments()[0];
            ip.is_loopback() || first & 0xfe00 == 0xfc00
                || first & 0xffc0 == 0xfe80
        }
    }
}

/// Numeric endpoints only for the first implementation. Discovery must supply
/// a concrete address. Hostnames require a separate, checked resolver later.
pub fn endpoint(value: &str, default_port: u16) -> Result<SocketAddr, &'static str> {
    let address = if let Ok(ip) = value.parse::<IpAddr>() {
        SocketAddr::new(ip, default_port)
    } else {
        value.parse::<SocketAddr>().map_err(|_| "numeric IP address required")?
    };
    if address.port() == 0 {
        return Err("nonzero port required");
    }
    if !allowed_ip(address.ip()) {
        return Err("private network address required");
    }
    Ok(address)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn accepts_private_and_tailscale_ranges() {
        for address in ["10.0.0.1", "172.16.0.1", "172.31.255.254",
                        "192.168.1.2", "100.64.0.1", "100.127.255.254",
                        "127.0.0.1", "169.254.1.1", "::1", "fd7a:115c:a1e0::1",
                        "fc00::1", "fe80::1", "::ffff:192.168.1.1"] {
            assert!(endpoint(address, 21118).is_ok(), "{address}");
        }
    }

    #[test]
    fn rejects_public_unspecified_multicast_and_range_neighbors() {
        for address in ["8.8.8.8", "0.0.0.0", "255.255.255.255", "224.0.0.1",
                        "172.15.255.255", "172.32.0.1", "100.63.255.255",
                        "100.128.0.1", "::", "ff02::1", "2001:4860:4860::8888",
                        "::ffff:8.8.8.8", "::ffff:0.0.0.0", "::192.168.1.1",
                        "64:ff9b::808:808", "2002:0808:0808::1", "fec0::1"] {
            assert!(endpoint(address, 21118).is_err(), "{address}");
        }
    }

    #[test]
    fn preserves_checked_address_and_port() {
        assert_eq!(endpoint("192.168.1.2:1234", 21118).unwrap().to_string(),
                   "192.168.1.2:1234");
        assert_eq!(endpoint("[fd7a:115c:a1e0::1]:21118", 1234).unwrap().port(), 21118);
        assert_eq!(endpoint("192.168.1.2", 21118).unwrap().port(), 21118);
    }

    #[test]
    fn rejects_indirection_and_invalid_ports() {
        for address in ["123456789", "host.local:21118", "localhost", "https://192.168.1.1",
                        "192.168.1.1:0", "192.168.1.1:65536", "192.168.1.1@8.8.8.8",
                        " 192.168.1.1", "127.1", "0x7f000001", "0177.0.0.1"] {
            assert!(endpoint(address, 21118).is_err(), "{address}");
        }
        assert!(endpoint("192.168.1.1", 0).is_err());
    }
}
