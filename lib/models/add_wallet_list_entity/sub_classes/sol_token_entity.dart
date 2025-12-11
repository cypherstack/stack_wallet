/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import '../../../wallets/crypto_currency/crypto_currency.dart';
import '../../isar/models/solana/sol_contract.dart';
import '../add_wallet_list_entity.dart';

class SolTokenEntity extends AddWalletListEntity {
  SolTokenEntity(this.token);

  final SolContract token;

  @override
  CryptoCurrency get cryptoCurrency => Solana(CryptoCurrencyNetwork.main);

  @override
  String get name => token.name;

  @override
  String get ticker => token.symbol;

  @override
  List<Object?> get props =>
      [cryptoCurrency.identifier, name, ticker, token.address];
}
