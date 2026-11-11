import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/isar/providers/favourite_wallets_provider.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';

import '../support/isar_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Isar isar;

  setUpAll(initializeTestIsar);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('wallet_disposal_');
    isar = await Isar.open(
      [WalletInfoSchema],
      directory: directory.path,
      name: 'wallet-disposal',
      inspector: false,
    );
    await MainDB.instance.initMainDB(mock: isar);
    await isar.writeTxn(
      () => isar.walletInfo.put(
        WalletInfo(
          walletId: 'fixture',
          name: 'Fixture wallet',
          mainAddressType: AddressType.p2wpkh,
          coinName: 'bitcoin',
        ),
      ),
    );
  });
  tearDown(() async {
    await isar.close();
    await directory.delete(recursive: true);
  });

  for (final favourite in [false, true]) {
    testWidgets('wallet scope disposes its '
        '${favourite ? 'favourite list' : 'wallet info'} watcher once', (
      tester,
    ) async {
      final container = ProviderContainer();
      if (favourite) {
        container.read(pFavouriteWalletInfos(true));
      } else {
        expect(container.read(pWalletInfo('fixture')).name, 'Fixture wallet');
      }
      container.dispose();
      await tester.pump();
      expect(tester.takeException(), isNull);

      // A later onboarding/unlock scope must still be able to use the DB.
      final reopened = ProviderContainer();
      expect(reopened.read(pWalletInfo('fixture')).name, 'Fixture wallet');
      reopened.dispose();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
