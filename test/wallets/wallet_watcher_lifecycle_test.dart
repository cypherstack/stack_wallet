import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/wallets/isar/models/token_wallet_info.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/isar/providers/all_wallets_info_provider.dart';
import 'package:stackwallet/wallets/isar/providers/eth/token_balance_provider.dart';
import 'package:stackwallet/wallets/isar/providers/favourite_wallets_provider.dart';
import 'package:stackwallet/wallets/isar/providers/solana/sol_token_balance_provider.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';

import '../support/isar_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Isar isar;

  setUpAll(initializeTestIsar);
  setUp(() async {
    final directory = await Directory.systemTemp.createTemp(
      'stack_wallet_providers_',
    );
    addTearDown(() => directory.delete(recursive: true));
    isar = await Isar.open(
      [
        WalletInfoSchema,
        TokenWalletInfoSchema,
        WalletSolanaTokenInfoSchema,
        EthContractSchema,
        SolContractSchema,
      ],
      directory: directory.path,
      name: 'wallet-providers-test',
      inspector: false,
    );
    addTearDown(() => isar.close());
    await MainDB.instance.initMainDB(mock: isar);
    await isar.writeTxn(() async {
      await isar.walletInfo.putAll([
        WalletInfo(
          walletId: 'visible',
          name: 'Visible wallet',
          mainAddressType: AddressType.p2wpkh,
          coinName: 'bitcoin',
          favouriteOrderIndex: 0,
          otherDataJsonString: jsonEncode({
            WalletInfoKeys.duressMarkedVisibleWalletKey: true,
          }),
        ),
        WalletInfo(
          walletId: 'hidden',
          name: 'Hidden wallet',
          mainAddressType: AddressType.p2wpkh,
          coinName: 'bitcoin',
          favouriteOrderIndex: 1,
        ),
      ]);
    });
  });

  test('a new provider container gets a live wallet watcher', () async {
    final first = ProviderContainer();
    expect(first.read(pAllWalletsInfo), hasLength(2));
    first.dispose();

    final second = ProviderContainer();
    addTearDown(second.dispose);
    final changed = second.listen(pAllWalletsInfo, (_, __) {});
    addTearDown(changed.close);
    expect(second.read(pAllWalletsInfo), hasLength(2));
    final nextValue = Completer<List<WalletInfo>>();
    final subscription = second.listen(pAllWalletsInfo, (_, value) {
      if (value.any((wallet) => wallet.name == 'Renamed wallet') &&
          !nextValue.isCompleted) {
        nextValue.complete(value);
      }
    });
    addTearDown(subscription.close);
    final wallet = await isar.walletInfo.getByWalletId('visible');
    await isar.writeTxn(
      () => isar.walletInfo.put(wallet!.copyWith(name: 'Renamed wallet')),
    );
    expect(
      await nextValue.future.timeout(const Duration(seconds: 5)),
      hasLength(2),
    );
  });

  testWidgets('wallet notifiers dispose once when their scope closes', (
    tester,
  ) async {
    final container = ProviderContainer();
    container.read(pWalletInfo('visible'));
    container.read(pFavouriteWalletInfos(true));
    container.read(
      pTokenBalance((walletId: 'visible', contractAddress: 'token')),
    );
    container.read(
      pSolanaTokenBalance((walletId: 'visible', tokenMint: 'mint')),
    );
    container.dispose();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
