// Compile the production request classifier and both production guard expressions.
// Protocol/host doubles keep this independent of native clipboard and codec SDKs.
use std::cell::Cell;
thread_local! { static ONE_WAY: Cell<bool> = const { Cell::new(false) }; }
mod keys { pub const OPTION_ONE_WAY_FILE_TRANSFER: &str = "one-way-file-transfer"; }
fn get_builtin_option(_: &str) -> String {
    ONE_WAY.with(|v| if v.get() { "Y" } else { "" }).to_owned()
}
fn is_support_file_copy_paste(version: &bool) -> bool { *version }
mod cliprdr {
    pub enum Union { FormatDataRequest(()), FileContentsRequest(()), FormatDataResponse(()),
        FileContentsResponse(()), Ready(()), FormatList(()), FormatListResponse(()), Files(()) }
}
struct Cliprdr { union: Option<cliprdr::Union> }
struct Login { version: bool }
struct Connection { lr: Login, enabled: bool }
impl Connection {
    fn file_transfer_enabled(&self) -> bool { self.enabled }
    fn one_way_blocks(&self, clip: &Cliprdr) -> bool {
        // ONE_WAY_GUARD
    }
    fn unix_handler_enabled(&self) -> bool {
        // PERMISSION_GUARD
    }
}
// PRODUCTION

#[test]
fn one_way_blocks_requests_for_host_files_but_allows_incoming_data() {
    use cliprdr::Union::*;
    let connection = Connection { lr: Login { version: true }, enabled: true };
    ONE_WAY.with(|v| v.set(true));
    for union in [FormatDataRequest(()), FileContentsRequest(())] {
        assert!(connection.one_way_blocks(&Cliprdr { union: Some(union) }));
    }
    for union in [FormatDataResponse(()), FileContentsResponse(()), Ready(()),
                  FormatList(()), FormatListResponse(()), Files(())] {
        assert!(!connection.one_way_blocks(&Cliprdr { union: Some(union) }));
    }
    assert!(!connection.one_way_blocks(&Cliprdr { union: None }));
    ONE_WAY.with(|v| v.set(false));
    assert!(!connection.one_way_blocks(&Cliprdr { union: Some(FileContentsRequest(())) }));
}

#[test]
fn disabling_file_transfer_mid_session_stops_unix_clipboard_handling() {
    let mut connection = Connection { lr: Login { version: true }, enabled: true };
    assert!(connection.unix_handler_enabled());
    connection.enabled = false;
    assert!(!connection.unix_handler_enabled());
    connection.enabled = true;
    connection.lr.version = false;
    assert!(!connection.unix_handler_enabled());
}
