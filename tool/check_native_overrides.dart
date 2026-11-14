// Plain Dart: inspect dependency checkouts without running any native hooks.
import 'dart:io';

import 'native_dependency_contract.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Usage: dart tool/check_native_overrides.dart <app>');
    exitCode = 64;
    return;
  }
  try {
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
