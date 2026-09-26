#!/usr/bin/env python3
import argparse
import pathlib
import shutil
import subprocess
import tempfile
import time

parser = argparse.ArgumentParser()
parser.add_argument('--flutter', default='flutter')
parser.add_argument('--adb', default='adb')
parser.add_argument('--device', required=True)
parser.add_argument('--scope', choices=['host', 'none', 'fields'], default='host')
parser.add_argument('--work-dir')
args = parser.parse_args()
if not args.device.startswith('emulator-'):
    parser.error('Use a disposable emulator; the probe enables test accessibility services.')

here = pathlib.Path(__file__).resolve().parent
repo = here.parents[1]
work = pathlib.Path(args.work_dir or tempfile.mkdtemp(prefix='stack-a11y-')).resolve()
app = work / 'app'
package = 'com.cypherstack.accessibility_probe'

def run(command, **kwargs):
    return subprocess.run(command, check=True, text=True, **kwargs)

def adb(*command, capture=False):
    return run([args.adb, '-s', args.device, *command], capture_output=capture)

if not app.exists():
    run([args.flutter, 'create', '--empty', '--platforms=android', '--org',
         'com.cypherstack', '--project-name', 'accessibility_probe', str(app)])
shutil.copyfile(here / 'main.dart', app / 'lib/main.dart')
shutil.copyfile(repo / 'lib/widgets/sensitive_wallet_content.dart', app / 'lib/sensitive_wallet_content.dart')
activity = (repo / 'scripts/app_config/templates/android/app/src/main/kotlin/com/cypherstack/stackwallet/MainActivity.kt').read_text()
activity = activity.replace('package com.place.holder', f'package {package}')
if args.scope != 'host':
    start = activity.index('    override fun provideRootLayout')
    end = activity.index('    var openPath:', start)
    activity = activity[:start] + activity[end:]
kotlin = app / 'android/app/src/main/kotlin/com/cypherstack/accessibility_probe'
kotlin.mkdir(parents=True, exist_ok=True)
(kotlin / 'MainActivity.kt').write_text(activity)
shutil.copyfile(here / 'Probe.kt', kotlin / 'Probe.kt')
xml = app / 'android/app/src/main/res/xml'
xml.mkdir(exist_ok=True)
for name, tool in [('tool', 'true'), ('non_tool', 'false')]:
    (xml / f'{name}.xml').write_text(f'''<accessibility-service xmlns:android="http://schemas.android.com/apk/res/android"
        android:accessibilityEventTypes="typeAllMask"
        android:accessibilityFeedbackType="feedbackGeneric"
        android:accessibilityFlags="flagReportViewIds|flagRetrieveInteractiveWindows"
        android:canRetrieveWindowContent="true"
        android:isAccessibilityTool="{tool}"
        android:packageNames="{package}" />''')
manifest_path = app / 'android/app/src/main/AndroidManifest.xml'
manifest = manifest_path.read_text().replace('${applicationName}', '.ProbeApplication')
start_marker, end_marker = '<!-- PROBE START -->', '<!-- PROBE END -->'
while start_marker in manifest:
    start = manifest.index(start_marker)
    end = manifest.index(end_marker, start) + len(end_marker)
    manifest = manifest[:start] + manifest[end:]
services = ''
for cls, xml_name in [('ToolProbeService', 'tool'), ('NonToolProbeService', 'non_tool')]:
    services += f'''<service android:name=".{cls}" android:exported="true"
        android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE">
        <intent-filter><action android:name="android.accessibilityservice.AccessibilityService" /></intent-filter>
        <meta-data android:name="android.accessibilityservice" android:resource="@xml/{xml_name}" />
        </service>'''
services += '<receiver android:name=".ProbeReceiver" android:exported="true" />'
manifest = manifest.replace('</application>', start_marker + services + end_marker + '</application>')
manifest_path.write_text(manifest)
run([args.flutter, 'build', 'apk', '--debug', '--target-platform', 'android-x64',
     f'--dart-define=HOST_FILTERED={str(args.scope != "fields").lower()}'], cwd=app)
adb('install', '-r', str(app / 'build/app/outputs/flutter-apk/app-debug.apk'))
old_services = adb('shell', 'settings', 'get', 'secure', 'enabled_accessibility_services', capture=True).stdout.strip()
old_enabled = adb('shell', 'settings', 'get', 'secure', 'accessibility_enabled', capture=True).stdout.strip()
try:
    services = f'{package}/.ToolProbeService:{package}/.NonToolProbeService'
    if old_services and old_services != 'null':
        services = old_services + ':' + services
    adb('shell', 'settings', 'put', 'secure', 'enabled_accessibility_services', services)
    adb('shell', 'settings', 'put', 'secure', 'accessibility_enabled', '1')
    adb('shell', 'run-as', package, 'rm', '-f', 'files/accessibility-result.txt')
    adb('shell', 'am', 'start', '-n', f'{package}/.MainActivity')
    adb('shell', 'am', 'broadcast', '-n', f'{package}/.ProbeReceiver', '--es', 'scope', args.scope)
    deadline = time.monotonic() + 90
    output = ''
    while time.monotonic() < deadline:
        result = subprocess.run([args.adb, '-s', args.device, 'shell', 'run-as', package,
                                 'cat', 'files/accessibility-result.txt'], text=True, capture_output=True)
        if result.returncode == 0 and result.stdout:
            output = result.stdout
            break
        time.sleep(1)
    print(output)
    if not output.startswith('PASS:'):
        raise SystemExit('Accessibility integration check failed or timed out')

finally:
    for key, value in [('enabled_accessibility_services', old_services), ('accessibility_enabled', old_enabled)]:
        if value == 'null':
            adb('shell', 'settings', 'delete', 'secure', key)
        else:
            adb('shell', 'settings', 'put', 'secure', key, value)
