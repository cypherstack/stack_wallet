import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_util/saf_util.dart';

abstract final class FS {
  static Future<String?> pickDirectory({String? initialDirectory}) async {
    final String? path;
    if (Platform.isAndroid) {
      final dir = await SafUtil().pickDirectory(
        writePermission: true,
        persistablePermission: true,
        initialUri: initialDirectory,
      );

      path = dir?.uri;
    } else {
      path = await FilePicker.platform.getDirectoryPath(
        lockParentWindow: true,
        initialDirectory: initialDirectory,
      );
    }

    return path;
  }

  static Future<void> writeStringToFile(
    String content,
    String dirPath,
    String fileName,
  ) {
    if (Platform.isAndroid && dirPath.startsWith("content://")) {
      final token = ServicesBinding.rootIsolateToken!;
      return compute(_androidSafWriteComputeWrapper, (
        dirPath: dirPath,
        fileName: fileName,
        content: content,
        isoToken: token,
      ));
    } else {
      return File(join(dirPath, fileName)).writeAsString(content, flush: true);
    }
  }
}

Future<void> _androidSafWriteComputeWrapper(
  ({String dirPath, String fileName, String content, RootIsolateToken isoToken})
  args,
) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(args.isoToken);
  final bytes = utf8.encode(args.content);
  await SafStream().writeFileBytes(args.dirPath, args.fileName, "txt", bytes);
}
