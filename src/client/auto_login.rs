//! Never infer LAN protocol capabilities from the upstream product version.
use base::message_proto::PeerInfo;

pub(super) fn supports_guarded_login(pi: &PeerInfo) -> bool {
    if pi.platform != "Windows" && pi.platform != "Mac OS" {
        return false;
    }
    serde_json::from_str::<serde_json::Value>(&pi.platform_additions)
        .ok()
        .and_then(|v| v.get("landesk-os-login-v1").and_then(|v| v.as_bool()))
        == Some(true)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn only_explicit_capability_on_supported_platform_enables_auto_login() {
        for platform in ["Windows", "Mac OS"] {
            let mut pi = PeerInfo {
                platform: platform.into(),
                version: "1.3.0".into(),
                ..Default::default()
            };
            for additions in [
                "",
                "{",
                "{}",
                "null",
                "{\"landesk-os-login-v1\":false}",
                "{\"landesk-os-login-v1\":\"true\"}",
            ] {
                pi.platform_additions = additions.into();
                assert!(!supports_guarded_login(&pi));
            }
            pi.platform_additions = "{\"landesk-os-login-v1\":true}".into();
            assert!(supports_guarded_login(&pi));
            pi.platform = "Linux".into();
            assert!(!supports_guarded_login(&pi));
        }
    }
}
