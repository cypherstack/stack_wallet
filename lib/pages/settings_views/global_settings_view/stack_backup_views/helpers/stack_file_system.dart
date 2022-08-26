import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class StackFileSystem {
  Directory? rootPath;
  Directory? startPath;

  String? filePath;
  String? dirPath;

  final bool isDesktop = !(Platform.isAndroid || Platform.isIOS);

  Future<void> prepareStorage() async {
    rootPath = (await getApplicationDocumentsDirectory());
    debugPrint(rootPath!.absolute.toString());
    if (Platform.isAndroid) {
      rootPath = Directory("/storage/emulated/0/");
    }
    debugPrint(rootPath!.absolute.toString());

    Directory sampleFolder =
        Directory('${rootPath!.path}/Documents/Stack_backups');
    if (Platform.isIOS) {
      sampleFolder = Directory(rootPath!.path);
    }
    try {
      if (!sampleFolder.existsSync()) {
        sampleFolder.createSync();
      }
    } catch (e, s) {
      debugPrint("$e $s");
    }

    File sampleFile = File('${sampleFolder.path}/Backups_Go_Here.info');
    if (Platform.isIOS) {
      sampleFile = File('${rootPath!.path}/Backups_Go_Here.info');
    }

    try {
      if (!sampleFile.existsSync()) {
        sampleFile.createSync();
      }
    } catch (e, s) {
      debugPrint("$e $s");
    }
    startPath = sampleFolder;
  }

  Future<void> pickDir(BuildContext context) async {
    final String? path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: "Choose Backup location",
      initialDirectory: startPath!.path,
      lockParentWindow: true,
    );
    dirPath = path;
  }

  Future<void> openFile(BuildContext context) async {
    FilePickerResult? result;
    if (Platform.isAndroid) {
      result = await FilePicker.platform.pickFiles(
        dialogTitle: "Load backup file",
        initialDirectory: startPath!.path,
        type: FileType.custom,
        allowedExtensions: ['bin'],
        allowCompression: false,
        lockParentWindow: true,
      );
    } else if (Platform.isIOS) {
      result = await FilePicker.platform.pickFiles(
        dialogTitle: "Load backup file",
        initialDirectory: startPath!.path,
        type: FileType.any,
        allowCompression: false,
        lockParentWindow: true,
      );
    } else {
      result = await FilePicker.platform.pickFiles(
        dialogTitle: "Load backup file",
        initialDirectory: startPath!.path,
        type: FileType.custom,
        allowedExtensions: ['bin', 'swb'],
        allowCompression: false,
        lockParentWindow: true,
      );
    }

    filePath = result?.paths.first;
  }
}
