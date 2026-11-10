import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/providers/global/duress_provider.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/isar/providers/all_wallets_info_provider.dart';
import 'package:stackwallet/wallets/isar/providers/favourite_wallets_provider.dart';

import '../support/isar_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('duress toggles preserve all cached wallet lists', () async {
    await initializeTestIsar();
    final directory = await Directory.systemTemp.createTemp('duress-wallets-');
    final isar = await Isar.open(
      [WalletInfoSchema],
      directory: directory.path,
      name: 'duress-wallets',
      inspector: false,
    );
    addTearDown(() async {
      await isar.close();
      await directory.delete(recursive: true);
    });
    await MainDB.instance.initMainDB(mock: isar);
    WalletInfo wallet(String id, {bool visible = false, int favourite = -1}) =>
        WalletInfo(
          walletId: id,
          name: id,
          coinName: 'bitcoin',
          mainAddressType: AddressType.p2wpkh,
          favouriteOrderIndex: favourite,
          otherDataJsonString: jsonEncode({
            WalletInfoKeys.duressMarkedVisibleWalletKey: visible,
          }),
        );
    await isar.writeTxn(
      () => isar.walletInfo.putAll([
        wallet('visible', visible: true, favourite: 0),
        wallet('hidden', favourite: 1),
        wallet('not-favourite'),
      ]),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscriptions = [
      container.listen(pAllWalletsInfo, (_, __) {}),
      container.listen(pFavouriteWalletInfos(true), (_, __) {}),
      container.listen(pFavouriteWalletInfos(false), (_, __) {}),
    ];
    addTearDown(() {
      for (final subscription in subscriptions) {
        subscription.close();
      }
    });
    await Future<void>.delayed(Duration.zero);
    final all = container.read(pAllWalletsInfo);
    final favourites = container.read(pFavouriteWalletInfos(true));
    final others = container.read(pFavouriteWalletInfos(false));
    for (var cycle = 0; cycle < 2; cycle++) {
      container.read(pDuress.notifier).state = true;
      expect(container.read(pAllWalletsInfo).map((w) => w.walletId), [
        'visible',
      ]);
      expect(
        container.read(pFavouriteWalletInfos(true)).map((w) => w.walletId),
        ['visible'],
      );
      expect(container.read(pFavouriteWalletInfos(false)), isEmpty);
      expect(all, hasLength(3));
      expect(favourites, hasLength(2));
      expect(others, hasLength(1));
      container.read(pDuress.notifier).state = false;
      expect(container.read(pAllWalletsInfo), hasLength(3));
      expect(
        container.read(pFavouriteWalletInfos(true)).map((w) => w.walletId),
        ['visible', 'hidden'],
      );
      expect(
        container.read(pFavouriteWalletInfos(false)).single.walletId,
        'not-favourite',
      );
    }
  });
}
