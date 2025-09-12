import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_libmwc/lib.dart' as mwc;

import '../models/mwcmqs_config_model.dart';
import '../utilities/amount/amount.dart';
import '../utilities/default_mwcmqs.dart';
import '../utilities/logger.dart';
import '../utilities/stack_file_system.dart';

/// Service layer that wraps flutter_libmwc FFI functions for Stack Wallet integration.
///
/// Based on the flutter_libmwc example WalletService but adapted for Stack Wallet patterns.
class MwcWalletService {
  static bool _isInitialized = false;
  static final Map<String, String> _walletHandles = {};

  /// Initialize the MWC wallet service.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    Logging.instance.i('MWC Wallet Service initialized');
    _isInitialized = true;
  }

  /// Create a new MWC wallet.
  static Future<MwcWalletResult> createWallet({
    required String walletId,
    required String password,
    String? customMnemonic,
  }) async {
    try {
      Logging.instance.i('Creating MWC wallet: $walletId');

      final config = await _getWalletConfig(walletId);
      final mnemonic = customMnemonic ?? mwc.Libmwc.getMnemonic();

      final result = await mwc.Libmwc.initializeNewWallet(
        config: config,
        mnemonic: mnemonic,
        password: password,
        name: walletId,
      );

      if (result.toUpperCase().contains('ERROR')) {
        return MwcWalletResult(
          success: false,
          error: 'Failed to create wallet: $result',
        );
      }

      _walletHandles[walletId] = result;

      Logging.instance.i('MWC wallet created successfully: $walletId');
      return MwcWalletResult(
        success: true,
        walletId: walletId,
        data: {'mnemonic': mnemonic, 'handle': result},
      );
    } catch (e, s) {
      Logging.instance.e('Failed to create MWC wallet: $e\n$s');
      return MwcWalletResult(
        success: false,
        error: 'Failed to create wallet: $e',
      );
    }
  }

  /// Recover MWC wallet from mnemonic.
  static Future<MwcWalletResult> recoverWallet({
    required String walletId,
    required String password,
    required String mnemonic,
  }) async {
    try {
      Logging.instance.i('Recovering MWC wallet: $walletId');

      final config = await _getWalletConfig(walletId);

      await mwc.Libmwc.recoverWallet(
        config: config,
        password: password,
        mnemonic: mnemonic,
        name: walletId,
      );

      final openResult = await openWallet(
        walletId: walletId,
        password: password,
      );

      if (openResult.success) {
        Logging.instance.i('MWC wallet recovered successfully: $walletId');
        return MwcWalletResult(
          success: true,
          walletId: walletId,
          data: {'recovered': true},
        );
      }

      return openResult;
    } catch (e, s) {
      Logging.instance.e('Failed to recover MWC wallet: $e\n$s');
      return MwcWalletResult(
        success: false,
        error: 'Failed to recover wallet: $e',
      );
    }
  }

  /// Open an existing MWC wallet.
  static Future<MwcWalletResult> openWallet({
    required String walletId,
    required String password,
  }) async {
    try {
      Logging.instance.i('Opening MWC wallet: $walletId');

      final config = await _getWalletConfig(walletId);

      final result = await mwc.Libmwc.openWallet(
        config: config,
        password: password,
      );

      if (result.toUpperCase().contains('ERROR')) {
        return MwcWalletResult(
          success: false,
          error: 'Failed to open wallet: $result',
        );
      }

      _walletHandles[walletId] = result;

      Logging.instance.i('MWC wallet opened successfully: $walletId');
      return MwcWalletResult(
        success: true,
        walletId: walletId,
        data: {'handle': result},
      );
    } catch (e, s) {
      Logging.instance.e('Failed to open MWC wallet: $e\n$s');
      return MwcWalletResult(
        success: false,
        error: 'Failed to open wallet: $e',
      );
    }
  }

  /// Create a slatepack for sending MWC.
  static Future<SlatepackResult> createSlatepack({
    required String walletId,
    required Amount amount,
    String? recipientAddress,
    String? message,
    bool encrypt = false,
    int minimumConfirmations = 1,
  }) async {
    try {
      final handle = _walletHandles[walletId];
      if (handle == null) {
        return SlatepackResult(
          success: false,
          error: 'Wallet not open: $walletId',
        );
      }

      Logging.instance.i('Creating slatepack for wallet: $walletId');

      // Generate S1 slate JSON.
      final s1Json = await mwc.Libmwc.txInit(
        wallet: handle,
        amount: amount.raw.toInt(),
        minimumConfirmations: minimumConfirmations,
        selectionStrategyIsAll: false,
        message: message ?? '',
      );

      // Encode to slatepack.
      final slatepackEncode = await mwc.Libmwc.encodeSlatepack(
        slateJson: s1Json,
        recipientAddress: recipientAddress,
        encrypt: encrypt,
        wallet: handle,
      );

      Logging.instance.i('Slatepack created successfully');
      return SlatepackResult(
        success: true,
        slatepack: slatepackEncode.slatepack,
        slateJson: s1Json,
        wasEncrypted: slatepackEncode.wasEncrypted,
        recipientAddress: slatepackEncode.recipientAddress,
      );
    } catch (e, s) {
      Logging.instance.e('Failed to create slatepack: $e\n$s');
      return SlatepackResult(
        success: false,
        error: 'Failed to create slatepack: $e',
      );
    }
  }

  /// Decode a slatepack.
  static Future<SlatepackDecodeResult> decodeSlatepack({
    required String slatepack,
    String? walletId,
  }) async {
    try {
      Logging.instance.i('Decoding slatepack');

      // Use wallet-aware decode if wallet is open (handles encrypted slatepacks)
      final handle = walletId != null ? _walletHandles[walletId] : null;
      final result =
          (handle != null)
              ? await mwc.Libmwc.decodeSlatepackWithWallet(
                wallet: handle,
                slatepack: slatepack,
              )
              : await mwc.Libmwc.decodeSlatepack(slatepack: slatepack);

      Logging.instance.i('Slatepack decoded successfully');
      return SlatepackDecodeResult(
        success: true,
        slateJson: result.slateJson,
        wasEncrypted: result.wasEncrypted,
        senderAddress: result.senderAddress,
        recipientAddress: result.recipientAddress,
      );
    } catch (e, s) {
      Logging.instance.e('Failed to decode slatepack: $e\n$s');
      return SlatepackDecodeResult(
        success: false,
        error: 'Failed to decode slatepack: $e',
      );
    }
  }

  /// Receive a slatepack and return response slatepack.
  static Future<ReceiveResult> receiveSlatepack({
    required String walletId,
    required String slatepack,
  }) async {
    try {
      final handle = _walletHandles[walletId];
      if (handle == null) {
        return ReceiveResult(
          success: false,
          error: 'Wallet not open: $walletId',
        );
      }

      Logging.instance.i('Receiving slatepack for wallet: $walletId');

      // Decode to get slate JSON and sender address.
      final decoded = await decodeSlatepack(
        slatepack: slatepack,
        walletId: walletId,
      );
      if (!decoded.success || decoded.slateJson == null) {
        return ReceiveResult(
          success: false,
          error: decoded.error ?? 'Failed to decode slatepack',
        );
      }

      // Receive and get updated slate JSON.
      final received = await mwc.Libmwc.txReceiveDetailed(
        wallet: handle,
        slateJson: decoded.slateJson!,
      );

      // Encode response slatepack back to sender.
      final encoded = await mwc.Libmwc.encodeSlatepack(
        slateJson: received.slateJson,
        recipientAddress: decoded.senderAddress,
        encrypt: decoded.senderAddress != null,
        wallet: handle,
      );

      Logging.instance.i('Slatepack received successfully');
      return ReceiveResult(
        success: true,
        slateId: received.slateId,
        commitId: received.commitId,
        responseSlatepack: encoded.slatepack,
        wasEncrypted: encoded.wasEncrypted,
        recipientAddress: decoded.senderAddress,
      );
    } catch (e, s) {
      Logging.instance.e('Failed to receive slatepack: $e\n$s');
      return ReceiveResult(
        success: false,
        error: 'Failed to receive slatepack: $e',
      );
    }
  }

  /// Finalize a slatepack (sender step 3).
  static Future<FinalizeResult> finalizeSlatepack({
    required String walletId,
    required String slatepack,
  }) async {
    try {
      final handle = _walletHandles[walletId];
      if (handle == null) {
        return FinalizeResult(
          success: false,
          error: 'Wallet not open: $walletId',
        );
      }

      Logging.instance.i('Finalizing slatepack for wallet: $walletId');

      // Decode to get slate JSON.
      final decoded = await decodeSlatepack(
        slatepack: slatepack,
        walletId: walletId,
      );
      if (!decoded.success || decoded.slateJson == null) {
        return FinalizeResult(
          success: false,
          error: decoded.error ?? 'Failed to decode slatepack',
        );
      }

      // Finalize transaction.
      final finalized = await mwc.Libmwc.txFinalize(
        wallet: handle,
        slateJson: decoded.slateJson!,
      );

      Logging.instance.i('Slatepack finalized successfully');
      return FinalizeResult(
        success: true,
        slateId: finalized.slateId,
        commitId: finalized.commitId,
      );
    } catch (e, s) {
      Logging.instance.e('Failed to finalize slatepack: $e\n$s');
      return FinalizeResult(
        success: false,
        error: 'Failed to finalize slatepack: $e',
      );
    }
  }

  /// Start MWCMQS listener.
  static Future<void> startMwcmqsListener({
    required String walletId,
    MwcMqsConfigModel? config,
  }) async {
    try {
      final handle = _walletHandles[walletId];
      if (handle == null) {
        throw Exception('Wallet not open: $walletId');
      }

      Logging.instance.i('Starting MWCMQS listener for wallet: $walletId');

      final mwcmqsConfig =
          config ??
          MwcMqsConfigModel.fromServer(DefaultMwcMqs.defaultMwcMqsServer);

      mwc.Libmwc.startMwcMqsListener(
        wallet: handle,
        mwcmqsConfig: mwcmqsConfig.toString(),
      );

      Logging.instance.i('MWCMQS listener started successfully');
    } catch (e, s) {
      Logging.instance.e('Failed to start MWCMQS listener: $e\n$s');
      rethrow;
    }
  }

  /// Stop MWCMQS listener.
  static Future<void> stopMwcmqsListener() async {
    try {
      Logging.instance.i('Stopping MWCMQS listener');

      mwc.Libmwc.stopMwcMqsListener();

      Logging.instance.i('MWCMQS listener stopped successfully');
    } catch (e, s) {
      Logging.instance.e('Failed to stop MWCMQS listener: $e\n$s');
    }
  }

  /// Get MWCMQS address for wallet.
  static Future<String> getMwcmqsAddress({
    required String walletId,
    int index = 0,
  }) async {
    try {
      final handle = _walletHandles[walletId];
      if (handle == null) {
        throw Exception('Wallet not open: $walletId');
      }

      final address = await mwc.Libmwc.getAddressInfo(
        wallet: handle,
        index: index,
      );

      if (address.isEmpty) {
        throw Exception('Failed to generate MWCMQS address');
      }

      return address;
    } catch (e, s) {
      Logging.instance.e('Failed to get MWCMQS address: $e\n$s');
      rethrow;
    }
  }

  /// Validate MWC address.
  static bool validateAddress(String address) {
    try {
      return mwc.Libmwc.validateSendAddress(address: address);
    } catch (e, s) {
      Logging.instance.e('Failed to validate address: $e\n$s');
      return false;
    }
  }

  /// Generate mnemonic.
  static String generateMnemonic() {
    try {
      return mwc.Libmwc.getMnemonic();
    } catch (e, s) {
      Logging.instance.e('Failed to generate mnemonic: $e\n$s');
      rethrow;
    }
  }

  /// Check if wallet is open.
  static bool isWalletOpen(String walletId) {
    return _walletHandles.containsKey(walletId);
  }

  /// Close wallet.
  static void closeWallet(String walletId) {
    _walletHandles.remove(walletId);
  }

  /// Get wallet configuration.
  static Future<String> _getWalletConfig(String walletId) async {
    final walletDir = await _getWalletDirectory(walletId);

    final config = {
      'wallet_dir': walletDir,
      'check_node_api_http_addr': 'https://mwc713.mwc.mw:443',
      'chain': 'mainnet',
      'account': 'default',
    };

    return jsonEncode(config);
  }

  /// Get wallet directory path.
  static Future<String> _getWalletDirectory(String walletId) async {
    final Directory appDir = await StackFileSystem.applicationRootDirectory();
    final path = "${appDir.path}/mimblewimblecoin";
    final String name = walletId.trim();
    return '$path/$name';
  }
}

/// Result classes for MWC wallet operations.

class MwcWalletResult {
  final bool success;
  final String? walletId;
  final String? error;
  final Map<String, dynamic>? data;

  MwcWalletResult({
    required this.success,
    this.walletId,
    this.error,
    this.data,
  });
}

class SlatepackResult {
  final bool success;
  final String? error;
  final String? slatepack;
  final String? slateJson;
  final bool? wasEncrypted;
  final String? recipientAddress;

  SlatepackResult({
    required this.success,
    this.error,
    this.slatepack,
    this.slateJson,
    this.wasEncrypted,
    this.recipientAddress,
  });
}

class SlatepackDecodeResult {
  final bool success;
  final String? error;
  final String? slateJson;
  final bool? wasEncrypted;
  final String? senderAddress;
  final String? recipientAddress;

  SlatepackDecodeResult({
    required this.success,
    this.error,
    this.slateJson,
    this.wasEncrypted,
    this.senderAddress,
    this.recipientAddress,
  });
}

class ReceiveResult {
  final bool success;
  final String? error;
  final String? slateId;
  final String? commitId;
  final String? responseSlatepack;
  final bool? wasEncrypted;
  final String? recipientAddress;

  ReceiveResult({
    required this.success,
    this.error,
    this.slateId,
    this.commitId,
    this.responseSlatepack,
    this.wasEncrypted,
    this.recipientAddress,
  });
}

class FinalizeResult {
  final bool success;
  final String? error;
  final String? slateId;
  final String? commitId;

  FinalizeResult({
    required this.success,
    this.error,
    this.slateId,
    this.commitId,
  });
}
