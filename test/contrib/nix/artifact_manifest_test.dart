import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import '../../../contrib/nix/artifact_manifest_lib.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() {
    temporaryDirectory = Directory.systemTemp.createTempSync(
      'stack-artifact-manifest-test.',
    );
  });

  tearDown(() {
    temporaryDirectory.deleteSync(recursive: true);
  });

  group('createArtifactManifest', () {
    test('is stable across creation order and timestamps', () async {
      final first = Directory(path.join(temporaryDirectory.path, 'first'))
        ..createSync();
      final second = Directory(path.join(temporaryDirectory.path, 'second'))
        ..createSync();
      File(path.join(first.path, 'b')).writeAsStringSync('bravo');
      File(path.join(first.path, 'a')).writeAsStringSync('alpha');
      File(path.join(second.path, 'a')).writeAsStringSync('alpha');
      File(path.join(second.path, 'b')).writeAsStringSync('bravo');
      File(path.join(second.path, 'a')).setLastModifiedSync(DateTime.utc(2040));

      final firstManifest = path.join(temporaryDirectory.path, 'first.txt');
      final secondManifest = path.join(temporaryDirectory.path, 'second.txt');
      final firstDigest = await createArtifactManifest(
        rootPath: first.path,
        outputPath: firstManifest,
      );
      final secondDigest = await createArtifactManifest(
        rootPath: second.path,
        outputPath: secondManifest,
      );

      expect(secondDigest, firstDigest);
      expect(
        await compareArtifactManifests(firstManifest, secondManifest),
        isTrue,
      );
    });

    test('detects content changes', () async {
      final artifact = File(path.join(temporaryDirectory.path, 'artifact'))
        ..writeAsStringSync('first');
      final firstManifest = path.join(temporaryDirectory.path, 'first.txt');
      final secondManifest = path.join(temporaryDirectory.path, 'second.txt');
      await createArtifactManifest(
        rootPath: artifact.path,
        outputPath: firstManifest,
      );
      artifact.writeAsStringSync('second');
      await createArtifactManifest(
        rootPath: artifact.path,
        outputPath: secondManifest,
      );

      expect(
        await compareArtifactManifests(firstManifest, secondManifest),
        isFalse,
      );
    });

    test('records symlink targets without following them', () async {
      if (Platform.isWindows) {
        return;
      }
      final artifact = Directory(path.join(temporaryDirectory.path, 'artifact'))
        ..createSync();
      Link(path.join(artifact.path, 'link')).createSync('../target');
      final manifest = path.join(temporaryDirectory.path, 'manifest.txt');

      await createArtifactManifest(
        rootPath: artifact.path,
        outputPath: manifest,
      );

      final content = File(manifest).readAsStringSync();
      expect(content, contains('l\t777\t'));
      expect(content, contains('"../target"'));
    });

    test('rejects a manifest inside the artifact', () async {
      final artifact = Directory(path.join(temporaryDirectory.path, 'artifact'))
        ..createSync();

      expect(
        () => createArtifactManifest(
          rootPath: artifact.path,
          outputPath: path.join(artifact.path, 'manifest.txt'),
        ),
        throwsArgumentError,
      );
    });
  });
}
