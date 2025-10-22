import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
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
      return SafStream().writeFileBytes(
        dirPath,
        fileName,
        "txt",
        utf8.encode(content),
      );
    } else {
      return File(join(dirPath, fileName)).writeAsString(content, flush: true);
    }
  }
}
