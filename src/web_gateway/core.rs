use std::{
    collections::{HashMap, HashSet},
    fs::{self, OpenOptions},
    future::Future,
    io::{self, Write},
    net::{IpAddr, Ipv4Addr, SocketAddr},
    path::{Path, PathBuf},
    pin::Pin,
    sync::{
        atomic::{AtomicUsize, Ordering},
        Arc, Mutex,
    },
    time::{Duration, Instant, SystemTime, UNIX_EPOCH},
};

use axum::{
    body::Body,
    extract::{
        ws::{Message as WebSocketMessage, WebSocket, WebSocketUpgrade},
        ConnectInfo, State,
    },
    http::{
        header::{CACHE_CONTROL, CONTENT_DISPOSITION, CONTENT_TYPE, HOST, ORIGIN},
        HeaderMap, HeaderValue, Request, StatusCode, Uri,
    },
    middleware::{self, Next},
    response::{IntoResponse, Response},
    routing::get,
    Json, Router,
};
use axum_server::{
    accept::Accept,
    tls_rustls::{RustlsAcceptor, RustlsConfig},
    Handle,
};
use hbb_common::{
    anyhow::{anyhow, bail, Context},
    bytes::Bytes,
    bytes_codec::BytesCodec,
    config::Config,
    futures::{SinkExt, StreamExt},
    log,
    sha2::{Digest, Sha256},
    tcp,
    tokio::{
        self,
        io::{duplex, AsyncReadExt, AsyncWriteExt},
        net::TcpStream,
        sync::{watch, OwnedSemaphorePermit, Semaphore},
        time::timeout,
    },
    tokio_util::codec::Framed,
    ResultType, Stream,
};
use rcgen::{
    BasicConstraints, CertificateParams, DistinguishedName, DnType, ExtendedKeyUsagePurpose, IsCa,
    KeyPair, KeyUsagePurpose,
};
use rustls::pki_types::{pem::PemObject, CertificateDer, PrivateKeyDer};
use tower_http::compression::CompressionLayer;
use x509_parser::prelude::{parse_x509_certificate, GeneralName};
use zeroize::Zeroize;

use crate::server::ServerPtr;

pub const DEFAULT_WEB_PORT: u16 = 18_123;
pub const MAX_WEBSOCKET_PAYLOAD_LEN: usize = 32 * 1024 * 1024;
pub const MAX_WEBSOCKET_CLIENT_PAYLOAD_LEN: usize = 256 * 1024;
const MAX_WEB_CONNECTIONS: usize = 16;
const MAX_WEB_CONNECTIONS_PER_SOURCE: usize = 4;
const MAX_WEB_REQUESTS_PER_MINUTE: usize = 120;
const WEB_CERTIFICATE_FILENAME: &str = "web-cert.der";
const WEB_PRIVATE_KEY_FILENAME: &str = "web-key.der";
const WEB_CA_CERTIFICATE_FILENAME: &str = "web-ca-cert.der";
const WEB_CA_PRIVATE_KEY_FILENAME: &str = "web-ca-key.der";
const WEB_CERTIFICATE_METADATA_FILENAME: &str = "web-cert-metadata.json";
const WEB_RUNTIME_STATUS_FILENAME: &str = "web-runtime.json";
const MAX_HTTP_REDIRECT_REQUEST_LEN: usize = 16 * 1024;
const MAX_CUSTOM_CERTIFICATE_LEN: u64 = 4 * 1024 * 1024;
const MAX_CUSTOM_PRIVATE_KEY_LEN: u64 = 1024 * 1024;
const HTTP_REDIRECT_TIMEOUT: Duration = Duration::from_secs(5);
const WEB_SOCKET_IDLE_TIMEOUT: Duration = Duration::from_secs(120);
const WEB_SOCKET_SHUTDOWN_TIMEOUT: Duration = Duration::from_secs(2);
const WEB_RUNTIME_HEARTBEAT_INTERVAL: Duration = Duration::from_secs(2);
const WEB_RUNTIME_STALE_SECONDS: u64 = 5;
const INDEX_HTML: &str = include_str!("../../web/dist/index.html");
const APP_JS: &[u8] = include_bytes!("../../web/dist/app.js");
const VIDEO_WORKER_JS: &[u8] = include_bytes!("../../web/dist/video-worker.js");
const STYLE_CSS: &str = include_str!("../../web/dist/style.css");
const GENERATED_CERTIFICATE_ROTATION_SECONDS: u64 = 30 * 24 * 60 * 60;
const CONTENT_SECURITY_POLICY: &str = "default-src 'self'; base-uri 'none'; connect-src 'self'; frame-ancestors 'none'; img-src 'self' data:; object-src 'none'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self'; worker-src 'self' blob:";

#[derive(Clone)]
struct WebState {
    server: ServerPtr,
    secure: bool,
    allowed_hosts: Arc<HashSet<String>>,
    connection_limiter: ConnectionLimiter,
    request_budget: Arc<Mutex<RequestRateBudget>>,
}

#[derive(Clone, Debug, serde::Deserialize, serde::Serialize)]
struct GeneratedCertificateMetadata {
    subject_alt_names: Vec<String>,
    generated_at_unix_seconds: u64,
}

#[derive(Clone, Debug, serde::Deserialize, serde::Serialize)]
pub(crate) struct WebRuntimeStatus {
    pub state: String,
    pub endpoints: Vec<String>,
    pub last_error: String,
    pub updated_at_unix_seconds: u64,
    pub process_id: u32,
    pub active_sessions: usize,
}

static ACTIVE_WEB_SESSIONS: AtomicUsize = AtomicUsize::new(0);

#[derive(Clone)]
struct ConnectionLimiter {
    global: Arc<Semaphore>,
    per_source: Arc<Mutex<HashMap<IpAddr, usize>>>,
    max_per_source: usize,
}

#[derive(Copy, Clone, Debug, Eq, PartialEq)]
enum ConnectionLimitError {
    Global,
    Source,
}

struct ConnectionPermit {
    _global: OwnedSemaphorePermit,
    source: IpAddr,
    per_source: Arc<Mutex<HashMap<IpAddr, usize>>>,
}

impl ConnectionLimiter {
    fn new(max_global: usize, max_per_source: usize) -> Self {
        Self {
            global: Arc::new(Semaphore::new(max_global)),
            per_source: Arc::new(Mutex::new(HashMap::new())),
            max_per_source,
        }
    }

    fn try_acquire(&self, source: IpAddr) -> Result<ConnectionPermit, ConnectionLimitError> {
        let global = self
            .global
            .clone()
            .try_acquire_owned()
            .map_err(|_| ConnectionLimitError::Global)?;
        let mut sources = self.per_source.lock().unwrap();
        let count = sources.entry(source).or_default();
        if *count >= self.max_per_source {
            return Err(ConnectionLimitError::Source);
        }
        *count += 1;
        ACTIVE_WEB_SESSIONS.fetch_add(1, Ordering::SeqCst);
        drop(sources);
        Ok(ConnectionPermit {
            _global: global,
            source,
            per_source: self.per_source.clone(),
        })
    }
}

impl Drop for ConnectionPermit {
    fn drop(&mut self) {
        ACTIVE_WEB_SESSIONS.fetch_sub(1, Ordering::SeqCst);
        let mut sources = self.per_source.lock().unwrap();
        if let Some(count) = sources.get_mut(&self.source) {
            *count = count.saturating_sub(1);
            if *count == 0 {
                sources.remove(&self.source);
            }
        }
    }
}

fn unix_seconds() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

fn runtime_status_path() -> PathBuf {
    Config::path(WEB_RUNTIME_STATUS_FILENAME)
}

fn runtime_status_is_fresh(updated_at: u64, now: u64) -> bool {
    now >= updated_at && now.saturating_sub(updated_at) <= WEB_RUNTIME_STALE_SECONDS
}

fn write_runtime_status(state: &str, endpoints: &[String], last_error: &str) -> ResultType<()> {
    let status = WebRuntimeStatus {
        state: state.to_owned(),
        endpoints: endpoints.to_vec(),
        last_error: last_error.to_owned(),
        updated_at_unix_seconds: unix_seconds(),
        process_id: std::process::id(),
        active_sessions: ACTIVE_WEB_SESSIONS.load(Ordering::SeqCst),
    };
    let path = runtime_status_path();
    let bytes = serde_json::to_vec(&status).context("Failed to encode Web runtime status")?;
    let temp_path = path.with_extension("json.tmp");
    write_private_file(&temp_path, &bytes)?;
    #[cfg(windows)]
    if path.exists() {
        fs::remove_file(&path)
            .with_context(|| format!("Failed to replace Web runtime status {}", path.display()))?;
    }
    fs::rename(&temp_path, &path)
        .with_context(|| format!("Failed to publish Web runtime status {}", path.display()))
}

pub(crate) fn record_start_failure(error: &str) {
    if let Err(write_error) = write_runtime_status("failed", &[], error) {
        log::debug!("Failed to record Web startup error: {write_error}");
    }
}

pub(crate) fn runtime_status() -> WebRuntimeStatus {
    if !is_enabled() {
        return WebRuntimeStatus {
            state: "disabled".to_owned(),
            endpoints: Vec::new(),
            last_error: String::new(),
            updated_at_unix_seconds: unix_seconds(),
            process_id: 0,
            active_sessions: 0,
        };
    }
    let path = runtime_status_path();
    let parsed = fs::read(&path)
        .ok()
        .and_then(|bytes| serde_json::from_slice::<WebRuntimeStatus>(&bytes).ok());
    match parsed {
        Some(mut status)
            if runtime_status_is_fresh(status.updated_at_unix_seconds, unix_seconds()) =>
        {
            status.active_sessions = ACTIVE_WEB_SESSIONS
                .load(Ordering::SeqCst)
                .max(status.active_sessions);
            status
        }
        Some(status) => WebRuntimeStatus {
            state: "stale".to_owned(),
            endpoints: status.endpoints,
            last_error: "Web runtime heartbeat is stale".to_owned(),
            updated_at_unix_seconds: status.updated_at_unix_seconds,
            process_id: status.process_id,
            active_sessions: 0,
        },
        None => WebRuntimeStatus {
            state: "starting".to_owned(),
            endpoints: Vec::new(),
            last_error: String::new(),
            updated_at_unix_seconds: unix_seconds(),
            process_id: 0,
            active_sessions: 0,
        },
    }
}

struct RequestRateBudget {
    max_requests: usize,
    window: Duration,
    sources: HashMap<IpAddr, (Instant, usize)>,
}

impl RequestRateBudget {
    fn new(max_requests: usize, window: Duration) -> Self {
        Self {
            max_requests,
            window,
            sources: HashMap::new(),
        }
    }

    fn allow(&mut self, source: IpAddr) -> bool {
        self.allow_at(source, Instant::now())
    }

    fn allow_at(&mut self, source: IpAddr, now: Instant) -> bool {
        self.sources
            .retain(|_, (started, _)| now.duration_since(*started) < self.window);
        let (started, count) = self.sources.entry(source).or_insert((now, 0));
        if now.duration_since(*started) >= self.window {
            *started = now;
            *count = 0;
        }
        if *count >= self.max_requests {
            return false;
        }
        *count += 1;
        true
    }
}

fn option_enabled(value: &str) -> bool {
    value == "Y"
}

fn https_required() -> bool {
    true
}

fn parse_web_port(value: &str) -> u16 {
    value
        .parse::<u16>()
        .ok()
        .filter(|port| *port > 0)
        .unwrap_or(DEFAULT_WEB_PORT)
}

fn valid_authority(authority: &str) -> bool {
    if authority.is_empty()
        || authority.len() > 512
        || authority.chars().any(char::is_whitespace)
        || authority
            .chars()
            .any(|value| matches!(value, '@' | '/' | '\\' | '?' | '#'))
    {
        return false;
    }
    let Ok(url) = url::Url::parse(&format!("http://{authority}")) else {
        return false;
    };
    url.host().is_some()
        && url.username().is_empty()
        && url.password().is_none()
        && url.path() == "/"
        && url.query().is_none()
        && url.fragment().is_none()
}

fn request_authority<'a>(headers: &'a HeaderMap, uri: &'a Uri) -> Option<&'a str> {
    let header_authority = match headers.get(HOST) {
        Some(value) => Some(value.to_str().ok()?),
        None => None,
    };
    let uri_authority = uri.authority().map(|value| value.as_str());
    match (header_authority, uri_authority) {
        (Some(header), Some(uri)) if header == uri => Some(header),
        (Some(_), Some(_)) => None,
        (Some(header), None) => Some(header),
        (None, Some(uri)) => Some(uri),
        (None, None) => None,
    }
}

fn origin_allowed(origin: Option<&str>, authority: &str, secure: bool) -> bool {
    if !valid_authority(authority) {
        return false;
    }
    let Some(origin) = origin else {
        return false;
    };
    let expected_scheme = if secure { "https" } else { "http" };
    let Ok(actual) = url::Url::parse(origin) else {
        return false;
    };
    let Ok(expected) = url::Url::parse(&format!("{expected_scheme}://{authority}")) else {
        return false;
    };
    actual.scheme() == expected.scheme()
        && actual.host() == expected.host()
        && actual.port_or_known_default() == expected.port_or_known_default()
        && actual.username().is_empty()
        && actual.password().is_none()
        && actual.path() == "/"
        && actual.query().is_none()
        && actual.fragment().is_none()
}

fn authority_host_allowed(authority: &str, allowed_hosts: &HashSet<String>) -> bool {
    if !valid_authority(authority) {
        return false;
    }
    url::Url::parse(&format!("http://{authority}"))
        .ok()
        .and_then(|url| {
            url.host().map(|host| {
                host.to_string()
                    .trim_start_matches('[')
                    .trim_end_matches(']')
                    .to_ascii_lowercase()
            })
        })
        .map(|host| allowed_hosts.contains(&host))
        .unwrap_or(false)
}

fn validate_websocket_payload_len(len: usize) -> ResultType<()> {
    if len == 0 {
        bail!("Empty WebSocket payload");
    }
    if len > MAX_WEBSOCKET_PAYLOAD_LEN {
        bail!("WebSocket payload is too large");
    }
    Ok(())
}

pub fn is_enabled() -> bool {
    option_enabled(&Config::get_option("web-access-enabled"))
}

pub fn is_https_enabled() -> bool {
    https_required()
}

pub fn configured_port() -> u16 {
    parse_web_port(&Config::get_option("web-listen-port"))
}

