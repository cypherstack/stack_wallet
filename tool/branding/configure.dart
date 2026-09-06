// Dependency-free entry point: use `dart tool/branding/configure.dart`, even before the
// application's pubspec has been generated. The tool has its own SDK and lockfile.
import 'dart:io';

Future<void> main(List<String> arguments) async {
  final adapter = Directory.fromUri(Platform.script.resolve('./'));
  try {
    final get = await Process.run(Platform.resolvedExecutable, [
      'pub',
      'get',
      '--enforce-lockfile',
    ], workingDirectory: adapter.path);
    // Keep stdout available for the configure command's machine-readable plan.
    stderr.write(get.stdout);
    stderr.write(get.stderr);
    if (get.exitCode != 0) {
      exitCode = get.exitCode;
      return;
    }
    final process = await Process.start(Platform.resolvedExecutable, [
      '--packages=${adapter.path}${Platform.pathSeparator}.dart_tool${Platform.pathSeparator}package_config.json',
      File.fromUri(adapter.uri.resolve('bin/configure.dart')).path,
      ...arguments,
    ], mode: ProcessStartMode.inheritStdio);
    exitCode = await process.exitCode;
  } catch (error) {
    stderr.writeln('Could not launch the branding tool: $error');
    exitCode = 1;
  }
}
