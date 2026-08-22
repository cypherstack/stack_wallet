import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

const manifestHeader = 'stack-artifact-manifest-v1';

Future<String> createArtifactManifest({
  required String rootPath,
  required String outputPath,
}) async {
  final root = path.normalize(path.absolute(rootPath));
  final output = path.normalize(path.absolute(outputPath));
  final rootType = FileSystemEntity.typeSync(root, followLinks: false);
  if (rootType == FileSystemEntityType.notFound) {
    throw ArgumentError.value(rootPath, 'rootPath', 'Artifact does not exist');
  }
  if (rootType == FileSystemEntityType.directory &&
      (path.equals(root, output) || path.isWithin(root, output))) {
    throw ArgumentError.value(
      outputPath,
      'outputPath',
      'Manifest must be outside the artifact',
    );
  }

  final entities = <FileSystemEntity>[];
  if (rootType == FileSystemEntityType.directory) {
    await for (final entity in Directory(
      root,
    ).list(recursive: true, followLinks: false)) {
      entities.add(entity);
    }
  } else {
    entities.add(_entityForType(root, rootType));
  }
  entities.sort(
    (left, right) => _relativePath(
      root,
      rootType,
      left.path,
    ).compareTo(_relativePath(root, rootType, right.path)),
  );

  final lines = <String>[manifestHeader];
  for (final entity in entities) {
    final relative = _relativePath(root, rootType, entity.path);
    final type = FileSystemEntity.typeSync(entity.path, followLinks: false);
    final mode = type == FileSystemEntityType.link
        ? '777'
        : (FileStat.statSync(entity.path).mode & 0x1ff)
              .toRadixString(8)
              .padLeft(3, '0');
    switch (type) {
      case FileSystemEntityType.directory:
        lines.add('d\t$mode\t${jsonEncode(relative)}');
      case FileSystemEntityType.file:
        final digest = await sha256.bind(File(entity.path).openRead()).first;
        lines.add('f\t$mode\t$digest\t${jsonEncode(relative)}');
      case FileSystemEntityType.link:
        final target = await Link(entity.path).target();
        final digest = sha256.convert(utf8.encode(target));
        lines.add(
          'l\t$mode\t$digest\t${jsonEncode(relative)}\t${jsonEncode(target)}',
        );
      default:
        throw FileSystemException('Unsupported artifact entry', entity.path);
    }
  }

  final content = '${lines.join('\n')}\n';
  final digest = sha256.convert(utf8.encode(content)).toString();
  await Directory(path.dirname(output)).create(recursive: true);
  await File(output).writeAsString(content, flush: true);
  await File('$output.sha256').writeAsString('$digest\n', flush: true);
  return digest;
}

Future<bool> compareArtifactManifests(String expected, String actual) async {
  final expectedBytes = await File(expected).readAsBytes();
  final actualBytes = await File(actual).readAsBytes();
  if (expectedBytes.length != actualBytes.length) {
    return false;
  }
  for (var index = 0; index < expectedBytes.length; index++) {
    if (expectedBytes[index] != actualBytes[index]) {
      return false;
    }
  }
  return true;
}

FileSystemEntity _entityForType(String entityPath, FileSystemEntityType type) {
  if (type == FileSystemEntityType.file) {
    return File(entityPath);
  }
  if (type == FileSystemEntityType.link) {
    return Link(entityPath);
  }
  throw FileSystemException('Unsupported artifact', entityPath);
}

String _relativePath(
  String root,
  FileSystemEntityType rootType,
  String entityPath,
) {
  final relative = rootType == FileSystemEntityType.directory
      ? path.relative(entityPath, from: root)
      : path.basename(entityPath);
  return relative.replaceAll('\\', '/');
}
