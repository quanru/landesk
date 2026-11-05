#[cfg(test)]
mod tests {
    use super::*;
    use rcgen::CertifiedKey;

    #[test]
    fn web_access_is_opt_in_and_https_is_mandatory() {
        assert!(!option_enabled(""));
        assert!(!option_enabled("N"));
        assert!(option_enabled("Y"));
        assert!(https_required());
    }

    #[test]
    fn custom_certificate_and_key_must_be_paired_absolute_paths() {
        assert!(custom_certificate_paths("", "").unwrap().is_none());
        assert!(custom_certificate_paths("/tmp/cert.pem", "").is_err());
        assert!(custom_certificate_paths("cert.pem", "key.pem").is_err());
        assert_eq!(
            custom_certificate_paths(" /tmp/cert.pem ", " /tmp/key.pem ").unwrap(),
            Some((
                PathBuf::from("/tmp/cert.pem"),
                PathBuf::from("/tmp/key.pem")
            ))
        );
    }

    #[test]
    fn same_port_distinguishes_plain_http_from_tls() {
        assert!(looks_like_plain_http(b"GET / HTTP/1.1\r\n"));
        assert!(looks_like_plain_http(b"PRI * HTTP/2.0\r\n"));
        assert!(!looks_like_plain_http(&[0x16, 0x03, 0x01, 0x00, 0xf0]));
    }

    #[test]
    fn plain_http_redirects_to_https_without_becoming_an_open_redirect() {
        let allowed = HashSet::from(["10.1.1.124".to_owned()]);
        assert_eq!(
            http_redirect_location(
                b"GET /viewer?display=1 HTTP/1.1\r\nHost: 10.1.1.124:18123\r\n\r\n",
                18_123,
                &allowed,
            ),
            Some("https://10.1.1.124:18123/viewer?display=1".to_owned())
        );
        assert_eq!(
            http_redirect_location(
                b"GET / HTTP/1.1\r\nHost: attacker.example:18123\r\n\r\n",
                18_123,
                &allowed,
            ),
            None
        );
        assert_eq!(
            http_redirect_location(
                b"GET / HTTP/1.1\r\nHost: 10.1.1.124:18123\r\nHost: attacker.example\r\n\r\n",
                18_123,
                &allowed,
            ),
            None
        );
    }

    #[test]
    fn web_port_falls_back_to_18123() {
        assert_eq!(parse_web_port(""), 18_123);
        assert_eq!(parse_web_port("0"), 18_123);
        assert_eq!(parse_web_port("65536"), 18_123);
        assert_eq!(parse_web_port("19123"), 19_123);
    }

    #[test]
    fn web_listener_defaults_and_explicit_addresses() {
        assert_eq!(configured_address_values("127.0.0.1,::1").unwrap(),
            vec!["127.0.0.1".parse::<IpAddr>().unwrap(), "::1".parse::<IpAddr>().unwrap()]);
        assert_eq!(configured_address_values("").unwrap(), vec![IpAddr::V4(Ipv4Addr::UNSPECIFIED)]);
        assert!(configured_address_values("example.com").is_err());
    }

    #[test]
    fn explicit_web_hosts_replace_implicit_interface_hosts() {
        let hosts = configured_allowed_hosts(
            "Desk.Example.LAN, [fd00::20],desk.example.lan",
            vec!["192.168.1.20".to_owned()],
        )
        .unwrap();
        assert!(hosts.contains("desk.example.lan"));
        assert!(hosts.contains("fd00::20"));
        assert!(!hosts.contains("192.168.1.20"));
        assert_eq!(
            configured_allowed_hosts("", vec!["192.168.1.20".to_owned()]).unwrap(),
            HashSet::from(["192.168.1.20".to_owned()])
        );
        assert!(configured_allowed_hosts("user@desk.example", Vec::new()).is_err());
    }

    #[test]
    fn explicit_vpn_listener_is_an_implicit_host_and_certificate_name() {
        let vpn_address = "110.110.110.164".parse::<IpAddr>().unwrap();
        let names = build_certificate_subject_alt_names("", &[vpn_address], &[]);

        assert!(names.contains(&vpn_address.to_string()));
        assert!(configured_allowed_hosts("", names)
            .unwrap()
            .contains(&vpn_address.to_string()));
    }

    #[test]
    fn generated_certificate_rotates_when_addresses_change_or_it_ages() {
        let metadata = GeneratedCertificateMetadata {
            subject_alt_names: vec!["192.168.1.20".to_owned(), "localdesk.local".to_owned()],
            generated_at_unix_seconds: 1_000,
        };
        assert!(!generated_certificate_needs_rotation(
            &metadata,
            &["192.168.1.20".to_owned(), "localdesk.local".to_owned()],
            1_000 + GENERATED_CERTIFICATE_ROTATION_SECONDS - 1,
        ));
        assert!(generated_certificate_needs_rotation(
            &metadata,
            &["192.168.1.21".to_owned(), "localdesk.local".to_owned()],
            1_001,
        ));
        assert!(generated_certificate_needs_rotation(
            &metadata,
            &["192.168.1.20".to_owned(), "localdesk.local".to_owned()],
            1_000 + GENERATED_CERTIFICATE_ROTATION_SECONDS,
        ));
    }

    #[test]
    fn generated_certificate_authority_requires_a_matching_private_key() {
        let (certificate, private_key) = generate_certificate_authority().unwrap();
        let (_, other_private_key) = generate_certificate_authority().unwrap();
        assert!(certificate_authority_material_valid(
            &certificate,
            &private_key
        ));
        assert!(!certificate_authority_material_valid(
            &certificate,
            &other_private_key
        ));
    }

    #[test]
    fn certificate_dns_names_support_exact_and_single_label_wildcards() {
        assert!(dns_name_matches("desk.example.lan", "desk.example.lan"));
        assert!(dns_name_matches("*.example.lan", "desk.example.lan"));
        assert!(!dns_name_matches("*.example.lan", "deep.desk.example.lan"));
        assert!(!dns_name_matches("*.example.lan", "example.lan"));
    }

    #[test]
    fn static_assets_use_immutable_cache_but_html_and_api_do_not() {
        assert_eq!(cache_control_for_path("/"), "no-store");
        assert_eq!(cache_control_for_path("/api/info"), "no-store");
        assert_eq!(
            cache_control_for_path("/app.0123456789abcdef.js"),
            "public, max-age=31536000, immutable"
        );
        assert_eq!(
            cache_control_for_path("/style.0123456789abcdef.css"),
            "public, max-age=31536000, immutable"
        );
        assert_eq!(
            cache_control_for_path("/video-worker.0123456789abcdef.js"),
            "public, max-age=31536000, immutable"
        );
    }

    #[test]
    fn websocket_connection_budget_limits_each_source_and_recovers_on_drop() {
        let limiter = ConnectionLimiter::new(3, 2);
        let source: IpAddr = "192.168.1.20".parse().unwrap();
        let first = limiter.try_acquire(source).unwrap();
        let second = limiter.try_acquire(source).unwrap();
        assert!(matches!(
            limiter.try_acquire(source),
            Err(ConnectionLimitError::Source)
        ));
        drop(first);
        assert!(limiter.try_acquire(source).is_ok());
        drop(second);
    }

    #[test]
    fn request_rate_budget_rejects_bursts_until_the_window_resets() {
        let mut budget = RequestRateBudget::new(2, Duration::from_secs(60));
        let source: IpAddr = "192.168.1.20".parse().unwrap();
        let start = std::time::Instant::now();
        assert!(budget.allow_at(source, start));
        assert!(budget.allow_at(source, start));
        assert!(!budget.allow_at(source, start));
        assert!(budget.allow_at(source, start + Duration::from_secs(61)));
    }

    #[test]
    fn persisted_runtime_status_expires_without_a_heartbeat() {
        assert!(runtime_status_is_fresh(100, 104));
        assert!(!runtime_status_is_fresh(100, 106));
        assert!(!runtime_status_is_fresh(200, 100));
    }

    #[test]
    fn origin_must_match_the_request_authority_and_transport() {
        assert!(origin_allowed(
            Some("https://192.168.0.123:18123"),
            "192.168.0.123:18123",
            true,
        ));
        assert!(origin_allowed(
            Some("http://localdesk.local:18123"),
            "localdesk.local:18123",
            false,
        ));
        assert!(!origin_allowed(
            Some("https://evil.example"),
            "192.168.0.123:18123",
            true,
        ));
        assert!(!origin_allowed(None, "192.168.0.123:18123", true));
        assert!(!origin_allowed(
            Some("http://192.168.0.123:18123"),
            "192.168.0.123:18123",
            true,
        ));
    }

    #[test]
    fn authority_validation_rejects_header_injection_and_user_info() {
        assert!(valid_authority("192.168.0.123:18123"));
        assert!(valid_authority("[fd00::20]:18123"));
        assert!(!valid_authority("user@192.168.0.123:18123"));
        assert!(!valid_authority("192.168.0.123:18123\r\nX-Test: bad"));
        assert!(!valid_authority(""));
    }

    #[test]
    fn authority_must_target_the_local_device() {
        let allowed = HashSet::from([
            "192.168.0.123".to_owned(),
            "fd00::20".to_owned(),
            "localdesk.local".to_owned(),
        ]);
        assert!(authority_host_allowed("192.168.0.123:18123", &allowed));
        assert!(authority_host_allowed("[fd00::20]:18123", &allowed));
        assert!(authority_host_allowed("localdesk.local:18123", &allowed));
        assert!(!authority_host_allowed("attacker.example:18123", &allowed));
    }

    #[test]
    fn request_authority_supports_http1_and_http2_without_host_confusion() {
        let mut http1_headers = HeaderMap::new();
        http1_headers.insert(HOST, HeaderValue::from_static("10.1.1.124:18123"));
        let origin_form = "/".parse().unwrap();
        assert_eq!(
            request_authority(&http1_headers, &origin_form),
            Some("10.1.1.124:18123")
        );

        let http2_headers = HeaderMap::new();
        let absolute_form = "https://10.1.1.124:18123/".parse().unwrap();
        assert_eq!(
            request_authority(&http2_headers, &absolute_form),
            Some("10.1.1.124:18123")
        );

        let mut conflicting_headers = HeaderMap::new();
        conflicting_headers.insert(HOST, HeaderValue::from_static("attacker.example:18123"));
        assert_eq!(
            request_authority(&conflicting_headers, &absolute_form),
            None
        );
    }

    #[test]
    fn content_security_policy_allows_wasm_without_general_eval() {
        let script_sources = CONTENT_SECURITY_POLICY
            .split(';')
            .map(str::trim)
            .find(|directive| directive.starts_with("script-src "))
            .unwrap();
        let sources = script_sources.split_whitespace().collect::<Vec<_>>();

        assert!(sources.contains(&"'self'"));
        assert!(sources.contains(&"'wasm-unsafe-eval'"));
        assert!(!sources.contains(&"'unsafe-eval'"));
        assert!(!sources.contains(&"'unsafe-inline'"));
    }

    #[test]
    fn websocket_payloads_have_a_bounded_size() {
        assert!(validate_websocket_payload_len(1).is_ok());
        assert!(validate_websocket_payload_len(MAX_WEBSOCKET_PAYLOAD_LEN).is_ok());
        assert!(validate_websocket_payload_len(0).is_err());
        assert!(validate_websocket_payload_len(MAX_WEBSOCKET_PAYLOAD_LEN + 1).is_err());
    }

    #[tokio::test]
    async fn generated_certificate_can_configure_the_https_server() {
        ensure_tls_crypto_provider().unwrap();
        let (certificate_authority, mut certificate_authority_key) =
            generate_certificate_authority().unwrap();
        let (certificate, mut private_key) =
            generate_leaf_certificate(&certificate_authority_key, &["localhost".to_owned()])
                .unwrap();
        assert!(!certificate_authority.is_empty());
        assert!(!certificate_authority_key.is_empty());
        assert!(!certificate.is_empty());
        assert!(!private_key.is_empty());
        assert!(RustlsConfig::from_der(
            vec![certificate, certificate_authority],
            private_key.clone()
        )
        .await
        .is_ok());
        private_key.zeroize();
        certificate_authority_key.zeroize();
    }

    #[tokio::test]
    async fn pem_certificate_chain_can_configure_the_https_server() {
        ensure_tls_crypto_provider().unwrap();
        let CertifiedKey { cert, key_pair } =
            rcgen::generate_simple_self_signed(vec!["localhost".to_owned()]).unwrap();
        let certificate = cert.pem().into_bytes();
        let mut private_key = key_pair.serialize_pem().into_bytes();
        assert!(validate_tls_material(&certificate, &private_key).is_ok());
        assert!(RustlsConfig::from_pem(certificate, private_key.clone())
            .await
            .is_ok());
        private_key.zeroize();
    }

    #[test]
    fn custom_certificate_validation_rejects_a_mismatched_private_key() {
        let CertifiedKey { cert, .. } =
            rcgen::generate_simple_self_signed(vec!["localhost".to_owned()]).unwrap();
        let CertifiedKey { key_pair, .. } =
            rcgen::generate_simple_self_signed(vec!["localhost".to_owned()]).unwrap();
        let certificate = cert.pem();
        let mut private_key = key_pair.serialize_pem();
        assert!(validate_tls_material(certificate.as_bytes(), private_key.as_bytes()).is_err());
        private_key.zeroize();
    }
}
