import 'dart:async';
import 'dart:convert';

import 'package:blockchain_utils/bip/bip/bip39/bip39_seed_generator.dart';
import 'package:blockchain_utils/bip/bip/bip44/bip44_base.dart';
import 'package:blockchain_utils/bip/bip/conf/bip44/bip44_coins.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:isar_community/isar.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

import '../../../exceptions/wallet/node_tor_mismatch_config_exception.dart';
import '../../../models/balance.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/keys/view_only_wallet_data.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/test_xrp_node_connection.dart';
import '../../../utilities/tor_plain_net_option_enum.dart';
import '../../api/xrp/xrp_rpc_client.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../models/tx_data.dart';
import '../intermediate/bip39_wallet.dart';
import '../wallet.dart';
import '../wallet_mixin_interfaces/private_key_interface.dart';
import '../wallet_mixin_interfaces/view_only_option_interface.dart';

/// XRP Ledger wallet: derivation, reserve-aware balance, transaction history,
/// chain height, node health, and sending (Payment with sequence +
/// LastLedgerSequence, destination tags / X-addresses, activation guard).
///
/// Modelled on [StellarWallet]. XRP is account-based; amounts are integer
/// "drops" (1 XRP = 1,000,000 drops), so — unlike the Stellar impl — balances
/// are parsed straight from integer strings (no float) and the account reserve
/// is subtracted from the spendable balance. Token (IOU/MPT) support is not
/// included; only native XRP payments are handled.
class XrpWallet extends Bip39Wallet<Xrp>
    with ViewOnlyOptionInterface<Xrp>, PrivateKeyInterface<Xrp> {
  XrpWallet(CryptoCurrencyNetwork network) : super(Xrp(network));

  /// Whether [seed] is a valid XRPL family seed (e.g. `sEd7…` / `s…`), used
  /// when importing an existing XRP-native wallet's secret.
  static bool isValidFamilySeed(String seed) {
    try {
      XRPPrivateKey.fromSeed(seed.trim());
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Whether [tag] is a valid XRP destination tag: a uint32 (0..4294967295),
  /// or null for "no tag". Out-of-range/negative values must be rejected rather
  /// than passed to the serializer, which would silently truncate/wrap them
  /// (e.g. 0x1_0000_0000 -> 0) and misdirect an exchange deposit.
  static bool isValidDestinationTag(int? tag) =>
      tag == null || (tag >= 0 && tag <= 0xFFFFFFFF);

  ({String host, int port}) get _nodeInfo {
    final node = getCurrentNode();
    return (host: node.host, port: node.port);
  }

  /// Rejects a node whose Tor/clearnet setting is incompatible with the current
  /// Tor preference (mirrors StellarWallet._hackedCheck).
  void _torConfigCheck() {
    final node = getCurrentNode();
    final netOption = TorPlainNetworkOption.fromNodeData(
      node.torEnabled,
      node.clearnetEnabled,
    );

    if (prefs.useTor) {
      if (netOption == TorPlainNetworkOption.clear) {
        throw NodeTorMismatchConfigException(
          message: "TOR enabled but node set to clearnet only",
        );
      }
    } else {
      if (netOption == TorPlainNetworkOption.tor) {
        throw NodeTorMismatchConfigException(
          message: "TOR off but node set to TOR only",
        );
      }
    }
  }

  /// The signing key. If the wallet was imported from an XRPL family seed
  /// (stored as a private key), decode it directly; otherwise derive from the
  /// BIP39 mnemonic at BIP44 `m/44'/144'/0'/0/0` (secp256k1). The address is
  /// computed via xrpl_dart from this exact key so the receiving address is
  /// always the one our signing key controls.
  Future<XRPPrivateKey> _signingKey() async {
    final stored = await secureStorageInterface.read(
      key: Wallet.privateKeyKey(walletId: walletId),
    );
    if (stored != null && stored.isNotEmpty) {
      return XRPPrivateKey.fromSeed(stored.trim());
    }

    final seed = Bip39SeedGenerator(
      Mnemonic.fromString(await getMnemonic()),
    ).generate(await getMnemonicPassphrase());
    final node = Bip44.fromSeed(seed, Bip44Coins.ripple).deriveDefaultPath;
    return XRPPrivateKey.fromBytes(
      node.privateKey.raw,
      algorithm: XRPKeyAlgorithm.secp256k1,
    );
  }

  Future<Address> _fetchXrpAddress({int index = 0}) async {
    final public = (await _signingKey()).getPublic();

    return Address(
      walletId: walletId,
      value: public.toAddress().toAddress(),
      publicKey: public.toBytes(),
      derivationIndex: index,
      derivationPath: null,
      type: AddressType.xrp,
      subType: AddressSubType.receiving,
    );
  }

  Amount _drops(BigInt raw) =>
      Amount(rawValue: raw, fractionDigits: cryptoCurrency.fractionDigits);

  // ============== Overrides ==================================================

  @override
  int get isarTransactionVersion => 2;

  @override
  FilterOperation? get changeAddressFilterOperation =>
      FilterGroup.and(standardChangeAddressFilters);

  @override
  FilterOperation? get receivingAddressFilterOperation =>
      FilterGroup.and(standardReceivingAddressFilters);

  @override
  Future<void> checkSaveInitialReceivingAddress() async {
    try {
      final address = await getCurrentReceivingAddress();
      if (address == null) {
        if (isViewOnly) {
          await recoverViewOnly();
        } else {
          await mainDB.updateOrPutAddresses([await _fetchXrpAddress(index: 0)]);
        }
      }
    } catch (e, s) {
      // do nothing, still allow user into wallet
      Logging.instance.e(
        "$runtimeType checkSaveInitialReceivingAddress() failed: ",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> recover({required bool isRescan}) async {
    if (isViewOnly) {
      await recoverViewOnly(isRescan: isRescan);
      return;
    }

    await refreshMutex.protect(() async {
      if (isRescan) {
        await mainDB.deleteWalletBlockchainData(walletId);
      }
      await mainDB.updateOrPutAddresses([await _fetchXrpAddress(index: 0)]);
    });

    if (isRescan) {
      unawaited(refresh());
    }
  }

  @override
  Future<void> recoverViewOnly({bool isRescan = false}) async {
    final data = await getViewOnlyWalletData();
    if (data is! AddressViewOnlyWalletData) {
      throw Exception("XRP view-only wallets must be address-only");
    }

    // Normalize to a classic r-address (also accepts X-addresses); throws if
    // the stored value is not a valid XRP address.
    final classic = XRPAddress(data.address, allowXAddress: true).address;

    await refreshMutex.protect(() async {
      if (isRescan) {
        await mainDB.deleteWalletBlockchainData(walletId);
      }
      await mainDB.updateOrPutAddresses([
        Address(
          walletId: walletId,
          value: classic,
          publicKey: const [],
          derivationIndex: 0,
          derivationPath: null,
          type: AddressType.xrp,
          subType: AddressSubType.receiving,
        ),
      ]);
    });

    if (isRescan) {
      unawaited(refresh());
    }
  }

  @override
  Future<void> updateBalance() async {
    try {
      _torConfigCheck();
      final address = (await getCurrentReceivingAddress())?.value;
      if (address == null) return;

      final account = await XrpRpcClient.accountInfo(
        nodeInfo: _nodeInfo,
        address: address,
      );

      // Unactivated account: no XRP on-ledger yet.
      if (account == null) {
        await info.updateBalance(
          newBalance: Balance(
            total: _drops(BigInt.zero),
            spendable: _drops(BigInt.zero),
            blockedTotal: _drops(BigInt.zero),
            pendingSpendable: _drops(BigInt.zero),
          ),
          isar: mainDB.isar,
        );
        return;
      }

      final server = await XrpRpcClient.serverState(nodeInfo: _nodeInfo);
      final feeDrops = await XrpRpcClient.baseFeeDrops(nodeInfo: _nodeInfo);
      final reserve =
          server.baseReserveDrops +
          (BigInt.from(account.ownerCount) * server.ownerReserveDrops);
      final total = account.balanceDrops;
      // Hold back the reserve (locked by protocol) plus one transaction fee so
      // the displayed spendable is actually sendable in a single Payment: XRPL
      // rejects a payment that would push the balance below the reserve, and
      // such a rejection still burns the fee. Without the fee held back, a
      // "send all" of the displayed spendable would always fail on-ledger.
      final available = total - reserve - feeDrops;
      final spendable = available < BigInt.zero ? BigInt.zero : available;

      await info.updateBalance(
        newBalance: Balance(
          total: _drops(total),
          spendable: _drops(spendable),
          blockedTotal: _drops(reserve),
          pendingSpendable: _drops(BigInt.zero),
        ),
        isar: mainDB.isar,
      );
    } catch (e, s) {
      Logging.instance.w(
        "$runtimeType ${info.name} $walletId updateBalance() failed: $e",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateChainHeight() async {
    try {
      _torConfigCheck();
      final server = await XrpRpcClient.serverState(nodeInfo: _nodeInfo);
      await info.updateCachedChainHeight(
        newHeight: server.ledgerIndex,
        isar: mainDB.isar,
      );
    } catch (e, s) {
      Logging.instance.e(
        "$runtimeType updateChainHeight() failed: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateTransactions() async {
    try {
      _torConfigCheck();
      final myAddress = (await getCurrentReceivingAddress())?.value;
      if (myAddress == null) return;

      final entries = await XrpRpcClient.accountTx(
        nodeInfo: _nodeInfo,
        address: myAddress,
      );

      final List<TransactionV2> transactionList = [];
      for (final entry in entries) {
        final tx = Map<String, dynamic>.from((entry["tx"] as Map?) ?? {});

        // PR1: native XRP Payments only. Token (IOU) payments carry an object
        // `Amount` instead of a drops string and are handled in a later PR.
        if (tx["TransactionType"] != "Payment") continue;
        final amountField = tx["Amount"];
        if (amountField is! String) continue;

        final amountDrops = BigInt.parse(amountField);
        final from = tx["Account"]?.toString() ?? "";
        final to = tx["Destination"]?.toString() ?? "";

        final TransactionType type;
        if (from == myAddress) {
          type = to == myAddress
              ? TransactionType.sentToSelf
              : TransactionType.outgoing;
        } else {
          type = TransactionType.incoming;
        }

        final feeDrops =
            BigInt.tryParse(tx["Fee"]?.toString() ?? "0") ?? BigInt.zero;
        final ledgerIndex =
            int.tryParse(
              (tx["ledger_index"] ?? entry["ledger_index"] ?? 0).toString(),
            ) ??
            0;
        // XRPL "ripple epoch" is seconds since 2000-01-01 UTC.
        final rippleDate = int.tryParse(tx["date"]?.toString() ?? "0") ?? 0;
        final timestamp = rippleDate + 946684800;
        final hash = (tx["hash"] ?? entry["hash"] ?? "").toString();

        final output = OutputV2.isarCantDoRequiredInDefaultConstructor(
          scriptPubKeyHex: "00",
          valueStringSats: amountDrops.toString(),
          addresses: [to],
          walletOwns: to == myAddress,
        );
        final input = InputV2.isarCantDoRequiredInDefaultConstructor(
          scriptSigHex: null,
          scriptSigAsm: null,
          sequence: null,
          outpoint: null,
          addresses: [from],
          valueStringSats: amountDrops.toString(),
          witness: null,
          innerRedeemScriptAsm: null,
          coinbase: null,
          walletOwns: from == myAddress,
        );

        final otherData = <String, dynamic>{
          "overrideFee": _drops(feeDrops).toJsonString(),
          if (tx["DestinationTag"] != null)
            "destinationTag": tx["DestinationTag"],
        };

        transactionList.add(
          TransactionV2(
            walletId: walletId,
            blockHash: "",
            hash: hash,
            txid: hash,
            timestamp: timestamp,
            height: ledgerIndex,
            inputs: [input],
            outputs: [output],
            version: -1,
            type: type,
            subType: TransactionSubType.none,
            otherData: jsonEncode(otherData),
          ),
        );
      }

      await mainDB.updateOrPutTransactionV2s(transactionList);
    } catch (e, s) {
      Logging.instance.e(
        "$runtimeType updateTransactions() failed: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateNode() async {
    // Stateless RPC client (reads the current node per call); nothing to
    // rebuild. A refresh is triggered by the caller.
  }

  @override
  Future<bool> updateUTXOs() async {
    // No UTXOs for XRP.
    return false;
  }

  @override
  Future<bool> pingCheck() async {
    try {
      final node = getCurrentNode();
      return await testXrpNodeConnection(node.host, node.port);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<FeeObject> get fees async {
    final fee = await XrpRpcClient.baseFeeDrops(nodeInfo: _nodeInfo);
    return FeeObject(
      numberOfBlocksFast: 1,
      numberOfBlocksAverage: 1,
      numberOfBlocksSlow: 1,
      fast: fee,
      medium: fee,
      slow: fee,
    );
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async {
    final fee = await XrpRpcClient.baseFeeDrops(nodeInfo: _nodeInfo);
    return _drops(fee);
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) async {
    if (isViewOnly) {
      throw Exception("Cannot send from a watch-only wallet");
    }
    _torConfigCheck();

    if (txData.recipients?.length != 1) {
      throw Exception("XRP supports exactly one recipient per transaction");
    }
    final recipient = txData.recipients!.first;
    if (recipient.amount.raw <= BigInt.zero) {
      throw Exception("Invalid send amount");
    }

    // Parse the destination (classic or X-address); throws if invalid. An
    // X-address carries its own destination tag which takes precedence.
    final parsed = XRPAddress(recipient.address, allowXAddress: true);
    final tag = parsed.tag ?? txData.xrpDestinationTag;
    if (!isValidDestinationTag(tag)) {
      throw Exception(
        "Invalid destination tag: must be between 0 and 4294967295",
      );
    }

    final feeDrops = await XrpRpcClient.baseFeeDrops(nodeInfo: _nodeInfo);

    // Activation guard: paying an unactivated account less than the base
    // reserve fails on-ledger (tecNO_DST_INSUF_XRP) and burns the fee.
    final destInfo = await XrpRpcClient.accountInfo(
      nodeInfo: _nodeInfo,
      address: parsed.address,
    );
    if (destInfo == null) {
      final server = await XrpRpcClient.serverState(nodeInfo: _nodeInfo);
      if (recipient.amount.raw < server.baseReserveDrops) {
        throw Exception(
          "Destination account is not activated. The first payment to it "
          "must be at least the base reserve "
          "(${_drops(server.baseReserveDrops).decimal} XRP) to activate it.",
        );
      }
    }

    return txData.copyWith(fee: _drops(feeDrops), xrpDestinationTag: tag);
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    if (isViewOnly) {
      throw Exception("Cannot send from a watch-only wallet");
    }
    _torConfigCheck();

    final recipient = txData.recipients!.first;
    final amountDrops = recipient.amount.raw;

    final parsed = XRPAddress(recipient.address, allowXAddress: true);
    final classicDest = parsed.address;
    final tag = parsed.tag ?? txData.xrpDestinationTag;

    final key = await _signingKey();
    final public = key.getPublic();
    final myAddress = public.toAddress().toAddress();

    // Fresh sequence + current ledger, right before signing.
    final account = await XrpRpcClient.accountInfo(
      nodeInfo: _nodeInfo,
      address: myAddress,
    );
    if (account == null) {
      throw Exception("Source account is not activated (no XRP on-ledger)");
    }
    final server = await XrpRpcClient.serverState(nodeInfo: _nodeInfo);

    final feeDrops =
        txData.fee?.raw ?? await XrpRpcClient.baseFeeDrops(nodeInfo: _nodeInfo);

    final payment = Payment(
      account: myAddress,
      destination: classicDest,
      amount: CurrencyAmount.xrp(amountDrops),
      destinationTag: tag,
      fee: feeDrops,
      sequence: account.sequence,
      // Deterministic finality window: expire if not validated soon.
      lastLedgerSequence: server.ledgerIndex + 20,
      // Set the signing public key so it is part of the signing blob.
      signer: XRPLSignature.signer(public.toHex()),
    );

    // Sign the serialized transaction, attach the signature, re-serialize.
    final signature = key.sign(payment.toBlob());
    payment.setSignature(signature);
    final signedBlob = payment.toBlob(forSigning: false);

    final engineResult = await XrpRpcClient.submit(
      nodeInfo: _nodeInfo,
      txBlobHex: signedBlob,
    );

    // tesSUCCESS = applied. tec* = a claimed-cost result: the tx WAS included
    // (fee burned, sequence consumed) but did not achieve its goal — surface
    // it as an error so the user knows it failed even though it "sent".
    if (engineResult != "tesSUCCESS") {
      throw Exception("XRP transaction failed to apply: $engineResult");
    }

    final txid = payment.getHash();
    return txData.copyWith(txid: txid, txHash: txid);
  }
}
