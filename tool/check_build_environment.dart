// Run directly with Dart before build_app.sh changes any generated files.
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
  final appleSource = mode == 'source' && {'ios', 'macos'}.contains(platform);
  if (appleSource && xcodeRequirement == null) {
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
    XcodeRequirement? requirement;
    if (args[2] == 'source' && {'ios', 'macos'}.contains(args[0])) {
      try {
        requirement = await loadXcodeRequirement(
          File.fromUri(Platform.script).parent.parent,
          app: args[1],
        );
      } catch (error) {
        stderr.writeln('Cannot determine the required Xcode: $error');
        stderr.writeln(
          'See docs/building.md for dependency setup instructions.',
        );
        exitCode = 1;
        return;
      }
    }
    final errors = await checkBuildEnvironment(
      host: BuildEnvironment.current(),
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
