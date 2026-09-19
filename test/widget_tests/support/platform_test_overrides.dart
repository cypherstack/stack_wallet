import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/manage_nodes_views/add_edit_node_view.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/test_node_connection.dart';
import 'package:stackwallet/utilities/tor_plain_net_option_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

class NodeConnectionTestInvocation {
  const NodeConnectionTestInvocation({
    required this.cryptoCurrency,
    required this.name,
    required this.host,
    required this.login,
    required this.password,
    required this.port,
    required this.useSSL,
    required this.isFailover,
    required this.trusted,
    required this.netOption,
  });

  factory NodeConnectionTestInvocation.fromFormData({
    required CryptoCurrency cryptoCurrency,
    required NodeFormData nodeFormData,
  }) {
    return NodeConnectionTestInvocation(
      cryptoCurrency: cryptoCurrency,
      name: nodeFormData.name,
      host: nodeFormData.host,
      login: nodeFormData.login,
      password: nodeFormData.password,
      port: nodeFormData.port,
      useSSL: nodeFormData.useSSL,
      isFailover: nodeFormData.isFailover,
      trusted: nodeFormData.trusted,
      netOption: nodeFormData.netOption,
    );
  }

  final CryptoCurrency cryptoCurrency;
  final String? name;
  final String? host;
  final String? login;
  final String? password;
  final int? port;
  final bool? useSSL;
  final bool? isFailover;
  final bool? trusted;
  final TorPlainNetworkOption? netOption;
}

typedef PlatformNodeConnectionHandler =
    FutureOr<bool> Function(NodeConnectionTestInvocation invocation);

class RecordingFakeSecureStorage extends FakeSecureStorage {
  final List<String> readKeys = [];
  final List<String> writtenKeys = [];
  final List<String> deletedKeys = [];

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    readKeys.add(key);
    return super.read(
      key: key,
      iOptions: iOptions,
      aOptions: aOptions,
      lOptions: lOptions,
      webOptions: webOptions,
      mOptions: mOptions,
      wOptions: wOptions,
    );
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    writtenKeys.add(key);
    return super.write(
      key: key,
      value: value,
      iOptions: iOptions,
      aOptions: aOptions,
      lOptions: lOptions,
      webOptions: webOptions,
      mOptions: mOptions,
      wOptions: wOptions,
    );
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    deletedKeys.add(key);
    return super.delete(
      key: key,
      iOptions: iOptions,
      aOptions: aOptions,
      lOptions: lOptions,
      webOptions: webOptions,
      mOptions: mOptions,
      wOptions: wOptions,
    );
  }
}

class PlatformTestOverrides {
  const PlatformTestOverrides._({
    required this.secureStorage,
    required this.connectionInvocations,
    required this.overrides,
  });

  final RecordingFakeSecureStorage secureStorage;
  final List<NodeConnectionTestInvocation> connectionInvocations;
  final List<Override> overrides;
}

Future<PlatformTestOverrides> createPlatformTestOverrides({
  Map<String, String?> secureStorageEntries = const {},
  bool connectionResult = true,
  PlatformNodeConnectionHandler? onTestNodeConnection,
}) async {
  final secureStorage = RecordingFakeSecureStorage();
  for (final entry in secureStorageEntries.entries) {
    await secureStorage.write(key: entry.key, value: entry.value);
  }

  final connectionInvocations = <NodeConnectionTestInvocation>[];

  return PlatformTestOverrides._(
    secureStorage: secureStorage,
    connectionInvocations: connectionInvocations,
    overrides: [
      secureStoreProvider.overrideWithValue(secureStorage),
      testNodeConnectionProvider.overrideWithValue(({
        required BuildContext context,
        required NodeFormData nodeFormData,
        required CryptoCurrency cryptoCurrency,
        void Function(NodeFormData)? onSuccess,
      }) async {
        final invocation = NodeConnectionTestInvocation.fromFormData(
          cryptoCurrency: cryptoCurrency,
          nodeFormData: nodeFormData,
        );
        connectionInvocations.add(invocation);

        final result = onTestNodeConnection != null
            ? await onTestNodeConnection(invocation)
            : connectionResult;

        if (result) {
          onSuccess?.call(nodeFormData);
        }

        return result;
      }),
    ],
  );
}
