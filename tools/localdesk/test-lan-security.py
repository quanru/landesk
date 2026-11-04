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
#[path = "{ROOT / 'src/lan_protocol.rs'}"]
mod lan_protocol;
''')
        subprocess.run([args.cargo, "test", "--lib", "--offline", "--manifest-path",
                        str(tmp / "Cargo.toml"), "--target-dir", str(ROOT / "target"),
                        "-j", "2", "--", "--test-threads=1"], check=True)


if __name__ == "__main__":
    main()
