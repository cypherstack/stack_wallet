import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_mwebd/flutter_mwebd.dart';
import 'package:mutex/mutex.dart';
import 'package:mweb_client/mweb_client.dart';

import '../utilities/logger.dart';
import '../utilities/prefs.dart';
import '../utilities/stack_file_system.dart';
import '../wallets/crypto_currency/crypto_currency.dart';
import 'event_bus/events/global/mweb_status_changed_event.dart';
import 'event_bus/events/global/tor_connection_status_changed_event.dart';
import 'event_bus/events/global/tor_status_changed_event.dart';
import 'event_bus/global_event_bus.dart';
import 'tor_service.dart';

final class MwebdService {
  final Map<CryptoCurrencyNetwork, ({MwebdServer server, MwebClient client})>
  _map = {};

  late final StreamSubscription<TorConnectionStatusChangedEvent>
  _torStatusListener;
  late final StreamSubscription<TorPreferenceChangedEvent>
  _torPreferenceListener;
  late final StreamSubscription<MwebPreferenceChangedEvent>
  _mwebPreferenceListener;

  final Mutex _torConnectingLock = Mutex();

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

    // Listen for mweb preference changes.
    _mwebPreferenceListener = bus.on<MwebPreferenceChangedEvent>().listen((
      event,
    ) async {
      switch (event.status) {
        case MwebStatus.enabled:
          // as we don't know which network(s) to use here
          // we will rely on status checks and init as required within wallets
          break;

        case MwebStatus.disabled:
          final nets = _map.keys;
          for (final net in nets) {
            final old = _map.remove(net)!;
            await old.client.cleanup();
            await old.server.stopServer();
          }
          break;
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
              : "${proxyInfo.host.address}:${proxyInfo.port}";
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

  Future<void> init(CryptoCurrencyNetwork net) async {
    Logging.instance.i("MwebdService init($net) called...");
    await _updateLock.protect(() async {
      if (_map[net] != null) {
        Logging.instance.i("MwebdService init($net) was already called.");
        return;
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
        proxy = "${proxyInfo.host.address}:${proxyInfo.port}";
      } else {
        proxy = "";
      }

      final newServer = MwebdServer(
        chain: chain,
        dataDir: dir.path,
        peer: "",
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
