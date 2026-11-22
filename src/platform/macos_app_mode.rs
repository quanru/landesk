use hbb_common::{libc, log, tokio};
use serde_json::{json, Value};
use std::ffi::{CStr, CString};

extern "C" {
    fn LandeskAppModeCreate() -> *mut libc::c_void;
    fn LandeskAppModeDestroy(state: *mut libc::c_void);
    fn LandeskAppModeThumbnail(window_id: u32) -> *mut libc::c_char;
    fn LandeskAppModeRequest(
        state: *mut libc::c_void,
        request: *const libc::c_char,
    ) -> *mut libc::c_char;
}

pub fn queue_thumbnail(request: &str, sender: Option<&crate::server::Sender>) -> bool {
    use base::message_proto::{Message, Misc};
    use std::sync::Arc;
    use tokio::{sync::Semaphore, time::Instant};

    let Ok(input) = serde_json::from_str::<Value>(request) else {
        return false;
    };
    if input["op"].as_str() != Some("thumbnail") {
        return false;
    }
    let (Some(request_id), Some(window_id), Some(sender)) = (
        input["request_id"].as_u64(),
        input["window_id"].as_u64().and_then(|id| u32::try_from(id).ok()).filter(|id| *id != 0),
        sender.cloned(),
    ) else {
        return true;
    };
    let send = move |thumbnail: Option<String>| {
        let mut misc = Misc::new();
        misc.set_landesk_app_response(json!({
            "request_id": request_id,
            "thumbnail": thumbnail,
        }).to_string());
        let mut message = Message::new();
        message.set_misc(misc);
        if sender.send((Instant::now(), Arc::new(message))).is_err() {
            log::trace!("Thumbnail connection closed");
        }
    };
    static CAPTURES: Semaphore = Semaphore::const_new(2);
    match CAPTURES.try_acquire() {
        Ok(permit) => {
            tokio::task::spawn_blocking(move || {
                let _permit = permit;
                let output = unsafe { LandeskAppModeThumbnail(window_id) };
                let thumbnail = if output.is_null() {
                    None
                } else {
                    let value = unsafe { CStr::from_ptr(output) }.to_str().ok().map(str::to_owned);
                    unsafe { libc::free(output as _) };
                    value
                };
                send(thumbnail);
            });
        }
        Err(_) => send(None),
    }
    true
}

#[derive(Default)]
pub struct AppMode(Option<usize>);

impl AppMode {
    pub fn request(&mut self, request: &str) -> String {
        let input: Value = match serde_json::from_str(request) {
            Ok(input) => input,
            Err(_) => return json!({"error": "Invalid app request."}).to_string(),
        };
        let mut response = if valid_request(&input) {
            self.native_request(request)
        } else {
            json!({"error": "Invalid app request."})
        };
        response["request_id"] = input["request_id"].clone();
        response.to_string()
    }

    fn native_request(&mut self, request: &str) -> Value {
        let Ok(request) = CString::new(request) else {
            return json!({"error": "Invalid app request."});
        };
        // The connection serializes access with a mutex. AX references are retained by
        // the native context and released after the final blocking request completes.
        let state = *self
            .0
            .get_or_insert_with(|| unsafe { LandeskAppModeCreate() as usize });
        let output = unsafe { LandeskAppModeRequest(state as _, request.as_ptr()) };
        if output.is_null() {
            return json!({"error": "The Mac could not complete the app action."});
        }
        let result = unsafe { serde_json::from_slice(CStr::from_ptr(output).to_bytes()) };
        unsafe { libc::free(output as _) };
        result.unwrap_or_else(|_| json!({"error": "Invalid app response."}))
    }
}

impl Drop for AppMode {
    fn drop(&mut self) {
        if let Some(state) = self.0 {
            // Disconnect can drop the connection on a Tokio worker; AX may block.
            std::thread::spawn(move || unsafe { LandeskAppModeDestroy(state as _) });
        }
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
            let height = input.get("height").map_or(0.0, |v| v.as_f64().unwrap_or(-1.0));
            id > 0 && id <= u32::MAX as u64 && (aspect == 0.0 || (0.2..=5.0).contains(&aspect))
                && (height == 0.0 || (160.0..=2160.0).contains(&height))
        }
        _ => false,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn only_bounded_window_actions_are_accepted() {
        assert!(valid_request(
            &json!({"request_id": 1, "op": "focus", "window_id": 42, "aspect": 0.5})
        ));
        assert!(!valid_request(
            &json!({"request_id": 1, "op": "focus", "window_id": 42, "aspect": 1000})
        ));
        assert!(!valid_request(
            &json!({"request_id": 1, "op": "launch", "path": "/bin/sh"})
        ));
        assert!(valid_request(
            &json!({"request_id": 1, "op": "focus", "window_id": 42, "aspect": 0.5, "height": 700})
        ));
        assert!(!valid_request(
            &json!({"request_id": 1, "op": "focus", "window_id": 42, "aspect": 0.5, "height": "700"})
        ));
    }
}
