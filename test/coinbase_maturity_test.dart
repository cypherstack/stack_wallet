/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import 'package:flutter_test/flutter_test.dart';

import 'package:bitfinite/models/isar/models/blockchain_data/utxo.dart';
import 'package:bitfinite/wallets/crypto_currency/crypto_currency.dart';
import 'package:bitfinite/wallets/crypto_currency/coins/bitfinite.dart';
import 'package:bitfinite/wallets/crypto_currency/coins/bellscoin.dart';
import 'package:bitfinite/wallets/crypto_currency/coins/pepecoin.dart';
import 'package:bitfinite/wallets/crypto_currency/coins/bitcoin.dart';
import 'package:bitfinite/wallets/crypto_currency/coins/dogecoin.dart';
import 'package:bitfinite/wallets/crypto_currency/coins/litecoin.dart';
import 'package:bitfinite/wallets/crypto_currency/coins/bitcoincash.dart';

/// A coinbase output cannot be spent until the chain says so.
///
/// This is a consensus rule, not a risk setting, which is what makes it
/// different from [CryptoCurrency.minConfirms]. A wallet that is relaxed about
/// ordinary payments is taking a risk it understands. A wallet that counts an
/// immature block reward as spendable is stating something the network will
/// simply refuse, and the person it refuses is a miner trying to spend what
/// they just earned.
///
/// The default used to be minConfirms, so BitFinite answered 0 and most of the
/// others answered 1 against a real maturity of 100. These tests exist because
/// nothing anywhere failed when that was true.
void main() {
  final coins = <String, CryptoCurrency>{
    "BitFinite": Bitfinite(CryptoCurrencyNetwork.main),
    "Pepecoin": Pepecoin(CryptoCurrencyNetwork.main),
    "Bellscoin": Bellscoin(CryptoCurrencyNetwork.main),
    "Bitcoin": Bitcoin(CryptoCurrencyNetwork.main),
    "Dogecoin": Dogecoin(CryptoCurrencyNetwork.main),
    "Litecoin": Litecoin(CryptoCurrencyNetwork.main),
    "Bitcoin Cash": Bitcoincash(CryptoCurrencyNetwork.main),
  };

  group("coinbase maturity", () {
    test("no coin claims a reward is spendable before 100 blocks", () {
      coins.forEach((name, coin) {
        expect(
          coin.minCoinbaseConfirms,
          greaterThanOrEqualTo(100),
          reason: "$name would offer an immature block reward as spendable",
        );
      });
    });

    test("BitFinite matches its own COINBASE_MATURITY", () {
      // bitfinite-core/src/consensus/consensus.h: COINBASE_MATURITY = 100.
      expect(Bitfinite(CryptoCurrencyNetwork.main).minCoinbaseConfirms, 100);
    });

    test("zeroconf on payments does not leak into coinbase", () {
      // The two settings answer different questions and must be free to
      // disagree. BitFinite is the case that proves it: 0 for payments,
      // 100 for rewards.
      final bfx = Bitfinite(CryptoCurrencyNetwork.main);
      expect(bfx.minConfirms, 0);
      expect(bfx.minCoinbaseConfirms, 100);
    });
  });

  group("a freshly mined reward", () {
    UTXO reward({required int minedAt}) => UTXO(
      walletId: "w",
      txid: "t",
      vout: 0,
      value: 5000000000,
      name: "",
      isBlocked: false,
      blockedReason: null,
      isCoinbase: true,
      blockHash: null,
      blockHeight: minedAt,
      blockTime: null,
      address: "a",
    );

    const tip = 1000;

    test("is not spendable one block after it is mined", () {
      final bfx = Bitfinite(CryptoCurrencyNetwork.main);
      expect(
        reward(
          minedAt: tip,
        ).isConfirmed(tip, bfx.minConfirms, bfx.minCoinbaseConfirms),
        isFalse,
        reason:
            "this is the exact case a solo miner hits: mine a block, open "
            "the wallet, and be offered coins the node will not let them send",
      );
    });

    test("is not spendable at 99 confirmations", () {
      final bfx = Bitfinite(CryptoCurrencyNetwork.main);
      expect(
        reward(
          minedAt: tip - 98,
        ).isConfirmed(tip, bfx.minConfirms, bfx.minCoinbaseConfirms),
        isFalse,
      );
    });

    test("is spendable at 100", () {
      final bfx = Bitfinite(CryptoCurrencyNetwork.main);
      expect(
        reward(
          minedAt: tip - 99,
        ).isConfirmed(tip, bfx.minConfirms, bfx.minCoinbaseConfirms),
        isTrue,
        reason:
            "erring high has a cost too: a mature reward must not stay "
            "stuck in the pending balance",
      );
    });

    test("an ordinary payment still settles at zeroconf", () {
      // The fix must not quietly turn BitFinite into a 100-confirm chain for
      // everything. Only coinbase outputs changed.
      final bfx = Bitfinite(CryptoCurrencyNetwork.main);
      final payment = UTXO(
        walletId: "w",
        txid: "t",
        vout: 0,
        value: 1000,
        name: "",
        isBlocked: false,
        blockedReason: null,
        isCoinbase: false,
        blockHash: null,
        blockHeight: tip,
        blockTime: null,
        address: "a",
      );
      expect(
        payment.isConfirmed(tip, bfx.minConfirms, bfx.minCoinbaseConfirms),
        isTrue,
      );
    });
  });
}
