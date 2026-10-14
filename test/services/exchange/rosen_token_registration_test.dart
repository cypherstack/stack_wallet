import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
import 'package:stackwallet/services/exchange/rosen/rosen_funding.dart';
import 'package:stackwallet/utilities/default_eth_tokens.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/ethereum_wallet.dart';

import '../../support/isar_test_utils.dart';

void main() {
  test(
    'rsFIRO registration preserves catalog metadata and address casing',
    () async {
      final directory = await Directory.systemTemp.createTemp('rosen-token-');
      addTearDown(() => directory.delete(recursive: true));
      await initializeTestIsar();
      final isar = await Isar.open(
        [EthContractSchema],
        directory: directory.path,
        inspector: false,
      );
      addTearDown(() => isar.close(deleteFromDisk: true));
      final db = MainDB.instance;
      await db.initMainDB(mock: isar);
      final existing = DefaultTokens.rsFiro.copyWith(
        id: Isar.autoIncrement,
        address: '0x${DefaultTokens.rsFiro.address.substring(2).toUpperCase()}',
        name: 'Existing rsFIRO',
        abi: 'preserve custom ABI',
      );
      await db.putEthContract(existing);

      final wallet = _Wallet(db, [DefaultTokens.usdc.address]);
      await RosenFunding.registerToken(wallet);
      await RosenFunding.registerToken(wallet);
      expect(wallet.info.tokenContractAddresses, [
        DefaultTokens.usdc.address,
        existing.address,
      ]);
      expect(wallet.updates, 1);

      final selected = _Wallet(db, [existing.address]);
      await RosenFunding.registerToken(selected);
      expect(selected.info.tokenContractAddresses, [existing.address]);
      expect(selected.updates, 0);

      final stored = (await db.getEthContracts().findAll()).single;
      expect(stored.id, existing.id);
      expect(stored.address, existing.address);
      expect(stored.name, existing.name);
      expect(stored.symbol, existing.symbol);
      expect(stored.decimals, existing.decimals);
      expect(stored.type, existing.type);
      expect(stored.abi, existing.abi);
    },
  );
}

class _Wallet extends Fake implements EthereumWallet {
  _Wallet(this.mainDB, List<String> addresses) : info = _WalletInfo(addresses);

  @override
  final MainDB mainDB;
  @override
  final _WalletInfo info;
  @override
  final Ethereum cryptoCurrency = Ethereum(CryptoCurrencyNetwork.main);
  int updates = 0;

  @override
  Future<void> updateTokenContracts(List<String> addresses) async {
    updates++;
    info.tokenContractAddresses = addresses;
  }
}

class _WalletInfo extends Fake implements WalletInfo {
  _WalletInfo(this.tokenContractAddresses);

  @override
  List<String> tokenContractAddresses;
}
