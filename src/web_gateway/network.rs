fn normalize_allowed_networks(value: &str) -> ResultType<Vec<cidr_utils::cidr::IpCidr>> {
    value.split(',').map(str::trim).filter(|s| !s.is_empty())
        .map(|s| cidr_utils::cidr::IpCidr::from_str(s)
            .map_err(|_| anyhow!("Invalid Web allowed network: {s}"))).collect()
}

fn source_allowed_with(ip: IpAddr, value: &str) -> bool {
    if !crate::landesk_native_policy::allowed_ip(ip) { return false; }
    match normalize_allowed_networks(value) {
        Ok(networks) => networks.is_empty() || networks.iter().any(|network| network.contains(ip)),
        Err(_) => false,
    }
}
