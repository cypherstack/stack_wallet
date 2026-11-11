import 'dart:convert';

import '../../../models/slatepack_models.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/enums/slatepack_method.dart';
import '../../../utilities/slatepack_terms.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../models/tx_data.dart';
import '../wallet.dart';

/// Slatepack exchange shared by the Mimblewimble coins. The slatepack
/// screens talk to this instead of a concrete wallet type.
///
/// The optional members (invoices, proofs, repost) default to unsupported so
/// Epic Cash and MWC only implement the standard send/receive round trip.
mixin SlatepackInterface<T extends CryptoCurrency> on Wallet<T> {
  /// Methods the send and receive screens offer. The first is the default.
  List<SlatepackMethod> get supportedMethods;

  /// Whether a send can carry a message that ends up on chain.
  bool get supportsOnChainNote;

  bool get supportsInvoices => false;

  bool get supportsPaymentProofs => false;

  /// "slate" or "slatepack" wording for this coin.
  SlatepackTerms get slatepackTerms => SlatepackTerms.slatepack;

  /// Restore or scan progress from 0 to 1.
  double get restoreProgress;

  /// The address another wallet encrypts a slatepack to.
  Future<String> slatepackAddress();

  /// Decode [armored] and work out its state without changing the wallet.
  /// Throws when the text cannot be decoded at all.
  Future<SlateInspection> inspectSlatepack(String armored);

  /// Amount, fee and direction of this wallet's transaction for [slateId], or
  /// null when the wallet has none. `isSend` is true for a send this wallet
  /// started, which is the only kind it can finalize.
  Future<({Amount amount, Amount fee, bool isSend})?> localTxForSlate(
    String slateId,
  );

  /// Start a send (S1). [message] is dropped when [supportsOnChainNote] is
  /// false. [recipientAddress] encrypts the slatepack to that address where
  /// the coin supports it.
  Future<SlatepackResult> createSlatepack({
    required Amount amount,
    String? recipientAddress,
    String? message,
    bool sendAll = false,
  });

  /// Answer an S1 with an S2.
  Future<SlatepackResult> receiveSlatepack(String s1);

  /// Finalize an S2 from the recipient and post it.
  Future<FinalizeResult> finalizeSlatepack(String s2);

  /// Returns an empty String on success, error message on failure.
  Future<String> cancelPendingTransactionAndPost(String slateId);

  /// The stored S1 or I1 for an unfinished transaction, to show again.
  Future<String?> pendingSlatepackFor(String txid) async => null;

  bool get supportsRepost => false;

  Future<void> repost(String txid) => throw UnsupportedError("repost");

  Future<SlatepackResult> issueInvoice({
    required Amount amount,
    String? payerAddress,
  }) => throw UnsupportedError("invoices");

  Future<SlatepackResult> processInvoice(
    String i1, {
    required Amount confirmedAmount,
  }) => throw UnsupportedError("invoices");

  Future<FinalizeResult> finalizeInvoice(String i2) =>
      throw UnsupportedError("invoices");

  Future<String> exportPaymentProof(String txid) =>
      throw UnsupportedError("proofs");
}

/// Key in [TxData.otherData] that tells the confirm screen how to send.
const kSlatepackMethodKey = "transactionMethod";

String slatepackMethodOtherData(SlatepackMethod method) =>
    jsonEncode({kSlatepackMethodKey: method.name});

extension SlatepackTxData on TxData {
  SlatepackMethod? get slatepackMethod {
    if (otherData == null) return null;
    try {
      final map = jsonDecode(otherData!);
      if (map is Map) {
        return SlatepackMethod.fromName(map[kSlatepackMethodKey] as String?);
      }
    } catch (_) {}
    return null;
  }

  bool get isSlatepackSend => slatepackMethod == SlatepackMethod.slatepack;
}
