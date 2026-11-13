// Run directly with Dart before build_app.sh changes any generated files.
import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'native_build_options.dart';
import 'native_dependency_contract.dart';

typedef CommandRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
  Map<String, String> environment,
);

/// Preflight only runs read-only subprocesses and reads directories.
/// Inject these boundaries in tests rather than rewriting executable scripts.
class BuildEnvironment {
  BuildEnvironment({
    required this.os,
    required this.architecture,
    required this.variables,
    required this.run,
    required this.listXcodes,
  });

  final String os;
  final String architecture;
  final Map<String, String> variables;
  final CommandRunner run;
  final Future<List<String>> Function() listXcodes;

  factory BuildEnvironment.current() => BuildEnvironment(
    os: Platform.operatingSystem,
    architecture: switch (Abi.current()) {
      Abi.macosArm64 || Abi.linuxArm64 || Abi.windowsArm64 => 'arm64',
      Abi.macosX64 || Abi.linuxX64 || Abi.windowsX64 => 'x64',
      _ => 'unsupported',
    },
    variables: Platform.environment,
    run: (executable, arguments, environment) => Process.run(
      executable,
      arguments,
      environment: environment,
      includeParentEnvironment: false,
    ),
    listXcodes: () async => [
      await for (final entry in Directory('/Applications').list())
        if (entry.path.split('/').last.startsWith('Xcode') &&
            entry.path.endsWith('.app') &&
            await Directory(entry.path).exists())
          entry.path,
    ],
  );

  Future<ProcessResult?> command(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
  }) async {
    try {
      return await run(executable, arguments, environment ?? variables);
    } on ProcessException {
      return null;
    }
  }
}

const wslNixProbe = r'''
set -eu
if ! command -v nix >/dev/null 2>&1; then
  for profile in "$HOME/.nix-profile/bin" /nix/var/nix/profiles/default/bin /run/current-system/sw/bin; do
    if [ -x "$profile/nix" ]; then
      PATH="$profile:$PATH"
      export PATH
      break
    fi
  done
fi
command -v wslpath >/dev/null 2>&1
if [ "$1" = android ] && [ "$(uname -m)" != x86_64 ]; then
  exit 78
fi
nix --version
''';

/// Only Apple source builds on an Apple Silicon Mac check the pinned Xcode.
bool needsXcodeRequirement(
  BuildEnvironment host, {
  required String platform,
  required String mode,
}) =>
    mode == 'source' &&
    {'ios', 'macos'}.contains(platform) &&
    host.os == 'macos' &&
    host.architecture == 'arm64';

/// Go releases required by the MWEB sources Stack Wallet builds: the go.mod of
/// the mwebd-wrapper commit that flutter_mwebd 0.0.1-pre.12 builds, and the
/// go.mod of mwebd v0.1.19, which tool/build_standalone_mwebd_windows.dart
/// builds for Windows. Update these when either pin changes.
const mwebGoMinimum = (1, 24, 1);
const windowsMwebGoMinimum = (1, 24, 0);

/// Parses `go version` output such as `go version go1.24.13 linux/amd64`.
(int, int, int)? parseGoVersion(String output) {
  final match = RegExp(r'\bgo(\d+)\.(\d+)(?:\.(\d+))?').firstMatch(output);
  if (match == null) return null;
  return (
    int.parse(match[1]!),
    int.parse(match[2]!),
    int.parse(match[3] ?? '0'),
  );
}

bool _olderThan((int, int, int) version, (int, int, int) minimum) {
  final (major, minor, patch) = version;
  final (minMajor, minMinor, minPatch) = minimum;
  if (major != minMajor) return major < minMajor;
  if (minor != minMinor) return minor < minMinor;
  return patch < minPatch;
}

String _goRelease((int, int, int) version) =>
    '${version.$1}.${version.$2}.${version.$3}';

Future<List<String>> checkBuildEnvironment({
  required BuildEnvironment host,
  required String platform,
  required String app,
  required String mode,
  String? wslDistribution,
  XcodeRequirement? xcodeRequirement,
}) async {
  if (!{'android', 'ios', 'macos', 'linux', 'windows'}.contains(platform) ||
      !{'stack_wallet', 'stack_duo', 'campfire'}.contains(app) ||
      !{'source', 'prebuilt'}.contains(mode)) {
    throw ArgumentError('Invalid platform, app or dnix build mode.');
  }
  final distribution = validatedDistribution(wslDistribution);
  if (needsXcodeRequirement(host, platform: platform, mode: mode) &&
      xcodeRequirement == null) {
    throw ArgumentError(
      'Apple source builds need the native Xcode requirement.',
    );
  }
  if (platform == 'windows' && host.os != 'windows') {
    return ['Configure Windows builds from Git Bash on Windows.'];
  }
  if ({'ios', 'macos'}.contains(platform) && host.os != 'macos') {
    return ['Apple targets require a macOS build host.'];
  }
  final errors = <String>[];
  var hasRustup = false;
  final home = host.variables[host.os == 'windows' ? 'USERPROFILE' : 'HOME'];
  final separator = host.os == 'windows' ? r'\' : '/';
  for (final executable in [
    'rustup',
    if (home != null) '$home$separator.cargo${separator}bin${separator}rustup',
  ]) {
    if ((await host.command(executable, ['--version']))?.exitCode == 0) {
      hasRustup = true;
      break;
    }
  }
  if (!hasRustup) {
    final xelis = app == 'stack_wallet'
        ? ' Stack Wallet also needs Rust 1.99.1 for Xelis.'
        : '';
    errors.add(
      'Install Rustup on the Flutter host (https://rustup.rs/). '
      'Every app needs Rust 1.90.0 for DNSSEC, including with -d.$xelis '
      'The hooks install their pinned toolchains automatically.',
    );
  }
  // flutter_mwebd's hook builds Stack Wallet's MWEB library with the host's Go
  // for every target except Windows, whose MWEB executable is checked next.
  if (app == 'stack_wallet' && platform != 'windows') {
    final result = await host.command('go', ['version']);
    final version = result?.exitCode == 0
        ? parseGoVersion('${result!.stdout}')
        : null;
    if (result?.exitCode != 0 ||
        (version != null && _olderThan(version, mwebGoMinimum))) {
      errors.add(
        'Install Go ${_goRelease(mwebGoMinimum)} or newer on the Flutter host '
        '(https://go.dev/doc/install). Stack Wallet builds its MWEB library '
        'with Go, including with -d.'
        '${version == null ? '' : ' Found Go ${_goRelease(version)}.'}',
      );
    }
  }
  // Stack Wallet's Windows configuration builds mwebd.exe with Go and MinGW in
  // the default WSL distribution (tool/build_standalone_mwebd_windows.dart),
  // unless MWEBD_FETCH=1 downloads it or CI builds it natively.
  if (app == 'stack_wallet' &&
      platform == 'windows' &&
      host.variables['MWEBD_FETCH'] != '1' &&
      host.variables['CI'] != 'true') {
    final result = await host.command(
      'wsl.exe',
      [
        '--cd',
        '/',
        '--exec',
        'bash',
        '-l',
        '-c',
        'command -v x86_64-w64-mingw32-gcc >/dev/null && go version',
      ],
      environment: {...host.variables, 'WSL_UTF8': '1'},
    );
    final version = result?.exitCode == 0
        ? parseGoVersion('${result!.stdout}')
        : null;
    if (result?.exitCode != 0 ||
        (version != null && _olderThan(version, windowsMwebGoMinimum))) {
      errors.add(
        "Stack Wallet's Windows MWEB build needs Go "
        '${_goRelease(windowsMwebGoMinimum)} or newer and '
        'x86_64-w64-mingw32-gcc in the default WSL distribution. Install Go '
        'and mingw-w64 there, or set MWEBD_FETCH=1 to download the published '
        'build.${version == null ? '' : ' Found Go ${_goRelease(version)}.'}',
      );
    }
  }
  if (mode == 'prebuilt') return errors;

  // Windows hooks run Nix in the default or requested WSL distribution.
  if (host.os == 'windows') {
    final result = await host.command(
      'wsl.exe',
      [
        if (distribution != null) ...['--distribution', distribution],
        '--cd',
        '/',
        '--exec',
        '/bin/sh',
        '-c',
        wslNixProbe,
        'stack-wallet-preflight',
        platform,
      ],
      environment: {...host.variables, 'WSL_UTF8': '1'},
    );
    if (result?.exitCode == 78) {
      errors.add(
        'dnix Android source builds need an x86_64 WSL distribution. '
        'Use build_app.sh -d for verified prebuilts on this host.',
      );
    } else if (result?.exitCode != 0) {
      final where = distribution == null
          ? 'the default distribution'
          : 'distribution "$distribution"';
      errors.add(
        'Source mode needs WSL2 with Nix in $where. '
        'Check wsl.exe --list --verbose and install Nix there, or rerun '
        'build_app.sh with -d for verified dnix prebuilts.',
      );
    }
  } else if (host.os == 'macos' || host.os == 'linux') {
    if (host.os == 'macos' && host.architecture != 'arm64') {
      errors.add(
        'dnix source builds require an Apple Silicon Mac. '
        'Rerun build_app.sh with -d for verified prebuilts.',
      );
    }
    if ((await host.command('nix', ['--version']))?.exitCode != 0) {
      errors.add(
        'Source mode needs Nix on PATH (https://nixos.org/download/). '
        'Install Nix or rerun build_app.sh with -d '
        'for verified dnix prebuilts.',
      );
    }
    if (host.os == 'linux' &&
        platform == 'android' &&
        host.architecture != 'x64') {
      errors.add(
        'dnix Android source builds require an x86_64 Linux host. '
        'Use build_app.sh -d for verified prebuilts on this host.',
      );
    }
  } else {
    errors.add(
      'dnix source builds need Linux, Apple Silicon macOS or Windows '
      'with WSL2. Use build_app.sh -d for verified prebuilts.',
    );
  }

  if (platform == 'ios' || platform == 'macos') {
    if (host.architecture == 'arm64') {
      final requirement = xcodeRequirement!;
      final selected = await selectedDnixXcode(
        host,
        version: requirement.version,
        pinnedBuild: requirement.upstreamBuildPinned ? requirement.build : null,
      );
      if (selected == null) {
        errors.add(
          'Source mode needs Xcode ${requirement.version} '
          '(${requirement.build}) under '
          '/Applications. Run dart tool/setup_xcode.dart, or use '
          'build_app.sh -d for verified dnix prebuilts.',
        );
      } else if (selected.build != requirement.build) {
        errors.add(
          'dnix would select Xcode ${requirement.version} (${selected.build}) '
          'at ${selected.directory}, rather than release ${requirement.build}. '
          'DEVELOPER_DIR is not forwarded to native hooks. Use -d for verified '
          'prebuilts, or keep the conflicting beta outside '
          '/Applications/Xcode*.app and make sure the system Xcode selection '
          'does not point to it. See docs/building.md; this check changes '
          'no Xcode selections.',
        );
      }
    }
  }
  return errors;
}

/// Match dnix's actual lookup: global selection first, then the shell glob.
/// Flutter's hooks runner does not forward the caller's DEVELOPER_DIR.
Future<({String directory, String build})?> selectedDnixXcode(
  BuildEnvironment host, {
  required String version,
  String? pinnedBuild,
}) async {
  final environment = Map<String, String>.of(host.variables)
    ..remove('DEVELOPER_DIR');
  final selected = await host.command('/usr/bin/xcode-select', [
    '-p',
  ], environment: environment);
  final candidates = <String>[
    if (selected?.exitCode == 0 && '${selected!.stdout}'.trim().isNotEmpty)
      '${selected.stdout}'.trim(),
  ];
  try {
    final applications = await host.listXcodes()
      ..sort();
    candidates.addAll(applications.map((app) => '$app/Contents/Developer'));
  } on FileSystemException {
    // The error below identifies the missing usable Xcode.
  }
  for (final candidate in candidates.toSet()) {
    final result = await host.command(
      '/usr/bin/xcodebuild',
      ['-version'],
      environment: {...environment, 'DEVELOPER_DIR': candidate},
    );
    if (result?.exitCode != 0) continue;
    final lines = '${result!.stdout}'.trim().split(RegExp(r'\r?\n'));
    if (lines.isEmpty || lines.first.trim() != 'Xcode $version') continue;
    final build = lines.length > 1
        ? lines[1].trim().replaceFirst('Build version ', '')
        : 'unknown';
    if (pinnedBuild != null && build != pinnedBuild) continue;
    return (directory: candidate, build: build);
  }
  return null;
}

Future<void> main(List<String> args) async {
  if (args.length < 3 || args.length > 4) {
    stderr.writeln(
      'Usage: dart tool/check_build_environment.dart '
      '<platform> <app> <source|prebuilt> [wslDistribution]',
    );
    exitCode = 64;
    return;
  }
  try {
    final host = BuildEnvironment.current();
    XcodeRequirement? requirement;
    if (needsXcodeRequirement(host, platform: args[0], mode: args[2])) {
      try {
        requirement = await loadXcodeRequirement(
          File.fromUri(Platform.script).parent.parent,
          app: args[1],
        );
      } catch (error) {
        stderr.writeln('Cannot determine the required Xcode: $error');
        stderr.writeln(
          error is SocketException ||
                  error is HttpException ||
                  error is TlsException ||
                  error is TimeoutException
              ? 'Check your network connection and retry.'
              : 'See docs/building.md for dependency setup instructions.',
        );
        exitCode = 1;
        return;
      }
    }
    final errors = await checkBuildEnvironment(
      host: host,
      platform: args[0],
      app: args[1],
      mode: args[2],
      wslDistribution: args.length == 4 ? args[3] : null,
      xcodeRequirement: requirement,
    );
    if (errors.isNotEmpty) {
      for (final error in errors) {
        stderr.writeln('Build prerequisite: $error');
      }
      stderr.writeln('See docs/building.md for setup instructions.');
      exitCode = 1;
    }
  } on ArgumentError catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
  }
}
