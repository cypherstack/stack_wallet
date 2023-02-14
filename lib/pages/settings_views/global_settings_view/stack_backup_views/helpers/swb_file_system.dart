import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stackwallet/utilities/util.dart';

class SWBFileSystem {
  Directory? rootPath;
  Directory? startPath;

  String? filePath;
  String? dirPath;

  final bool isDesktop = Util.isDesktop;

  Future<Directory> prepareStorage() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
    }
    rootPath = (await getApplicationDocumentsDirectory());
    //todo: check if print needed
    // debugPrint(rootPath!.absolute.toString());
    if (Platform.isAndroid) {
      rootPath = Directory("/storage/emulated/0/");
    }
    //todo: check if print needed
    // debugPrint(rootPath!.absolute.toString());

    late Directory sampleFolder;

    if (Platform.isIOS) {
      sampleFolder = Directory(rootPath!.path);
    } else if (Platform.isAndroid) {
      sampleFolder = Directory('${rootPath!.path}Documents/Stack_backups');
    } else if (Platform.isLinux) {
      sampleFolder = Directory('${rootPath!.path}/Stack_backups');
    } else if (Platform.isWindows) {
      sampleFolder = Directory('${rootPath!.path}/Stack_backups');
    } else if (Platform.isMacOS) {
      sampleFolder = Directory('${rootPath!.path}/Stack_backups');
    }

    try {
      if (!sampleFolder.existsSync()) {
        sampleFolder.createSync(recursive: true);
      }
    } catch (e, s) {
      // todo: come back to this
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
      // todo: come back to this
      debugPrint("$e $s");
    }
    startPath = sampleFolder;
    return sampleFolder;
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
        type: FileType.any,
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
