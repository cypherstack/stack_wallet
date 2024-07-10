import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../networking/http.dart';
import '../pages/settings_views/global_settings_view/manage_nodes_views/add_edit_node_view.dart';
import '../providers/global/prefs_provider.dart';
import '../services/tor_service.dart';
import '../wallets/api/tezos/tezos_rpc_api.dart';
import '../wallets/crypto_currency/crypto_currency.dart';
import '../wallets/crypto_currency/interfaces/electrumx_currency_interface.dart';
import '../wallets/crypto_currency/intermediate/cryptonote_currency.dart';
import '../wallets/crypto_currency/intermediate/nano_currency.dart';
import '../wallets/wallet/impl/solana_wallet.dart';
import 'connection_check/electrum_connection_check.dart';
import 'logger.dart';
import 'test_epic_box_connection.dart';
import 'test_eth_node_connection.dart';
import 'test_monero_node_connection.dart';
import 'test_stellar_node_connection.dart';

Future<bool> _xmrHelper(
  NodeFormData nodeFormData,
  BuildContext context,
  void Function(NodeFormData)? onSuccess,
  ({
    InternetAddress host,
    int port,
  })? proxyInfo,
) async {
  final data = nodeFormData;
  final url = data.host!;
  final port = data.port;

  final uri = Uri.parse(url);

  final String path = uri.path.isEmpty ? "/json_rpc" : uri.path;

  final uriString = "${uri.scheme}://${uri.host}:${port ?? 0}$path";

  final response = await testMoneroNodeConnection(
    Uri.parse(uriString),
    false,
    proxyInfo: proxyInfo,
  );

  if (response.cert != null) {
    if (context.mounted) {
      final shouldAllowBadCert = await showBadX509CertificateDialog(
        response.cert!,
        response.url!,
        response.port!,
        context,
      );

      if (shouldAllowBadCert) {
        final response = await testMoneroNodeConnection(
          Uri.parse(uriString),
          true,
          proxyInfo: proxyInfo,
        );
        onSuccess?.call(data..host = url);
        return response.success;
      }
    }
  } else {
    onSuccess?.call(data..host = url);
    return response.success;
  }

  return false;
}

// TODO: probably pull this into each coin's functionality otherwise updating this separately will get irritating
Future<bool> testNodeConnection({
  required BuildContext context,
  required NodeFormData nodeFormData,
  required CryptoCurrency cryptoCurrency,
  required WidgetRef ref,
  void Function(NodeFormData)? onSuccess,
}) async {
  final formData = nodeFormData;

  bool testPassed = false;

  switch (cryptoCurrency) {
    case Epiccash():
      try {
        final data = await testEpicNodeConnection(formData);

        if (data != null) {
          testPassed = true;
          onSuccess?.call(data);
        }
      } catch (e, s) {
        Logging.instance.log("$e\n$s", level: LogLevel.Warning);
      }
      break;

    case CryptonoteCurrency():
      try {
        final proxyInfo = ref.read(prefsChangeNotifierProvider).useTor
            ? ref.read(pTorService).getProxyInfo()
            : null;

        final url = formData.host!;
        final uri = Uri.tryParse(url);
        if (uri != null) {
          if (!uri.hasScheme) {
            // try https first
            testPassed = await _xmrHelper(
              formData
                ..host = "https://$url"
                ..useSSL = true,
              context,
              onSuccess,
              proxyInfo,
            );

            if (testPassed == false && context.mounted) {
              // try http
              testPassed = await _xmrHelper(
                formData
                  ..host = "http://$url"
                  ..useSSL = false,
                context,
                onSuccess,
                proxyInfo,
              );
            }
          } else {
            testPassed = await _xmrHelper(
              formData
                ..host = url
                ..useSSL = true,
              context,
              onSuccess,
              proxyInfo,
            );
          }
        }
      } catch (e, s) {
        Logging.instance.log("$e\n$s", level: LogLevel.Warning);
      }

      break;

    case ElectrumXCurrencyInterface():
    case BitcoinFrost():
      try {
        testPassed = await checkElectrumServer(
          host: formData.host!,
          port: formData.port!,
          useSSL: formData.useSSL!,
          overridePrefs: ref.read(prefsChangeNotifierProvider),
          overrideTorService: ref.read(pTorService),
        );
      } catch (_) {
        testPassed = false;
      }

      break;

    case Ethereum():
      try {
        testPassed = await testEthNodeConnection(formData.host!);
      } catch (_) {
        testPassed = false;
      }
      break;

    case Stellar():
      try {
        testPassed =
            await testStellarNodeConnection(formData.host!, formData.port!);
      } catch (_) {}
      break;

    case NanoCurrency():
      try {
        final uri = Uri.parse(formData.host!);

        final response = await HTTP().post(
          url: uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(
            {
              "action": "version",
            },
          ),
          proxyInfo: ref.read(prefsChangeNotifierProvider).useTor
              ? ref.read(pTorService).getProxyInfo()
              : null,
        );

        testPassed = response.code == 200;
      } catch (_) {}
      break;

    case Tezos():
      try {
        testPassed = await TezosRpcAPI.testNetworkConnection(
          nodeInfo: (host: formData.host!, port: formData.port!),
        );
      } catch (_) {}
      break;

    case Solana():
      try {
        final rpcClient = SolanaWallet.createRpcClient(
          formData.host!,
          formData.port!,
          formData.useSSL ?? false,
          ref.read(prefsChangeNotifierProvider),
          ref.read(pTorService),
        );

        final health = await rpcClient.getHealth();
        Logging.instance.log(
          "Solana testNodeConnection \"health=$health\"",
          level: LogLevel.Info,
        );
        return true;
      } catch (_) {
        testPassed = false;
      }
      break;
  }

  return testPassed;
}
