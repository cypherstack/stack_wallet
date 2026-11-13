"""Offline regression tests for AppImage layout and pinned release tooling."""

import hashlib
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[3]
MAKE_APPDIR = ROOT / "appimage" / "make_appdir.sh"
BUILD_APPIMAGE = ROOT / "appimage" / "build_appimage.sh"
BUILD_WORKFLOW = ROOT / ".github" / "workflows" / "build.yaml"

APP_IDS = {
    "stack_wallet": "com.cypherstack.stackwallet",
    "stack_duo": "com.cypherstack.stackduo",
    "campfire": "com.cypherstack.campfire",
}


class AppImageScriptsTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="appimage-test-")
        self.addCleanup(self.temp.cleanup)
        self.temp_path = Path(self.temp.name)
        self.bundle = self.temp_path / "bundle"
        self.bundle.mkdir()
        (self.bundle / "bundle-marker").write_text("copied\n")

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
                self.assertFalse((appdir / "usr/share/metainfo").exists())

    def test_unknown_app_is_rejected(self):
        result = subprocess.run(
            [str(MAKE_APPDIR), "unknown", str(self.bundle), str(self.temp_path / "out")],
            capture_output=True,
            text=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unknown app", result.stderr)

    def test_release_toolchain_is_immutable_and_explicit(self):
        script = BUILD_APPIMAGE.read_text()
        self.assertNotIn("/continuous/", script)
        self.assertIn("releases/download/${APPIMAGETOOL_VERSION}", script)
        self.assertIn("releases/download/${APPIMAGE_RUNTIME_VERSION}", script)
        self.assertIn("--proto '=https'", script)
        self.assertIn("--proto-redir '=https'", script)
        self.assertIn("--connect-timeout 30", script)
        self.assertIn("--max-time 300", script)
        self.assertIn("--runtime-file", script)
        self.assertIn("verify_sha256", script)
        self.assertRegex(script, r'APPIMAGETOOL_SHA256="[0-9a-f]{64}"')
        self.assertRegex(script, r'APPIMAGE_RUNTIME_SHA256="[0-9a-f]{64}"')

    def test_workflow_uses_one_shared_packaging_entrypoint(self):
        workflow = BUILD_WORKFLOW.read_text()
        self.assertNotIn("AppImage/appimagetool/releases/download/continuous", workflow)
        self.assertEqual(workflow.count("appimage/build_appimage.sh"), 3)
        self.assertEqual(workflow.count("build-appimage:\n"), 1)
        self.assertEqual(workflow.count("build-campfire-appimage:\n"), 1)
        self.assertEqual(workflow.count("build-stack-duo-appimage:\n"), 1)
        for job, needs in {
            "build-appimage": "build-linux",
            "build-campfire-appimage": "build-campfire-linux",
            "build-stack-duo-appimage": "build-stack-duo-linux",
        }.items():
            self.assertIn(
                f"  {job}:\n"
                "    runs-on: ubuntu-24.04\n"
                f"    needs: {needs}\n"
                "    permissions:\n      contents: read\n    steps:\n",
                workflow,
            )
        for app in APP_IDS:
            self.assertIn(f"appimage/build_appimage.sh {app} bundle", workflow)

    def test_checksum_verification_accepts_match_and_rejects_mismatch(self):
        payload = self.temp_path / "payload"
        payload.write_bytes(b"known AppImage tool fixture\n")
        digest = hashlib.sha256(payload.read_bytes()).hexdigest()
        command = 'source "$1"; verify_sha256 "$2" "$3"'

        valid = subprocess.run(
            ["bash", "-c", command, "bash", str(BUILD_APPIMAGE), str(payload), digest],
            capture_output=True,
            text=True,
        )
        self.assertEqual(valid.returncode, 0, valid.stdout + valid.stderr)

        invalid = subprocess.run(
            ["bash", "-c", command, "bash", str(BUILD_APPIMAGE), str(payload), "0" * 64],
            capture_output=True,
            text=True,
        )
        self.assertNotEqual(invalid.returncode, 0)
        self.assertIn("SHA-256 mismatch", invalid.stderr)


if __name__ == "__main__":
    unittest.main()
