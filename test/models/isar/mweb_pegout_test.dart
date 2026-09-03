import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/electrumx_interface.dart';

void main() {
  UTXO utxo({String? otherData}) => UTXO(
    walletId: "walletId",
    txid: "txid",
    vout: 1,
    value: 1000,
    name: "",
    isBlocked: false,
    blockedReason: null,
    isCoinbase: false,
    blockHash: "blockHash",
    blockHeight: 100,
    blockTime: 1,
    otherData: otherData,
  );

  group("MWEB pegout detection", () {
    test("recognizes outputs after the HogAddr output", () {
      final outputs = [
        {
          "n": 0,
          "scriptPubKey": {"type": "witness_mweb_hogaddr"},
        },
        {
          "n": 1,
          "scriptPubKey": {"type": "witness_v0_keyhash"},
        },
      ];

      expect(isMwebPegoutOutput(outputs, 0), isFalse);
      expect(isMwebPegoutOutput(outputs, 1), isTrue);
    });

    test("recognizes the HogAddr script when type is unavailable", () {
      final outputs = [
        {
          "n": 0,
          "scriptPubKey": {
            "hex":
                "5820000000000000000000000000000000"
                "0000000000000000000000000000000000",
          },
        },
      ];

      expect(isMwebPegoutOutput(outputs, 1), isTrue);
    });

    test("does not classify native MWEB or ordinary outputs as pegouts", () {
      final outputs = [
        {
          "n": 0,
          "ismweb": true,
          "scriptPubKey": {"type": "witness_v0_keyhash"},
        },
      ];

      expect(isMwebPegoutOutput(outputs, 1), isFalse);
    });
  });

  test("Litecoin pegouts require six confirmations", () {
    final maturity = Litecoin(CryptoCurrencyNetwork.main).mwebPegoutMaturity;
    final pegout = utxo(
      otherData: jsonEncode({UTXOOtherDataKeys.mwebPegoutMaturity: maturity}),
    );

    expect(pegout.isMwebPegout, isTrue);
    expect(pegout.getConfirmations(104), 5);
    expect(pegout.isConfirmed(104, 1, 1), isFalse);
    expect(pegout.isConfirmed(104, 1, 1, overrideMinConfirms: 1), isFalse);
    expect(pegout.isConfirmed(105, 1, 1), isTrue);
  });

  test("ordinary outputs retain the currency confirmation policy", () {
    final ordinary = utxo();

    expect(ordinary.isMwebPegout, isFalse);
    expect(ordinary.isConfirmed(100, 1, 1), isTrue);
  });
}
