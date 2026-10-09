import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.length != 1 || !File('pubspec.yaml').existsSync()) {
    throw ArgumentError(
      'Run from the configured app root with the package workspace path.',
    );
  }
  final workspace = Directory(args.single).absolute;
  const packages = ['doh_resolver', 'dnssec_resolver', 'openalias'];
  for (final package in packages) {
    if (!File('${workspace.path}/$package/pubspec.yaml').existsSync()) {
      throw ArgumentError('Missing package $package in ${workspace.path}');
    }
  }

  // Pub replaces the whole override map; retain the app's overrides.
  final lines = File('pubspec.yaml').readAsLinesSync();
  final start = lines.indexOf('dependency_overrides:');
  if (start < 0) {
    throw StateError('Expected generated app dependency overrides');
  }
  final overrides = <String>[];
  var skippingReplacedPackage = false;
  final overrideKey = RegExp(r'^  ([A-Za-z0-9_]+):(?:\s.*)?$');
  for (final line in lines.skip(start + 1)) {
    if (line.isNotEmpty && !line.startsWith(' ') && !line.startsWith('#')) {
      break;
    }
    if (skippingReplacedPackage) {
      final indentation = line.length - line.trimLeft().length;
      if (line.trim().isNotEmpty && indentation > 2) {
        continue;
      }
      skippingReplacedPackage = false;
    }
    final match = overrideKey.firstMatch(line);
    if (match != null && packages.contains(match.group(1))) {
      skippingReplacedPackage = true;
      continue;
    }
    overrides.add(line);
  }
  final localOverrides = packages.map((package) {
    final path = jsonEncode('${workspace.path}/$package');
    return '  $package:\n    path: $path\n';
  }).join();
  File('pubspec_overrides.yaml').writeAsStringSync(
    'dependency_overrides:\n${overrides.join('\n')}\n'
    '$localOverrides',
  );
  stdout.writeln('Wrote local package overrides; run flutter pub get next.');
}
