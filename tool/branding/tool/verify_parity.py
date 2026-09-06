#!/usr/bin/env python3
"""Consumer-only comparison of the legacy scripts with the generic engine adapter."""
import argparse
import filecmp
from pathlib import Path
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--repo', required=True, type=Path)
parser.add_argument('--base', default='HEAD')
args = parser.parse_args()
adapter = Path(__file__).resolve().parents[1]
revision = subprocess.check_output(['git', '-C', str(args.repo), 'rev-parse', '--verify', '--end-of-options', f'{args.base}^{{commit}}'], text=True).strip()

baseline = r'''
source ./env.sh
export BUILD_ISAR_FROM_SOURCE=0 USE_SYSTEM_SECURE_STORAGE_DEPS=0
source app_config/templates/configure_template_files.sh
app_config/shared/update_version.sh -v 2.4.0 -b 123
app_config/shared/link_assets.sh "$1" linux
cp "$APP_PROJECT_ROOT_DIR/asset_sources/other/playstore_icon/$1/app_icon-playstore.png" "$APP_PROJECT_ROOT_DIR/android/app/src/main/app_icon-playstore.png"
source "app_config/configure_$1.sh" linux
app_config/platforms/android/platform_config.sh
app_config/platforms/linux/platform_config.sh
'''
files = [
    'pubspec.yaml', 'lib/app_config.g.dart', 'android/app/build.gradle',
    'android/app/src/debug/AndroidManifest.xml', 'android/app/src/profile/AndroidManifest.xml',
    'android/app/src/main/AndroidManifest.xml', 'android/app/src/main/profile/AndroidManifest.xml',
    'android/app/src/main/kotlin/com/cypherstack/stackwallet/MainActivity.kt',
    'android/app/src/main/app_icon-playstore.png', 'linux/CMakeLists.txt', 'linux/my_application.cc',
]

def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def compare_tree(a, b):
    left = sorted(p.relative_to(a) for p in a.rglob('*') if p.is_file())
    right = sorted(p.relative_to(b) for p in b.rglob('*') if p.is_file())
    require(left == right, f'Tree entries differ: {a}, {b}')
    for path in left:
        require(filecmp.cmp(a/path, b/path, shallow=False), f'Content differs: {path}')


def run(command, cwd=None):
    result = subprocess.run(command, cwd=cwd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if result.returncode:
        raise RuntimeError(f'{command}\n{result.stdout}')

with tempfile.TemporaryDirectory(prefix='stack-wallet-adapter-parity-') as work:
    for brand in ['stack_wallet', 'stack_duo', 'campfire']:
        roots = []
        for method in ['bash', 'adapter']:
            root = Path(work)/brand/method
            run(['git', 'clone', '--quiet', '--shared', '--no-checkout', str(args.repo.resolve()), str(root)])
            run(['git', '-C', str(root), 'checkout', '--quiet', '--detach', revision])
            roots.append(root)
        a, b = roots
        run(['bash', '-e', '-c', baseline, 'baseline', brand], a/'scripts')
        run(['dart', 'run', 'bin/configure.dart', '--brand', brand, '-p', str(b), '-v', '2.4.0', '-b', '123', '--platforms', 'android,linux', '--apply', '--overwrite'], adapter)
        for path in files:
            require(filecmp.cmp(a/path, b/path, shallow=False), f'{brand}: differs {path}')
        compare_tree(a/'lib/wl_gen/generated', b/'lib/wl_gen/generated')
        for directory in ['default_themes', 'icon', 'lottie', 'in_app_logo_icons', 'svg']:
            require(not (b/'assets'/directory).is_symlink(), f'{brand}: unexpected asset symlink {directory}')
            compare_tree((a/'assets'/directory).resolve(), b/'assets'/directory)
        run(['dart', 'run', 'bin/configure.dart', '--brand', brand, '-p', str(b), '-v', '2.4.0', '-b', '123', '--platforms', 'android,linux', '--apply'], adapter)
        print(f'{brand}: identical generated files and asset contents; repeat configuration passed', flush=True)
print(f'Verified against app revision {revision}', flush=True)
