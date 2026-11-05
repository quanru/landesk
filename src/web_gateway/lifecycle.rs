/// Rebind only this gateway when its settings change; desktop sessions stay alive.
pub async fn run(server: ServerPtr) {
    let mut previous = None;
    let mut tasks: Vec<tokio::task::JoinHandle<()>> = Vec::new();
    let mut stop = None;
    loop {
        let settings = ["web-access-enabled", "stop-service", "web-listen-port",
            "web-listen-addresses", "web-allowed-hosts", "web-allowed-networks",
            "web-certificate-path", "web-private-key-path"]
            .map(Config::get_option);
        if previous.as_ref() != Some(&settings) {
            if let Some(sender) = stop.take() {
                let sender: watch::Sender<bool> = sender;
                let _ = sender.send(true);
            }
            for mut task in tasks.drain(..) {
                if timeout(Duration::from_secs(3), &mut task).await.is_err() {
                    task.abort();
                    let _ = task.await;
                }
            }
            let (sender, receiver) = watch::channel(false);
            if Config::get_option("stop-service") != "Y" {
                match bind(server.clone(), receiver).await {
                    Ok(started) => tasks = started,
                    Err(error) => record_start_failure(&error.to_string()),
                }
            } else {
                let _ = write_runtime_status("disabled", &[], "");
            }
            stop = Some(sender);
            previous = Some(settings);
        }
        tokio::time::sleep(Duration::from_secs(1)).await;
    }
}
