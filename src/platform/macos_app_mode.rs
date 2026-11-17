use hbb_common::libc;
use serde_json::{json, Value};
use std::ffi::{CStr, CString};

extern "C" {
    fn LandeskAppModeCreate() -> *mut libc::c_void;
    fn LandeskAppModeDestroy(state: *mut libc::c_void);
    fn LandeskAppModeRequest(
        state: *mut libc::c_void,
        request: *const libc::c_char,
    ) -> *mut libc::c_char;
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
