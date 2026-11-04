#!/usr/bin/env python3
"""Compile selected production components with minimal OS boundary doubles.

No SDK download is performed. Supply rustc and optionally the Kotlin compiler
classpath. --ref HEAD runs the same regressions against the pre-backport source.
These component checks do not replace native Android/Linux integration builds.
"""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
FIXTURES = Path(__file__).with_name("upstream-tests")


def run(*args):
    subprocess.run([str(arg) for arg in args], check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rustc", default="rustc")
    parser.add_argument("--sysroot")
    parser.add_argument("--java", default="java")
    parser.add_argument("--kotlin-classpath")
    parser.add_argument("--kotlin-stdlib")
    parser.add_argument("--ref", help="Read production source from this Git ref")
    parser.add_argument("--only", choices=["frame", "x11", "file-permission", "clipboard"])
    args = parser.parse_args()

    def read(path):
        if args.ref:
            return subprocess.check_output(
                ["git", "show", f"{args.ref}:{path}"], cwd=ROOT, text=True
            )
        return (ROOT / path).read_text()

    def between(source, start, end):
        return start + source.split(start, 1)[1].split(end, 1)[0]

    with tempfile.TemporaryDirectory(prefix="landesk-backports-") as tmp:
        tmp = Path(tmp)
        for name in ["frame", "x11", "file-permission"]:
            if args.only and args.only != name:
                continue
            if name == "frame":
                source = between(read("libs/scrap/src/android/ffi.rs"),
                                 "struct FrameRaw {", "pub fn get_video_raw")
                common = read("libs/scrap/src/common/mod.rs")
                source += between(common, "pub fn would_block_if_equal(", "\n}") + "\n}\n"
            elif name == "x11":
                source = between(read("libs/scrap/src/x11/iter.rs"),
                                 "pub struct DisplayIter {", "\nfn get_atom_name")
            else:
                source = between(read("src/clipboard_file.rs"),
                                 "pub fn is_file_data_request(", "\n}") + "\n}\n"
            target = tmp / f"{name}.rs"
            fixture = (FIXTURES / f"{name}.rs").read_text().replace("// PRODUCTION", source)
            if name == "file-permission":
                connection = read("src/server/connection.rs")
                connection = connection[connection.index("} else if is_file_data_request(&clip)"):]
                one_way = between(connection, "is_file_data_request(&clip)", "\n                    {")
                permission = between(connection, "crate::is_support_file_copy_paste(&self.lr.version)", "\n                        {")
                fixture = fixture.replace("// ONE_WAY_GUARD", one_way)
                fixture = fixture.replace("// PERMISSION_GUARD", permission)
            target.write_text(fixture)
            cmd = [args.rustc, "--edition=2021", "--test", "--crate-name", name.replace("-", "_"),
                   "-A", "unused_imports"]
            if args.sysroot:
                cmd += ["--sysroot", args.sysroot]
            run(*cmd, target, "-o", tmp / name)
            run(tmp / name, "--test-threads=1")

        if args.only in [None, "clipboard"]:
            if not args.kotlin_classpath or not args.kotlin_stdlib:
                raise SystemExit("Kotlin checks require --kotlin-classpath and --kotlin-stdlib")
            source = read("flutter/android/app/src/main/kotlin/com/carriez/flutter_hbb/RdClipboardManager.kt")
            # Use the production limit when present; the old source has no limit.
            companion = ""
            if "    companion object {" in source:
                companion = between(source, "    companion object {", "\n    }") + "\n    }\n"
            method = between(source, "    @Keep\n    fun rustUpdateClipboard(", "\n    }\n}") + "\n    }\n"
            target = tmp / "clipboard.kt"
            target.write_text((FIXTURES / "clipboard.kt").read_text().replace("// PRODUCTION", companion + method))
            run(args.java, "-cp", args.kotlin_classpath,
                "org.jetbrains.kotlin.cli.jvm.K2JVMCompiler", "-no-stdlib", "-no-reflect",
                "-classpath", args.kotlin_stdlib, target, "-d", tmp / "clipboard.jar")
            run(args.java, "-cp", str(tmp / "clipboard.jar") + os.pathsep + args.kotlin_stdlib,
                "ClipboardKt")


if __name__ == "__main__":
    main()
