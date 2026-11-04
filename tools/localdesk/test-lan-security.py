#!/usr/bin/env python3
"""Compile production admission, LAN protocol and clipboard gating with real crates.

Uses the application's fixed dependency graph and real loopback TCP/crypto. Does
not run the full app, read host credentials or open a public listener.
"""
import argparse
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cargo", default="cargo")
    args = parser.parse_args()
    # Actual protocol code calls this small helper from the app. Extract it
    # verbatim so the loopback encryption tests use the production key exchange.
    common = (ROOT / "src/common.rs").read_text()
    helper = "pub fn create_symmetric_key_msg(" + common.split(
        "pub fn create_symmetric_key_msg(", 1)[1].split("\npub struct ThrottledInterval", 1)[0]
    connection = (ROOT / "src/server/connection.rs").read_text()
    guarded = "    async fn type_auto_login_password" + connection.split(
        "    async fn type_auto_login_password", 1)[1].split("\n    #[inline]", 1)[0]
    win_input = (ROOT / "libs/enigo/src/win/win_impl.rs").read_text()
    win_input = "fn to_absolute(" + win_input.split("fn to_absolute(", 1)[1].split("\nfn keybd_event", 1)[0]
    input_fixture = (ROOT / "tools/localdesk/upstream-tests/windows-input.rs").read_text()
    fixture = (ROOT / "tools/localdesk/upstream-tests/auto-login.rs").read_text()
    with tempfile.TemporaryDirectory(prefix="landesk-security-") as tmp:
        tmp = Path(tmp)
        (tmp / "src").mkdir()
        (tmp / "Cargo.toml").write_text(f'''[package]
name = "landesk-security-check"
version = "0.1.0"
edition = "2021"
[dependencies]
hbb_common = {{ path = "{ROOT / 'libs/hbb_common'}" }}
base = {{ path = "{ROOT / 'libs/base'}" }}
serde_json = "1.0"
bytes = {{ version = "1.10", features = ["serde"] }}
lazy_static = "1.5"
tokio = {{ version = "1.44", features = ["full"] }}
''')
        # Use existing pins; Cargo prunes unused application packages, retaining
        # all dependency versions used by these production modules.
        (tmp / "Cargo.lock").write_bytes((ROOT / "Cargo.lock").read_bytes())
        (tmp / "src/lib.rs").write_text(f'''use bytes::Bytes;
use hbb_common::sodiumoxide::crypto::{{box_, secretbox}};
{helper}
#[path = "{ROOT / 'src/server/admission.rs'}"]
mod admission;
#[path = "{ROOT / 'src/client/prelogin.rs'}"]
mod prelogin;
#[path = "{ROOT / 'src/client/auto_login.rs'}"]
mod auto_login;
#[path = "{ROOT / 'src/platform/windows/login_state.rs'}"]
mod windows_login_state;
{input_fixture.replace("// PRODUCTION_ABSOLUTE_COORDINATES", win_input)}
{fixture.replace("// GUARDED_PRODUCTION_METHOD", guarded)}
#[path = "{ROOT / 'src/lan_protocol.rs'}"]
mod lan_protocol;
''')
        subprocess.run([args.cargo, "test", "--lib", "--offline", "--manifest-path",
                        str(tmp / "Cargo.toml"), "--target-dir", str(ROOT / "target"),
                        "-j", "2", "--", "--test-threads=1"], check=True)


if __name__ == "__main__":
    main()
