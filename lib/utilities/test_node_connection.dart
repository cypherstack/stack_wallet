import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solana/solana.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/manage_nodes_views/add_edit_node_view.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/utilities/connection_check/electrum_connection_check.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/test_epic_box_connection.dart';
import 'package:stackwallet/utilities/test_eth_node_connection.dart';
import 'package:stackwallet/utilities/test_monero_node_connection.dart';
import 'package:stackwallet/utilities/test_stellar_node_connection.dart';
import 'package:stackwallet/wallets/api/tezos/tezos_rpc_api.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/bitcoin_frost.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/epiccash.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/ethereum.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/solana.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/stellar.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/tezos.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/interfaces/electrumx_currency_interface.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/cryptonote_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/nano_currency.dart';

Future<bool> _xmrHelper(
  NodeFormData nodeFormData,
  BuildContext context,
  void Function(NodeFormData)? onSuccess,
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
        final response =
            await testMoneroNodeConnection(Uri.parse(uriString), true);
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
            );

            if (testPassed == false) {
              // try http
              testPassed = await _xmrHelper(
                formData
                  ..host = "http://$url"
                  ..useSSL = false,
                context,
                onSuccess,
              );
            }
          } else {
            testPassed = await _xmrHelper(
              formData
                ..host = url
                ..useSSL = true,
              context,
              onSuccess,
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
      //TODO: check network/node
      throw UnimplementedError();

    case Tezos():
      try {
        testPassed = await TezosRpcAPI.testNetworkConnection(
          nodeInfo: (host: formData.host!, port: formData.port!),
        );
      } catch (_) {}
      break;

    case Solana():
      try {
        RpcClient rpcClient;
        if (formData.host!.startsWith("http") ||
            formData.host!.startsWith("https")) {
          rpcClient = RpcClient("${formData.host}:${formData.port}");
        } else {
          rpcClient = RpcClient("http://${formData.host}:${formData.port}");
        }
        await rpcClient.getEpochInfo().then((value) => testPassed = true);
      } catch (_) {
        testPassed = false;
      }
      break;
  }

  return testPassed;
}
