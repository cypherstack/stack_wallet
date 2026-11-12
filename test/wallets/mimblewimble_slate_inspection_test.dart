import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/models/slatepack_models.dart';
import 'package:stackwallet/utilities/enums/slatepack_method.dart';
import 'package:stackwallet/utilities/slatepack_terms.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/epiccash_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/mimblewimblecoin_wallet.dart';
import 'package:stackwallet/wallets/wallet/intermediate/mimblewimble_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/slatepack_interface.dart';

Map<String, dynamic> _slate({required int signatures, int participants = 2}) {
  return {
    "id": "0436430c-2b02-624c-2032-570501212b00",
    "amount": "150000000",
    "fee": "8000000",
    "ttl_cutoff_height": "123456",
    "participant_data": [
      for (int i = 0; i < participants; i++)
        {"id": "$i", "part_sig": i < signatures ? "sig$i" : null},
    ],
  };
}

TransactionV2 _tx(int n, TransactionType type, String slateId) => TransactionV2(
  walletId: "wallet",
  blockHash: null,
  hash: "hash$n",
  txid: "txid$n",
  timestamp: 0,
  height: null,
  inputs: const [],
  outputs: const [],
  version: 0,
  type: type,
  subType: TransactionSubType.none,
  otherData: jsonEncode({"slateId": slateId}),
);

void main() {
  test("local transaction for a slate", () {
    const id = "0436430c-2b02-624c-2032-570501212b00";
    final received = _tx(1, TransactionType.incoming, id);
    final sent = _tx(2, TransactionType.outgoing, id);
    // Contains the id without being the transaction for it.
    final other = _tx(3, TransactionType.outgoing, "$id-other");

    expect(MimblewimbleWallet.localTxMatching([other], id), isNull);
    expect(MimblewimbleWallet.localTxMatching([other, received], id), received);
    // A send to self holds both sides, and the send is what gets finalized.
    expect(MimblewimbleWallet.localTxMatching([received, sent], id), sent);
    expect(MimblewimbleWallet.localTxMatching([sent, received], id), sent);
  });

  SlateInspection inspect(
    Map<String, dynamic> json, {
    String? sender,
    String? recipient,
  }) => MimblewimbleWallet.inspectSlateJson(
    json,
    fractionDigits: 8,
    senderAddress: sender,
    recipientAddress: recipient,
  );

  test("state from partial signatures", () {
    expect(inspect(_slate(signatures: 0)).state, SlateState.s1);
    expect(inspect(_slate(signatures: 1)).state, SlateState.s2);
    expect(inspect(_slate(signatures: 2)).state, SlateState.s3);
  });

  test("falls back to sta, then to addresses", () {
    expect(inspect({"id": "a", "sta": "I1"}).state, SlateState.i1);
    expect(
      inspect({"id": "a"}, sender: "s", recipient: "r").state,
      SlateState.s2,
    );
    expect(inspect({"id": "a"}, sender: "s").state, SlateState.s1);
    expect(inspect({"id": "a"}).state, SlateState.unknown);
  });

  test("id, amount, fee and ttl", () {
    final i = inspect(_slate(signatures: 0));
    expect(i.slateId, "0436430c-2b02-624c-2032-570501212b00");
    expect(i.amount!.raw, BigInt.from(150000000));
    expect(i.fee!.raw, BigInt.from(8000000));
    expect(i.ttlCutoffHeight, 123456);
    expect(inspect({"id": "a", "amt": 5}).amount!.raw, BigInt.from(5));
    expect(inspect({"id": "a"}).amount, isNull);
  });

  test("Epic and MWC capabilities", () {
    final epic = EpiccashWallet(CryptoCurrencyNetwork.main);
    final mwc = MimblewimblecoinWallet(CryptoCurrencyNetwork.main);

    expect(epic.supportedMethods.first, SlatepackMethod.relay);
    expect(mwc.supportedMethods.first, SlatepackMethod.slatepack);
    for (final SlatepackInterface w in [epic, mwc]) {
      expect(w.supportedMethods, contains(SlatepackMethod.slatepack));
      expect(w.supportsOnChainNote, isTrue);
      expect(w.supportsInvoices, isFalse);
      expect(w.supportsRepost, isFalse);
    }
    expect(epic.slatepackTerms, SlatepackTerms.slate);
    expect(mwc.slatepackTerms, SlatepackTerms.slatepack);
  });

  test("slatepack method rides in TxData.otherData", () {
    final tx = TxData(
      otherData: slatepackMethodOtherData(SlatepackMethod.slatepack),
    );
    expect(tx.isSlatepackSend, isTrue);
    expect(
      TxData(otherData: slatepackMethodOtherData(SlatepackMethod.relay))
          .isSlatepackSend,
      isFalse,
    );
    expect(TxData().slatepackMethod, isNull);
    expect(TxData(otherData: "not json").slatepackMethod, isNull);
  });
}
