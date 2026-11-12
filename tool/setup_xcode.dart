// Run directly with `dart tool/setup_xcode.dart`; no pub get/build hooks needed.
import 'dart:io';

import 'native_dependency_contract.dart';

// Explicit native tools let tests substitute fixtures without rewriting source
// or risking a real sudo invocation. The CLI always uses these system defaults.
class SetupTools {
  const SetupTools({
    this.applications = '/Applications',
    this.id = '/usr/bin/id',
    this.uname = '/usr/bin/uname',
    this.plistBuddy = '/usr/libexec/PlistBuddy',
    this.sudo = '/usr/bin/sudo',
  });
  final String applications;
  final String id;
  final String uname;
  final String plistBuddy;
  final String sudo;
}

String shellQuote(String value) => "'${value.replaceAll("'", "'\\''")}'";

String installerScript({
  required String home,
  required String user,
  required String version,
  required String build,
  String? xcodes,
  SetupTools tools = const SetupTools(),
  bool interactive = true,
  String? cleanupDirectory,
}) {
  final xcodesDirectory = xcodes == null ? null : File(xcodes).parent.path;
  final installerPath = [
    if (xcodesDirectory != null) xcodesDirectory,
    '/opt/homebrew/bin',
    '/usr/local/bin',
    '/usr/bin',
    '/bin',
    '/usr/sbin',
    '/sbin',
  ].join(':');
  return '''#!/bin/bash
set -euo pipefail
umask 077
export HOME=${shellQuote(home)} USER=${shellQuote(user)} LOGNAME=${shellQuote(user)}
export PATH=${shellQuote(installerPath)} TERM=xterm-256color
XCODE_VERSION=${shellQuote(version)}
XCODE_BUILD=${shellQuote(build)}
APPLICATIONS=${shellQuote(tools.applications)}
ID=${shellQuote(tools.id)}
UNAME=${shellQuote(tools.uname)}
PLIST_BUDDY=${shellQuote(tools.plistBuddy)}
SUDO=${shellQuote(tools.sudo)}
XCODES=${shellQuote(xcodes ?? '')}
INTERACTIVE=${interactive ? 1 : 0}
CLEANUP_DIRECTORY=${shellQuote(cleanupDirectory ?? '')}
'''
      r'''
finish() {
  local status=$?
  trap - EXIT
  if [ "$status" -ne 0 ]; then
    printf '\nXcode setup failed (exit %s). Review the error above.\n' "$status" >&2
  fi
  if [ "$INTERACTIVE" = 1 ] && [ -t 0 ]; then
    # Keep results visible even with Terminal's close-on-exit profiles.
    printf '\nPress Return to close this setup session. '
    IFS= read -r acknowledgement || true
  fi
  if [ -n "$CLEANUP_DIRECTORY" ]; then
    /bin/rm -f "$CLEANUP_DIRECTORY/setup.sh"
    /bin/rmdir "$CLEANUP_DIRECTORY" 2>/dev/null || true
  fi
  exit "$status"
}
trap finish EXIT
cd "$HOME"
if [ "$("$ID" -u)" = 0 ]; then
  echo 'Run this helper as your normal macOS user, without sudo.' >&2
  exit 1
fi
if [ "$("$UNAME" -m)" != arm64 ]; then
  echo 'This setup helper requires an Apple Silicon Mac.' >&2
  exit 1
fi
if [ "$INTERACTIVE" = 1 ] && [ ! -t 0 ]; then
  echo 'Run this setup in its own interactive Terminal window.' >&2
  exit 1
fi

find_xcode() {
  local candidate version build
  CONFLICTING_XCODES=()
  for candidate in "$APPLICATIONS"/Xcode*.app; do
    [ -f "$candidate/Contents/Info.plist" ] || continue
    version=$("$PLIST_BUDDY" -c 'Print :CFBundleShortVersionString' \
      "$candidate/Contents/Info.plist" 2>/dev/null) || continue
    [ "$version" = "$XCODE_VERSION" ] || continue
    build=$("$PLIST_BUDDY" -c 'Print :ProductBuildVersion' \
      "$candidate/Contents/version.plist" 2>/dev/null) || build=unknown
    if [ "$build" = "$XCODE_BUILD" ]; then
      XCODE_APP="$candidate"
      return 0
    fi
    CONFLICTING_XCODES+=("$candidate ($build)")
  done
  return 1
}

if ! find_xcode; then
  if [ "${#CONFLICTING_XCODES[@]}" -gt 0 ]; then
    printf 'These Xcode %s installations have a different build:\n' "$XCODE_VERSION" >&2
    printf '  %s\n' "${CONFLICTING_XCODES[@]}" >&2
    echo 'xcodes may refuse to install another build of the same version.' >&2
    printf 'Download Xcode %s (%s) from https://developer.apple.com/download/all/?q=Xcode\n' \
      "$XCODE_VERSION" "$XCODE_BUILD" >&2
    echo 'Expand the archive in Finder, then rename the extracted app to' >&2
    printf 'Xcode-%s-%s.app before moving it into %s.\n' \
      "$XCODE_VERSION" "$XCODE_BUILD" "$APPLICATIONS" >&2
    echo 'Rerun this helper afterward. Existing Xcodes have been left untouched.' >&2
    exit 1
  fi
  if [ -z "$XCODES" ] || [ ! -x "$XCODES" ]; then
    echo 'xcodes was not found on your PATH when setup was launched.' >&2
    echo 'Install it or add it to PATH, then rerun this helper.' >&2
    echo 'Homebrew option: brew install xcodes' >&2
    exit 1
  fi
  if ! help=$("$XCODES" install --help); then
    echo 'xcodes could not run from HOME with a clean setup environment.' >&2
    echo 'Use a globally configured xcodes or put its direct executable on PATH.' >&2
    exit 1
  fi
  if [[ "$help" != *--no-superuser* ]]; then
    echo 'Update xcodes: this helper requires --no-superuser support.' >&2
    exit 1
  fi
  # xcodes handles Apple account authentication, never sudo's password.
  "$XCODES" install "$XCODE_VERSION" --directory "$APPLICATIONS" --no-superuser --update
  if ! find_xcode; then
    printf 'Installation did not produce Xcode %s (%s) under %s.\n' \
      "$XCODE_VERSION" "$XCODE_BUILD" "$APPLICATIONS" >&2
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
if [ "$version" != "$(printf 'Xcode %s\nBuild version %s' "$XCODE_VERSION" "$XCODE_BUILD")" ]; then
  printf 'Unexpected Xcode version:\n%s\n' "$version" >&2
  exit 1
fi
printf 'Setting up %s\n' "$XCODE_APP"
echo 'Apple first-launch setup installs components and accepts the Xcode license.'
echo 'Enter your administrator password only at the sudo prompt below.'
# -k WITH a command bypasses and does not update sudo's credential cache.
# Absolute executable, no root shell, no -S, no sudo -v, no cached ticket.
"$SUDO" -k "$xcodebuild" -runFirstLaunch

"$xcodebuild" -checkFirstLaunchStatus
printf '\n%s\n' "$version"
echo 'Setup complete. The system-wide Xcode selection is unchanged.'
echo 'For Flutter and Xcode commands in a bash/zsh build terminal, use:'
printf 'export DEVELOPER_DIR=%q\n' "$DEVELOPER_DIR"
echo 'Dart native hooks do not inherit this variable; dnix discovers Xcode separately.'
''';
}

String? findXcodes(String? searchPath) {
  for (final directory in (searchPath ?? '').split(':')) {
    // Do not execute a repo-local program via a relative/empty PATH entry.
    if (!directory.startsWith('/')) continue;
    final candidate = File('$directory/xcodes');
    try {
      final stat = candidate.statSync();
      if (stat.type == FileSystemEntityType.file && stat.mode & 0x49 != 0) {
        // Keep the name used to invoke it: mise/asdf-style shims can dispatch
        // through argv[0], and their own directory must remain on PATH.
        return candidate.path;
      }
    } on FileSystemException {
      // Keep searching if an earlier PATH entry is inaccessible.
    }
  }
  return null;
}

String terminalCommand(String scriptPath) {
  // This is typed into the user's login shell, possibly tcsh. Send only a
  // short, whitespace-free command; the multiline installer stays in a file.
  if (!RegExp(r'^/tmp/stack-xcode-setup-[a-zA-Z0-9]+/setup\.sh$')
      .hasMatch(scriptPath)) {
    throw ArgumentError.value(
      scriptPath,
      'scriptPath',
      'Unexpected setup path',
    );
  }
  return 'exec /usr/bin/env -i /bin/bash --noprofile --norc $scriptPath';
}

String terminalAppleScript(String command) {
  if (!RegExp(r'^[a-zA-Z0-9 /_.-]+$').hasMatch(command)) {
    throw ArgumentError.value(
      command,
      'command',
      'Unexpected Terminal command',
    );
  }
  // launch sends no run event (and hence no default startup window). Create
  // the dedicated setup window before bringing Terminal to the foreground.
  return 'tell application "Terminal"\n'
      '  launch\n'
      '  do script "$command"\n'
      '  activate\n'
      'end tell\n';
}

Future<void> main(List<String> args) async {
  if (args.length == 1 && ['-h', '--help'].contains(args.single)) {
    stdout.writeln('''Usage: dart tool/setup_xcode.dart [--print]
Install/setup the Xcode required by the pinned native dependencies.
Finds xcodes on your current PATH before cleaning the installer environment.
Apple account prompts go to xcodes; the administrator prompt goes to sudo.
Apple first-launch setup accepts the Xcode license. No build is launched.
--print prints the installer script for review without executing it.''');
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
  final printOnly = args.isNotEmpty;
  if (!printOnly && !Platform.isMacOS) {
    stderr.writeln('Xcode setup requires macOS.');
    exitCode = 1;
    return;
  }
  if (!printOnly) {
    final uid = await Process.run('/usr/bin/id', [
      '-u',
    ], includeParentEnvironment: false);
    if (uid.exitCode != 0 || uid.stdout.toString().trim() == '0') {
      stderr.writeln(
        'Run this helper as your normal macOS user, without sudo.',
      );
      exitCode = 1;
      return;
    }
  }
  final XcodeRequirement requirement;
  try {
    requirement = await loadXcodeRequirement(
      File.fromUri(Platform.script).parent.parent,
    );
  } catch (error) {
    stderr.writeln('Cannot determine the required Xcode: $error');
    exitCode = 1;
    return;
  }
  final xcodes = findXcodes(Platform.environment['PATH']);
  if (printOnly) {
    stdout.writeln(
      installerScript(
        home: home,
        user: user,
        version: requirement.version,
        build: requirement.build,
        xcodes: xcodes,
      ),
    );
    return;
  }
  if (!requirement.upstreamBuildPinned) {
    stdout.writeln(
      'The native packages pin Xcode ${requirement.version} without a build '
      'number. Using the recorded compatible release ${requirement.build} '
      'for these exact dependency revisions.',
    );
  }
  // Fixed safe pathname for every supported login shell. mkdtemp creates the
  // directory with mode 0700; the script contains no credentials or build env.
  Directory? directory;
  var launched = false;
  try {
    directory = Directory('/tmp').createTempSync('stack-xcode-setup-');
    final script = File('${directory.path}/setup.sh');
    script.writeAsStringSync(
      installerScript(
        home: home,
        user: user,
        version: requirement.version,
        build: requirement.build,
        xcodes: xcodes,
        cleanupDirectory: directory.path,
      ),
    );
    final launch = await Process.run('/usr/bin/osascript', [
      '-e',
      terminalAppleScript(terminalCommand(script.path)),
    ], includeParentEnvironment: false);
    if (launch.exitCode != 0) {
      stderr.writeln('Could not open Terminal: ${launch.stderr}');
      exitCode = launch.exitCode;
      return;
    }
    launched = true;
  } on FileSystemException catch (error) {
    stderr.writeln('Could not prepare Xcode setup: ${error.message}');
    exitCode = 1;
    return;
  } on ProcessException catch (error) {
    stderr.writeln('Could not open Terminal: ${error.message}');
    exitCode = 1;
    return;
  } finally {
    // Once Terminal accepts the launch, the installer owns its temporary files.
    if (!launched && directory != null && directory.existsSync()) {
      try {
        directory.deleteSync(recursive: true);
      } on FileSystemException {
        stderr.writeln('Remove the unused setup directory: ${directory.path}');
      }
    }
  }
  stdout.writeln(
    'Setup launched in a separate Terminal window. Finish the prompts there '
    'and wait for "Setup complete" before building. Press Return there after '
    'copying the instructions. This launcher does not receive passwords or '
    'report installation success.',
  );
}
