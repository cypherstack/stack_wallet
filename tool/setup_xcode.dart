// Run directly with `dart tool/setup_xcode.dart`; no pub get/build hooks needed.
import 'dart:io';

const xcodeVersion = '27.0';

// This runs only in the new Terminal session, never in the build process.
// Keep privileged operations explicit and use sudo -k WITH a command: sudo
// prompts itself and neither reads nor updates its cached credentials.
const installerScript = r'''
set -euo pipefail
umask 077
cd "$HOME"

if [ "$(/usr/bin/id -u)" = 0 ]; then
  echo 'Run this helper as your normal macOS user, without sudo.' >&2
  exit 1
fi
if [ "$(/usr/bin/uname -m)" != arm64 ]; then
  echo 'This setup helper requires an Apple Silicon Mac.' >&2
  exit 1
fi
if [ ! -t 0 ]; then
  echo 'Run this setup in its own interactive Terminal window.' >&2
  exit 1
fi

find_xcode() {
  local candidate version
  for candidate in /Applications/Xcode*.app; do
    [ -f "$candidate/Contents/Info.plist" ] || continue
    version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
      "$candidate/Contents/Info.plist" 2>/dev/null) || continue
    case "$version" in
      27.0|27.0.0) XCODE_APP="$candidate"; return 0 ;;
    esac
  done
  return 1
}

if ! find_xcode; then
  if ! command -v xcodes >/dev/null 2>&1; then
    echo 'Install xcodes first: brew install xcodesorg/made/xcodes' >&2
    exit 1
  fi
  help=$(xcodes install --help)
  if [[ "$help" != *--no-superuser* ]]; then
    echo 'Update xcodes: brew upgrade xcodesorg/made/xcodes' >&2
    exit 1
  fi
  # xcodes handles Apple account authentication. It never receives sudo's password.
  xcodes install 27.0 --directory /Applications --no-superuser --update
  if ! find_xcode; then
    echo 'Installation did not produce Xcode 27.0 under /Applications.' >&2
    exit 1
  fi
fi

export DEVELOPER_DIR="$XCODE_APP/Contents/Developer"
xcodebuild="$DEVELOPER_DIR/usr/bin/xcodebuild"
if [ ! -x "$xcodebuild" ]; then
  echo "Missing xcodebuild in $XCODE_APP" >&2
  exit 1
fi
version=$("$xcodebuild" -version)
if [ "${version%%$'\n'*}" != 'Xcode 27.0' ]; then
  printf 'Unexpected Xcode version:\n%s\n' "$version" >&2
  exit 1
fi
printf 'Setting up %s\n' "$XCODE_APP"
echo 'Apple first-launch setup installs components and accepts the Xcode license.'
echo 'Enter your administrator password only at the sudo prompt below.'
# An absolute executable, no root shell, no -S, no sudo -v, no cached ticket.
/usr/bin/sudo -k "$xcodebuild" -runFirstLaunch

"$xcodebuild" -checkFirstLaunchStatus
printf '\n%s\n' "$version"
echo 'Setup complete. The system-wide Xcode selection is unchanged.'
echo 'In your build terminal, use:'
printf 'export DEVELOPER_DIR=%q\n' "$DEVELOPER_DIR"
''';

String shellQuote(String value) => "'${value.replaceAll("'", "'\\''")}'";

String terminalCommand({required String home, required String user}) {
  // Do not forward PATH, BASH_ENV, shell options, Apple account credentials,
  // or any other environment from the caller/build. No shell startup files.
  final command = [
    '/usr/bin/env',
    '-i',
    'HOME=$home',
    'USER=$user',
    'LOGNAME=$user',
    'PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    'TERM=xterm-256color',
    '/bin/bash',
    '--noprofile',
    '--norc',
    '-c',
    installerScript,
  ];
  // Replace the new terminal's shell so it cannot become a later build shell.
  return 'exec ${command.map(shellQuote).join(' ')}';
}

String terminalAppleScript(String command) {
  final quoted = command
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\r', r'\r')
      .replaceAll('\n', r'\n');
  // No "in window/tab": Terminal creates a new session with its own TTY.
  return 'tell application "Terminal"\n'
      '  activate\n'
      '  do script "$quoted"\n'
      'end tell\n';
}

Future<void> main(List<String> args) async {
  if (args.length == 1 && ['-h', '--help'].contains(args.single)) {
    stdout.writeln('''Usage: dart tool/setup_xcode.dart [--print]
Install/setup Xcode $xcodeVersion in a separate Terminal window using xcodes.
Apple account prompts go to xcodes; the administrator prompt goes to sudo.
Apple first-launch setup accepts the Xcode license. No build is launched.
--print prints the Terminal command for review without executing it.''');
    return;
  }
  if (args.isNotEmpty && !(args.length == 1 && args.single == '--print')) {
    stderr.writeln('Usage: dart tool/setup_xcode.dart [--print]');
    exitCode = 64;
    return;
  }
  final home = Platform.environment['HOME'];
  final user = Platform.environment['USER'];
  if (home == null || !home.startsWith('/') || user == null || user.isEmpty) {
    stderr.writeln('HOME and USER must identify your macOS account.');
    exitCode = 1;
    return;
  }
  final command = terminalCommand(home: home, user: user);
  if (args.isNotEmpty) {
    stdout.writeln(command);
    return;
  }
  if (!Platform.isMacOS) {
    stderr.writeln('Xcode setup requires macOS.');
    exitCode = 1;
    return;
  }
  final uid = await Process.run('/usr/bin/id', [
    '-u',
  ], includeParentEnvironment: false);
  if (uid.exitCode != 0 || uid.stdout.toString().trim() == '0') {
    stderr.writeln('Run this helper as your normal macOS user, without sudo.');
    exitCode = 1;
    return;
  }
  final launch = await Process.run('/usr/bin/osascript', [
    '-e',
    terminalAppleScript(command),
  ], includeParentEnvironment: false);
  if (launch.exitCode != 0) {
    stderr.writeln('Could not open Terminal: ${launch.stderr}');
    exitCode = launch.exitCode;
    return;
  }
  stdout.writeln(
    'Setup launched in a separate Terminal window. Finish the prompts there '
    'and wait for "Setup complete" before building. This launcher does not '
    'receive passwords or report installation success.',
  );
}
