// Plain Dart so configuration does not require pub get or run native hooks.
import 'dart:convert';
import 'dart:io';

String configureNativeAssets(
  String template,
  String mode,
  String? distribution,
) {
  if (!['source', 'prebuilt'].contains(mode)) {
    throw ArgumentError.value(mode, 'mode', 'Expected source or prebuilt');
  }
  final selectedDistribution = distribution?.trim();
  if (distribution != null &&
      (selectedDistribution!.isEmpty ||
          selectedDistribution.startsWith('-') ||
          distribution.contains(RegExp(r'[\x00-\x1f\x7f]')))) {
    throw ArgumentError.value(distribution, 'distribution', 'Invalid WSL name');
  }
  return template
      .split('\n')
      .where(
        (line) =>
            selectedDistribution != null ||
            !line.contains('PLACEHOLDER_DNIX_WSL_DISTRIBUTION'),
      )
      .map(
        (line) => line
            .replaceAll('PLACEHOLDER_DNIX_BUILD_MODE', mode)
            .replaceAll(
              'PLACEHOLDER_DNIX_WSL_DISTRIBUTION',
              jsonEncode(selectedDistribution),
            ),
      )
      .join('\n');
}

void main(List<String> args) {
  if (args.length < 2 || args.length > 3) {
    stderr.writeln(
      'Usage: dart tool/configure_native_assets.dart <pubspec> '
      '<source|prebuilt> [wsl-distribution]',
    );
    exitCode = 64;
    return;
  }
  final file = File(args[0]);
  file.writeAsStringSync(
    configureNativeAssets(
      file.readAsStringSync(),
      args[1],
      args.length == 3 ? args[2] : null,
    ),
  );
}
