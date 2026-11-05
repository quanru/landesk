async fn websocket_upgrade(
    State(state): State<WebState>,
    ConnectInfo(remote_addr): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
    uri: Uri,
    websocket: WebSocketUpgrade,
) -> Response {
    let authority = request_authority(&headers, &uri).unwrap_or_default();
    let origin = headers.get(ORIGIN).and_then(|value| value.to_str().ok());
    if !web_source_allowed(remote_addr.ip())
        || !authority_host_allowed(authority, &state.allowed_hosts)
        || !origin_allowed(origin, authority, state.secure)
    {
        return (StatusCode::FORBIDDEN, "Forbidden").into_response();
    }
    let permit = match state.connection_limiter.try_acquire(remote_addr.ip()) {
        Ok(permit) => permit,
        Err(_) => return (StatusCode::TOO_MANY_REQUESTS, "Too many Web sessions").into_response(),
    };
    websocket
        .max_frame_size(MAX_WEBSOCKET_PAYLOAD_LEN)
        .max_message_size(MAX_WEBSOCKET_PAYLOAD_LEN)
        .on_upgrade(move |socket| bridge_websocket(socket, state.server, remote_addr, permit))
}

async fn bridge_websocket(
    mut socket: WebSocket,
    server: ServerPtr,
    remote_addr: SocketAddr,
    _permit: ConnectionPermit,
) {
    let (server_stream, bridge_stream) = duplex(4 * 1024 * 1024);
    let local_addr = SocketAddr::new(IpAddr::V4(Ipv4Addr::LOCALHOST), configured_port());
    // `duplex` yields a `DuplexStream` (a generic `TcpStreamTrait` impl), not a
    // concrete `TcpStream`, so `Stream::from` can't be used — build from the
    // framed stream instead.
    let stream = Stream::Tcp(tcp::FramedStream::from(server_stream, local_addr));
    let mut server_task = tokio::spawn(async move {
        if let Err(err) =
            crate::server::create_tcp_connection(server, stream, remote_addr, false, Default::default()).await
        {
            log::warn!("Web LAN connection from {remote_addr} failed: {err}");
        }
    });
    let mut framed = Framed::new(bridge_stream, BytesCodec::new());
    let idle_timeout = tokio::time::sleep(WEB_SOCKET_IDLE_TIMEOUT);
    tokio::pin!(idle_timeout);

    loop {
        tokio::select! {
            _ = &mut idle_timeout => {
                log::debug!("Closing idle Web session from {remote_addr}");
                break;
            }
            incoming = socket.recv() => {
                idle_timeout.as_mut().reset(tokio::time::Instant::now() + WEB_SOCKET_IDLE_TIMEOUT);
                match incoming {
                    Some(Ok(WebSocketMessage::Binary(bytes))) => {
                        if validate_websocket_payload_len(bytes.len()).is_err()
                            || bytes.len() > MAX_WEBSOCKET_CLIENT_PAYLOAD_LEN
                        {
                            break;
                        }
                        if let Err(err) = framed.send(Bytes::from(bytes)).await {
                            log::debug!("WebSocket bridge input closed: {err}");
                            break;
                        }
                    }
                    Some(Ok(WebSocketMessage::Close(_))) | None => break,
                    Some(Ok(WebSocketMessage::Ping(_))) | Some(Ok(WebSocketMessage::Pong(_))) => {}
                    Some(Ok(WebSocketMessage::Text(_))) => break,
                    Some(Err(err)) => {
                        log::debug!("WebSocket receive failed: {err}");
                        break;
                    }
                }
            }
            outgoing = framed.next() => {
                idle_timeout.as_mut().reset(tokio::time::Instant::now() + WEB_SOCKET_IDLE_TIMEOUT);
                match outgoing {
                    Some(Ok(bytes)) => {
                        if validate_websocket_payload_len(bytes.len()).is_err() {
                            break;
                        }
                        if socket.send(WebSocketMessage::Binary(bytes.to_vec())).await.is_err() {
                            break;
                        }
                    }
                    Some(Err(err)) => {
                        log::debug!("WebSocket bridge output failed: {err}");
                        break;
                    }
                    None => break,
                }
            }
        }
    }
    drop(framed);
    drop(socket);
    match timeout(WEB_SOCKET_SHUTDOWN_TIMEOUT, &mut server_task).await {
        Ok(Err(err)) => log::debug!("Web connection task ended unexpectedly: {err}"),
        Ok(Ok(())) => {}
        Err(_) => {
            server_task.abort();
            let _ = server_task.await;
        }
    }
}

async fn wait_for_stop(mut stop_rx: watch::Receiver<bool>) {
    loop {
        if *stop_rx.borrow() || stop_rx.changed().await.is_err() {
            return;
        }
    }
}

pub async fn bind(
    server: ServerPtr,
    stop_rx: watch::Receiver<bool>,
) -> ResultType<Vec<tokio::task::JoinHandle<()>>> {
    if !is_enabled() {
        let _ = write_runtime_status("disabled", &[], "");
        return Ok(Vec::new());
    }
    let _ = write_runtime_status("starting", &[], "");
    validate_web_network_policy()?;
    let port = configured_port();
    let native_port = Config::get_option("direct-access-port")
        .parse::<u16>()
        .ok()
        .filter(|value| *value > 0)
        .unwrap_or(21118);
    if port == native_port {
        bail!("Web listen port must differ from the native LAN port");
    }
    let addresses = configured_addresses()?;
    let allowed_hosts = allowed_hosts()?;
    let tls_config = load_tls_config().await?;
    let mut listeners = Vec::new();
    for address in addresses {
        let socket_addr = SocketAddr::new(address, port);
        let listener = std::net::TcpListener::bind(socket_addr)
            .with_context(|| format!("Failed to bind Web access on {socket_addr}"))?;
        listener.set_nonblocking(true)?;
        listeners.push((socket_addr, listener));
    }
    let mut endpoint_hosts = allowed_hosts.iter().cloned().collect::<Vec<_>>();
    endpoint_hosts.sort();
    let endpoints = endpoint_hosts
        .into_iter()
        .filter(|host| host != "localhost")
        .map(|host| {
            let host = if host.contains(':') {
                format!("[{host}]")
            } else {
                host
            };
            format!("https://{host}:{port}")
        })
        .collect::<Vec<_>>();
    write_runtime_status("listening", &endpoints, "")?;

    let mut handles = Vec::with_capacity(listeners.len() + 1);
    let connection_limiter =
        ConnectionLimiter::new(MAX_WEB_CONNECTIONS, MAX_WEB_CONNECTIONS_PER_SOURCE);
    let request_budget = Arc::new(Mutex::new(RequestRateBudget::new(
        MAX_WEB_REQUESTS_PER_MINUTE,
        Duration::from_secs(60),
    )));
    for (socket_addr, listener) in listeners {
        let state = WebState {
            server: server.clone(),
            secure: true,
            allowed_hosts: allowed_hosts.clone(),
            connection_limiter: connection_limiter.clone(),
            request_budget: request_budget.clone(),
        };
        let router = app(state);
        let handle = Handle::new();
        let shutdown_handle = handle.clone();
        let stop_rx = stop_rx.clone();
        log::info!("Web access listening on https://{socket_addr} with HTTP redirect");
        let acceptor = RustlsAcceptor::new(tls_config.clone())
            .acceptor(HttpsRedirectAcceptor::new(port, allowed_hosts.clone()));
        let task = tokio::spawn(async move {
            let server = axum_server::from_tcp(listener)
                .acceptor(acceptor)
                .handle(handle)
                .serve(router.into_make_service_with_connect_info::<SocketAddr>());
            tokio::pin!(server);
            tokio::select! {
                result = &mut server => {
                    if let Err(err) = result {
                        log::error!("Web HTTPS server stopped: {err}");
                    }
                }
                _ = wait_for_stop(stop_rx) => {
                    shutdown_handle.graceful_shutdown(Some(Duration::from_secs(2)));
                    if let Err(err) = server.await {
                        log::debug!("Web HTTPS server shutdown: {err}");
                    }
                }
            }
        });
        handles.push(task);
    }
    let mut heartbeat_stop_rx = stop_rx.clone();
    let heartbeat_endpoints = endpoints.clone();
    handles.push(tokio::spawn(async move {
        let mut interval = tokio::time::interval(WEB_RUNTIME_HEARTBEAT_INTERVAL);
        loop {
            tokio::select! {
                _ = interval.tick() => {
                    if let Err(err) = write_runtime_status("listening", &heartbeat_endpoints, "") {
                        log::debug!("Failed to update Web runtime heartbeat: {err}");
                    }
                }
                changed = heartbeat_stop_rx.changed() => {
                    if changed.is_err() || *heartbeat_stop_rx.borrow() {
                        let _ = write_runtime_status("stopped", &heartbeat_endpoints, "");
                        break;
                    }
                }
            }
        }
    }));
    Ok(handles)
}

