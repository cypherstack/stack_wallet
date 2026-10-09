"""Exercise local resolver overrides against a configured app with Git pins.

Run with python3 scripts/dev/test_use_openalias_packages.py; requires Dart.
No network or wallet state is used.
"""

import json
from pathlib import Path
import subprocess
import tempfile
import unittest


HELPER = Path(__file__).with_name('use_openalias_packages.dart').resolve()


class LocalOverridesTest(unittest.TestCase):
    def test_replaces_existing_pins_and_preserves_other_overrides(self):
        with tempfile.TemporaryDirectory(prefix='alias overrides ') as directory:
            root = Path(directory)
            packages = ['doh_resolver', 'dnssec_resolver', 'openalias', 'keep']
            for name in packages:
                package = root / name
                package.mkdir()
                (package / 'pubspec.yaml').write_text(
                    f'name: {name}\nversion: 0.0.1\n'
                    'environment:\n  sdk: ">=3.5.0 <4.0.0"\n'
                )
            app = root / 'app'
            app.mkdir()
            dependencies = ''.join(f'  {name}: any\n' for name in packages)
            pins = ''.join(
                f'  {name}:\n    git:\n'
                f'      url: https://invalid.example/{name}.git\n'
                '      ref: main\n'
                for name in packages[:-1]
            )
            (app / 'pubspec.yaml').write_text(
                'name: override_fixture\nenvironment:\n'
                '  sdk: ">=3.5.0 <4.0.0"\ndependencies:\n' + dependencies
                + 'dependency_overrides:\n' + pins
                + '  keep:\n    path: ../keep\n'
            )
            def run(*args):
                return subprocess.run(
                    ['dart', *args], cwd=app, check=True,
                    capture_output=True, text=True, timeout=60,
                )
            run(str(HELPER), str(root))
            first = (app / 'pubspec_overrides.yaml').read_text()
            run(str(HELPER), str(root))
            self.assertEqual(first, (app / 'pubspec_overrides.yaml').read_text())
            run('pub', 'get', '--offline')
            config = json.loads((app / '.dart_tool/package_config.json').read_text())
            resolved = {item['name']: item for item in config['packages']}
            for name in packages:
                uri = resolved[name]['rootUri']
                self.assertTrue(uri.endswith(f'/{name}') or uri.endswith(f'/{name}/'))


if __name__ == '__main__':
    unittest.main()
