//ON
import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mwebd/flutter_mwebd.dart';
import 'package:path/path.dart';

import '../../app_config.dart';
//END_ON
import '../../utilities/dynamic_object.dart';
import '../../utilities/extensions/extensions.dart';
import '../../utilities/stack_file_system.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../interfaces/mwebd_server_interface.dart';

MwebdServerInterface get mwebdServerInterface => _getInterface();

//OFF
MwebdServerInterface _getInterface() => throw Exception("MWEBD not enabled!");

//END_OFF
//ON
MwebdServerInterface _getInterface() => const _MwebdServerInterfaceImpl();

class _MwebdServerInterfaceImpl extends MwebdServerInterface {
  const _MwebdServerInterfaceImpl();

  static const _kExe = "mwebd.exe";

  static String? _cachedWinExePath;

  Future<String> _prepareWindowsExeDirPath() async {
    if (_cachedWinExePath == null) {
      final dir = (await StackFileSystem.applicationMwebdDirectory(
        "dummy",
      )).parent.path;

      final exe = File(join(dir, _kExe));

      if (await exe.exists()) {
        await exe.delete();
      }

      final bytes = await rootBundle.load("assets/windows/mwebd.exe");
      await exe.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
      _cachedWinExePath = exe.parent.path;
    }

    final hash = await sha256
        .bind(File(join(_cachedWinExePath!, _kExe)).openRead())
        .first;
    final hexHash = Uint8List.fromList(hash.bytes).toHex;
    if (AppConfig.windowsMwebdExeHash != hexHash) {
      throw Exception("Windows mwebd.exe sha256 has mismatch!!!");
    }

    return _cachedWinExePath!;
  }

  @override
  Future<({DynamicObject server, int port})> createAndStartServer(
    CryptoCurrencyNetwork net, {
    required String chain,
    required String dataDir,
    required String peer,
    String proxy = "",
    required int serverPort,
  }) async {
    final newServer = MwebdServer(
      chain: chain,
      dataDir: dataDir,
      peer: peer,
      proxy: proxy,
      serverPort: serverPort,
    );

    if (Platform.isWindows) {
      final exeDirPath = await _prepareWindowsExeDirPath();
      final process = await Process.start(join(exeDirPath, _kExe), [
        "-c",
        chain,
        "-d",
        chain,
        "-l",
        "127.0.0.1:$serverPort",
        "-p",
        peer,
        "-proxy",
        proxy,
      ], workingDirectory: exeDirPath);
      return (server: DynamicObject((process, newServer)), port: serverPort);
    } else {
      await newServer.createServer();
      await newServer.startServer();
      return (server: DynamicObject(newServer), port: newServer.serverPort);
    }
  }

  @override
  Future<({String chain, String dataDir, String peer})> stopServer(
    DynamicObject server,
  ) async {
    if (server.get<Object>() is (Process, MwebdServer)) {
      final actual = server.get<(Process, MwebdServer)>();
      actual.$1.kill();
      return (
        chain: actual.$2.chain,
        dataDir: actual.$2.dataDir,
        peer: actual.$2.peer,
      );
    } else {
      final actual = server.get<MwebdServer>();
      final data = (
        chain: actual.chain,
        dataDir: actual.dataDir,
        peer: actual.peer,
      );
      await actual.stopServer();
      return data;
    }
  }
}

//END_ON
