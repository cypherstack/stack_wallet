import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/models/slatepack_models.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/slatepack_method.dart';
import 'package:stackwallet/utilities/slatepack_terms.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/epiccash_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/mimblewimblecoin_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/slatepack_interface.dart';

import '../support/isar_test_utils.dart';

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

TransactionV2 _tx(
  int n,
  TransactionType type,
  String slateId, {
  bool isCancelled = false,
  int? numberOfMessages,
  String? onChainNote,
}) => TransactionV2(
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
  otherData: jsonEncode({
    "slateId": slateId,
    if (numberOfMessages != null) "numberOfMessages": numberOfMessages,
    if (onChainNote != null) "onChainNote": onChainNote,
    TxV2OdKeys.overrideFee: Amount.zeroWith(fractionDigits: 9).toJsonString(),
    if (isCancelled) TxV2OdKeys.isCancelled: true,
  }),
);

class _DecodeFailureWallet extends MimblewimblecoinWallet {
  _DecodeFailureWallet(this.failure) : super(CryptoCurrencyNetwork.main);

  final SlatepackDecodeFailure failure;

  @override
  Future<SlatepackDecodeResult> decodeSlatepack(String slatepack) async =>
      SlatepackDecodeResult(success: false, failure: failure);
}

class _LocalLookupWallet extends MimblewimblecoinWallet {
  _LocalLookupWallet() : super(CryptoCurrencyNetwork.main) {
    mainDB = MainDB.instance;
  }

  @override
  String get walletId => 'wallet';
}

class _PendingLookupWallet extends _LocalLookupWallet {
  _PendingLookupWallet({this.failPersistence = false});

  final bool failPersistence;
  Map<dynamic, dynamic> metadata = {};

  @override
  Map<dynamic, dynamic> get slatepackTransactionMetadata => metadata;

  @override
  Future<void> updateSlatepackTransactionMetadata(
    Map<dynamic, dynamic> metadata,
  ) async {
    if (failPersistence) throw StateError('persistence unavailable');
    this.metadata = metadata;
  }

  Future<void> remember(SlatepackResult result) =>
      rememberPendingSlateSend(result);

  Future<void> rememberCancelled(String slateId) =>
      rememberPendingSlateCancelled(slateId);
}

void main() {
  setUpAll(initializeTestIsar);

  test("local transaction for a slate", () {
    const id = "0436430c-2b02-624c-2032-570501212b00";
    final received = _tx(1, TransactionType.incoming, id);
    final sent = _tx(2, TransactionType.outgoing, id);
    // Contains the id without being the transaction for it.
    final other = _tx(3, TransactionType.outgoing, "$id-other");

    expect(localSlateTransaction([other], id), isNull);
    expect(localSlateTransaction([other, received], id), received);
    // A send to self holds both sides, and the send is what gets finalized.
    expect(localSlateTransaction([received, sent], id), sent);
    expect(localSlateTransaction([sent, received], id), sent);

    final cancelled = _tx(4, TransactionType.outgoing, id, isCancelled: true);
    expect(cancelled.isCancelled, isTrue);
    expect(localSlateTransaction([received, cancelled], id), cancelled);

    // Received again after a cancelled receive: the live record wins
    // whichever order the two come in.
    final cancelledReceive = _tx(
      5,
      TransactionType.incoming,
      id,
      isCancelled: true,
    );
    expect(localSlateTransaction([cancelledReceive, received], id), received);
    expect(localSlateTransaction([received, cancelledReceive], id), received);
    expect(localSlateTransaction([cancelledReceive], id), cancelledReceive);
  });

  SlateInspection inspect(
    Map<String, dynamic> json, {
    String? sender,
    String? recipient,
  }) => inspectSlateJson(
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

  test("explicit invoice state overrides standard-send signatures", () {
    final invoice = _slate(signatures: 0)..["sta"] = "I1";

    expect(inspect(invoice).state, SlateState.i1);
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

  test("zero amount and fee on a response slate are unknown", () {
    final json = _slate(signatures: 1)
      ..["amount"] = "0"
      ..["fee"] = "0";

    final response = inspect(json);

    expect(response.state, SlateState.s2);
    expect(response.amount, isNull);
    expect(response.fee, isNull);
  });

  test('decode failures explain likely slatepack problems', () async {
    final wallet = _DecodeFailureWallet(SlatepackDecodeFailure.invalidInput);

    await expectLater(
      wallet.inspectSlatepack('BEGINSLATEPACK. broken. ENDSLATEPACK.'),
      throwsA(
        isA<Exception>()
            .having(
              (error) => error.toString(),
              'message',
              contains('damaged, incomplete, or encrypted for another wallet'),
            )
            .having(
              (error) => error.toString(),
              'native error hidden',
              isNot(contains('FormatException')),
            ),
      ),
    );
  });

  test('wallet-open failures are not blamed on the slatepack', () async {
    final wallet = _DecodeFailureWallet(
      SlatepackDecodeFailure.walletUnavailable,
    );

    await expectLater(
      wallet.inspectSlatepack('BEGINSLATEPACK. valid. ENDSLATEPACK.'),
      throwsA(
        isA<Exception>()
            .having(
              (error) => error.toString(),
              'wallet error',
              contains('wallet could not be opened. Try again.'),
            )
            .having(
              (error) => error.toString(),
              'does not blame input',
              isNot(contains('damaged')),
            )
            .having(
              (error) => error.toString(),
              'does not suggest a nonexistent unlock action',
              isNot(contains('Unlock')),
            ),
      ),
    );
  });

  test('Epic decode errors do not mention unsupported encryption', () async {
    final wallet = EpiccashWallet(CryptoCurrencyNetwork.main);

    await expectLater(
      wallet.inspectSlatepack('not json'),
      throwsA(
        isA<Exception>()
            .having(
              (error) => error.toString(),
              'input explanation',
              contains('damaged or incomplete'),
            )
            .having(
              (error) => error.toString(),
              'encryption omitted',
              isNot(contains('encrypted')),
            ),
      ),
    );
  });

  test('a cache miss never waits for native wallet history', () async {
    final directory = await Directory.systemTemp.createTemp(
      'mimblewimble-local-history-',
    );
    final isar = await Isar.open(
      [TransactionV2Schema, WalletInfoSchema],
      directory: directory.path,
      name: 'mimblewimble-local-history',
      inspector: false,
    );
    addTearDown(() async {
      await isar.close();
      await directory.delete(recursive: true);
    });
    await MainDB.instance.initMainDB(mock: isar);
    await MainDB.instance.putWalletInfo(
      WalletInfo(
        walletId: 'wallet',
        name: 'fixture',
        mainAddressType: AddressType.mimbleWimble,
        coinName: 'mimblewimblecoin',
      ),
    );

    final wallet = _PendingLookupWallet();
    final result = await wallet.localTxForSlate('slate');

    expect(result, isNull);
    expect(
      await MainDB.instance.isar.transactionV2s.count(),
      0,
      reason: 'reading an incoming S1 must not trigger a native history load',
    );

    await wallet.remember(
      SlatepackResult(
        success: true,
        slatepack: 'slate',
        slateId: 'slate',
        state: SlateState.s1,
        amount: Amount(rawValue: BigInt.from(123), fractionDigits: 8),
        fee: Amount(rawValue: BigInt.from(4), fractionDigits: 8),
      ),
    );
    final pending = await wallet.localTxForSlate('slate');
    expect(pending?.isSend, isTrue);
    expect(pending?.amount.raw, BigInt.from(123));
    expect(pending?.fee.raw, BigInt.from(4));
    expect(pending?.isCancelled, isFalse);

    await wallet.rememberCancelled('slate');
    expect((await wallet.localTxForSlate('slate'))?.isCancelled, isTrue);
  });

  test("Epic and MWC capabilities", () {
    final epic = EpiccashWallet(CryptoCurrencyNetwork.main);
    final mwc = MimblewimblecoinWallet(CryptoCurrencyNetwork.main);

    expect(epic.supportedMethods.first, SlatepackMethod.relay);
    expect(mwc.supportedMethods.first, SlatepackMethod.slatepack);
    for (final SlatepackInterface w in [epic, mwc]) {
      expect(w.supportedMethods, contains(SlatepackMethod.slatepack));
      expect(w.supportsOnChainNote, isTrue);
    }
    expect(epic.slatepackTerms, SlatepackTerms.slate);
    expect(mwc.slatepackTerms, SlatepackTerms.slatepack);
    expect(epic.supportsSlatepackEncryption, isFalse);
    expect(mwc.supportsSlatepackEncryption, isTrue);
    expect(epic.hasSlatepackMethodToggle, isTrue);
    expect(mwc.hasSlatepackMethodToggle, isTrue);
  });

  test('pending send metadata is immediately usable for ownership checks', () {
    final pending = pendingSlateSendMatching(
      {
        'slate': {
          'amount': '123',
          'fee': '4',
          'isSend': true,
          'isCancelled': false,
        },
      },
      'slate',
      fractionDigits: 8,
    );

    expect(pending?.amount.raw, BigInt.from(123));
    expect(pending?.fee.raw, BigInt.from(4));
    expect(pending?.isSend, isTrue);
    expect(pending?.isCancelled, isFalse);
    expect(
      pendingSlateSendMatching(
        {
          'legacy': {'commitId': 'commit'},
        },
        'legacy',
        fractionDigits: 8,
      ),
      isNull,
    );
  });

  test('Epic treats a successful legacy finalize as broadcast', () {
    expect(epicFinalizeBroadcastResult(null), isTrue);
    expect(epicFinalizeBroadcastResult(true), isTrue);
    expect(epicFinalizeBroadcastResult(false), isFalse);
  });

  test(
    'ownership remains local when durable metadata cannot be written',
    () async {
      final wallet = _PendingLookupWallet(failPersistence: true);
      await wallet.remember(
        SlatepackResult(
          success: true,
          slatepack: 'slate',
          slateId: 'volatile-slate',
          state: SlateState.s1,
          amount: Amount(rawValue: BigInt.from(123), fractionDigits: 8),
          fee: Amount(rawValue: BigInt.from(4), fractionDigits: 8),
        ),
      );

      expect((await wallet.localTxForSlate('volatile-slate'))?.isSend, isTrue);
      await wallet.rememberCancelled('volatile-slate');
      expect(
        (await wallet.localTxForSlate('volatile-slate'))?.isCancelled,
        isTrue,
      );
    },
  );
}
