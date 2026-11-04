#!/usr/bin/env python3
"""Compile actual platform helpers and pinned security dependencies in isolation.

Needs Cargo/Rust; invokes no Flutter, Linux service or real user configuration.
OS boundaries in the fixture are doubles. Cargo may download registry crates.
"""
import argparse
from pathlib import Path
import subprocess
import tempfile
import tomllib

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cargo", default="cargo")
    args = parser.parse_args()
    linux = (ROOT / "src/platform/linux.rs").read_text()
    lang = (ROOT / "src/lang.rs").read_text()

    def block(source, start, end):
        return start + source.split(start, 1)[1].split(end, 1)[0]

    code = block(linux, "fn append_audio_latency_envs(", "\n#[inline]\nfn try_start_server_")
    code += block(linux, "pub fn get_active_username()", "\npub fn get_user_home_by_name")
    code += block(linux, "pub fn is_prelogin()", "\n// Check \"Lock\".")
    code += block(linux, "fn get_width_height_from_captures", "\npub fn resolutions(")
    code += block(linux, "mod xrandr_tests {", "\npub fn change_resolution_directly")
    code += block(lang, "pub(crate) fn is_cjk_lang(", '\n#[cfg(not(any(target_os = "android", target_os = "ios")))]')
    code += block(lang, "fn extract_placeholder(", "\nmod test {")
    code += "mod test {" + lang.split("\nmod test {", 1)[1]
    code += block((ROOT / "src/flutter_ffi.rs").read_text(), "fn peer_config_path_ready()", "\npub fn main_load_recent_peers")

    paths = ["src/platform/linux.rs", "src/platform/gtk_sudo.rs", "src/client.rs",
             "src/client/io_loop.rs", "src/ipc.rs", "src/server/audio_service.rs",
             "src/server/wayland.rs", "src/flutter.rs", "src/flutter_ffi.rs",
             "src/lang.rs", "libs/scrap/src/wayland/pipewire.rs"]
    # Parse complete production files, beyond the small components compiled below.
    code += "\nconst SOURCES: &[(&str, &str)] = &[\n"
    for path in paths:
        code += f'("{path}", include_str!("{ROOT / path}")),\n'
    code += "];\n"
    lock = tomllib.loads((ROOT / "Cargo.lock").read_text())
    names = ["bytes", "crossbeam-epoch", "rustls-pki-types", "rustls-webpki", "webpki-root-certs", "webpki-roots"]
    dependencies = ['regex = "=1.11.1"', 'syn = { version = "=2.0.108", features = ["full"] }']
    for name in names:
        package, = [p for p in lock["package"] if p["name"] == name]
        dependencies.append(f'{name} = "={package["version"]}"')
    # Keep relevant transitive crates at the application's pins too. Otherwise a
    # fresh small harness may resolve a newer edition/MSRV than the real build.
    for name in ["zeroize", "cc", "libc", "proc-macro2", "quote", "unicode-ident",
                 "serde", "serde_core", "regex-automata", "regex-syntax", "aho-corasick",
                 "memchr", "find-msvc-tools", "shlex"]:
        packages = [p for p in lock["package"] if p["name"] == name]
        if len(packages) == 1:
            dependencies.append(f'{name} = "={packages[0]["version"]}"')
    with tempfile.TemporaryDirectory(prefix="landesk-platform-") as tmp:
        tmp = Path(tmp)
        (tmp / "src").mkdir()
        (tmp / "Cargo.toml").write_text('[package]\nname = "landesk-upstream-platform"\nversion = "0.1.0"\nedition = "2021"\n[dependencies]\n' + "\n".join(dependencies))
        fixture = Path(__file__).with_name("upstream-tests") / "platform.rs"
        (tmp / "src/lib.rs").write_text(fixture.read_text().replace("// PRODUCTION", code))
        subprocess.run([args.cargo, "test", "--lib", "--manifest-path", str(tmp / "Cargo.toml"), "-j", "2", "--", "--test-threads=1"], check=True)
        resolved = tomllib.loads((tmp / "Cargo.lock").read_text())["package"]
        for name in names:
            expected, = [p for p in lock["package"] if p["name"] == name]
            actual, = [p for p in resolved if p["name"] == name]
            for field in ["version", "source", "checksum"]:
                if expected[field] != actual[field]:
                    raise SystemExit(f"Application lock mismatch: {name} {field}")
        print("Six dependency versions, registry sources and SHA-256 checksums match the application lock")


if __name__ == "__main__":
    main()
