fn asset_hash(bytes: &[u8]) -> String {
    format!("{:x}", Sha256::digest(bytes))
}

fn app_javascript_path() -> String {
    format!("/app.{}.js", &asset_hash(APP_JS)[..16])
}

fn stylesheet_path() -> String {
    format!("/style.{}.css", &asset_hash(STYLE_CSS.as_bytes())[..16])
}

fn video_worker_javascript_path() -> String {
    format!("/video-worker.{}.js", &asset_hash(VIDEO_WORKER_JS)[..16])
}

fn cache_control_for_path(path: &str) -> &'static str {
    let file_name = path.rsplit('/').next().unwrap_or_default();
    let is_hashed_asset = (file_name.starts_with("app.") && file_name.ends_with(".js"))
        || (file_name.starts_with("video-worker.") && file_name.ends_with(".js"))
        || (file_name.starts_with("style.") && file_name.ends_with(".css"));
    if is_hashed_asset
        && file_name
            .split('.')
            .nth(1)
            .map(|hash| hash.len() >= 16 && hash.bytes().all(|value| value.is_ascii_hexdigit()))
            .unwrap_or(false)
    {
        "public, max-age=31536000, immutable"
    } else {
        "no-store"
    }
}

fn looks_like_plain_http(prefix: &[u8]) -> bool {
    prefix
        .first()
        .map(|value| value.is_ascii_uppercase())
        .unwrap_or(false)
}

fn http_redirect_location(
    request: &[u8],
    https_port: u16,
    allowed_hosts: &HashSet<String>,
) -> Option<String> {
    let header_end = request.windows(4).position(|value| value == b"\r\n\r\n")?;
    let request = std::str::from_utf8(&request[..header_end]).ok()?;
    let mut lines = request.split("\r\n");
    let mut request_line = lines.next()?.split_whitespace();
    let method = request_line.next()?;
    let target = request_line.next()?;
    let version = request_line.next()?;
    if request_line.next().is_some()
        || method.is_empty()
        || !method.bytes().all(|value| value.is_ascii_uppercase())
        || !matches!(version, "HTTP/1.0" | "HTTP/1.1")
    {
        return None;
    }
    let hosts = lines
        .filter_map(|line| line.split_once(':'))
        .filter(|(name, _)| name.trim().eq_ignore_ascii_case("host"))
        .map(|(_, value)| value.trim())
        .collect::<Vec<_>>();
    let [authority] = hosts.as_slice() else {
        return None;
    };
    if !authority_host_allowed(authority, allowed_hosts) {
        return None;
    }
    let authority_url = url::Url::parse(&format!("http://{authority}")).ok()?;
    let host = match authority_url.host()? {
        url::Host::Domain(value) => value.to_owned(),
        url::Host::Ipv4(value) => value.to_string(),
        url::Host::Ipv6(value) => format!("[{value}]"),
    };
    let target = target.parse::<Uri>().ok()?;
    if target.scheme().is_some() || target.authority().is_some() || !target.path().starts_with('/')
    {
        return None;
    }
    let path_and_query = target.path_and_query()?.as_str();
    Some(format!("https://{host}:{https_port}{path_and_query}"))
}

async fn write_plain_http_response(stream: &mut TcpStream, response: &[u8]) -> io::Result<()> {
    stream.write_all(response).await?;
    stream.shutdown().await
}

async fn redirect_plain_http(
    stream: &mut TcpStream,
    https_port: u16,
    allowed_hosts: &HashSet<String>,
) -> io::Result<()> {
    let remote_addr = stream.peer_addr()?;
    if !web_source_allowed(remote_addr.ip()) {
        return write_plain_http_response(
            stream,
            b"HTTP/1.1 403 Forbidden\r\nConnection: close\r\nContent-Length: 0\r\nCache-Control: no-store\r\n\r\n",
        )
        .await;
    }
    let mut request = Vec::with_capacity(1024);
    let mut buffer = [0u8; 1024];
    while request.len() < MAX_HTTP_REDIRECT_REQUEST_LEN {
        let read = stream.read(&mut buffer).await?;
        if read == 0 {
            break;
        }
        request.extend_from_slice(&buffer[..read]);
        if request.windows(4).any(|value| value == b"\r\n\r\n") {
            break;
        }
    }
    let Some(location) = http_redirect_location(&request, https_port, allowed_hosts) else {
        return write_plain_http_response(
            stream,
            b"HTTP/1.1 400 Bad Request\r\nConnection: close\r\nContent-Length: 0\r\nCache-Control: no-store\r\n\r\n",
        )
        .await;
    };
    let response = format!(
        "HTTP/1.1 308 Permanent Redirect\r\nLocation: {location}\r\nConnection: close\r\nContent-Length: 0\r\nCache-Control: no-store\r\n\r\n"
    );
    write_plain_http_response(stream, response.as_bytes()).await
}

#[derive(Clone)]
struct HttpsRedirectAcceptor {
    https_port: u16,
    allowed_hosts: Arc<HashSet<String>>,
}

impl HttpsRedirectAcceptor {
    fn new(https_port: u16, allowed_hosts: Arc<HashSet<String>>) -> Self {
        Self {
            https_port,
            allowed_hosts,
        }
    }
}

impl<S> Accept<TcpStream, S> for HttpsRedirectAcceptor
where
    S: Send + 'static,
{
    type Stream = TcpStream;
    type Service = S;
    type Future = Pin<Box<dyn Future<Output = io::Result<(TcpStream, S)>> + Send>>;

    fn accept(&self, mut stream: TcpStream, service: S) -> Self::Future {
        let https_port = self.https_port;
        let allowed_hosts = self.allowed_hosts.clone();
        Box::pin(async move {
            let mut prefix = [0u8; 8];
            let read = timeout(HTTP_REDIRECT_TIMEOUT, stream.peek(&mut prefix))
                .await
                .map_err(|_| {
                    io::Error::new(io::ErrorKind::TimedOut, "connection detection timed out")
                })??;
            if looks_like_plain_http(&prefix[..read]) {
                let _ = timeout(
                    HTTP_REDIRECT_TIMEOUT,
                    redirect_plain_http(&mut stream, https_port, &allowed_hosts),
                )
                .await;
                return Err(io::Error::new(
                    io::ErrorKind::ConnectionAborted,
                    "plain HTTP request redirected to HTTPS",
                ));
            }
            Ok((stream, service))
        })
    }
}

fn app(state: WebState) -> Router {
    let app_path = app_javascript_path();
    let style_path = stylesheet_path();
    let worker_path = video_worker_javascript_path();
    Router::new()
        .route("/", get(index))
        .route(&app_path, get(app_javascript))
        .route(&worker_path, get(video_worker_javascript))
        .route(&style_path, get(stylesheet))
        .route("/api/info", get(info))
        .route("/api/ca-certificate", get(ca_certificate))
        .route("/ws", get(websocket_upgrade))
        .fallback(not_found)
        .layer(CompressionLayer::new().br(true).gzip(true))
        .layer(middleware::from_fn(security_headers))
        .layer(middleware::from_fn_with_state(
            state.clone(),
            restrict_request,
        ))
        .with_state(state)
}

async fn index() -> Response {
    let html = INDEX_HTML
        .replace("/app.js", &app_javascript_path())
        .replace("/style.css", &stylesheet_path());
    ([(CONTENT_TYPE, "text/html; charset=utf-8")], html).into_response()
}

async fn app_javascript() -> Response {
    (
        [(CONTENT_TYPE, "text/javascript; charset=utf-8")],
        Body::from(APP_JS),
    )
        .into_response()
}

async fn video_worker_javascript() -> Response {
    (
        [(CONTENT_TYPE, "text/javascript; charset=utf-8")],
        Body::from(VIDEO_WORKER_JS),
    )
        .into_response()
}

async fn stylesheet() -> Response {
    ([(CONTENT_TYPE, "text/css; charset=utf-8")], STYLE_CSS).into_response()
}

async fn ca_certificate() -> Response {
    if !Config::get_option("web-certificate-path").trim().is_empty() {
        return (StatusCode::NOT_FOUND, "A custom certificate is configured").into_response();
    }
    let (certificate_path, _) = certificate_authority_paths();
    match fs::read(&certificate_path) {
        Ok(certificate) if !certificate.is_empty() => (
            [
                (CONTENT_TYPE, "application/pkix-cert"),
                (
                    CONTENT_DISPOSITION,
                    "attachment; filename=\"localdesk-local-ca.der\"",
                ),
            ],
            Body::from(certificate),
        )
            .into_response(),
        _ => (
            StatusCode::NOT_FOUND,
            "Certificate authority is unavailable",
        )
            .into_response(),
    }
}

async fn info(State(state): State<WebState>) -> Response {
    Json(serde_json::json!({
        "app_name": crate::get_app_name(),
        "device_name": crate::whoami_hostname(),
        "peer_id": Config::get_id(),
        "version": crate::VERSION,
        "secure": state.secure,
        "certificate_mode": if Config::get_option("web-certificate-path").trim().is_empty() {
            "local-ca"
        } else {
            "custom"
        },
        "ca_certificate_url": if Config::get_option("web-certificate-path").trim().is_empty() {
            "/api/ca-certificate"
        } else {
            ""
        },
        "video_worker_url": video_worker_javascript_path(),
    }))
    .into_response()
}

async fn not_found() -> Response {
    (StatusCode::NOT_FOUND, "Not found").into_response()
}

async fn restrict_request(
    State(state): State<WebState>,
    request: Request<Body>,
    next: Next,
) -> Response {
    let source_allowed = request
        .extensions()
        .get::<ConnectInfo<SocketAddr>>()
        .map(|connect| web_source_allowed(connect.0.ip()))
        .unwrap_or(false);
    let source = request
        .extensions()
        .get::<ConnectInfo<SocketAddr>>()
        .map(|connect| connect.0.ip());
    let authority = request_authority(request.headers(), request.uri()).unwrap_or_default();
    if !source_allowed {
        log::warn!(
            "Rejected Web request from {}: source is outside the allowed networks",
            source
                .map(|address| address.to_string())
                .unwrap_or_else(|| "unknown source".to_owned())
        );
        return (StatusCode::FORBIDDEN, "Source address is not allowed").into_response();
    }
    if !authority_host_allowed(authority, &state.allowed_hosts) {
        log::warn!(
            "Rejected Web request from {} for disallowed Host {authority}",
            source
                .map(|address| address.to_string())
                .unwrap_or_else(|| "unknown source".to_owned())
        );
        return (StatusCode::FORBIDDEN, "Host is not allowed").into_response();
    }
    if !source
        .map(|source| state.request_budget.lock().unwrap().allow(source))
        .unwrap_or(false)
    {
        return (StatusCode::TOO_MANY_REQUESTS, "Too many requests").into_response();
    }
    next.run(request).await
}

async fn security_headers(request: Request<Body>, next: Next) -> Response {
    let cache_control = cache_control_for_path(request.uri().path());
    let mut response = next.run(request).await;
    let headers = response.headers_mut();
    headers.insert(CACHE_CONTROL, HeaderValue::from_static(cache_control));
    headers.insert(
        "content-security-policy",
        HeaderValue::from_static(CONTENT_SECURITY_POLICY),
    );
    headers.insert(
        "x-content-type-options",
        HeaderValue::from_static("nosniff"),
    );
    headers.insert("x-frame-options", HeaderValue::from_static("DENY"));
    headers.insert("referrer-policy", HeaderValue::from_static("no-referrer"));
    headers.insert(
        "permissions-policy",
        HeaderValue::from_static(
            "camera=(), microphone=(), geolocation=(), clipboard-read=(self), clipboard-write=(self), fullscreen=(self)",
        ),
    );
    response
}

