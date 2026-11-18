"""Offline regression tests for AppImage layout and pinned release tooling."""

import configparser
import hashlib
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import time
import unittest


ROOT = Path(__file__).resolve().parents[3]
MAKE_APPDIR = ROOT / "appimage" / "make_appdir.sh"
BUILD_APPIMAGE = ROOT / "appimage" / "build_appimage.sh"
ASSEMBLE_APPIMAGE = ROOT / "appimage" / "assemble_appimage.sh"
VERIFY_APPIMAGE = ROOT / "appimage" / "verify_appimage.sh"
FLATPAK = ROOT / "flatpak"
BUILD_WORKFLOW = ROOT / ".github/workflows/build.yaml"


def read_desktop(path):
    parser = configparser.ConfigParser(interpolation=None)
    parser.optionxform = str
    with path.open() as desktop_file:
        parser.read_file(desktop_file)
    return parser["Desktop Entry"]


CONFIGURE_SCRIPTS = {
    "campfire": ROOT / "scripts/app_config/configure_campfire.sh",
    "stack_duo": ROOT / "scripts/app_config/configure_stack_duo.sh",
    "stack_wallet": ROOT / "scripts/app_config/configure_stack_wallet.sh",
}


def configured_app_id(path):
    match = re.search(r'^\s*export NEW_APP_ID="([^"]+)"', path.read_text(), re.M)
    if match is None:
        raise AssertionError(f"NEW_APP_ID not found in {path}")
    return match.group(1)


APP_IDS = {app: configured_app_id(path) for app, path in CONFIGURE_SCRIPTS.items()}


def requires_tools(*tools):
    missing = [tool for tool in tools if shutil.which(tool) is None]
    return unittest.skipIf(bool(missing), f"required tools not found: {', '.join(missing)}")


class AppImageScriptsTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="appimage-test-")
        self.addCleanup(self.temp.cleanup)
        self.temp_path = Path(self.temp.name)
        self.bundle = self.temp_path / "bundle"
        self.bundle.mkdir()
        (self.bundle / "bundle-marker").write_text("copied\n")
        for app in APP_IDS:
            executable = self.bundle / app
            executable.write_text("#!/bin/sh\nprintf '%s\\n' \"$LD_LIBRARY_PATH\"\n")
            executable.chmod(0o755)

    def run_make_appdir(self, app="stack_wallet", appdir=None, script=MAKE_APPDIR):
        if appdir is None:
            appdir = self.temp_path / "AppDir"
        return subprocess.run(
            [str(script), app, str(self.bundle), str(appdir)],
            capture_output=True,
            text=True,
        )

    def make_test_packaging_root(self, name, icon_bytes):
        root = self.temp_path / f"packaging-root-{name.replace(' ', '-')}"
        shutil.copytree(ROOT / "appimage", root / "appimage")
        shutil.copytree(ROOT / "flatpak", root / "flatpak")
        icon = root / "asset_sources/icon/stack_wallet/icon.png"
        icon.parent.mkdir(parents=True)
        icon.write_bytes(icon_bytes)
        return root

    def make_fake_curl(self, runtime):
        fake_bin = self.temp_path / "fake-bin"
        fake_bin.mkdir(exist_ok=True)
        runtime_fixture = self.temp_path / "runtime-fixture"
        runtime_fixture.write_bytes(runtime)
        curl_log = self.temp_path / "curl-arguments"
        curl = fake_bin / "curl"
        curl.write_text(
            "#!/bin/sh\n"
            "set -eu\n"
            "printf '%s\\n' \"$@\" > \"$APPIMAGE_TEST_CURL_LOG\"\n"
            "output=\n"
            "retry_all_errors=false\n"
            "while [ \"$#\" -gt 0 ]; do\n"
            "  case \"$1\" in\n"
            "    --output) output=$2; shift 2 ;;\n"
            "    --retry-all-errors) retry_all_errors=true; shift ;;\n"
            "    *) shift ;;\n"
            "  esac\n"
            "done\n"
            "[ \"$retry_all_errors\" = true ]\n"
            "cp \"$APPIMAGE_TEST_RUNTIME\" \"$output\"\n"
        )
        curl.chmod(0o755)
        return fake_bin, runtime_fixture, curl_log

    def make_elf_executable(self, path, machine=62):
        header = bytearray(64)
        header[:4] = b"\x7fELF"
        header[4:7] = bytes((2, 1, 1))
        header[16:18] = (2).to_bytes(2, "little")
        header[18:20] = machine.to_bytes(2, "little")
        header[20:24] = (1).to_bytes(4, "little")
        header[52:54] = (64).to_bytes(2, "little")
        path.write_bytes(header)
        path.chmod(0o755)

    def run_build_appimage(self, runtime, output=None):
        fake_bin, runtime_fixture, curl_log = self.make_fake_curl(runtime)
        if output is None:
            output = self.temp_path / "test.AppImage"
        result = subprocess.run(
            [str(BUILD_APPIMAGE), "stack_wallet", str(self.bundle), str(output)],
            capture_output=True,
            text=True,
            env={
                **os.environ,
                "PATH": f"{fake_bin}:{os.environ['PATH']}",
                "VERSION": "1.2.3-test",
                "APPIMAGE_RUNTIME_URL": "https://attacker.invalid/runtime",
                "APPIMAGE_RUNTIME_SHA256": hashlib.sha256(runtime).hexdigest(),
                "APPIMAGE_TEST_RUNTIME": str(runtime_fixture),
                "APPIMAGE_TEST_CURL_LOG": str(curl_log),
            },
        )
        return result, output, curl_log

    def test_apprun_does_not_override_the_process_library_path(self):
        for app in APP_IDS:
            with self.subTest(app=app):
                appdir = self.temp_path / f"{app}-AppDir"
                subprocess.run(
                    [str(MAKE_APPDIR), app, str(self.bundle), str(appdir)],
                    check=True,
                    capture_output=True,
                    text=True,
                )

                unset = subprocess.run(
                    [str(appdir / "AppRun")],
                    check=True,
                    capture_output=True,
                    text=True,
                    env={},
                )
                self.assertEqual(unset.stdout.strip(), "")

                existing = subprocess.run(
                    [str(appdir / "AppRun")],
                    check=True,
                    capture_output=True,
                    text=True,
                    env={"LD_LIBRARY_PATH": "/trusted/lib"},
                )
                self.assertEqual(existing.stdout.strip(), "/trusted/lib")

    def test_appdir_layout_for_all_apps(self):
        for app, app_id in APP_IDS.items():
            with self.subTest(app=app):
                appdir = self.temp_path / f"{app} AppDir"
                subprocess.run(
                    [str(MAKE_APPDIR), app, str(self.bundle), str(appdir)],
                    check=True,
                    capture_output=True,
                    text=True,
                )
                self.assertTrue((appdir / "AppRun").stat().st_mode & 0o111)
                self.assertTrue((appdir / "bundle-marker").is_file())
                self.assertEqual(
                    (appdir / "bundle-marker").stat().st_ino,
                    (self.bundle / "bundle-marker").stat().st_ino,
                )
                self.assertTrue((appdir / f"{app_id}.desktop").is_file())
                self.assertTrue((appdir / f"{app_id}.png").is_file())
                self.assertEqual((appdir / ".DirIcon").readlink(), Path(f"{app_id}.png"))
                self.assertTrue(
                    (appdir / "usr/share/applications" / f"{app_id}.desktop").is_file()
                )
                self.assertTrue(
                    (
                        appdir
                        / "usr/share/icons/hicolor/512x512/apps"
                        / f"{app_id}.png"
                    ).is_file()
                )
                canonical_desktop = FLATPAK / f"{app_id}.desktop"
                self.assertEqual(
                    (appdir / f"{app_id}.desktop").read_bytes(),
                    canonical_desktop.read_bytes(),
                )
                self.assertEqual(
                    (
                        appdir / "usr/share/applications" / f"{app_id}.desktop"
                    ).read_bytes(),
                    canonical_desktop.read_bytes(),
                )
                self.assertEqual(
                    (
                        appdir / "usr/share/metainfo" / f"{app_id}.metainfo.xml"
                    ).read_bytes(),
                    (FLATPAK / f"{app_id}.metainfo.xml").read_bytes(),
                )

    def test_desktop_metadata_matches_the_application_id(self):
        for app, app_id in APP_IDS.items():
            with self.subTest(app=app):
                desktop = read_desktop(FLATPAK / f"{app_id}.desktop")
                self.assertEqual(desktop["Exec"], app)
                self.assertEqual(desktop["Icon"], app_id)
                self.assertEqual(desktop["StartupWMClass"], app_id)
                self.assertEqual(desktop["Categories"], "Office;Finance;")

    def test_x11_theme_shortcut_requires_a_usable_size(self):
        application = (
            ROOT / "scripts/app_config/templates/linux/my_application.cc"
        ).read_text()
        self.assertIn("gtk_icon_theme_get_icon_sizes", application)
        self.assertIn("size <= 256", application)
        self.assertIn('"icon.png"', application)
        self.assertIn("gdk_pixbuf_new_from_file_at_scale", application)
        self.assertIn("gtk_window_set_icon(window, icon)", application)
        self.assertNotIn("gdk_pixbuf_scale_simple", application)
        for app in APP_IDS:
            self.assertEqual(
                list((ROOT / f"asset_sources/icon/{app}").glob("icon-*.png")),
                [],
            )

    def test_metadata_does_not_advertise_the_abandoned_campfire_domain(self):
        metadata = (FLATPAK / "com.cypherstack.campfire.metainfo.xml").read_text()
        self.assertNotIn("campfireprivacy.com", metadata)
        self.assertIn(
            '<url type="homepage">https://github.com/firoorg/campfire</url>',
            metadata,
        )

    def test_unknown_app_is_rejected(self):
        result = subprocess.run(
            [str(MAKE_APPDIR), "unknown", str(self.bundle), str(self.temp_path / "out")],
            capture_output=True,
            text=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unknown app", result.stderr)

    def test_app_lookup_uses_the_desktop_entry_command(self):
        icon = (ROOT / "asset_sources/icon/stack_wallet/icon.png").read_bytes()
        packaging_root = self.make_test_packaging_root("exec-field-code", icon)
        desktop = packaging_root / "flatpak/com.cypherstack.stackwallet.desktop"
        desktop.write_text(
            desktop.read_text().replace("Exec=stack_wallet\n", "Exec=stack_wallet %U\n")
            + "\n[Desktop Action Settings]\n"
            + "Name=Settings\n"
            + "Exec=unrelated-command\n"
        )

        result = self.run_make_appdir(
            script=packaging_root / "appimage/make_appdir.sh",
            appdir=self.temp_path / "field-code-AppDir",
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_bundle_must_contain_the_expected_executable(self):
        (self.bundle / "stack_wallet").unlink()
        result = self.run_make_appdir()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("executable not found", result.stderr)

    def test_bundle_executable_must_not_be_a_symbolic_link(self):
        executable = self.bundle / "stack_wallet"
        executable.unlink()
        executable.symlink_to("/bin/true")

        result = self.run_make_appdir()

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("regular file, not a symbolic link", result.stderr)

    def test_existing_appdir_must_be_empty(self):
        appdir = self.temp_path / "AppDir"
        appdir.mkdir()
        sentinel = appdir / "old.desktop"
        sentinel.write_text("stale\n")

        result = self.run_make_appdir(appdir=appdir)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("not empty", result.stderr)
        self.assertEqual(sentinel.read_text(), "stale\n")

    def test_bundle_cannot_redirect_packaging_paths_outside_the_appdir(self):
        outside = self.temp_path / "outside"
        outside.mkdir()
        (self.bundle / "usr").symlink_to(outside, target_is_directory=True)

        result = self.run_make_appdir()

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("reserved packaging path", result.stderr)
        self.assertEqual(list(outside.iterdir()), [])

    def test_bundle_cannot_supply_an_extra_desktop_entry(self):
        (self.bundle / "injected.desktop").write_text(
            "[Desktop Entry]\n"
            "Type=Application\n"
            "Name=Injected\n"
            "Exec=stack_wallet\n"
        )

        result = self.run_make_appdir()

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("reserved packaging path", result.stderr)

    def test_cdpath_cannot_redirect_repository_discovery(self):
        decoy = self.temp_path / "decoy"
        (decoy / "appimage").mkdir(parents=True)
        result = subprocess.run(
            [
                "appimage/make_appdir.sh",
                "stack_wallet",
                str(self.bundle),
                str(self.temp_path / "cdpath-AppDir"),
            ],
            cwd=ROOT,
            env={**os.environ, "CDPATH": str(decoy)},
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_icon_must_be_a_512_pixel_square_png(self):
        cases = {
            "bad signature": b"not a png" + bytes(32),
            "wrong size": (
                b"\x89PNG\r\n\x1a\n"
                + bytes(8)
                + (32).to_bytes(4, "big")
                + (32).to_bytes(4, "big")
            ),
            "not square": (
                b"\x89PNG\r\n\x1a\n"
                + bytes(8)
                + (512).to_bytes(4, "big")
                + (256).to_bytes(4, "big")
            ),
        }
        for name, icon_bytes in cases.items():
            with self.subTest(name=name):
                root = self.make_test_packaging_root(name, icon_bytes)
                result = self.run_make_appdir(
                    script=root / "appimage/make_appdir.sh",
                    appdir=self.temp_path / f"{name}-AppDir",
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("expected a 512x512 PNG", result.stderr)

    def test_missing_icon_reports_a_diagnostic(self):
        root = self.make_test_packaging_root("missing-icon", b"unused")
        (root / "asset_sources/icon/stack_wallet/icon.png").unlink()

        result = self.run_make_appdir(
            script=root / "appimage/make_appdir.sh",
            appdir=self.temp_path / "missing-icon-AppDir",
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("icon is not a readable regular file", result.stderr)

    @requires_tools(
        "appstreamcli",
        "desktop-file-edit",
        "desktop-file-validate",
        "mksquashfs",
        "realpath",
        "unsquashfs",
    )
    def test_assembly_produces_a_gzip_appimage_with_versioned_metadata(self):
        runtime_log = self.temp_path / "runtime-log"
        runtime = (
            "#!/bin/sh\n"
            "set -eu\n"
            "[ \"${TARGET_APPIMAGE:-}\" = \"$APPIMAGE_TEST_EXPECTED_TARGET\" ]\n"
            "printf '%s | %s\\n' \"$TARGET_APPIMAGE\" \"$*\" "
            ">> \"$APPIMAGE_TEST_RUNTIME_LOG\"\n"
            "case $1 in\n"
            "  --appimage-offset) wc -c < \"$0\" ;;\n"
            "  --appimage-extract)\n"
            "    [ \"$2\" = AppRun ]\n"
            "    mkdir -p squashfs-root\n"
            "    printf '#!/bin/sh\\n' > squashfs-root/AppRun\n"
            "    chmod 0755 squashfs-root/AppRun\n"
            "    ;;\n"
            "  *) exit 2 ;;\n"
            "esac\n"
        ).encode()
        appdir = self.temp_path / "assembly-AppDir"
        make_result = self.run_make_appdir(appdir=appdir)
        self.assertEqual(
            make_result.returncode, 0, make_result.stdout + make_result.stderr
        )
        runtime_path = self.temp_path / "runtime-x86_64"
        runtime_path.write_bytes(runtime)
        runtime_path.chmod(0o755)
        mksquashfs_log = self.temp_path / "mksquashfs-log"
        fake_bin = self.temp_path / "assembly-fake-bin"
        fake_bin.mkdir()
        mksquashfs = fake_bin / "mksquashfs"
        mksquashfs.write_text(
            "#!/bin/sh\n"
            "printf '%s\\n' \"$@\" > \"$APPIMAGE_TEST_MKSQUASHFS_LOG\"\n"
            f"exec {shutil.which('mksquashfs')} \"$@\"\n"
        )
        mksquashfs.chmod(0o755)
        for desktop in (
            appdir / "com.cypherstack.stackwallet.desktop",
            appdir / "usr/share/applications/com.cypherstack.stackwallet.desktop",
        ):
            desktop.write_text(
                desktop.read_text().replace(
                    "Type=Application\n", "Type=Application\nActions=Settings;\n"
                )
                + (
                    "\n[Desktop Action Settings]\n"
                    "Name=Settings\n"
                    "Exec=stack_wallet --settings\n"
                )
            )
        output = self.temp_path / "test.AppImage"
        result = subprocess.run(
            [
                str(ASSEMBLE_APPIMAGE),
                str(appdir),
                str(runtime_path),
                str(output),
                "1.2.3-test",
            ],
            capture_output=True,
            text=True,
            env={
                **os.environ,
                "PATH": f"{fake_bin}:{os.environ['PATH']}",
                "APPIMAGE_TEST_MKSQUASHFS_LOG": str(mksquashfs_log),
            },
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(output.stat().st_mode & 0o111)
        mksquashfs_arguments = mksquashfs_log.read_text().splitlines()
        self.assertIn("-offset", mksquashfs_arguments)
        self.assertEqual(
            mksquashfs_arguments[mksquashfs_arguments.index("-offset") + 1],
            str(len(runtime)),
        )
        self.assertEqual(
            mksquashfs_arguments[mksquashfs_arguments.index("-mkfs-time") + 1],
            "0",
        )
        self.assertEqual(
            mksquashfs_arguments[mksquashfs_arguments.index("-all-time") + 1],
            "0",
        )
        self.assertNotIn("filesystem.squashfs", " ".join(mksquashfs_arguments))
        time.sleep(1.1)
        second_output = self.temp_path / "second.AppImage"
        second_result = subprocess.run(
            [
                str(ASSEMBLE_APPIMAGE),
                str(appdir),
                str(runtime_path),
                str(second_output),
                "1.2.3-test",
            ],
            capture_output=True,
            text=True,
            env={
                **os.environ,
                "PATH": f"{fake_bin}:{os.environ['PATH']}",
                "APPIMAGE_TEST_MKSQUASHFS_LOG": str(mksquashfs_log),
            },
        )
        self.assertEqual(
            second_result.returncode,
            0,
            second_result.stdout + second_result.stderr,
        )
        self.assertEqual(output.read_bytes(), second_output.read_bytes())

        verify = subprocess.run(
            [str(VERIFY_APPIMAGE), str(output), str(runtime_path)],
            capture_output=True,
            text=True,
            env={
                **os.environ,
                "APPIMAGE_TEST_EXPECTED_TARGET": str(output.resolve()),
                "APPIMAGE_TEST_RUNTIME_LOG": str(runtime_log),
            },
        )
        self.assertEqual(verify.returncode, 0, verify.stdout + verify.stderr)
        self.assertEqual(
            runtime_log.read_text().splitlines(),
            [
                f"{output.resolve()} | --appimage-offset",
                f"{output.resolve()} | --appimage-extract AppRun",
            ],
        )

        filesystem = subprocess.run(
            ["unsquashfs", "-s", "-o", str(len(runtime)), str(output)],
            check=True,
            capture_output=True,
            text=True,
        )
        self.assertIn("Compression gzip", filesystem.stdout)

        extracted = self.temp_path / "extracted-AppDir"
        subprocess.run(
            [
                "unsquashfs",
                "-q",
                "-no-progress",
                "-o",
                str(len(runtime)),
                "-d",
                str(extracted),
                str(output),
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        desktop = read_desktop(extracted / "com.cypherstack.stackwallet.desktop")
        self.assertEqual(desktop["X-AppImage-Version"], "1.2.3-test")

    @requires_tools(
        "appstreamcli",
        "cmp",
        "desktop-file-edit",
        "desktop-file-validate",
        "mksquashfs",
        "realpath",
        "sha256sum",
        "unsquashfs",
    )
    def test_runtime_pin_cannot_be_replaced_by_the_build_environment(self):
        (self.bundle / "stack_wallet").unlink()
        result, output, curl_log = self.run_build_appimage(b"corrupt runtime")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("SHA-256 mismatch", result.stderr)
        self.assertNotIn("executable not found", result.stderr)
        self.assertFalse(output.exists())

        curl_arguments = curl_log.read_text().splitlines()
        self.assertIn("--retry-all-errors", curl_arguments)
        self.assertIn("--proto", curl_arguments)
        self.assertIn("=https", curl_arguments)
        self.assertIn(
            "https://github.com/AppImage/type2-runtime/releases/download/20251108/runtime-x86_64",
            curl_arguments,
        )
        self.assertFalse(any("/continuous/" in arg for arg in curl_arguments))

    @requires_tools("readelf")
    def test_architecture_check_accepts_x86_64_and_rejects_arm64(self):
        cases = ((62, 0), (183, 1))
        for machine, expected_failure in cases:
            with self.subTest(machine=machine):
                executable = self.temp_path / f"machine-{machine}-app"
                self.make_elf_executable(executable, machine=machine)

                result = subprocess.run(
                    [
                        "bash",
                        "-c",
                        'source "$1"; verify_x86_64_bundle "$2"',
                        "bash",
                        str(BUILD_APPIMAGE),
                        str(executable),
                    ],
                    capture_output=True,
                    text=True,
                )

                self.assertEqual(bool(result.returncode), bool(expected_failure))
                if expected_failure:
                    self.assertIn("must be an x86-64 ELF", result.stderr)

    @requires_tools(
        "appstreamcli",
        "cmp",
        "desktop-file-edit",
        "desktop-file-validate",
        "mksquashfs",
        "readelf",
        "realpath",
        "sha256sum",
        "unsquashfs",
    )
    def test_builder_rejects_a_non_x86_64_bundle(self):
        icon = (ROOT / "asset_sources/icon/stack_wallet/icon.png").read_bytes()
        packaging_root = self.make_test_packaging_root("arm64-bundle", icon)
        runtime = bytes(4096)
        build_script = packaging_root / "appimage/build_appimage.sh"
        build_script.write_text(
            build_script.read_text().replace(
                "2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d",
                hashlib.sha256(runtime).hexdigest(),
            )
        )
        self.make_elf_executable(self.bundle / "stack_wallet", machine=183)
        fake_bin, runtime_fixture, curl_log = self.make_fake_curl(runtime)
        output = self.temp_path / "arm64.AppImage"

        result = subprocess.run(
            [str(build_script), "stack_wallet", str(self.bundle), str(output)],
            capture_output=True,
            text=True,
            env={
                **os.environ,
                "PATH": f"{fake_bin}:{os.environ['PATH']}",
                "VERSION": "1.2.3-test",
                "APPIMAGE_TEST_RUNTIME": str(runtime_fixture),
                "APPIMAGE_TEST_CURL_LOG": str(curl_log),
            },
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must be an x86-64 ELF", result.stderr)
        self.assertFalse(output.exists())

    def test_packaging_scripts_use_the_shared_tool_check(self):
        for script in (MAKE_APPDIR, ASSEMBLE_APPIMAGE, BUILD_APPIMAGE, VERIFY_APPIMAGE):
            with self.subTest(script=script.name):
                source = script.read_text()
                self.assertIn('source "$script_dir/lib.sh"', source)
                self.assertIn("require_tools ", source)
        self.assertNotIn("for tool in appstreamcli", BUILD_APPIMAGE.read_text())

    @requires_tools(
        "appstreamcli",
        "cmp",
        "desktop-file-edit",
        "desktop-file-validate",
        "mksquashfs",
        "realpath",
        "sha256sum",
        "unsquashfs",
    )
    def test_failed_verification_preserves_the_published_image_and_cleans_work(self):
        icon = (ROOT / "asset_sources/icon/stack_wallet/icon.png").read_bytes()
        packaging_root = self.make_test_packaging_root("failed-verification", icon)
        runtime = bytes(4096)
        build_script = packaging_root / "appimage/build_appimage.sh"
        build_script.write_text(
            build_script.read_text().replace(
                "2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d",
                hashlib.sha256(runtime).hexdigest(),
            )
        )
        verifier = packaging_root / "appimage/verify_appimage.sh"
        verifier.write_text(
            "#!/bin/sh\n"
            "set -eu\n"
            "work_marker=$(find \"$(dirname \"$1\")\" "
            "-path '*/AppDir/bundle-marker' -print -quit)\n"
            "[ -n \"$work_marker\" ]\n"
            "work_prefix=$(dirname \"$1\")/.appimage-work.\n"
            "case $work_marker in\n"
            "  \"$work_prefix\"*/AppDir/bundle-marker) ;;\n"
            "  *) exit 24 ;;\n"
            "esac\n"
            "[ \"$work_marker\" -ef \"$APPIMAGE_TEST_BUNDLE_MARKER\" ]\n"
            "exit 23\n"
        )
        verifier.chmod(0o755)
        fake_bin, runtime_fixture, curl_log = self.make_fake_curl(runtime)
        output = self.temp_path / "published.AppImage"
        output.write_bytes(b"known-good\n")
        temp_root = self.temp_path / "tmp"
        temp_root.mkdir()
        self.make_elf_executable(self.bundle / "stack_wallet")

        result = subprocess.run(
            [str(build_script), "stack_wallet", str(self.bundle), str(output)],
            capture_output=True,
            text=True,
            env={
                **os.environ,
                "PATH": f"{fake_bin}:{os.environ['PATH']}",
                "TMPDIR": str(temp_root),
                "VERSION": "1.2.3-test",
                "APPIMAGE_TEST_RUNTIME": str(runtime_fixture),
                "APPIMAGE_TEST_CURL_LOG": str(curl_log),
                "APPIMAGE_TEST_BUNDLE_MARKER": str(self.bundle / "bundle-marker"),
            },
        )

        self.assertEqual(result.returncode, 23)
        self.assertEqual(output.read_bytes(), b"known-good\n")
        self.assertEqual(list(output.parent.glob(".appimage-work.*")), [])
        self.assertEqual(list(output.parent.glob(".appimage-unverified.*")), [])
        self.assertEqual(list(temp_root.iterdir()), [])

    @requires_tools("appstreamcli", "desktop-file-edit", "mksquashfs", "realpath")
    def test_work_directory_is_cleaned_if_staged_output_creation_fails(self):
        icon = (ROOT / "asset_sources/icon/stack_wallet/icon.png").read_bytes()
        packaging_root = self.make_test_packaging_root("failed-mktemp", icon)
        build_script = packaging_root / "appimage/build_appimage.sh"
        fake_bin, runtime_fixture, curl_log = self.make_fake_curl(bytes(4096))
        mktemp_log = self.temp_path / "mktemp-count"
        mktemp = fake_bin / "mktemp"
        real_mktemp = shutil.which("mktemp")
        mktemp.write_text(
            "#!/bin/sh\n"
            "set -eu\n"
            "count=0\n"
            "[ ! -f \"$APPIMAGE_TEST_MKTEMP_LOG\" ] || "
            "count=$(cat \"$APPIMAGE_TEST_MKTEMP_LOG\")\n"
            "count=$((count + 1))\n"
            "printf '%s\\n' \"$count\" > \"$APPIMAGE_TEST_MKTEMP_LOG\"\n"
            "[ \"$count\" -ne 2 ] || exit 55\n"
            f"exec {real_mktemp} \"$@\"\n"
        )
        mktemp.chmod(0o755)
        output_dir = self.temp_path / "output"
        output_dir.mkdir()
        temp_root = self.temp_path / "tmp"
        temp_root.mkdir()
        output = output_dir / "published.AppImage"

        result = subprocess.run(
            [str(build_script), "stack_wallet", str(self.bundle), str(output)],
            capture_output=True,
            text=True,
            env={
                **os.environ,
                "PATH": f"{fake_bin}:{os.environ['PATH']}",
                "TMPDIR": str(temp_root),
                "VERSION": "1.2.3-test",
                "APPIMAGE_TEST_RUNTIME": str(runtime_fixture),
                "APPIMAGE_TEST_CURL_LOG": str(curl_log),
                "APPIMAGE_TEST_MKTEMP_LOG": str(mktemp_log),
            },
        )

        self.assertEqual(result.returncode, 55, result.stdout + result.stderr)
        self.assertEqual(list(output_dir.glob(".appimage-work.*")), [])
        self.assertEqual(list(output_dir.glob(".appimage-unverified.*")), [])
        self.assertEqual(list(temp_root.iterdir()), [])

    def test_linux_build_docs_state_appimage_requirements(self):
        docs = (ROOT / "docs/building/linux.md").read_text()
        appimage_docs = docs.split("## Build an AppImage", 1)[1]

        self.assertRegex(appimage_docs, r"apt-get install[^\n]*\bbinutils\b")
        self.assertRegex(appimage_docs, r"apt-get install[^\n]*\bcurl\b")
        self.assertIn("AppImageLauncher 3 beta", appimage_docs)
        self.assertRegex(appimage_docs, r"AppImageLauncher\s+2\.2")
        self.assertIn("usable size", appimage_docs)
        self.assertIn("falls back to the Flutter asset", appimage_docs)

    def test_appimage_version_is_passed_to_workflow_steps_through_env(self):
        workflow = BUILD_WORKFLOW.read_text()

        self.assertNotIn(
            'export VERSION="${{ steps.ver.outputs.version }}"', workflow
        )
        self.assertEqual(
            workflow.count("VERSION: ${{ steps.ver.outputs.version }}"), 3
        )

    @requires_tools(
        "appstreamcli",
        "desktop-file-edit",
        "desktop-file-validate",
        "mksquashfs",
        "realpath",
    )
    def test_assembly_rejects_output_inside_the_appdir(self):
        appdir = self.temp_path / "nested-output-AppDir"
        make_result = self.run_make_appdir(appdir=appdir)
        self.assertEqual(
            make_result.returncode, 0, make_result.stdout + make_result.stderr
        )
        runtime = self.temp_path / "runtime-x86_64"
        runtime.write_bytes(bytes(4096))
        output = appdir / "nested" / "nested.AppImage"

        result = subprocess.run(
            [
                str(ASSEMBLE_APPIMAGE),
                str(appdir),
                str(runtime),
                str(output),
                "1.2.3-test",
            ],
            capture_output=True,
            text=True,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must be outside the AppDir", result.stderr)
        self.assertFalse(output.exists())
        self.assertFalse(output.parent.exists())
        self.assertEqual(list(appdir.glob(".appimage-assemble.*")), [])

    @requires_tools(
        "appstreamcli",
        "desktop-file-edit",
        "desktop-file-validate",
        "mksquashfs",
        "realpath",
    )
    def test_assembly_replaces_a_directory_symlink_without_writing_through_it(self):
        appdir = self.temp_path / "symlink-output-AppDir"
        make_result = self.run_make_appdir(appdir=appdir)
        self.assertEqual(
            make_result.returncode, 0, make_result.stdout + make_result.stderr
        )
        runtime = self.temp_path / "runtime-x86_64"
        runtime.write_bytes(bytes(4096))
        redirected_directory = appdir / "redirected-output"
        redirected_directory.mkdir()
        output = self.temp_path / "external.AppImage"
        output.symlink_to(redirected_directory, target_is_directory=True)

        result = subprocess.run(
            [
                str(ASSEMBLE_APPIMAGE),
                str(appdir),
                str(runtime),
                str(output),
                "1.2.3-test",
            ],
            capture_output=True,
            text=True,
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(output.is_file())
        self.assertFalse(output.is_symlink())
        self.assertEqual(list(redirected_directory.iterdir()), [])

    @requires_tools(
        "appstreamcli",
        "desktop-file-edit",
        "desktop-file-validate",
        "mksquashfs",
        "realpath",
    )
    def test_assembly_rejects_incomplete_runtime_layout(self):
        cases = {
            "missing AppRun": ("AppRun", "AppDir must contain an executable"),
            "missing icon": (
                "com.cypherstack.stackwallet.png",
                "desktop entry icon not found",
            ),
            "missing DirIcon": (".DirIcon", ".DirIcon must be a relative"),
        }
        for name, (missing, message) in cases.items():
            with self.subTest(name=name):
                appdir = self.temp_path / f"{name}-AppDir"
                make_result = self.run_make_appdir(appdir=appdir)
                self.assertEqual(
                    make_result.returncode,
                    0,
                    make_result.stdout + make_result.stderr,
                )
                (appdir / missing).unlink()
                runtime = self.temp_path / f"{name}-runtime"
                runtime.write_bytes(bytes(4096))
                result = subprocess.run(
                    [
                        str(ASSEMBLE_APPIMAGE),
                        str(appdir),
                        str(runtime),
                        str(self.temp_path / f"{name}.AppImage"),
                        "1.2.3-test",
                    ],
                    capture_output=True,
                    text=True,
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(message, result.stderr)

    @requires_tools(
        "appstreamcli",
        "desktop-file-edit",
        "desktop-file-validate",
        "mksquashfs",
        "realpath",
    )
    def test_assembly_rejects_an_absolute_diricon_link(self):
        appdir = self.temp_path / "absolute-diricon-AppDir"
        make_result = self.run_make_appdir(appdir=appdir)
        self.assertEqual(
            make_result.returncode, 0, make_result.stdout + make_result.stderr
        )
        diricon = appdir / ".DirIcon"
        diricon.unlink()
        diricon.symlink_to((appdir / "com.cypherstack.stackwallet.png").resolve())
        runtime = self.temp_path / "absolute-diricon-runtime"
        runtime.write_bytes(bytes(4096))

        result = subprocess.run(
            [
                str(ASSEMBLE_APPIMAGE),
                str(appdir),
                str(runtime),
                str(self.temp_path / "absolute-diricon.AppImage"),
                "1.2.3-test",
            ],
            capture_output=True,
            text=True,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("relative link to the desktop entry icon", result.stderr)

    @requires_tools("cmp", "realpath", "unsquashfs")
    def test_image_verifier_does_not_execute_untrusted_input(self):
        image = self.temp_path / "fake.AppImage"
        marker = self.temp_path / "executed"
        image.write_text(
            "#!/bin/sh\n"
            f"touch {marker}\n"
        )
        image.chmod(0o755)
        runtime = self.temp_path / "fake-runtime"
        runtime.write_bytes(image.read_bytes())

        result = subprocess.run(
            [str(VERIFY_APPIMAGE), str(image), str(runtime)],
            capture_output=True,
            text=True,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(marker.exists())

    @requires_tools("cmp", "mksquashfs", "realpath", "unsquashfs")
    def test_image_verifier_rejects_a_symbolic_apprun(self):
        runtime = self.temp_path / "runtime"
        runtime.write_bytes(bytes(4096))
        payload = self.temp_path / "payload"
        payload.mkdir()
        (payload / "AppRun").symlink_to("/bin/sh")
        squashfs = self.temp_path / "payload.squashfs"
        subprocess.run(
            [
                "mksquashfs",
                str(payload),
                str(squashfs),
                "-all-root",
                "-noappend",
                "-no-xattrs",
                "-comp",
                "gzip",
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        image = self.temp_path / "symbolic-AppRun.AppImage"
        image.write_bytes(runtime.read_bytes() + squashfs.read_bytes())
        image.chmod(0o755)

        result = subprocess.run(
            [str(VERIFY_APPIMAGE), str(image), str(runtime)],
            capture_output=True,
            text=True,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("non-symbolic AppRun", result.stderr)

    def test_build_script_can_be_sourced_repeatedly_without_side_effects(self):
        result = subprocess.run(
            [
                "bash",
                "-c",
                'source "$1"; source "$1"; printf sourced',
                "bash",
                str(BUILD_APPIMAGE),
            ],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(result.stdout, "sourced")


if __name__ == "__main__":
    unittest.main()
