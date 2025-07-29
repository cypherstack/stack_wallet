import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_mwebd/flutter_mwebd.dart';
import 'package:mutex/mutex.dart';
import 'package:mweb_client/mweb_client.dart';

import '../utilities/logger.dart';
import '../utilities/prefs.dart';
import '../utilities/stack_file_system.dart';
import '../wallets/crypto_currency/crypto_currency.dart';
import 'event_bus/events/global/tor_connection_status_changed_event.dart';
import 'event_bus/events/global/tor_status_changed_event.dart';
import 'event_bus/global_event_bus.dart';
import 'tor_service.dart';

final class MwebdService {
  static String defaultPeer(CryptoCurrencyNetwork net) => switch (net) {
    CryptoCurrencyNetwork.main => "litecoin.stackwallet.com:9333",
    CryptoCurrencyNetwork.test => "litecoin.stackwallet.com:19335",
    CryptoCurrencyNetwork.stage => throw UnimplementedError(),
    CryptoCurrencyNetwork.test4 => throw UnimplementedError(),
  };

  final Map<CryptoCurrencyNetwork, ({MwebdServer server, MwebClient client})>
  _map = {};

  late final StreamSubscription<TorConnectionStatusChangedEvent>
  _torStatusListener;
  late final StreamSubscription<TorPreferenceChangedEvent>
  _torPreferenceListener;

  final Mutex _torConnectingLock = Mutex();

  // Track active log stream controllers for cleanup during shutdown.
  final Set<StreamController<String>> _activeLogControllers = {};

  static final instance = MwebdService._();

  MwebdService._() {
    final bus = GlobalEventBus.instance;

    // Listen for tor status changes.
    _torStatusListener = bus.on<TorConnectionStatusChangedEvent>().listen((
      event,
    ) async {
      switch (event.newStatus) {
        case TorConnectionStatus.connecting:
          if (!_torConnectingLock.isLocked) {
            await _torConnectingLock.acquire();
          }
          break;

        case TorConnectionStatus.connected:
        case TorConnectionStatus.disconnected:
          if (_torConnectingLock.isLocked) {
            _torConnectingLock.release();
          }
          break;
      }
    });

    // Listen for tor preference changes.
    _torPreferenceListener = bus.on<TorPreferenceChangedEvent>().listen((
      event,
    ) async {
      if (Prefs.instance.useTor) {
        return await _torConnectingLock.protect(() async {
          final proxyInfo = TorService.sharedInstance.getProxyInfo();
          return await _update(proxyInfo);
        });
      } else {
        return await _update(null);
      }
    });
  }

  // locked while mweb servers and clients are updating
  final _updateLock = Mutex();

  // update function called when Tor pref changed
  Future<void> _update(({InternetAddress host, int port})? proxyInfo) async {
    await _updateLock.protect(() async {
      final proxy =
          proxyInfo == null
              ? ""
              : "socks5://${proxyInfo.host.address}:${proxyInfo.port}";
      final nets = _map.keys;
      for (final net in nets) {
        final old = _map.remove(net)!;

        await old.client.cleanup();
        await old.server.stopServer();

        final port = await _getRandomUnusedPort();
        if (port == null) {
          throw Exception("Could not find an unused port for mwebd");
        }

        final newServer = MwebdServer(
          chain: old.server.chain,
          dataDir: old.server.dataDir,
          peer: old.server.peer,
          proxy: proxy,
          serverPort: port,
        );
        await newServer.createServer();
        await newServer.startServer();

        final newClient = MwebClient.fromHost(
          "127.0.0.1",
          newServer.serverPort,
        );

        _map[net] = (server: newServer, client: newClient);
      }
    });
  }

  Future<void> initService(CryptoCurrencyNetwork net) async {
    Logging.instance.i("MwebdService init($net) called...");
    await _updateLock.protect(() async {
      if (_map[net] != null) {
        Logging.instance.i("MwebdService init($net) was already called.");
        return;
      }

      if (_map.isNotEmpty) {
        for (final old in _map.values) {
          try {
            await old.client.cleanup();
            await old.server.stopServer();
          } catch (e, s) {
            Logging.instance.i(
              "Switching mwebd chain. Error likely expected here.",
              error: e,
              stackTrace: s,
            );
          }
        }
        _map.clear();
      }

      final port = await _getRandomUnusedPort();

      if (port == null) {
        throw Exception("Could not find an unused port for mwebd");
      }

      final chain = switch (net) {
        CryptoCurrencyNetwork.main => "mainnet",
        CryptoCurrencyNetwork.test => "testnet",
        CryptoCurrencyNetwork.stage => throw UnimplementedError(),
        CryptoCurrencyNetwork.test4 => throw UnimplementedError(),
      };

      final dir = await StackFileSystem.applicationMwebdDirectory(chain);

      final String proxy;
      if (Prefs.instance.useTor) {
        final proxyInfo = TorService.sharedInstance.getProxyInfo();
        proxy = "socks5://${proxyInfo.host.address}:${proxyInfo.port}";
      } else {
        proxy = "";
      }

      final newServer = MwebdServer(
        chain: chain,
        dataDir: dir.path,
        peer: defaultPeer(net),
        proxy: proxy,
        serverPort: port,
      );
      await newServer.createServer();
      await newServer.startServer();

      final newClient = MwebClient.fromHost("127.0.0.1", newServer.serverPort);

      _map[net] = (server: newServer, client: newClient);

      Logging.instance.i("MwebdService init($net) completed!");
    });
  }

  /// Get server status. Returns null if no server was initialized.
  Future<Status?> getServerStatus(CryptoCurrencyNetwork net) async {
    return await _updateLock.protect(() async {
      return await _map[net]?.server.getStatus();
    });
  }

  /// Get client for network. Returns null if no server was initialized.
  Future<MwebClient?> getClient(CryptoCurrencyNetwork net) async {
    return await _updateLock.protect(() async {
      return _map[net]?.client;
    });
  }

  Future<Stream<String>> logsStream(
    CryptoCurrencyNetwork net, {
    Duration pollInterval = const Duration(milliseconds: 200),
  }) async {
    final controller = StreamController<String>();
    int offset = 0;
    String leftover = '';
    Timer? timer;

    // Track this controller for cleanup during shutdown.
    _activeLogControllers.add(controller);

    final path =
        "${(await StackFileSystem.applicationMwebdDirectory(net == CryptoCurrencyNetwork.main ? "mainnet" : "testnet")).path}"
        "${Platform.pathSeparator}logs"
        "${Platform.pathSeparator}debug.log";

    Future<void> poll() async {
      if (!controller.isClosed) {
        final file = File(path);
        final length = await file.length();

        if (length > offset) {
          final raf = await file.open();
          await raf.setPosition(offset);
          final bytes = await raf.read(length - offset);
          await raf.close();

          final chunk = utf8.decode(bytes);
          final lines = (leftover + chunk).split('\n');
          leftover = lines.removeLast(); // possibly incomplete

          for (final line in lines) {
            controller.add(line);
          }

          offset = length;
        }
      }
    }

    timer = Timer.periodic(pollInterval, (_) => poll());

    controller.onCancel = () {
      timer?.cancel();
      _activeLogControllers.remove(controller);
      controller.close();
    };

    return controller.stream;
  }

  /// Shutdown all mwebd servers and clean up resources.
  ///
  /// This method should be called when the app is terminating to prevent hanging.
  Future<void> shutdown() async {
    final stopwatch = Stopwatch()..start();
    Logging.instance.i("MwebdService shutdown() started");
    
    await _updateLock.protect(() async {
      // Cancel stream subscriptions to prevent further events.
      try {
        await _torStatusListener.cancel();
        Logging.instance.i("Canceled tor status listener");
      } catch (e, s) {
        Logging.instance.w(
          "Error canceling tor status listener", 
          error: e, 
          stackTrace: s,
        );
      }

      try {
        await _torPreferenceListener.cancel();
        Logging.instance.i("Canceled tor preference listener");
      } catch (e, s) {
        Logging.instance.w(
          "Error canceling tor preference listener", 
          error: e, 
          stackTrace: s,
        );
      }

      // Cancel all active log stream controllers and their timers.
      final logControllers = List.from(_activeLogControllers);
      for (final controller in logControllers) {
        try {
          await controller.close();
          Logging.instance.i("Closed log stream controller");
        } catch (e, s) {
          Logging.instance.w(
            "Error closing log stream controller", 
            error: e, 
            stackTrace: s,
          );
        }
      }
      _activeLogControllers.clear();

      // Stop all servers and clean up clients with timeout protection.
      final stopFutures = <Future>[];
      for (final entry in _map.values) {
        stopFutures.add(_shutdownServerSafely(entry));
      }

      // Wait for all shutdowns with overall timeout.
      try {
        await Future.wait(stopFutures).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            Logging.instance.w("Timeout waiting for mwebd servers to stop");
            return []; // Return a dummy list.
          },
        );
      } catch (e, s) {
        Logging.instance.w(
          "Error during mwebd servers shutdown", 
          error: e, 
          stackTrace: s,
        );
      }

      _map.clear();
      
      final elapsedMs = stopwatch.elapsedMilliseconds;
      Logging.instance.i("MwebdService shutdown() completed in ${elapsedMs}ms");
      
      // Warn if shutdown took too long (could indicate hanging).
      if (elapsedMs > 3000) {
        Logging.instance.w("MwebdService shutdown took ${elapsedMs}ms - longer than expected");
      }
    });
  }

  /// Safely shutdown a server/client pair with timeout protection.
  Future<void> _shutdownServerSafely(
    ({MwebdServer server, MwebClient client}) entry,
  ) async {
    final serverStopwatch = Stopwatch()..start();
    Logging.instance.i("Starting shutdown of mwebd server/client pair");
    
    try {
      // Clean up client first.
      final clientStopwatch = Stopwatch()..start();
      await entry.client.cleanup().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          Logging.instance.w("Timeout cleaning up mweb client after 3s");
        },
      );
      Logging.instance.i("Client cleanup completed in ${clientStopwatch.elapsedMilliseconds}ms");
    } catch (e, s) {
      Logging.instance.w(
        "Error cleaning up mweb client", 
        error: e, 
        stackTrace: s,
      );
    }

    try {
      // Stop server with timeout protection.
      final serverShutdownStopwatch = Stopwatch()..start();
      await entry.server.stopServer().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          Logging.instance.w("Timeout stopping mwebd server after 5s");
        },
      );
      Logging.instance.i("Server stop completed in ${serverShutdownStopwatch.elapsedMilliseconds}ms");
    } catch (e, s) {
      Logging.instance.w(
        "Error stopping mwebd server", 
        error: e, 
        stackTrace: s,
      );
    }
    
    final totalMs = serverStopwatch.elapsedMilliseconds;
    Logging.instance.i("Server/client pair shutdown completed in ${totalMs}ms");
  }
}

// ============================================================================
Future<int?> _getRandomUnusedPort({Set<int> excluded = const {}}) async {
  const int minPort = 1024;
  const int maxPort = 65535;
  const int maxAttempts = 1000;

  final random = Random.secure();

  for (int i = 0; i < maxAttempts; i++) {
    final int potentialPort = minPort + random.nextInt(maxPort - minPort + 1);

    if (excluded.contains(potentialPort)) {
      continue;
    }

    try {
      final ServerSocket socket = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        potentialPort,
      );
      await socket.close();
      return potentialPort;
    } catch (_) {
      excluded.add(potentialPort);
      continue;
    }
  }

  return null;
}

// final class MwebdService {
//   static String defaultPeer(CryptoCurrencyNetwork net) => switch (net) {
//     CryptoCurrencyNetwork.main => "litecoin.stackwallet.com:9333",
//     CryptoCurrencyNetwork.test => "litecoin.stackwallet.com:19335",
//     CryptoCurrencyNetwork.stage => throw UnimplementedError(),
//     CryptoCurrencyNetwork.test4 => throw UnimplementedError(),
//   };
//
//   final Map<CryptoCurrencyNetwork, ({MwebdServer server, MwebClient client})>
//   _map = {};
//
//   late final StreamSubscription<TorConnectionStatusChangedEvent>
//   _torStatusListener;
//   late final StreamSubscription<TorPreferenceChangedEvent>
//   _torPreferenceListener;
//
//   final Mutex _torConnectingLock = Mutex();
//
//   static final instance = MwebdService._();
//
//   MwebdService._() {
//     final bus = GlobalEventBus.instance;
//
//     // Listen for tor status changes.
//     _torStatusListener = bus.on<TorConnectionStatusChangedEvent>().listen((
//       event,
//     ) async {
//       switch (event.newStatus) {
//         case TorConnectionStatus.connecting:
//           if (!_torConnectingLock.isLocked) {
//             await _torConnectingLock.acquire();
//           }
//           break;
//
//         case TorConnectionStatus.connected:
//         case TorConnectionStatus.disconnected:
//           if (_torConnectingLock.isLocked) {
//             _torConnectingLock.release();
//           }
//           break;
//       }
//     });
//
//     // Listen for tor preference changes.
//     _torPreferenceListener = bus.on<TorPreferenceChangedEvent>().listen((
//       event,
//     ) async {
//       if (Prefs.instance.useTor) {
//         return await _torConnectingLock.protect(() async {
//           final proxyInfo = TorService.sharedInstance.getProxyInfo();
//           return await _update(proxyInfo);
//         });
//       } else {
//         return await _update(null);
//       }
//     });
//   }
//
//   // locked while mweb servers and clients are updating
//   final _updateLock = Mutex();
//
//   // update function called when Tor pref changed
//   Future<void> _update(({InternetAddress host, int port})? proxyInfo) async {
//     await _updateLock.protect(() async {
//       final proxy =
//           proxyInfo == null
//               ? ""
//               : "${proxyInfo.host.address}:${proxyInfo.port}";
//       final nets = _map.keys;
//       for (final net in nets) {
//         final old = _map.remove(net)!;
//
//         await old.client.cleanup();
//         await old.server.stopServer();
//
//         final port = await _getRandomUnusedPort();
//         if (port == null) {
//           throw Exception("Could not find an unused port for mwebd");
//         }
//
//         final newServer = MwebdServer(
//           chain: old.server.chain,
//           dataDir: old.server.dataDir,
//           peer: old.server.peer,
//           proxy: proxy,
//           serverPort: port,
//         );
//         await newServer.createServer();
//         await newServer.startServer();
//
//         final newClient = MwebClient.fromHost(
//           "127.0.0.1",
//           newServer.serverPort,
//         );
//
//         _map[net] = (server: newServer, client: newClient);
//       }
//     });
//   }
//
//   Future<void> init(CryptoCurrencyNetwork net) async {
//     if (net == CryptoCurrencyNetwork.test) return;
//
//     Logging.instance.i("MwebdService init($net) called...");
//     await _updateLock.protect(() async {
//       if (_map[net] != null) {
//         Logging.instance.i("MwebdService init($net) was already called.");
//         return;
//       }
//
//       final port = await _getRandomUnusedPort();
//
//       if (port == null) {
//         throw Exception("Could not find an unused port for mwebd");
//       }
//
//       final chain = switch (net) {
//         CryptoCurrencyNetwork.main => "mainnet",
//         CryptoCurrencyNetwork.test => "testnet",
//         CryptoCurrencyNetwork.stage => throw UnimplementedError(),
//         CryptoCurrencyNetwork.test4 => throw UnimplementedError(),
//       };
//
//       final dir = await StackFileSystem.applicationMwebdDirectory(chain);
//
//       final String proxy;
//       if (Prefs.instance.useTor) {
//         final proxyInfo = TorService.sharedInstance.getProxyInfo();
//         proxy = "${proxyInfo.host.address}:${proxyInfo.port}";
//       } else {
//         proxy = "";
//       }
//
//       final newServer = MwebdServer(
//         chain: chain,
//         dataDir: dir.path,
//         peer: defaultPeer(net),
//         proxy: proxy,
//         serverPort: port,
//       );
//       await newServer.createServer();
//       await newServer.startServer();
//
//       final newClient = MwebClient.fromHost("127.0.0.1", newServer.serverPort);
//
//       _map[net] = (server: newServer, client: newClient);
//
//       Logging.instance.i("MwebdService init($net) completed!");
//     });
//   }
//
//   /// Get server status. Returns null if no server was initialized.
//   Future<Status?> getServerStatus(CryptoCurrencyNetwork net) async {
//     return await _updateLock.protect(() async {
//       return await _map[net]?.server.getStatus();
//     });
//   }
//
//   /// Get client for network. Returns null if no server was initialized.
//   Future<MwebClient?> getClient(CryptoCurrencyNetwork net) async {
//     return await _updateLock.protect(() async {
//       return _map[net]?.client;
//     });
//   }
// }
//
// // ============================================================================
// Future<int?> _getRandomUnusedPort({Set<int> excluded = const {}}) async {
//   const int minPort = 1024;
//   const int maxPort = 65535;
//   const int maxAttempts = 1000;
//
//   final random = Random.secure();
//
//   for (int i = 0; i < maxAttempts; i++) {
//     final int potentialPort = minPort + random.nextInt(maxPort - minPort + 1);
//
//     if (excluded.contains(potentialPort)) {
//       continue;
//     }
//
//     try {
//       final ServerSocket socket = await ServerSocket.bind(
//         InternetAddress.anyIPv4,
//         potentialPort,
//       );
//       await socket.close();
//       return potentialPort;
//     } catch (_) {
//       excluded.add(potentialPort);
//       continue;
//     }
//   }
//
//   return null;
// }
