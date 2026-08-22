import 'dart:io';

import 'artifact_manifest_lib.dart';

Future<void> main(List<String> arguments) async {
  try {
    switch (arguments) {
      case ['create', final root, final output]:
        final digest = await createArtifactManifest(
          rootPath: root,
          outputPath: output,
        );
        stdout.writeln(digest);
      case ['compare', final expected, final actual]:
        if (!await compareArtifactManifests(expected, actual)) {
          stderr.writeln('Artifact manifests differ.');
          exitCode = 1;
        }
      default:
        stderr.writeln(
          'Usage: dart run contrib/nix/artifact_manifest.dart '
          '<create ROOT OUTPUT | compare EXPECTED ACTUAL>',
        );
        exitCode = 64;
    }
  } on Object catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}
