import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/contact_entry.dart';
import 'package:stackwallet/services/address_book_service.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

class _TestAddressBookService extends AddressBookService {
  final writes = <ContactEntry>[];

  @override
  Future<bool> editContact(ContactEntry editedContact) async {
    writes.add(editedContact);
    return true;
  }
}

class _TestWallet extends Mock implements Wallet {
  _TestWallet({required this.info, required this.loadAddress});

  @override
  final WalletInfo info;

  final Future<Address?> Function() loadAddress;

  @override
  Future<Address?> getCurrentReceivingAddress() => loadAddress();
}

WalletInfo _walletInfo(String id) => WalletInfo(
  walletId: id,
  name: id,
  mainAddressType: AddressType.p2wpkh,
  coinName: "bitcoin",
  cachedReceivingAddress: "cached-$id",
);

Address _address(String walletId) => Address(
  walletId: walletId,
  value: "address-$walletId",
  publicKey: const [],
  derivationIndex: 0,
  derivationPath: null,
  type: AddressType.p2wpkh,
  subType: AddressSubType.receiving,
);

void main() {
  test("does not replace My Stack with a partial contact", () async {
    final service = _TestAddressBookService();
    final goodWallet = _TestWallet(
      info: _walletInfo("good"),
      loadAddress: () async => _address("good"),
    );
    final failingWallet = _TestWallet(
      info: _walletInfo("failing"),
      loadAddress: () async => throw Exception("temporary failure"),
    );

    await service.updateMyStackContact([goodWallet, failingWallet]);

    expect(service.writes, isEmpty);
  });

  test("serializes My Stack updates in call order", () async {
    final service = _TestAddressBookService();
    final firstStarted = Completer<void>();
    final firstAddress = Completer<Address?>();
    final firstWallet = _TestWallet(
      info: _walletInfo("first"),
      loadAddress: () {
        firstStarted.complete();
        return firstAddress.future;
      },
    );
    final secondWallet = _TestWallet(
      info: _walletInfo("second"),
      loadAddress: () async => _address("second"),
    );

    final firstUpdate = service.updateMyStackContact([firstWallet]);
    await firstStarted.future;
    final secondUpdate = service.updateMyStackContact([secondWallet]);
    await Future<void>.delayed(Duration.zero);

    expect(service.writes, isEmpty);

    firstAddress.complete(_address("first"));
    await Future.wait([firstUpdate, secondUpdate]);

    expect(service.writes, hasLength(2));
    expect(service.writes.last.addresses.single.address, "address-second");
  });
}
