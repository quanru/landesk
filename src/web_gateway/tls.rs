fn write_private_file(path: &Path, bytes: &[u8]) -> ResultType<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).with_context(|| {
            format!(
                "Failed to create certificate directory {}",
                parent.display()
            )
        })?;
    }
    let mut options = OpenOptions::new();
    options.write(true).create(true).truncate(true);
    #[cfg(unix)]
    {
        use std::os::unix::fs::OpenOptionsExt;
        options.mode(0o600);
    }
    let mut file = options
        .open(path)
        .with_context(|| format!("Failed to open {}", path.display()))?;
    file.write_all(bytes)
        .with_context(|| format!("Failed to write {}", path.display()))?;
    file.sync_all()
        .with_context(|| format!("Failed to sync {}", path.display()))?;
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        fs::set_permissions(path, fs::Permissions::from_mode(0o600))
            .with_context(|| format!("Failed to secure {}", path.display()))?;
    }
    Ok(())
}

#[cfg(unix)]
fn secure_private_file_permissions(path: &Path) -> ResultType<()> {
    use std::os::unix::fs::PermissionsExt;
    fs::set_permissions(path, fs::Permissions::from_mode(0o600))
        .with_context(|| format!("Failed to secure {}", path.display()))?;
    Ok(())
}

#[cfg(not(unix))]
fn secure_private_file_permissions(_path: &Path) -> ResultType<()> {
    Ok(())
}

fn certificate_authority_params() -> CertificateParams {
    let mut params = CertificateParams::default();
    let mut distinguished_name = DistinguishedName::new();
    distinguished_name.push(DnType::CommonName, "LocalDesk Local CA");
    params.distinguished_name = distinguished_name;
    params.is_ca = IsCa::Ca(BasicConstraints::Unconstrained);
    params.key_usages = vec![
        KeyUsagePurpose::KeyCertSign,
        KeyUsagePurpose::DigitalSignature,
        KeyUsagePurpose::CrlSign,
    ];
    params
}

fn generate_certificate_authority() -> ResultType<(Vec<u8>, Vec<u8>)> {
    let key_pair =
        KeyPair::generate().context("Failed to generate the Web certificate authority key")?;
    let certificate = certificate_authority_params()
        .self_signed(&key_pair)
        .context("Failed to generate the Web certificate authority")?;
    Ok((certificate.der().to_vec(), key_pair.serialize_der()))
}

fn certificate_authority_material_valid(certificate: &[u8], private_key: &[u8]) -> bool {
    let Ok(key_pair) = KeyPair::try_from(private_key) else {
        return false;
    };
    let Ok((remaining, certificate)) = parse_x509_certificate(certificate) else {
        return false;
    };
    remaining.is_empty()
        && certificate.validity().is_valid()
        && certificate.is_ca()
        && certificate.public_key().raw == key_pair.public_key_der()
}

fn generate_leaf_certificate(
    certificate_authority_key: &[u8],
    subject_alt_names: &[String],
) -> ResultType<(Vec<u8>, Vec<u8>)> {
    let certificate_authority_key = KeyPair::try_from(certificate_authority_key)
        .context("Failed to load the Web certificate authority key")?;
    let certificate_authority = certificate_authority_params()
        .self_signed(&certificate_authority_key)
        .context("Failed to reconstruct the Web certificate authority")?;
    let leaf_key = KeyPair::generate().context("Failed to generate the Web server key")?;
    let mut params = CertificateParams::new(subject_alt_names.to_vec())
        .context("Failed to configure Web certificate names")?;
    let mut distinguished_name = DistinguishedName::new();
    distinguished_name.push(DnType::CommonName, "localdesk.local");
    params.distinguished_name = distinguished_name;
    params.extended_key_usages = vec![ExtendedKeyUsagePurpose::ServerAuth];
    params.key_usages = vec![KeyUsagePurpose::DigitalSignature];
    let certificate = params
        .signed_by(
            &leaf_key,
            &certificate_authority,
            &certificate_authority_key,
        )
        .context("Failed to sign the Web server certificate")?;
    Ok((certificate.der().to_vec(), leaf_key.serialize_der()))
}

fn load_or_generate_certificate_authority() -> ResultType<(Vec<u8>, Vec<u8>)> {
    let (certificate_path, private_key_path) = certificate_authority_paths();
    match (fs::read(&certificate_path), fs::read(&private_key_path)) {
        (Ok(certificate), Ok(private_key))
            if !certificate.is_empty()
                && !private_key.is_empty()
                && certificate_authority_material_valid(&certificate, &private_key) =>
        {
            secure_private_file_permissions(&private_key_path)?;
            return Ok((certificate, private_key));
        }
        _ => {}
    }
    let (certificate, mut private_key) = generate_certificate_authority()?;
    if let Err(err) = write_private_file(&private_key_path, &private_key) {
        private_key.zeroize();
        return Err(err);
    }
    if let Err(err) = write_private_file(&certificate_path, &certificate) {
        private_key.zeroize();
        return Err(err);
    }
    Ok((certificate, private_key))
}

fn load_generated_certificate_metadata() -> Option<GeneratedCertificateMetadata> {
    fs::read(certificate_metadata_path())
        .ok()
        .and_then(|bytes| serde_json::from_slice(&bytes).ok())
}

fn write_generated_certificate_metadata(metadata: &GeneratedCertificateMetadata) -> ResultType<()> {
    let bytes =
        serde_json::to_vec(metadata).context("Failed to encode Web certificate metadata")?;
    write_private_file(&certificate_metadata_path(), &bytes)
}

fn load_or_generate_certificate() -> ResultType<(Vec<Vec<u8>>, Vec<u8>)> {
    let (certificate_authority, mut certificate_authority_key) =
        load_or_generate_certificate_authority()?;
    let subject_alt_names = certificate_subject_alt_names();
    let now = unix_seconds();
    let metadata = load_generated_certificate_metadata();
    let (certificate_path, private_key_path) = certificate_paths();
    let existing = match (fs::read(&certificate_path), fs::read(&private_key_path)) {
        (Ok(certificate), Ok(private_key))
            if !certificate.is_empty()
                && !private_key.is_empty()
                && metadata
                    .as_ref()
                    .map(|metadata| {
                        !generated_certificate_needs_rotation(metadata, &subject_alt_names, now)
                    })
                    .unwrap_or(false) =>
        {
            secure_private_file_permissions(&private_key_path)?;
            Some((certificate, private_key))
        }
        _ => None,
    };
    let (certificate, private_key) = match existing {
        Some(existing) => existing,
        None => {
            let (certificate, mut private_key) =
                generate_leaf_certificate(&certificate_authority_key, &subject_alt_names)?;
            if let Err(err) = write_private_file(&private_key_path, &private_key) {
                private_key.zeroize();
                certificate_authority_key.zeroize();
                return Err(err);
            }
            if let Err(err) = write_private_file(&certificate_path, &certificate) {
                private_key.zeroize();
                certificate_authority_key.zeroize();
                return Err(err);
            }
            write_generated_certificate_metadata(&GeneratedCertificateMetadata {
                subject_alt_names,
                generated_at_unix_seconds: now,
            })?;
            (certificate, private_key)
        }
    };
    certificate_authority_key.zeroize();
    Ok((vec![certificate, certificate_authority], private_key))
}

async fn load_tls_config() -> ResultType<RustlsConfig> {
    ensure_tls_crypto_provider()?;
    if let Some((certificate_path, private_key_path)) = validate_custom_certificate_files(
        &Config::get_option("web-certificate-path"),
        &Config::get_option("web-private-key-path"),
    )? {
        return RustlsConfig::from_pem_chain_file(&certificate_path, &private_key_path)
            .await
            .with_context(|| {
                format!(
                    "Failed to load custom Web TLS certificate {} and private key {}",
                    certificate_path.display(),
                    private_key_path.display()
                )
            });
    }
    let (certificates, mut private_key) = load_or_generate_certificate()?;
    let result = RustlsConfig::from_der(certificates, private_key.clone())
        .await
        .context("Failed to load the Web TLS certificate");
    private_key.zeroize();
    if let Ok(config) = result {
        return Ok(config);
    }

    log::warn!("Regenerating an invalid Web TLS certificate");
    let _ = fs::remove_file(certificate_metadata_path());
    let (certificates, mut private_key) = load_or_generate_certificate()?;
    let result = RustlsConfig::from_der(certificates, private_key.clone())
        .await
        .context("Failed to load the regenerated Web TLS certificate");
    private_key.zeroize();
    result
}

fn ensure_tls_crypto_provider() -> ResultType<()> {
    if rustls::crypto::CryptoProvider::get_default().is_some() {
        return Ok(());
    }
    if rustls::crypto::ring::default_provider()
        .install_default()
        .is_ok()
        || rustls::crypto::CryptoProvider::get_default().is_some()
    {
        Ok(())
    } else {
        bail!("Failed to initialize the HTTPS cryptography provider")
    }
}

fn configured_address_values(web_value: &str) -> ResultType<Vec<IpAddr>> {
    let values: Vec<_> = web_value
        .split(',')
        .map(str::trim)
        .filter(|value| !value.is_empty())
        .map(|value| {
            value
                .parse::<IpAddr>()
                .map_err(|_| anyhow!("Invalid Web listen address: {value}"))
        })
        .collect::<Result<_, _>>()?;
    if values.is_empty() {
        Ok(vec![IpAddr::V4(Ipv4Addr::UNSPECIFIED)])
    } else {
        Ok(values)
    }
}

fn configured_addresses() -> ResultType<Vec<IpAddr>> {
    configured_address_values(
        &Config::get_option("web-listen-addresses"),
    )
}

fn web_source_allowed(ip: IpAddr) -> bool {
    let configured = Config::get_option("web-allowed-networks");
    source_allowed_with(ip, &configured)
}

fn validate_web_network_policy() -> ResultType<()> {
    let configured = Config::get_option("web-allowed-networks");
    normalize_allowed_networks(&configured)
        .context("Invalid Web allowed network policy")?;
    Ok(())
}

