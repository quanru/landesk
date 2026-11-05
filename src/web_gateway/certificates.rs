fn certificate_paths() -> (PathBuf, PathBuf) {
    (
        Config::path(WEB_CERTIFICATE_FILENAME),
        Config::path(WEB_PRIVATE_KEY_FILENAME),
    )
}

fn certificate_authority_paths() -> (PathBuf, PathBuf) {
    (
        Config::path(WEB_CA_CERTIFICATE_FILENAME),
        Config::path(WEB_CA_PRIVATE_KEY_FILENAME),
    )
}

pub(crate) fn certificate_authority_path_for_ui() -> String {
    if !Config::get_option("web-certificate-path").trim().is_empty() {
        return String::new();
    }
    let (path, _) = certificate_authority_paths();
    if path.is_file() {
        path.to_string_lossy().into_owned()
    } else {
        String::new()
    }
}

fn certificate_metadata_path() -> PathBuf {
    Config::path(WEB_CERTIFICATE_METADATA_FILENAME)
}

fn custom_certificate_paths(
    certificate_path: &str,
    private_key_path: &str,
) -> ResultType<Option<(PathBuf, PathBuf)>> {
    let certificate_path = certificate_path.trim();
    let private_key_path = private_key_path.trim();
    match (certificate_path.is_empty(), private_key_path.is_empty()) {
        (true, true) => return Ok(None),
        (true, false) | (false, true) => {
            bail!("Custom Web certificate and private key must both be configured")
        }
        (false, false) => {}
    }
    let certificate_path = PathBuf::from(certificate_path);
    let private_key_path = PathBuf::from(private_key_path);
    if !certificate_path.is_absolute() || !private_key_path.is_absolute() {
        bail!("Custom Web certificate and private key paths must be absolute");
    }
    Ok(Some((certificate_path, private_key_path)))
}

pub(crate) fn validate_custom_certificate_files(
    certificate_path: &str,
    private_key_path: &str,
) -> ResultType<Option<(PathBuf, PathBuf)>> {
    let Some((certificate_path, private_key_path)) =
        custom_certificate_paths(certificate_path, private_key_path)?
    else {
        return Ok(None);
    };
    let certificate_metadata = fs::metadata(&certificate_path).with_context(|| {
        format!(
            "Failed to read custom Web certificate {}",
            certificate_path.display()
        )
    })?;
    if !certificate_metadata.is_file()
        || certificate_metadata.len() == 0
        || certificate_metadata.len() > MAX_CUSTOM_CERTIFICATE_LEN
    {
        bail!("Custom Web certificate must be a PEM file no larger than 4 MiB");
    }
    let private_key_metadata = fs::metadata(&private_key_path).with_context(|| {
        format!(
            "Failed to read custom Web private key {}",
            private_key_path.display()
        )
    })?;
    if !private_key_metadata.is_file()
        || private_key_metadata.len() == 0
        || private_key_metadata.len() > MAX_CUSTOM_PRIVATE_KEY_LEN
    {
        bail!("Custom Web private key must be a PEM file no larger than 1 MiB");
    }
    #[cfg(unix)]
    {
        use std::os::unix::fs::MetadataExt;
        if private_key_metadata.mode() & 0o077 != 0 {
            bail!("Custom Web private key must not be accessible by group or other users");
        }
    }
    let certificate = fs::read(&certificate_path).with_context(|| {
        format!(
            "Failed to read custom Web certificate {}",
            certificate_path.display()
        )
    })?;
    let mut private_key = fs::read(&private_key_path).with_context(|| {
        format!(
            "Failed to read custom Web private key {}",
            private_key_path.display()
        )
    })?;
    let validation_result = validate_tls_material(&certificate, &private_key);
    private_key.zeroize();
    validation_result?;
    Ok(Some((certificate_path, private_key_path)))
}

fn validate_tls_material(certificate: &[u8], private_key: &[u8]) -> ResultType<()> {
    ensure_tls_crypto_provider()?;
    let certificates = CertificateDer::pem_slice_iter(certificate)
        .collect::<Result<Vec<_>, _>>()
        .context("Custom Web certificate is not a valid PEM certificate chain")?;
    if certificates.is_empty() {
        bail!("Custom Web certificate must contain at least one PEM certificate");
    }
    validate_custom_certificate_identity(certificates[0].as_ref())?;
    let mut private_keys = PrivateKeyDer::pem_slice_iter(private_key)
        .collect::<Result<Vec<_>, _>>()
        .context("Custom Web private key is not a supported PEM private key")?;
    if private_keys.len() != 1 {
        bail!("Custom Web private key must contain exactly one private key");
    }
    rustls::ServerConfig::builder()
        .with_no_client_auth()
        .with_single_cert(certificates, private_keys.remove(0))
        .context("Custom Web certificate and private key are invalid or do not match")?;
    Ok(())
}

fn dns_name_matches(pattern: &str, host: &str) -> bool {
    let pattern = pattern.to_ascii_lowercase();
    let host = host.to_ascii_lowercase();
    if pattern == host {
        return true;
    }
    let Some(suffix) = pattern.strip_prefix("*.") else {
        return false;
    };
    let Some(prefix) = host.strip_suffix(suffix) else {
        return false;
    };
    prefix.ends_with('.') && !prefix[..prefix.len() - 1].contains('.')
}

fn validate_custom_certificate_identity(certificate: &[u8]) -> ResultType<()> {
    let (_, certificate) = parse_x509_certificate(certificate)
        .map_err(|_| anyhow!("Custom Web certificate could not be parsed"))?;
    if !certificate.validity().is_valid() {
        bail!("Custom Web certificate is expired or not yet valid");
    }
    let configured_hosts = Config::get_option("web-allowed-hosts")
        .split(',')
        .map(str::trim)
        .filter(|value| !value.is_empty())
        .map(normalize_configured_host)
        .collect::<Result<Vec<_>, _>>()?;
    if configured_hosts.is_empty() {
        return Ok(());
    }
    let names = certificate
        .subject_alternative_name()
        .context("Custom Web certificate has an invalid subject alternative name extension")?
        .ok_or_else(|| anyhow!("Custom Web certificate has no subject alternative names"))?;
    for host in configured_hosts {
        let host_ip = host.parse::<IpAddr>().ok();
        let covered = names.value.general_names.iter().any(|name| match name {
            GeneralName::DNSName(pattern) if host_ip.is_none() => dns_name_matches(pattern, &host),
            GeneralName::IPAddress(bytes) => match (host_ip, bytes.len()) {
                (Some(IpAddr::V4(expected)), 4) => expected.octets().as_slice() == *bytes,
                (Some(IpAddr::V6(expected)), 16) => expected.octets().as_slice() == *bytes,
                _ => false,
            },
            _ => false,
        });
        if !covered {
            bail!("Custom Web certificate does not cover allowed host {host}");
        }
    }
    Ok(())
}

fn build_certificate_subject_alt_names(
    configured_hosts: &str,
    listen_addresses: &[IpAddr],
    interface_addresses: &[IpAddr],
) -> Vec<String> {
    let mut names = vec!["localhost".to_owned(), "localdesk.local".to_owned()];
    names.extend(
        configured_hosts
            .split(',')
            .filter_map(|value| normalize_configured_host(value).ok()),
    );
    names.extend(
        listen_addresses
            .iter()
            .filter(|address| !address.is_unspecified())
            .map(ToString::to_string),
    );
    names.extend(interface_addresses.iter().map(ToString::to_string));
    names.sort();
    names.dedup();
    names
}

fn certificate_subject_alt_names() -> Vec<String> {
    let listen_addresses = match configured_addresses() {
        Ok(addresses) => addresses,
        Err(error) => {
            log::warn!("Failed to include Web listen addresses in certificate: {error}");
            Vec::new()
        }
    };
    let mut interface_addresses = Vec::new();
    for interface in default_net::get_interfaces() {
        interface_addresses.extend(
            interface
                .ipv4
                .into_iter()
                .filter(|network| web_source_allowed(IpAddr::V4(network.addr)))
                .map(|network| IpAddr::V4(network.addr)),
        );
        interface_addresses.extend(
            interface
                .ipv6
                .into_iter()
                .filter(|network| web_source_allowed(IpAddr::V6(network.addr)))
                .map(|network| IpAddr::V6(network.addr)),
        );
    }
    build_certificate_subject_alt_names(
        &Config::get_option("web-allowed-hosts"),
        &listen_addresses,
        &interface_addresses,
    )
}

pub(crate) fn certificate_address_signature() -> Vec<String> {
    certificate_subject_alt_names()
}

fn normalize_configured_host(value: &str) -> ResultType<String> {
    let value = value.trim();
    if value.is_empty() {
        bail!("Web allowed host must not be empty");
    }
    let url = url::Url::parse(&format!("http://{value}"))
        .map_err(|_| anyhow!("Invalid Web allowed host: {value}"))?;
    if !url.username().is_empty()
        || url.password().is_some()
        || url.port().is_some()
        || url.path() != "/"
        || url.query().is_some()
        || url.fragment().is_some()
    {
        bail!("Invalid Web allowed host: {value}");
    }
    url.host()
        .map(|host| {
            host.to_string()
                .trim_start_matches('[')
                .trim_end_matches(']')
                .to_ascii_lowercase()
        })
        .ok_or_else(|| anyhow!("Invalid Web allowed host: {value}"))
}

fn configured_allowed_hosts(
    configured: &str,
    base_hosts: Vec<String>,
) -> ResultType<HashSet<String>> {
    let configured_hosts = configured
        .split(',')
        .map(str::trim)
        .filter(|value| !value.is_empty())
        .map(normalize_configured_host)
        .collect::<Result<HashSet<_>, _>>()?;
    if configured_hosts.is_empty() {
        Ok(base_hosts
            .into_iter()
            .map(|host| host.to_ascii_lowercase())
            .collect())
    } else {
        Ok(configured_hosts)
    }
}

fn allowed_hosts() -> ResultType<Arc<HashSet<String>>> {
    let configured = Config::get_option("web-allowed-hosts");
    if configured.trim().is_empty() && !Config::get_option("web-certificate-path").trim().is_empty()
    {
        bail!("Web allowed host names are required with a custom certificate");
    }
    configured_allowed_hosts(&configured, certificate_subject_alt_names()).map(Arc::new)
}

fn generated_certificate_needs_rotation(
    metadata: &GeneratedCertificateMetadata,
    subject_alt_names: &[String],
    now_unix_seconds: u64,
) -> bool {
    metadata.subject_alt_names != subject_alt_names
        || now_unix_seconds.saturating_sub(metadata.generated_at_unix_seconds)
            >= GENERATED_CERTIFICATE_ROTATION_SECONDS
}

