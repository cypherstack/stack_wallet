import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wl_gen/interfaces/lib_xelis_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Stack adapter opens native storage and exposes typed zero state',
    () async {
      await libXelis.initRustLib();
      final root = await Directory.systemTemp.createTemp(
        'stack_xelis_adapter_',
      );
      final tableDirectory = await Directory(path.join(root.path, 'table'))
          .create();
      final tablesPath = '${tableDirectory.path}${Platform.pathSeparator}';
      OpaqueXelisWallet? wallet;
      try {
        wallet = await libXelis.createXelisWallet(
          'wallet',
          name: 'wallet',
          directory: root.path,
          password: 'isolated-fixture-password',
          network: CryptoCurrencyNetwork.test,
          precomputedTablesPath: tablesPath,
          stack_l1Low: true,
        );
        expect(
          await Directory(path.join(root.path, 'wallet')).exists(),
          isTrue,
        );
        expect(await libXelis.getXelisBalanceRaw(wallet), BigInt.zero);
        expect(await libXelis.allHistory(wallet), isEmpty);
        expect(
          libXelis.isAddressValid(
            address: libXelis.getAddress(wallet),
            network: CryptoCurrencyNetwork.test,
          ),
          isTrue,
        );
        expect(
          libXelis.isAddressValid(
            address: libXelis.getAddress(wallet),
            network: CryptoCurrencyNetwork.main,
          ),
          isFalse,
        );
        final seed = await libXelis.getSeed(wallet);
        expect(seed.split(' '), hasLength(25));
        expect(seed.split(' ').every(libXelis.validateSeedWord), isTrue);
        final runtime = await libXelis.subscribeRuntimeEvents(wallet);
        final business = await libXelis.subscribeBusinessEvents(wallet);
        await runtime.cancel();
        await business.cancel();
      } finally {
        if (wallet != null) await libXelis.closeWallet(wallet);
        await root.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
