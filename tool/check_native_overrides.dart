// Plain Dart: inspect dependency checkouts without running any native hooks.
import 'dart:convert';
import 'dart:io';

import 'native_dependency_contract.dart';

typedef OverrideCommandRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
);

Future<ProcessResult> _run(String executable, List<String> arguments) =>
    Process.run(executable, arguments);

String windowsOverrideCommand(String script, String app) {
  String literal(String value) => "'${value.replaceAll("'", "''")}'";
  // Flutter normally exposes dart.bat. Invoke its SDK executable directly so
  // cmd.exe cannot expand percent signs in script paths or arguments.
  return r"$ErrorActionPreference = 'Stop'; "
      r'[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false); '
      r'$sdk = Get-Command dart.exe -CommandType Application '
      r'-ErrorAction SilentlyContinue | Select-Object -First 1; '
      r'if ($null -ne $sdk) { $dart = $sdk.Source } else { '
      r'$launcher = Get-Command dart -CommandType Application '
      r'-ErrorAction Stop; '
      r'$dart = Join-Path '
      r'([System.IO.Path]::GetDirectoryName($launcher.Source)) '
      r"'cache\dart-sdk\bin\dart.exe'; "
      r'if (!(Test-Path -LiteralPath $dart -PathType Leaf)) { '
      r"throw 'Put native Windows Flutter or a Dart SDK on the Windows PATH, "
      r"or configure from Git Bash.' } }; "
      '& \$dart ${literal(script)} ${literal(app)} windows; '
      r'exit $LASTEXITCODE';
}

String encodePowerShell(String command) => base64Encode([
  for (final unit in command.codeUnits) ...[unit & 0xff, unit >> 8],
]);

Future<ProcessResult> checkWindowsOverridesFromWsl({
  required String script,
  required String app,
  OverrideCommandRunner run = _run,
}) async {
  try {
    final converted = await run('wslpath', ['-w', script]);
    if (converted.exitCode != 0 || converted.stdout.toString().trim().isEmpty) {
      throw StateError('wslpath could not translate the override guard path.');
    }
    return await run('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-EncodedCommand',
      encodePowerShell(
        windowsOverrideCommand(converted.stdout.toString().trim(), app),
      ),
    ]);
  } on ProcessException catch (error) {
    throw StateError(
      'Could not check the native Windows dependency cache from WSL: $error. '
      'Enable WSL interoperability and put Windows Flutter on the Windows '
      'PATH, or configure from Git Bash.',
    );
  }
}

Future<void> main(List<String> args) async {
  if (args.isEmpty ||
      args.length > 2 ||
      (args.length == 2 &&
          !{'android', 'ios', 'macos', 'linux', 'windows'}.contains(args[1]))) {
    stderr.writeln(
      'Usage: dart tool/check_native_overrides.dart <app> [targetPlatform]',
    );
    exitCode = 64;
    return;
  }
  try {
    enabledDnixPackages(args.first); // Validate before dispatching to Windows.
    if (args.length == 2 &&
        args[1] == 'windows' &&
        Platform.isLinux &&
        (Platform.environment['WSL_DISTRO_NAME']?.isNotEmpty ?? false)) {
      final result = await checkWindowsOverridesFromWsl(
        script: File.fromUri(Platform.script).absolute.path,
        app: args.first,
      );
      stdout.write(result.stdout);
      stderr.write(result.stderr);
      if (result.exitCode != 0) {
        stderr.writeln(
          'Windows override check failed. Fix the reported issue or '
          'configure from native Windows Git Bash.',
        );
      }
      exitCode = result.exitCode;
      return;
    }
    final project = File.fromUri(Platform.script).parent.parent;
    final overrides = nativeBuildOverrides(project, args.first);
    if (overrides.isNotEmpty) {
      stderr.writeln(
        'Package-local overrides take precedence over both source '
        'and -d, and dev mode skips hash verification. Remove these files, '
        'run flutter clean, then reconfigure:',
      );
      for (final file in overrides) {
        stderr.writeln('  $file');
      }
      exitCode = 1;
    }
  } catch (error) {
    stderr.writeln('Unable to check native build overrides: $error');
    exitCode = 1;
  }
}
