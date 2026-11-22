use hbb_common::{libc, log};
use serde_json::{json, Value};
use std::{
    fs,
    io::{Read, Write},
    os::unix::net::UnixStream,
    path::{Path, PathBuf},
    time::Duration,
};

#[derive(Default)]
pub struct AppMode(Option<SavedWindow>);

struct SavedWindow {
    id: u64,
    pid: u64,
    frame: Option<[i32; 4]>,
    floating: bool,
}

struct Hyprland {
    socket: PathBuf,
    monitor: Value,
}

type AppResult<T> = Result<T, String>;

fn socket_path() -> AppResult<PathBuf> {
    let runtime = std::env::var_os("XDG_RUNTIME_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from(format!("/run/user/{}", unsafe { libc::geteuid() })));
    let root = runtime.join("hypr");
    if let Ok(instance) = std::env::var("HYPRLAND_INSTANCE_SIGNATURE") {
        if !instance.is_empty() && !instance.contains('/') && instance != ".." {
            let path = root.join(instance).join(".socket.sock");
            if path.exists() {
                return Ok(path);
            }
        }
    }
    let entries = fs::read_dir(root).map_err(|_| "Hyprland is not available.".to_owned())?;
    let mut sockets = Vec::new();
    for entry in entries {
        let path = entry
            .map_err(|_| "Cannot inspect the Hyprland session.".to_owned())?
            .path()
            .join(".socket.sock");
        if path.exists() {
            sockets.push(path);
        }
    }
    if sockets.len() != 1 {
        return Err("A single Hyprland session is required.".into());
    }
    Ok(sockets.remove(0))
}

fn ipc(socket: &Path, command: &str) -> AppResult<String> {
    let mut stream = UnixStream::connect(socket)
        .map_err(|_| "Cannot connect to the Hyprland session.".to_owned())?;
    stream
        .set_read_timeout(Some(Duration::from_secs(2)))
        .and_then(|_| stream.set_write_timeout(Some(Duration::from_secs(2))))
        .and_then(|_| stream.write_all(command.as_bytes()))
        .map_err(|_| "Cannot send the window action to Hyprland.".to_owned())?;
    let mut response = String::new();
    stream
        .take(4 * 1024 * 1024 + 1)
        .read_to_string(&mut response)
        .map_err(|_| "Hyprland did not respond to the window action.".to_owned())?;
    if response.len() > 4 * 1024 * 1024 {
        return Err("The Hyprland response is too large.".into());
    }
    Ok(response)
}

fn query(socket: &Path, name: &str) -> AppResult<Value> {
    serde_json::from_str(&ipc(socket, &format!("j/{name}"))?)
        .map_err(|_| "Invalid Hyprland response.".into())
}

fn window_id(window: &Value) -> Option<u64> {
    u64::from_str_radix(window["address"].as_str()?.strip_prefix("0x")?, 16)
        .ok()
        .filter(|id| *id > 0)
}

fn window_frame(window: &Value) -> Option<[i32; 4]> {
    Some([
        i32::try_from(window["at"][0].as_i64()?).ok()?,
        i32::try_from(window["at"][1].as_i64()?).ok()?,
        i32::try_from(window["size"][0].as_i64()?).ok()?,
        i32::try_from(window["size"][1].as_i64()?).ok()?,
    ])
}

impl Hyprland {
    fn new() -> AppResult<Self> {
        let socket = socket_path()?;
        let version = query(&socket, "version")?;
        if !version["version"]
            .as_str()
            .unwrap_or("")
            .starts_with("0.57.")
        {
            return Err("App mode currently requires Hyprland 0.57.x.".into());
        }
        let monitors = query(&socket, "monitors")?;
        let monitors = monitors.as_array().ok_or("Invalid monitor response.")?;
        if monitors.len() != 1 {
            return Err("App mode currently requires a single monitor.".into());
        }
        let monitor = &monitors[0];
        let scale = monitor["scale"].as_f64().unwrap_or(0.0);
        if monitor["x"].as_i64() != Some(0)
            || monitor["y"].as_i64() != Some(0)
            || monitor["transform"].as_i64() != Some(0)
            || monitor["width"].as_i64().unwrap_or(0) < 160
            || monitor["height"].as_i64().unwrap_or(0) < 160
            || !(0.25..=8.0).contains(&scale)
        {
            return Err("This monitor layout is not supported by app mode.".into());
        }
        Ok(Self {
            socket,
            monitor: monitor.clone(),
        })
    }

    fn windows(&self) -> AppResult<Vec<Value>> {
        query(&self.socket, "clients")?
            .as_array()
            .cloned()
            .ok_or_else(|| "Invalid window response.".into())
    }

    fn find(&self, id: u64) -> AppResult<Option<Value>> {
        Ok(self
            .windows()?
            .into_iter()
            .find(|w| window_id(w) == Some(id)))
    }

    fn visible(&self, window: &Value) -> bool {
        window["mapped"].as_bool() == Some(true)
            && window["hidden"].as_bool() != Some(true)
            && window["monitor"] == self.monitor["id"]
            && (window["pinned"].as_bool() == Some(true)
                || window["workspace"]["address"] == self.monitor["activeWorkspace"]["address"])
            && window["pid"].as_u64().unwrap_or(0) > 0
            && window["class"].as_str().map_or(false, |s| !s.is_empty())
            && window["title"].as_str().map_or(false, |s| !s.is_empty())
    }

    fn window_json(&self, window: &Value) -> Option<Value> {
        let [x, y, width, height] = window_frame(window)?;
        let scale = self.monitor["scale"].as_f64()?;
        let frame = [
            x as f64 * scale,
            y as f64 * scale,
            width as f64 * scale,
            height as f64 * scale,
        ];
        if x < 0
            || y < 0
            || width < 40
            || height < 40
            || frame[0] + frame[2] > self.monitor["width"].as_f64()?
            || frame[1] + frame[3] > self.monitor["height"].as_f64()?
        {
            return None;
        }
        // The existing single-monitor Wayland protocol uses physical coordinates and scale=1.
        Some(
            json!({"id": window_id(window)?, "app": window["class"], "title": window["title"],
            "frame": {"x": frame[0], "y": frame[1], "width": frame[2], "height": frame[3]}}),
        )
    }

    fn dispatch(&self, action: &str, id: u64, args: &str) -> AppResult<()> {
        let response = ipc(
            &self.socket,
            &format!("/dispatch hl.dsp.{action}({{window=\"address:0x{id:x}\"{args}}})"),
        )?;
        if response.trim() != "ok" {
            return Err("Hyprland could not complete the window action.".into());
        }
        Ok(())
    }
}

fn valid_request(input: &Value) -> bool {
    if input["request_id"].as_u64().is_none() {
        return false;
    }
    match input["op"].as_str() {
        Some("list" | "current" | "desktop") => true,
        Some("focus") => {
            let id = input["window_id"].as_u64().unwrap_or(0);
            let aspect = input["aspect"].as_f64().unwrap_or(-1.0);
            let height = input
                .get("height")
                .map_or(0.0, |h| h.as_f64().unwrap_or(-1.0));
            id > 0
                && id <= (1u64 << 53) - 1
                && (aspect == 0.0 || (0.2..=5.0).contains(&aspect))
                && (height == 0.0 || (160.0..=2160.0).contains(&height))
        }
        _ => false,
    }
}

fn fitted_frame(monitor: &Value, aspect: f64, height: f64) -> Option<[i32; 4]> {
    let scale = monitor["scale"].as_f64()?;
    let left = monitor["reserved"][0].as_f64()?;
    let top = monitor["reserved"][1].as_f64()?;
    let width = monitor["width"].as_f64()? / scale - left - monitor["reserved"][2].as_f64()?;
    let available_height =
        monitor["height"].as_f64()? / scale - top - monitor["reserved"][3].as_f64()?;
    let height = if height > 0.0 {
        height.min(available_height)
    } else {
        available_height
    };
    let width = (height * aspect).min(width);
    let height = height.min(width / aspect);
    if width < 40.0 || height < 40.0 {
        return None;
    }
    Some([
        left as i32,
        top as i32,
        width.round() as i32,
        height.round() as i32,
    ])
}

fn restore(saved: &SavedWindow) -> AppResult<()> {
    let Some(frame) = saved.frame else {
        return Ok(());
    };
    let backend = Hyprland::new()?;
    if let Some(window) = backend.find(saved.id)? {
        if window["pid"].as_u64() == Some(saved.pid) {
            let [x, y, width, height] = frame;
            backend.dispatch(
                "window.resize",
                saved.id,
                &format!(",x={width},y={height},relative=false"),
            )?;
            backend.dispatch(
                "window.move",
                saved.id,
                &format!(",x={x},y={y},relative=false"),
            )?;
            if !saved.floating {
                backend.dispatch("window.float", saved.id, ",action=\"disable\"")?;
            }
        }
    }
    Ok(())
}

impl AppMode {
    pub fn supported() -> bool {
        Hyprland::new().is_ok()
    }

    pub fn request(&mut self, request: &str) -> String {
        let input: Value = match serde_json::from_str(request) {
            Ok(v) => v,
            Err(_) => return json!({"error": "Invalid app request."}).to_string(),
        };
        let mut response = if valid_request(&input) {
            self.handle(&input).unwrap_or_else(|e| json!({"error": e}))
        } else {
            json!({"error": "Invalid app request."})
        };
        response["request_id"] = input["request_id"].clone();
        response.to_string()
    }

    fn clear(&mut self) -> AppResult<()> {
        if let Some(saved) = self.0.as_ref() {
            restore(saved)?;
        }
        self.0 = None;
        Ok(())
    }

    fn current(&self) -> AppResult<Value> {
        let backend = Hyprland::new()?;
        if let Some(saved) = &self.0 {
            if let Some(window) = backend.find(saved.id)? {
                if window["pid"].as_u64() == Some(saved.pid) && backend.visible(&window) {
                    if let Some(window) = backend.window_json(&window) {
                        return Ok(json!({"window": window}));
                    }
                }
            }
        }
        Err("The window is no longer available.".into())
    }

    fn handle(&mut self, input: &Value) -> AppResult<Value> {
        match input["op"].as_str() {
            Some("desktop") => {
                self.clear()?;
                return Ok(json!({}));
            }
            Some("current") => return self.current(),
            _ => {}
        }
        let backend = Hyprland::new()?;
        if input["op"] == "list" {
            let windows: Vec<_> = backend
                .windows()?
                .iter()
                .filter(|w| backend.visible(w))
                .filter_map(|w| backend.window_json(w))
                .take(100)
                .collect();
            return Ok(json!({"windows": windows}));
        }
        self.clear()?;
        let id = input["window_id"].as_u64().ok_or("Invalid window ID.")?;
        let window = backend
            .find(id)?
            .filter(|w| backend.visible(w))
            .ok_or("The window is no longer available.")?;
        let aspect = input["aspect"].as_f64().ok_or("Invalid app request.")?;
        if aspect > 0.0 && window["fullscreen"].as_i64().unwrap_or(0) != 0 {
            return Err("Exit the app's fullscreen state before resizing it.".into());
        }
        backend.dispatch("focus", id, "")?;
        let original = SavedWindow {
            id,
            pid: window["pid"].as_u64().ok_or("Invalid window process.")?,
            frame: if aspect > 0.0 {
                Some(window_frame(&window).ok_or("Invalid window bounds.")?)
            } else {
                None
            },
            floating: window["floating"].as_bool().unwrap_or(false),
        };
        if aspect > 0.0 {
            let [x, y, width, height] = fitted_frame(
                &backend.monitor,
                aspect,
                input["height"].as_f64().unwrap_or(0.0),
            )
            .ok_or("Cannot fit the window on this monitor.")?;
            self.0 = Some(original);
            backend.dispatch("window.float", id, ",action=\"enable\"")?;
            backend.dispatch(
                "window.resize",
                id,
                &format!(",x={width},y={height},relative=false"),
            )?;
            backend.dispatch("window.move", id, &format!(",x={x},y={y},relative=false"))?;
        } else {
            self.0 = Some(original);
        }
        if aspect > 0.0 || window["floating"].as_bool() == Some(true) {
            backend.dispatch("window.alter_zorder", id, ",mode=\"top\"")?;
        }
        self.current()
    }
}

impl Drop for AppMode {
    fn drop(&mut self) {
        if let Some(saved) = self.0.take() {
            if let Err(error) = std::thread::Builder::new()
                .name("app-mode-restore".into())
                .spawn(move || {
                    if let Err(error) = restore(&saved) {
                        log::trace!("App mode could not restore the Linux window: {error}");
                    }
                })
            {
                log::trace!("App mode could not start Linux window restoration: {error}");
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn accepts_only_bounded_window_actions() {
        assert!(valid_request(
            &json!({"request_id":1,"op":"focus","window_id":42,"aspect":0.5,"height":700})
        ));
        assert!(!valid_request(
            &json!({"request_id":1,"op":"focus","window_id":42,"aspect":1000})
        ));
        assert!(!valid_request(
            &json!({"request_id":1,"op":"launch","path":"/bin/sh"})
        ));
    }

    #[test]
    fn portrait_and_landscape_fit_the_logical_work_area() {
        let monitor = json!({"width":2560,"height":1600,"scale":2,"reserved":[0,26,0,0]});
        assert_eq!(fitted_frame(&monitor, 0.5, 700.0), Some([0, 26, 350, 700]));
        assert_eq!(
            fitted_frame(&monitor, 2.0, 2000.0),
            Some([0, 26, 1280, 640])
        );
    }
}
