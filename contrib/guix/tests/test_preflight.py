"""Fast checks for the Guix prototype's supported-input boundary."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[3]
PRELUDE = ROOT / 'contrib/guix/libexec/prelude.bash'


class PreflightTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='guix-preflight-', dir=ROOT / 'contrib/guix/tests')
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.env = os.environ.copy()
        for name in ('SOURCE_DIR', 'BASE_CACHE', 'FLUTTER_SDK_SHA256'):
            self.env.pop(name, None)
        self.env['BASE_CACHE'] = str(self.directory / 'cache')

    def shell(self, command, *args):
        return subprocess.run(
            ['bash', '-c', 'source "$1"; shift; ' + command, 'test', str(PRELUDE), *args],
            env=self.env, text=True, capture_output=True,
        )

    def test_source_defaults_to_containing_checkout(self):
        result = self.shell('printf "%s" "$SOURCE_DIR"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(Path(result.stdout), ROOT)

    def test_current_checkout_fails_before_cache_mutation(self):
        for entry in ('guix-build', 'supplementary/deps/fetch-pub-deps.sh',
                      'supplementary/deps/fetch-cargo-deps.sh', 'supplementary/deps/verify-deps.sh'):
            with self.subTest(entry=entry):
                result = subprocess.run(['bash', str(ROOT / 'contrib/guix' / entry)],
                                        env=self.env, text=True, capture_output=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('Guix native-assets support is not implemented', result.stderr)
                self.assertFalse((self.directory / 'cache').exists())

    def test_legacy_layout_requires_all_manifests(self):
        self.env['SOURCE_DIR'] = str(self.directory)
        paths = ('flutter_libepiccash/rust', 'flutter_libmwc/rust', 'frostdart/src/serai')
        for path in paths:
            self.assertNotEqual(self.shell('require_supported_native_layout').returncode, 0)
            manifest = self.directory / 'crypto_plugins' / path / 'Cargo.toml'
            manifest.parent.mkdir(parents=True)
            manifest.write_text('[workspace]\n')
        template = self.directory / 'scripts/app_config/templates/pubspec.template.yaml'
        template.parent.mkdir(parents=True)
        template.write_text('\n'.join('#    path: ./crypto_plugins/' + name for name in
                                      ('flutter_libepiccash', 'flutter_libmwc', 'frostdart')))
        self.assertEqual(self.shell('require_supported_native_layout').returncode, 0)
        # Ignored workspaces from an older checkout cannot bypass the guard.
        template.write_text((ROOT / 'scripts/app_config/templates/pubspec.template.yaml').read_text())
        self.assertNotEqual(self.shell('require_supported_native_layout').returncode, 0)

    def test_checksum_required_and_well_formed(self):
        for value in ('', 'abc', 'z' * 64):
            self.env['FLUTTER_SDK_SHA256'] = value
            self.assertNotEqual(self.shell('require_flutter_checksum').returncode, 0)
        self.env['FLUTTER_SDK_SHA256'] = 'a' * 64
        self.assertEqual(self.shell('require_flutter_checksum').returncode, 0)

    def test_checksum_mismatch_fails(self):
        archive = self.directory / 'archive'
        archive.write_bytes(b'fixture')
        expected = hashlib.sha256(b'fixture').hexdigest()
        self.assertEqual(self.shell('verify_sha256 "$1" "$2"', str(archive), expected).returncode, 0)
        self.assertNotEqual(self.shell('verify_sha256 "$1" "$2"', str(archive), '0' * 64).returncode, 0)

    def test_sdk_metadata_accepts_whitespace_and_rejects_invalid_versions(self):
        executable = self.directory / 'flutter'
        for metadata, valid in ((json.dumps({'frameworkVersion': '3.47.2'}, indent=2), True),
                                ('{"frameworkVersion":"3.38.1"}', False), ('{}', False),
                                ('not json', False), ('', False)):
            with self.subTest(metadata=metadata):
                executable.write_text("#!/bin/sh\ncat <<'METADATA'\n" + metadata + '\nMETADATA\n')
                executable.chmod(0o755)
                result = self.shell('verify_flutter_sdk_version "$1"', str(executable))
                self.assertEqual(result.returncode == 0, valid, result.stderr)


if __name__ == '__main__':
    unittest.main()
