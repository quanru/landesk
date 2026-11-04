//! Keep process-wide clipboard broadcasts out of a round that has not logged in.
use base::message_proto::{message, Message};

pub(super) fn blocks_clipboard(connected: bool, message: &Message) -> bool {
    !connected
        && matches!(
            message.union.as_ref(),
            Some(message::Union::Clipboard(_)) | Some(message::Union::MultiClipboards(_))
        )
}

#[cfg(test)]
mod tests {
    use super::*;
    use base::message_proto::{Clipboard, LoginRequest, MultiClipboards};

    #[test]
    fn clipboard_waits_for_this_rounds_login_and_login_messages_still_pass() {
        let mut single = Message::new();
        single.set_clipboard(Clipboard::new());
        let mut multiple = Message::new();
        multiple.set_multi_clipboards(MultiClipboards::new());
        for message in [single, multiple] {
            assert!(blocks_clipboard(false, &message));
            assert!(!blocks_clipboard(true, &message));
        }
        let mut login = Message::new();
        login.set_login_request(LoginRequest::new());
        assert!(!blocks_clipboard(false, &login));
    }
}
