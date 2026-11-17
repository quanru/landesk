use hbb_common::log;
use serde_json::{json, Value};
use std::{mem, path::Path, ptr::null_mut};
use winapi::{
    shared::{
        minwindef::{BOOL, FALSE, LPARAM, TRUE},
        windef::{HWND, RECT},
    },
    um::{
        dwmapi::{DwmGetWindowAttribute, DWMWA_CLOAKED, DWMWA_EXTENDED_FRAME_BOUNDS},
        handleapi::CloseHandle,
        processthreadsapi::OpenProcess,
        winbase::QueryFullProcessImageNameW,
        winnt::PROCESS_QUERY_LIMITED_INFORMATION,
        winuser::*,
    },
};

#[derive(Default)]
pub struct AppMode(Option<SavedWindow>);

struct SavedWindow {
    handle: usize,
    process: u32,
    thread: u32,
    placement: WINDOWPLACEMENT,
    resized: bool,
}

impl SavedWindow {
    fn window(&self) -> Option<HWND> {
        let hwnd = self.handle as HWND;
        let mut process = 0;
        let thread = unsafe { GetWindowThreadProcessId(hwnd, &mut process) };
        (thread != 0 && thread == self.thread && process == self.process).then_some(hwnd)
    }
}

fn error(text: &str) -> Value {
    json!({"error": text})
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
                .map_or(0.0, |v| v.as_f64().unwrap_or(-1.0));
            id > 0
                && id <= usize::MAX as u64
                && (aspect == 0.0 || (0.2..=5.0).contains(&aspect))
                && (height == 0.0 || (160.0..=2160.0).contains(&height))
        }
        _ => false,
    }
}

fn frame(hwnd: HWND) -> Option<RECT> {
    let mut rect = unsafe { mem::zeroed::<RECT>() };
    // GetWindowRect includes invisible resize borders, including off-screen
    // borders of maximized windows. DWM bounds match the captured pixels.
    let visible = unsafe {
        DwmGetWindowAttribute(
            hwnd,
            DWMWA_EXTENDED_FRAME_BOUNDS,
            &mut rect as *mut _ as _,
            mem::size_of_val(&rect) as u32,
        )
    } >= 0;
    ((visible || unsafe { GetWindowRect(hwnd, &mut rect) } != FALSE)
        && rect.right > rect.left
        && rect.bottom > rect.top)
        .then_some(rect)
}

fn candidate(hwnd: HWND) -> bool {
    unsafe {
        if IsWindowVisible(hwnd) == FALSE
            || IsIconic(hwnd) != FALSE
            || GetWindow(hwnd, GW_OWNER) != null_mut()
            || GetWindowLongW(hwnd, GWL_EXSTYLE) as u32 & WS_EX_TOOLWINDOW != 0
            || GetWindowTextLengthW(hwnd) <= 0
        {
            return false;
        }
        let mut cloaked: u32 = 0;
        if DwmGetWindowAttribute(
            hwnd,
            DWMWA_CLOAKED,
            &mut cloaked as *mut _ as _,
            mem::size_of_val(&cloaked) as u32,
        ) >= 0
            && cloaked != 0
        {
            return false;
        }
    }
    frame(hwnd).map_or(false, |r| r.right - r.left >= 80 && r.bottom - r.top >= 80)
}

fn window_json(hwnd: HWND) -> Option<Value> {
    let r = frame(hwnd)?;
    let mut title = vec![0u16; 4096];
    let len = unsafe { GetWindowTextW(hwnd, title.as_mut_ptr(), title.len() as i32) };
    if len <= 0 {
        return None;
    }
    let title = String::from_utf16_lossy(&title[..len as usize]);
    let mut process = 0;
    unsafe { GetWindowThreadProcessId(hwnd, &mut process) };
    let mut app = title.clone();
    let handle = unsafe { OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, process) };
    if !handle.is_null() {
        let mut path = vec![0u16; 32768];
        let mut len = path.len() as u32;
        if unsafe { QueryFullProcessImageNameW(handle, 0, path.as_mut_ptr(), &mut len) } != FALSE {
            let path = String::from_utf16_lossy(&path[..len as usize]);
            if let Some(name) = Path::new(&path).file_stem() {
                app = name.to_string_lossy().into_owned();
            }
        }
        if unsafe { CloseHandle(handle) } == FALSE {
            log::trace!(
                "App mode could not close process query handle: {}",
                std::io::Error::last_os_error()
            );
        }
    }
    Some(json!({"id": hwnd as usize, "app": app, "title": title,
        "frame": {"x": r.left, "y": r.top, "width": r.right - r.left, "height": r.bottom - r.top}}))
}

unsafe extern "system" fn enum_window(hwnd: HWND, data: LPARAM) -> BOOL {
    let windows = &mut *(data as *mut Vec<Value>);
    if candidate(hwnd) {
        if let Some(window) = window_json(hwnd) {
            windows.push(window);
        }
    }
    if windows.len() >= 100 {
        FALSE
    } else {
        TRUE
    }
}

fn fitted_frame(bounds: RECT, aspect: f64, requested_height: f64) -> RECT {
    let height = if requested_height > 0.0 {
        requested_height.min((bounds.bottom - bounds.top) as f64)
    } else {
        (bounds.bottom - bounds.top) as f64
    };
    let width = (height * aspect).min((bounds.right - bounds.left) as f64);
    let height = height.min(width / aspect);
    let width = width.round() as i32;
    let height = height.round() as i32;
    let left = bounds.left + (bounds.right - bounds.left - width) / 2;
    let top = bounds.top + (bounds.bottom - bounds.top - height) / 2;
    RECT {
        left,
        top,
        right: left + width,
        bottom: top + height,
    }
}

impl AppMode {
    pub fn request(&mut self, request: &str) -> String {
        let input: Value = match serde_json::from_str(request) {
            Ok(input) => input,
            Err(_) => return error("Invalid app request.").to_string(),
        };
        let mut response = if valid_request(&input) {
            if super::windows::desktop_changed() && !super::windows::try_change_desktop() {
                error("Cannot access the Windows desktop.")
            } else {
                self.handle(&input)
            }
        } else {
            error("Invalid app request.")
        };
        response["request_id"] = input["request_id"].clone();
        response.to_string()
    }

    fn clear(&mut self) -> bool {
        if let Some(saved) = self.0.as_ref() {
            if let Some(hwnd) = saved.window() {
                if saved.resized && unsafe { SetWindowPlacement(hwnd, &saved.placement) } == FALSE {
                    return false;
                }
            }
        }
        self.0 = None;
        true
    }

    fn current(&self) -> Value {
        self.0
            .as_ref()
            .and_then(SavedWindow::window)
            .filter(|&hwnd| candidate(hwnd))
            .and_then(window_json)
            .map_or_else(
                || error("The window is no longer available."),
                |w| json!({"window": w}),
            )
    }

    fn handle(&mut self, input: &Value) -> Value {
        match input["op"].as_str() {
            Some("desktop") => {
                return if self.clear() {
                    json!({})
                } else {
                    error("The original window size could not be restored.")
                }
            }
            Some("current") => return self.current(),
            Some("list") => {
                let mut windows = Vec::<Value>::new();
                if unsafe { EnumWindows(Some(enum_window), &mut windows as *mut _ as LPARAM) }
                    == FALSE
                    && windows.len() < 100
                {
                    return error("Cannot list Windows app windows.");
                }
                return json!({"windows": windows});
            }
            _ => {}
        }
        let hwnd = input["window_id"].as_u64().unwrap_or(0) as usize as HWND;
        if !candidate(hwnd) {
            return error("The window is no longer available.");
        }
        if !self.clear() {
            return error("The previous window size could not be restored.");
        }
        if unsafe { SetForegroundWindow(hwnd) } == FALSE && unsafe { GetForegroundWindow() } != hwnd
        {
            return error("Windows did not allow this app to come to the foreground. Try again from the desktop.");
        }
        let mut placement = unsafe { mem::zeroed::<WINDOWPLACEMENT>() };
        placement.length = mem::size_of_val(&placement) as u32;
        if unsafe { GetWindowPlacement(hwnd, &mut placement) } == FALSE {
            return error("Cannot read the window size.");
        }
        let mut process = 0;
        let thread = unsafe { GetWindowThreadProcessId(hwnd, &mut process) };
        self.0 = Some(SavedWindow {
            handle: hwnd as usize,
            process,
            thread,
            placement,
            resized: false,
        });
        let aspect = input["aspect"].as_f64().unwrap_or(0.0);
        if aspect > 0.0 {
            let mut info = unsafe { mem::zeroed::<MONITORINFO>() };
            info.cbSize = mem::size_of_val(&info) as u32;
            let monitor = unsafe { MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST) };
            if unsafe { GetMonitorInfoW(monitor, &mut info) } == FALSE {
                return error("Cannot find the window display.");
            }
            let bounds = RECT {
                left: info.rcWork.left + 16,
                top: info.rcWork.top + 16,
                right: info.rcWork.right - 16,
                bottom: info.rcWork.bottom - 16,
            };
            if bounds.right <= bounds.left || bounds.bottom <= bounds.top {
                return error("The window display is too small.");
            }
            let rect = fitted_frame(bounds, aspect, input["height"].as_f64().unwrap_or(0.0));
            if let Some(saved) = self.0.as_mut() {
                saved.resized = true;
            }
            unsafe { ShowWindow(hwnd, SW_RESTORE) };
            if unsafe {
                SetWindowPos(
                    hwnd,
                    null_mut(),
                    rect.left,
                    rect.top,
                    rect.right - rect.left,
                    rect.bottom - rect.top,
                    SWP_NOZORDER | SWP_NOACTIVATE,
                )
            } == FALSE
            {
                if !self.clear() {
                    return error("The window could not be resized or restored. Return to desktop to retry restoration.");
                }
                return error("This window cannot be resized. Try keeping its current size.");
            }
        }
        self.current()
    }
}

impl Drop for AppMode {
    fn drop(&mut self) {
        if let Some(saved) = self.0.take() {
            // Disconnect can run on a Tokio worker; window messages may block.
            if let Err(err) = std::thread::Builder::new()
                .name("app-mode-restore".into())
                .spawn(move || {
                    if super::windows::desktop_changed() && !super::windows::try_change_desktop() {
                        log::warn!(
                            "App mode could not access the desktop to restore the Windows window."
                        );
                        return;
                    }
                    let mut state = AppMode(Some(saved));
                    if !state.clear() {
                        log::warn!(
                            "App mode could not restore the Windows window after disconnect."
                        );
                        state.0 = None;
                    }
                })
            {
                log::warn!("App mode could not start window restoration: {}", err);
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    #[ignore = "Requires an interactive Windows desktop; run explicitly in App mode CI"]
    fn real_windows_switch_resize_and_restore() {
        fn pump() {
            unsafe {
                let mut message = mem::zeroed::<MSG>();
                while PeekMessageW(&mut message, null_mut(), 0, 0, PM_REMOVE) != FALSE {
                    TranslateMessage(&message);
                    DispatchMessageW(&message);
                }
            }
            std::thread::sleep(std::time::Duration::from_millis(200));
        }
        fn placement(hwnd: HWND) -> [i32; 5] {
            let mut value = unsafe { mem::zeroed::<WINDOWPLACEMENT>() };
            value.length = mem::size_of_val(&value) as u32;
            assert_ne!(unsafe { GetWindowPlacement(hwnd, &mut value) }, FALSE);
            let r = value.rcNormalPosition;
            [value.showCmd as i32, r.left, r.top, r.right, r.bottom]
        }
        struct Window(HWND);
        impl Drop for Window {
            fn drop(&mut self) {
                unsafe { DestroyWindow(self.0) };
            }
        }
        fn create(title: &str, x: i32) -> Window {
            let class: Vec<u16> = "STATIC\0".encode_utf16().collect();
            let title: Vec<u16> = title.encode_utf16().chain(Some(0)).collect();
            let hwnd = unsafe {
                CreateWindowExW(
                    0,
                    class.as_ptr(),
                    title.as_ptr(),
                    WS_OVERLAPPEDWINDOW | WS_VISIBLE,
                    x,
                    80,
                    420,
                    320,
                    null_mut(),
                    null_mut(),
                    null_mut(),
                    null_mut(),
                )
            };
            assert!(!hwnd.is_null(), "Cannot create a visible test window");
            Window(hwnd)
        }
        assert!(
            !unsafe { GetForegroundWindow() }.is_null(),
            "No interactive foreground desktop"
        );
        let first = create("LanDesk App mode CI A", 40);
        let second = create("LanDesk App mode CI B", 500);
        pump();
        let original = [placement(first.0), placement(second.0)];
        let mut mode = AppMode::default();
        let mut request_id = 0;
        let mut ask = |mode: &mut AppMode, op: &str, hwnd: HWND, aspect: f64| {
            request_id += 1;
            let result: Value = serde_json::from_str(
                &mode.request(
                    &json!({
                        "request_id": request_id, "op": op,
                        "window_id": hwnd as usize, "aspect": aspect, "height": 600
                    })
                    .to_string(),
                ),
            )
            .unwrap();
            assert!(result.get("error").is_none(), "{result}");
            assert_eq!(result["request_id"], request_id);
            result
        };
        let list = ask(&mut mode, "list", null_mut(), 0.0);
        for hwnd in [first.0, second.0] {
            assert!(list["windows"]
                .as_array()
                .unwrap()
                .iter()
                .any(|w| w["id"].as_u64() == Some(hwnd as usize as u64)));
        }
        let mut observed = Vec::new();
        for (hwnd, aspect) in [(first.0, 0.5), (second.0, 2.0)] {
            ask(&mut mode, "focus", hwnd, aspect);
            pump();
            assert_eq!(unsafe { GetForegroundWindow() }, hwnd);
            let window = ask(&mut mode, "current", null_mut(), 0.0)["window"].clone();
            let r = &window["frame"];
            let ratio = r["width"].as_f64().unwrap() / r["height"].as_f64().unwrap();
            assert!(
                (ratio - aspect).abs() < 0.12,
                "Unexpected visible bounds: {window}"
            );
            observed.push(window);
        }
        assert_eq!(
            placement(first.0),
            original[0],
            "Switch did not restore the first window"
        );
        ask(&mut mode, "desktop", null_mut(), 0.0);
        pump();
        assert_eq!(
            placement(second.0),
            original[1],
            "Desktop did not restore the second window"
        );
        ask(&mut mode, "focus", first.0, 0.5);
        drop(mode);
        let deadline = std::time::Instant::now() + std::time::Duration::from_secs(5);
        while placement(first.0) != original[0] && std::time::Instant::now() < deadline {
            pump();
        }
        assert_eq!(
            placement(first.0),
            original[0],
            "Session cleanup did not restore the first window"
        );
        if let Ok(path) = std::env::var("LANDESK_APP_MODE_EVIDENCE") {
            let evidence = json!({"environment":"Windows CI virtual machine", "windows":observed,
                "listed_both":true, "foreground_switch":true, "desktop_restored":true,
                "switch_restored":true, "session_cleanup_restored":true});
            std::fs::write(path, serde_json::to_vec_pretty(&evidence).unwrap()).unwrap();
        }
    }

    #[test]
    fn rejects_unbounded_actions() {
        assert!(valid_request(
            &json!({"request_id": 1, "op": "focus", "window_id": 42, "aspect": 0.5, "height": 700})
        ));
        assert!(!valid_request(
            &json!({"request_id": 1, "op": "focus", "window_id": 42, "aspect": 1000})
        ));
        assert!(!valid_request(
            &json!({"request_id": 1, "op": "launch", "path": "cmd.exe"})
        ));
    }

    #[test]
    fn fits_phone_size_inside_monitor_work_area() {
        let bounds = RECT {
            left: -1904,
            top: 16,
            right: -16,
            bottom: 1024,
        };
        let portrait = fitted_frame(bounds, 0.5, 700.0);
        assert_eq!(
            (portrait.left, portrait.top, portrait.right, portrait.bottom),
            (-1135, 170, -785, 870)
        );
        let landscape = fitted_frame(bounds, 2.0, 2000.0);
        assert_eq!(
            (
                landscape.left,
                landscape.top,
                landscape.right,
                landscape.bottom
            ),
            (-1904, 48, -16, 992)
        );
    }
}
