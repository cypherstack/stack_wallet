import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';

import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/slatepack_models.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/enums/slatepack_method.dart';
import '../../../utilities/slatepack_terms.dart';
import '../../../utilities/logger.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../wallet.dart';

/// Slatepack exchange shared by the Mimblewimble coins. The slatepack
/// screens talk to this instead of a concrete wallet type.
///
mixin SlatepackInterface<T extends CryptoCurrency> on Wallet<T> {
  final Map<
    String,
    ({Amount amount, Amount fee, bool isSend, bool isCancelled})
  >
  _pendingSlateTransactions = {};

  /// Methods the send and receive screens offer. The first is the default.
  List<SlatepackMethod> get supportedMethods;

  /// Whether a send can carry a message that ends up on chain.
  bool get supportsOnChainNote;

  /// Whether this wallet can encrypt slatepacks to another wallet's address.
  bool get supportsSlatepackEncryption => false;

  /// Whether send/receive should offer a method selector.
  bool get hasSlatepackMethodToggle =>
      supportedMethods.any((method) => method != SlatepackMethod.slatepack);

  /// "slate" or "slatepack" wording for this coin.
  SlatepackTerms get slatepackTerms => SlatepackTerms.slatepack;

  /// Durable per-slate metadata owned by the concrete wallet. Existing relay
  /// address/commit data and the manual-send ownership marker share this map.
  @protected
  Map<dynamic, dynamic> get slatepackTransactionMetadata => const {};

  /// Persists [metadata] without requiring a native history refresh.
  @protected
  Future<void> updateSlatepackTransactionMetadata(
    Map<dynamic, dynamic> metadata,
  ) async {}

  /// The address another wallet encrypts a slatepack to.
  Future<String> slatepackAddress() async =>
      (await getCurrentReceivingAddress())?.value ?? "";

  /// Decode [armored] without changing wallet state.
  Future<SlatepackDecodeResult> decodeSlatepack(String armored);

  /// Reject text that is clearly not this coin's slate format before doing
  /// native work. Epic's JSON slates need no additional framing check.
  @protected
  void checkSlatepackFormat(String armored) {}

  /// Decode [armored] and work out its state without changing the wallet.
  /// Throws when the text cannot be decoded at all.
  Future<SlateInspection> inspectSlatepack(String armored) async {
    final text = armored.trim();
    if (text.isEmpty) {
      throw Exception("No ${slatepackTerms.noun} entered");
    }

    checkSlatepackFormat(text);
    final decoded = await decodeSlatepack(text);
    if (!decoded.success || decoded.slateJson == null) {
      if (decoded.failure == SlatepackDecodeFailure.walletUnavailable) {
        throw Exception(
          "This ${slatepackTerms.noun} could not be read because the wallet "
          "could not be opened. Try again.",
        );
      }
      final encryptionCause = supportsSlatepackEncryption
          ? ", incomplete, or encrypted for another wallet"
          : " or incomplete";
      throw Exception(
        "This ${slatepackTerms.noun} could not be decoded. It may be damaged"
        "$encryptionCause.",
      );
    }

    final dynamic json = jsonDecode(decoded.slateJson!);
    if (json is! Map) {
      throw Exception("Not a ${slatepackTerms.noun}");
    }

    final inspection = inspectSlateJson(
      json,
      fractionDigits: cryptoCurrency.fractionDigits,
      slateJson: decoded.slateJson,
      isEncrypted: decoded.wasEncrypted ?? false,
      senderAddress: decoded.senderAddress,
      recipientAddress: decoded.recipientAddress,
    );
    Logging.instance.d("Inspected ${slatepackTerms.noun}: $inspection");
    return inspection;
  }

  /// Amount, fee and status of this wallet's transaction for [slateId], or
  /// null when the wallet has none. `isSend` is true for a send this wallet
  /// started, which is the only kind it can finalize. A cancelled send must
  /// not be finalized.
  Future<({Amount amount, Amount fee, bool isSend, bool isCancelled})?>
  localTxForSlate(String slateId) async {
    if (slateId.isEmpty) return null;

    // A slate created in this process is authoritative and immediately
    // available, even while Isar is shutting down or before native history is
    // refreshed.
    final inMemory = _pendingSlateTransactions[slateId];
    if (inMemory != null) return inMemory;

    final tx = localSlateTransaction(
      await mainDB.isar.transactionV2s
          .where()
          .walletIdEqualTo(walletId)
          .filter()
          .otherDataContains(slateId)
          .findAll(),
      slateId,
    );
    final pending = pendingSlateSendMatching(
      slatepackTransactionMetadata,
      slateId,
      fractionDigits: cryptoCurrency.fractionDigits,
    );
    if (tx == null) return pending;

    final digits = cryptoCurrency.fractionDigits;
    final isSend = tx.type == TransactionType.outgoing;
    return (
      amount: isSend
          ? tx.getAmountSentFromThisWallet(
              fractionDigits: digits,
              subtractFee: true,
            )
          : tx.getAmountReceivedInThisWallet(fractionDigits: digits),
      fee: tx.getFee(fractionDigits: digits),
      isSend: isSend,
      isCancelled: tx.isCancelled || (isSend && pending?.isCancelled == true),
    );
  }

  /// Persists ownership as soon as an S1 is created, before a refresh can
  /// copy the native transaction into Isar.
  @protected
  Future<void> rememberPendingSlateSend(SlatepackResult result) async {
    final slateId = result.slateId;
    final amount = result.amount;
    final fee = result.fee;
    if (slateId == null || slateId.isEmpty || amount == null || fee == null) {
      return;
    }

    _pendingSlateTransactions[slateId] = (
      amount: amount,
      fee: fee,
      isSend: true,
      isCancelled: false,
    );

    final metadata = Map<dynamic, dynamic>.from(slatepackTransactionMetadata);
    final existing = metadata[slateId];
    final entry = existing is Map
        ? Map<String, dynamic>.from(existing)
        : <String, dynamic>{};
    entry.addAll({
      'amount': amount.raw.toString(),
      'fee': fee.raw.toString(),
      'isSend': true,
      'isCancelled': false,
    });
    metadata[slateId] = entry;
    try {
      await updateSlatepackTransactionMetadata(metadata);
    } catch (e, s) {
      Logging.instance.w(
        "Could not persist ownership for slate $slateId",
        error: e,
        stackTrace: s,
      );
    }
  }

  @protected
  Future<void> rememberPendingSlateCancelled(String slateId) async {
    final metadata = Map<dynamic, dynamic>.from(slatepackTransactionMetadata);
    final raw = metadata[slateId];
    final pending =
        _pendingSlateTransactions[slateId] ??
        pendingSlateSendMatching(
          metadata,
          slateId,
          fractionDigits: cryptoCurrency.fractionDigits,
        );
    if (pending == null) return;

    _pendingSlateTransactions[slateId] = (
      amount: pending.amount,
      fee: pending.fee,
      isSend: true,
      isCancelled: true,
    );

    final entry = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{
            'amount': pending.amount.raw.toString(),
            'fee': pending.fee.raw.toString(),
            'isSend': true,
          };
    entry['isCancelled'] = true;
    metadata[slateId] = entry;
    try {
      await updateSlatepackTransactionMetadata(metadata);
    } catch (e, s) {
      Logging.instance.w(
        "Could not persist cancellation for slate $slateId",
        error: e,
        stackTrace: s,
      );
    }
  }

  /// State, id, amount and fee for a native slate JSON result.
  @protected
  SlateInspection? inspectSlateJsonString(String? slateJson) {
    if (slateJson == null) return null;
    try {
      final dynamic json = jsonDecode(slateJson);
      if (json is! Map) return null;
      return inspectSlateJson(
        json,
        fractionDigits: cryptoCurrency.fractionDigits,
        slateJson: slateJson,
      );
    } catch (_) {
      return null;
    }
  }

  /// Start a send (S1). [message] is dropped when [supportsOnChainNote] is
  /// false. [recipientAddress] encrypts the slatepack to that address where
  /// the coin supports it.
  Future<SlatepackResult> createSlatepack({
    required Amount amount,
    String? recipientAddress,
    String? message,
  });

  /// Answer an S1 with an S2.
  Future<SlatepackResult> receiveSlatepack(
    String s1, {
    required SlateInspection inspection,
  });

  /// Finalize an S2 from the recipient and post it.
  Future<FinalizeResult> finalizeSlatepack(
    String s2, {
    required SlateInspection inspection,
  });

  /// Returns an empty String on success, error message on failure.
  Future<String> cancelPendingTransactionAndPost(String slateId);
}

/// Reads the small durable record written when a wallet creates an S1.
@visibleForTesting
({Amount amount, Amount fee, bool isSend, bool isCancelled})?
pendingSlateSendMatching(
  Map<dynamic, dynamic> metadata,
  String slateId, {
  required int fractionDigits,
}) {
  final raw = metadata[slateId];
  if (raw is! Map || raw['isSend'] != true) return null;

  final amount = BigInt.tryParse(raw['amount']?.toString() ?? '');
  final fee = BigInt.tryParse(raw['fee']?.toString() ?? '');
  if (amount == null || fee == null) return null;

  return (
    amount: Amount(rawValue: amount, fractionDigits: fractionDigits),
    fee: Amount(rawValue: fee, fractionDigits: fractionDigits),
    isSend: true,
    isCancelled: raw['isCancelled'] == true,
  );
}

/// Inspect Epic/MWC slate JSON without invoking either native wallet.
@visibleForTesting
SlateInspection inspectSlateJson(
  Map<dynamic, dynamic> json, {
  required int fractionDigits,
  String? slateJson,
  bool isEncrypted = false,
  String? senderAddress,
  String? recipientAddress,
}) {
  var state = SlateState.fromCode(json['sta']?.toString());
  final dynamic participants = json['participant_data'];
  if (state == SlateState.unknown &&
      participants is List &&
      participants.isNotEmpty) {
    var signed = 0;
    for (final dynamic participant in participants) {
      if (participant is Map && participant['part_sig'] != null) signed++;
    }
    if (signed == 0) {
      state = SlateState.s1;
    } else if (signed == 1) {
      state = SlateState.s2;
    } else if (signed >= participants.length) {
      state = SlateState.s3;
    }
  }

  if (state == SlateState.unknown) {
    if (senderAddress != null && recipientAddress != null) {
      state = SlateState.s2;
    } else if (senderAddress != null) {
      state = SlateState.s1;
    }
  }

  Amount? parseAmount(dynamic raw) {
    final value = BigInt.tryParse(raw?.toString() ?? "");
    final isResponse = state == SlateState.s2 || state == SlateState.i2;
    if (isResponse && value == BigInt.zero) return null;
    return value == null
        ? null
        : Amount(rawValue: value, fractionDigits: fractionDigits);
  }

  return SlateInspection(
    state: state,
    slateId: (json['id'] ?? '').toString(),
    slateJson: slateJson,
    amount: parseAmount(json['amount'] ?? json['amt']),
    fee: parseAmount(json['fee']),
    senderAddress: senderAddress,
    recipientAddress: recipientAddress,
    isEncrypted: isEncrypted,
    ttlCutoffHeight: int.tryParse(
      (json['ttl_cutoff_height'] ?? json['ttl'] ?? '').toString(),
    ),
  );
}

/// Exact local transaction for [slateId]. Sends win for self-transfers; a
/// live receive wins over a cancelled duplicate receive.
@visibleForTesting
TransactionV2? localSlateTransaction(
  Iterable<TransactionV2> candidates,
  String slateId,
) {
  TransactionV2? match;
  for (final tx in candidates) {
    if (tx.slateId != slateId) continue;
    if (tx.type == TransactionType.outgoing) return tx;
    if (match == null || (match.isCancelled && !tx.isCancelled)) {
      match = tx;
    }
  }
  return match;
}
