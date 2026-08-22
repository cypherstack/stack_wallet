import 'dart:io';

import 'package:nix/src/command_runner.dart';

Future<void> main(List<String> arguments) async {
  try {
    exitCode = await NixCommandRunner().run(arguments) ?? 0;
  } on Exception catch (error) {
    stderr.writeln('Error: $error');
    exitCode = 1;
  }
}
