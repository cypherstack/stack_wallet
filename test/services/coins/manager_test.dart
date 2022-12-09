import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:epicmobile/electrumx_rpc/electrumx.dart';
import 'package:epicmobile/models/models.dart';
import 'package:epicmobile/services/coins/coin_service.dart';
import 'package:epicmobile/services/coins/firo/firo_wallet.dart';
import 'package:epicmobile/services/coins/manager.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';

import 'firo/sample_data/transaction_data_samples.dart';
import 'manager_test.mocks.dart';

@GenerateMocks([FiroWallet, ElectrumX])
void main() {
  test("Manager should have a backgroundRefreshListener on initialization", () {
    final manager = Manager(MockFiroWallet());

    expect(manager.hasBackgroundRefreshListener, true);
  });

  test("get coin", () {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.coin).thenAnswer((_) => Coin.firo);
    final manager = Manager(wallet);

    expect(manager.coin, Coin.firo);
  });

  group("send", () {
    test("successful send", () async {
      final CoinServiceAPI wallet = MockFiroWallet();
      when(wallet.send(toAddress: "some address", amount: 1987634))
          .thenAnswer((_) async => "some txid");

      final manager = Manager(wallet);

      expect(await manager.send(toAddress: "some address", amount: 1987634),
          "some txid");
    });

    test("failed send", () {
      final CoinServiceAPI wallet = MockFiroWallet();
      when(wallet.send(toAddress: "some address", amount: 1987634))
          .thenThrow(Exception("Tx failed!"));

      final manager = Manager(wallet);

      expect(() => manager.send(toAddress: "some address", amount: 1987634),
          throwsA(isA<Exception>()));
    });
  });

  test("fees", () async {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.fees).thenAnswer((_) async => FeeObject(
        fast: 10,
        medium: 5,
        slow: 1,
        numberOfBlocksFast: 4,
        numberOfBlocksSlow: 2,
        numberOfBlocksAverage: 3));

    final manager = Manager(wallet);

    final feeObject = await manager.fees;

    expect(feeObject.fast, 10);
    expect(feeObject.medium, 5);
    expect(feeObject.slow, 1);
    expect(feeObject.numberOfBlocksFast, 4);
    expect(feeObject.numberOfBlocksAverage, 3);
    expect(feeObject.numberOfBlocksSlow, 2);
  });

  test("maxFee", () async {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.maxFee).thenAnswer((_) async => 10);

    final manager = Manager(wallet);

    final fee = await manager.maxFee;

    expect(fee, 10);
  });

  test("get currentReceivingAddress", () async {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.currentReceivingAddress)
        .thenAnswer((_) async => "Some address string");

    final manager = Manager(wallet);

    expect(await manager.currentReceivingAddress, "Some address string");
  });

  group("get balances", () {
    test("balance", () async {
      final CoinServiceAPI wallet = MockFiroWallet();
      when(wallet.availableBalance).thenAnswer((_) async => Decimal.ten);

      final manager = Manager(wallet);

      expect(await manager.availableBalance, Decimal.ten);
    });

    test("pendingBalance", () async {
      final CoinServiceAPI wallet = MockFiroWallet();
      when(wallet.pendingBalance).thenAnswer((_) async => Decimal.fromInt(23));

      final manager = Manager(wallet);

      expect(await manager.pendingBalance, Decimal.fromInt(23));
    });

    test("totalBalance", () async {
      final wallet = MockFiroWallet();
      when(wallet.totalBalance).thenAnswer((_) async => Decimal.fromInt(2));

      final manager = Manager(wallet);

      expect(await manager.totalBalance, Decimal.fromInt(2));
    });

    test("balanceMinusMaxFee", () async {
      final CoinServiceAPI wallet = MockFiroWallet();
      when(wallet.balanceMinusMaxFee).thenAnswer((_) async => Decimal.one);

      final manager = Manager(wallet);

      expect(await manager.balanceMinusMaxFee, Decimal.one);
    });
  });

  test("allOwnAddresses", () async {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.allOwnAddresses)
        .thenAnswer((_) async => ["address1", "address2", "address3"]);

    final manager = Manager(wallet);

    expect(await manager.allOwnAddresses, ["address1", "address2", "address3"]);
  });

  test("transactionData", () async {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.transactionData)
        .thenAnswer((_) async => TransactionData.fromJson(dateTimeChunksJson));

    final manager = Manager(wallet);

    final expectedMap =
        TransactionData.fromJson(dateTimeChunksJson).getAllTransactions();
    final result = (await manager.transactionData).getAllTransactions();

    expect(result.length, expectedMap.length);

    for (int i = 0; i < expectedMap.length; i++) {
      final resultTxid = result.keys.toList(growable: false)[i];
      expect(result[resultTxid].toString(), expectedMap[resultTxid].toString());
    }
  });

  test("refresh", () async {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.refresh()).thenAnswer((_) => Future(() => {}));

    final manager = Manager(wallet);

    await manager.refresh();

    verify(wallet.refresh()).called(1);
  });

  test("get walletName", () {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.walletName).thenAnswer((_) => "Some wallet name");
    final manager = Manager(wallet);

    expect(manager.walletName, "Some wallet name");
  });

  test("get walletId", () {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.walletId).thenAnswer((_) => "Some wallet ID");

    final manager = Manager(wallet);

    expect(manager.walletId, "Some wallet ID");
  });

  group("validateAddress", () {
    test("some valid address", () {
      final CoinServiceAPI wallet = MockFiroWallet();
      when(wallet.validateAddress("a valid address")).thenAnswer((_) => true);

      final manager = Manager(wallet);

      expect(manager.validateAddress("a valid address"), true);
    });

    test("some invalid address", () {
      final CoinServiceAPI wallet = MockFiroWallet();
      when(wallet.validateAddress("an invalid address"))
          .thenAnswer((_) => false);

      final manager = Manager(wallet);

      expect(manager.validateAddress("an invalid address"), false);
    });
  });

  test("get mnemonic", () async {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.mnemonic)
        .thenAnswer((_) async => ["Some", "seed", "word", "list"]);

    final manager = Manager(wallet);

    expect(await manager.mnemonic, ["Some", "seed", "word", "list"]);
  });

  test("testNetworkConnection", () async {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.testNetworkConnection()).thenAnswer((_) async => true);

    final manager = Manager(wallet);

    expect(await manager.testNetworkConnection(), true);
  });

  group("recoverFromMnemonic", () {
    test("successfully recover", () async {
      final CoinServiceAPI wallet = MockFiroWallet();
      when(wallet.recoverFromMnemonic(
              mnemonic: "Some valid mnemonic",
              maxUnusedAddressGap: 20,
              maxNumberOfIndexesToCheck: 1000,
              height: 0))
          .thenAnswer((realInvocation) => Future(() => {}));

      final manager = Manager(wallet);

      await manager.recoverFromMnemonic(
          mnemonic: "Some valid mnemonic",
          maxUnusedAddressGap: 20,
          maxNumberOfIndexesToCheck: 1000,
          height: 0);

      verify(wallet.recoverFromMnemonic(
              mnemonic: "Some valid mnemonic",
              maxUnusedAddressGap: 20,
              maxNumberOfIndexesToCheck: 1000,
              height: 0))
          .called(1);
    });

    test("failed recovery", () async {
      final CoinServiceAPI wallet = MockFiroWallet();
      when(wallet.recoverFromMnemonic(
              mnemonic: "Some invalid mnemonic",
              maxUnusedAddressGap: 20,
              maxNumberOfIndexesToCheck: 1000,
              height: 0))
          .thenThrow(Exception("Invalid mnemonic"));

      final manager = Manager(wallet);

      expect(
          () => manager.recoverFromMnemonic(
              mnemonic: "Some invalid mnemonic",
              maxUnusedAddressGap: 20,
              maxNumberOfIndexesToCheck: 1000,
              height: 0),
          throwsA(isA<Exception>()));

      verify(wallet.recoverFromMnemonic(
              mnemonic: "Some invalid mnemonic",
              maxUnusedAddressGap: 20,
              maxNumberOfIndexesToCheck: 1000,
              height: 0))
          .called(1);
    });

    test("failed recovery due to some other error", () async {
      final CoinServiceAPI wallet = MockFiroWallet();
      when(wallet.recoverFromMnemonic(
              mnemonic: "Some valid mnemonic",
              maxUnusedAddressGap: 20,
              maxNumberOfIndexesToCheck: 1000,
              height: 0))
          .thenThrow(Error());

      final manager = Manager(wallet);

      expect(
          () => manager.recoverFromMnemonic(
              mnemonic: "Some valid mnemonic",
              maxUnusedAddressGap: 20,
              maxNumberOfIndexesToCheck: 1000,
              height: 0),
          throwsA(isA<Error>()));

      verify(wallet.recoverFromMnemonic(
              mnemonic: "Some valid mnemonic",
              maxUnusedAddressGap: 20,
              maxNumberOfIndexesToCheck: 1000,
              height: 0))
          .called(1);
    });
  });

  test("exitCurrentWallet", () async {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.exit()).thenAnswer((realInvocation) => Future(() => {}));
    when(wallet.walletId).thenAnswer((realInvocation) => "some id");
    when(wallet.walletName).thenAnswer((realInvocation) => "some name");

    final manager = Manager(wallet);

    await manager.exitCurrentWallet();

    verify(wallet.exit()).called(1);
    verify(wallet.walletName).called(1);
    verify(wallet.walletId).called(1);

    expect(manager.hasBackgroundRefreshListener, false);
  });

  test("dispose", () async {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.exit()).thenAnswer((realInvocation) => Future(() => {}));
    when(wallet.walletId).thenAnswer((realInvocation) => "some id");
    when(wallet.walletName).thenAnswer((realInvocation) => "some name");

    final manager = Manager(wallet);

    expect(() => manager.dispose(), returnsNormally);
  });

  test("fullRescan succeeds", () {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.fullRescan(20, 1000)).thenAnswer((_) async {});

    final manager = Manager(wallet);

    expect(() => manager.fullRescan(20, 1000), returnsNormally);
  });

  test("fullRescan fails", () {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.fullRescan(20, 1000)).thenThrow(Exception());

    final manager = Manager(wallet);

    expect(() => manager.fullRescan(20, 1000), throwsA(isA<Exception>()));
  });

  // test("act on event", () async {
  //   final CoinServiceAPI wallet = MockFiroWallet();
  //   when(wallet.exit()).thenAnswer((realInvocation) => Future(() => {}));
  //
  //   final manager = Manager(wallet);
  //
  //   expect(
  //       () => GlobalEventBus.instance.fire(UpdatedInBackgroundEvent(
  //           "act on event - test message", "wallet ID")),
  //       returnsNormally);
  //
  //   expect(() => manager.dispose(), returnsNormally);
  // });
}
