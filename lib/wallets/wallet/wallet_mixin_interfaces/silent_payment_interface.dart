import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:isar/isar.dart';
import 'package:silent_payments/silent_payments.dart';

import '../../../electrumx_rpc/cached_electrumx_client.dart';
import '../../../electrumx_rpc/client_manager.dart';
import '../../../electrumx_rpc/electrumx_client.dart';
import '../../../models/coinlib/exp2pkh_address.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/isar/models/isar_models.dart';
import '../../../models/isar/models/silent_payments/silent_payment_config.dart';
import '../../../models/isar/models/silent_payments/silent_payment_metadata.dart';
import '../../../models/keys/view_only_wallet_data.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../models/signing_data.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../../../utilities/enums/fee_rate_type_enum.dart';
import '../../../utilities/extensions/extensions.dart';
import '../../../utilities/logger.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../crypto_currency/interfaces/electrumx_currency_interface.dart';
import '../../isar/models/wallet_info.dart';
import '../../models/tx_data.dart';
import '../impl/bitcoin_wallet.dart';
import '../intermediate/bip39_hd_wallet.dart';
import 'electrumx_interface.dart';
import 'view_only_option_interface.dart';

/// A mixin that provides Silent Payment capabilities to a wallet
///
/// This interface focuses on the unique aspects of Silent Payments:
/// 1. Generating Silent Payment addresses
/// 2. Deriving recipient addresses for sending
/// 3. Scanning for received payments
///
/// It leverages the existing wallet methods for transaction building
/// and blockchain interaction.
mixin SilentPaymentInterface<T extends ElectrumXCurrencyInterface>
    on ElectrumXInterface<T> {
  // Cache for the silent payment owner to avoid repetitive derivation
  SilentPaymentOwner? _silentPaymentOwner;

  // Cached labeled addresses
  final Map<int, SilentPaymentAddress> _labeledAddresses = {};

  /// Whether Silent Payment scanning is enabled for this wallet
  Future<bool> get isSilentPaymentScanningEnabled async {
    final config = await _getSilentPaymentConfig();
    return config?.isEnabled ?? false;
  }

  /// Set whether Silent Payment scanning is enabled
  Future<void> setSilentPaymentScanningEnabled(bool enabled) async {
    final config = await _getSilentPaymentConfig();
    if (config != null) {
      await config.updateEnabled(enabled: enabled, isar: mainDB.isar);
    } else {
      await mainDB.isar.writeTxn(() async {
        await mainDB.isar.silentPaymentConfig.put(
          SilentPaymentConfig(walletId: walletId, isEnabled: enabled),
        );
      });
    }
  }

  /// Get the wallet's Silent Payment address
  ///
  /// Returns the base Silent Payment address for this wallet
  Future<String> getSilentPaymentAddress() async {
    final owner = await _getSilentPaymentOwner();
    return owner.toString(network: _getNetworkString());
  }

  /// Get the wallet's Silent Payment address with a specific label
  ///
  /// Labels allow a single Silent Payment address to be shared while
  /// still allowing different addresses to be generated for different
  /// uses or senders
  Future<String> getLabeledSilentPaymentAddress(int label) async {
    final owner = await _getSilentPaymentOwner();

    if (!_labeledAddresses.containsKey(label)) {
      _labeledAddresses[label] = owner.toLabeledAddress(label);
    }

    return _labeledAddresses[label]!.toString(network: _getNetworkString());
  }

  /// Derive the recipient address(es) for a Silent Payment transaction
  ///
  /// This can be used with your existing prepareSend method:
  /// ```
  /// final selectedUtxos = await wallet.coinSelection(...);
  /// final recipientAddress = await wallet.deriveSilentPaymentAddress("sp1...", selectedUtxos);
  /// wallet.prepareSend(txData: TxData(recipients: [(address: recipientAddress, amount: amount)]));
  /// ```
  Future<String> deriveSilentPaymentAddress(
    String silentPaymentAddress,
    List<UTXO> selectedUtxos, {
    int amount = 0,
  }) async {
    // Validate the recipient address
    if (!SilentPaymentAddress.regex.hasMatch(silentPaymentAddress)) {
      throw Exception("Invalid Silent Payment address format");
    }

    // Ensure we have UTXOs to work with
    if (selectedUtxos.isEmpty) {
      throw Exception("No UTXOs provided for the transaction");
    }

    // Create a destination from the address
    final destination = SilentPaymentDestination.fromAddress(
      silentPaymentAddress,
      amount,
    );

    // Extract outpoints from selected UTXOs
    final outpoints =
        selectedUtxos
            .map((utxo) => coinlib.OutPoint.fromHex(utxo.txid, utxo.vout))
            .toList();

    // Get private keys for the inputs needed by the Silent Payment builder
    final inputPrivKeyInfos = <ECPrivateInfo>[];
    final pubKeys = <coinlib.ECPublicKey>[];

    for (final utxo in selectedUtxos) {
      final address = utxo.address!;
      // TODO: convert to 'Address' type
      final privkey = await getPrivateKey(address);
      final isP2TR = address.startsWith('bc1p') || address.startsWith('tb1p');

      inputPrivKeyInfos.add(
        ECPrivateInfo(privkey, isP2TR, needsTweaking: isP2TR),
      );

      pubKeys.add(privkey.pubkey);
    }

    // Create the Silent Payment Builder
    final builder = SilentPaymentBuilder(
      outpoints: outpoints,
      publicKeys: pubKeys,
      hrp: info.coin.network == CryptoCurrencyNetwork.main ? 'bc' : 'tb',
    );

    // Create the outputs - this is where the Silent Payment magic happens
    final outputMap = builder.createOutputs(inputPrivKeyInfos, [destination]);

    // Extract the first output for the given destination
    if (outputMap.isEmpty ||
        !outputMap.containsKey(silentPaymentAddress) ||
        outputMap[silentPaymentAddress]!.isEmpty) {
      throw Exception("Failed to derive Silent Payment address");
    }

    return outputMap[silentPaymentAddress]!.first.address.toString();
  }

  /// Derive multiple recipient addresses for a batch of Silent Payment recipients
  ///
  /// This is useful for sending to multiple Silent Payment addresses in one transaction.
  Future<List<String>> deriveSilentPaymentAddresses(
    Map<String, int> silentPaymentAddressesWithAmounts,
    List<UTXO> selectedUtxos,
  ) async {
    if (silentPaymentAddressesWithAmounts.isEmpty) {
      return [];
    }

    // Ensure we have UTXOs to work with
    if (selectedUtxos.isEmpty) {
      throw Exception("No UTXOs provided for the transaction");
    }

    // Create destinations from the addresses
    final destinations =
        silentPaymentAddressesWithAmounts.entries
            .map(
              (entry) =>
                  SilentPaymentDestination.fromAddress(entry.key, entry.value),
            )
            .toList();

    // Extract outpoints from selected UTXOs
    final outpoints =
        selectedUtxos
            .map((utxo) => coinlib.OutPoint.fromHex(utxo.txid, utxo.vout))
            .toList();

    // Get private keys for the inputs needed by the Silent Payment builder
    final inputPrivKeyInfos = <ECPrivateInfo>[];
    final pubKeys = <coinlib.ECPublicKey>[];

    for (final utxo in selectedUtxos) {
      final address = utxo.address!;
      final privkey = await getPrivateKey(address);
      final isP2TR = address.startsWith('bc1p') || address.startsWith('tb1p');

      inputPrivKeyInfos.add(
        ECPrivateInfo(privkey, isP2TR, needsTweaking: isP2TR),
      );

      pubKeys.add(privkey.pubkey);
    }

    // Create the Silent Payment Builder
    final builder = SilentPaymentBuilder(
      outpoints: outpoints,
      publicKeys: pubKeys,
      hrp: info.coin.network == CryptoCurrencyNetwork.main ? 'bc' : 'tb',
    );

    // Create the outputs - this is where the Silent Payment magic happens
    final outputMap = builder.createOutputs(inputPrivKeyInfos, destinations);

    // Extract all derived addresses
    final derivedAddresses = <String>[];
    for (final outputs in outputMap.values) {
      for (final output in outputs) {
        derivedAddresses.add(output.address.toString());
      }
    }

    return derivedAddresses;
  }

  /// Scan for Silent Payments in recent transactions
  ///
  /// This method checks recent blocks for transactions that contain
  /// Silent Payments to this wallet.
  ///
  /// Returns a list of detected outputs with their details
  Future<List<Map<String, dynamic>>> scanForSilentPayments({
    int? fromHeight,
    int? toHeight,
  }) async {
    final isEnabled = await isSilentPaymentScanningEnabled;
    if (!isEnabled) {
      return [];
    }

    // Get the config to determine last scanned height
    final config = await _getSilentPaymentConfig();
    if (config == null) {
      return [];
    }

    // Get heights to scan
    final currentHeight = await chainHeight;
    final scanFromHeight =
        fromHeight ??
        (config.lastScannedHeight > 0
            ? config.lastScannedHeight + 1
            : currentHeight - 10);
    final scanToHeight = toHeight ?? currentHeight;

    final foundOutputs = <Map<String, dynamic>>[];

    // Get the Silent Payment owner
    final owner = await _getSilentPaymentOwner();

    // Initialize precomputed labels from the config
    final labelMap = config.labelMap;

    // Scan each block in the range
    for (int height = scanFromHeight; height <= scanToHeight; height++) {
      // Get transactions in the block
      final blockHeader = await electrumXClient.getBlockHeadTip();

      // TODO: Figure out how to get block tx data!
      final txids = await getBlockTransactions(blockHeader['id']);
      if (txids.isEmpty) continue;

      // Process each transaction
      for (final txid in txids) {
        final tx = await getTransaction(txid);
        if (tx == null) continue;

        // Get inputs and outputs
        final inputs = tx['vin'] as List<dynamic>;
        final outputs = tx['vout'] as List<dynamic>;

        // Skip transactions with no inputs or outputs
        if (inputs.isEmpty || outputs.isEmpty) continue;

        // Collect outpoints and input public keys
        final outpoints = <coinlib.OutPoint>[];
        final pubKeys = <coinlib.ECPublicKey>[];

        for (final input in inputs) {
          final prevTxid = input['txid'];
          final prevVout = input['vout'];

          if (prevTxid == null || prevVout == null) continue;

          outpoints.add(coinlib.OutPoint.fromHex(prevTxid, prevVout));

          // Extract public key from input
          final witnessData = input['txinwitness'];
          if (witnessData is List && witnessData.isNotEmpty) {
            try {
              final pubkeyHex = witnessData.last;
              pubKeys.add(coinlib.ECPublicKey.fromHex(pubkeyHex));
            } catch (_) {
              // Skip if unable to extract public key
              continue;
            }
          }
        }

        // Skip if unable to extract public keys
        if (pubKeys.isEmpty) continue;

        // Create SilentPaymentBuilder to scan outputs
        final builder = SilentPaymentBuilder(
          outpoints: outpoints,
          publicKeys: pubKeys,
          hrp: info.coin.network == CryptoCurrencyNetwork.main ? 'bc' : 'tb',
        );

        // Convert outputs to format expected by scanner
        final outputsToCheck = <coinlib.Output>[];
        for (final output in outputs) {
          final scriptPubKey = output['scriptPubKey'];
          if (scriptPubKey == null) continue;

          final hexScript = scriptPubKey['hex'];
          final value = output['value'] ?? 0;

          if (hexScript == null) continue;

          try {
            outputsToCheck.add(
              coinlib.Output.fromScriptBytes(
                BigInt.from(value * 100000000), // Convert BTC to satoshis
                hexToBytes(hexScript),
              ),
            );
          } catch (_) {
            continue;
          }
        }

        // Scan for outputs belonging to this wallet
        final scanResults = builder.scanOutputs(
          owner,
          outputsToCheck,
          precomputedLabels: labelMap,
        );

        // Process found outputs
        for (final result in scanResults.entries) {
          final output = result.value.output;
          final label = result.value.label;

          foundOutputs.add({
            'txid': txid,
            'address': output.address.toString(),
            'amount': output.amount,
            'label': label,
            'derivedPrivateKey': bytesToHex(
              owner.b_spend.tweak(hexToBytes(result.value.tweak))!.data,
            ),
          });

          // Import the address to the wallet for tracking
          await importAddress(
            output.address.toString(),
            AddressType.p2tr,
            isChange: false,
          );
        }
      }
    }

    // Update the last scanned height
    if (scanToHeight > config.lastScannedHeight) {
      await config.updateLastScannedHeight(height: scanToHeight, isar: mainDB);
    }

    return foundOutputs;
  }

  /// Add a label for the wallet's Silent Payment address
  ///
  /// Returns the labeled address
  Future<String> addSilentPaymentLabel(int label) async {
    final owner = await _getSilentPaymentOwner();
    final labeledAddress = owner.toLabeledAddress(label);

    // Get or create the config
    var config = await _getSilentPaymentConfig();
    if (config == null) {
      await mainDB.writeTxn(() async {
        await mainDB.silentPaymentConfig.put(
          SilentPaymentConfig(walletId: walletId),
        );
      });
      config = await _getSilentPaymentConfig();
    }

    if (config != null) {
      // Generate label data
      final generatedLabel = owner.generateLabel(label);
      final G = ECPublicKey(ECCurve_secp256k1().G.getEncoded(true));

      // Add to the config's label map
      final labelMap = config.labelMap ?? {};
      labelMap[bytesToHex(tweakMulPublic(G, generatedLabel))] = bytesToHex(
        generatedLabel,
      );

      await config.updateLabelMap(newLabelMap: labelMap, isar: mainDB);
    }

    // Update cache
    _labeledAddresses[label] = labeledAddress;

    return labeledAddress.toString(network: _getNetworkString());
  }

  /// Remove a label from the wallet's Silent Payment address
  Future<void> removeSilentPaymentLabel(int label) async {
    final config = await _getSilentPaymentConfig();
    if (config == null || config.labelMap == null || config.labelMap!.isEmpty) {
      return;
    }

    // Generate label data
    final owner = await _getSilentPaymentOwner();
    final generatedLabel = owner.generateLabel(label);
    final G = ECPublicKey(ECCurve_secp256k1().G.getEncoded(true));
    final labelKey = bytesToHex(tweakMulPublic(G, generatedLabel));

    // Check if the label exists
    if (!config.labelMap!.containsKey(labelKey)) return;

    // Create new map without this label
    final updatedMap = Map<String, String>.from(config.labelMap!);
    updatedMap.remove(labelKey);

    // Update the config
    await config.updateLabelMap(newLabelMap: updatedMap, isar: mainDB);

    // Update cache
    _labeledAddresses.remove(label);
  }

  /// Get all Silent Payment labels for this wallet
  Future<List<int>> getSilentPaymentLabels() async {
    final config = await _getSilentPaymentConfig();
    if (config == null || config.labelMap == null || config.labelMap!.isEmpty) {
      return [];
    }

    // We need to regenerate the numeric labels from the stored label data
    // This is a brute force approach but works for reasonable numbers of labels
    final labelMap = config.labelMap!;
    final owner = await _getSilentPaymentOwner();
    final G = ECPublicKey(ECCurve_secp256k1().G.getEncoded(true));

    final labels = <int>[];
    for (int i = 0; i < 1000; i++) {
      // Arbitrary limit
      final generatedLabel = owner.generateLabel(i);
      final labelKey = bytesToHex(tweakMulPublic(G, generatedLabel));

      if (labelMap.containsKey(labelKey)) {
        labels.add(i);
      }
    }

    return labels;
  }

  // Helper method to get the wallet's SilentPaymentOwner
  Future<SilentPaymentOwner> _getSilentPaymentOwner() async {
    if (_silentPaymentOwner != null) {
      return _silentPaymentOwner!;
    }

    final rootNode = await getRootHDNode();
    _silentPaymentOwner = SilentPaymentOwner.fromBip32(rootNode);

    return _silentPaymentOwner!;
  }

  // Helper method to get the SilentPaymentConfig
  Future<SilentPaymentConfig?> _getSilentPaymentConfig() async {
    return mainDB.isar.silentPaymentConfig
        .where()
        .walletIdEqualTo(walletId)
        .findFirst();
  }

  // Helper method to get the network string in the format expected by SilentPayments
  String _getNetworkString() {
    switch (info.coin.network) {
      case CryptoCurrencyNetwork.main:
        return 'BitcoinNetwork.mainnet';
      case CryptoCurrencyNetwork.test:
      case CryptoCurrencyNetwork.test4:
        return 'BitcoinNetwork.testnet';
      default:
        return 'BitcoinNetwork.regtest';
    }
  }
}
