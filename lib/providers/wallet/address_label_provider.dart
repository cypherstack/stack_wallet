import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../models/isar/models/address_label.dart';
import '../db/main_db_provider.dart';

typedef AddressLabelKey = ({String walletId, String address});

abstract interface class AddressLabelStore {
  AddressLabel? find(AddressLabelKey key);

  Stream<List<AddressLabel>> watch(AddressLabelKey key);
}

class _MainDBAddressLabelStore implements AddressLabelStore {
  const _MainDBAddressLabelStore(this.isar);

  final Isar isar;

  QueryBuilder<AddressLabel, AddressLabel, QAfterWhereClause> _query(
    AddressLabelKey key,
  ) => isar.addressLabels.where().addressStringWalletIdEqualTo(
    key.address,
    key.walletId,
  );

  @override
  AddressLabel? find(AddressLabelKey key) => _query(key).findFirstSync();

  @override
  Stream<List<AddressLabel>> watch(AddressLabelKey key) =>
      _query(key).watch(fireImmediately: true);
}

final addressLabelStoreProvider = Provider<AddressLabelStore>((ref) {
  return _MainDBAddressLabelStore(ref.watch(mainDBProvider).isar);
});

class _AddressLabelWatcher extends ChangeNotifier {
  _AddressLabelWatcher(AddressLabelStore store, AddressLabelKey key)
    : _value = store.find(key) {
    _subscription = store.watch(key).listen((labels) {
      _value = labels.firstOrNull;
      notifyListeners();
    });
  }

  late final StreamSubscription<List<AddressLabel>> _subscription;
  AddressLabel? _value;

  AddressLabel? get value => _value;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final _addressLabelWatcherProvider = ChangeNotifierProvider.autoDispose
    .family<_AddressLabelWatcher, AddressLabelKey>((ref, key) {
      return _AddressLabelWatcher(ref.watch(addressLabelStoreProvider), key);
    });

final pAddressLabel = Provider.autoDispose
    .family<AddressLabel?, AddressLabelKey>(
      (ref, key) => ref.watch(_addressLabelWatcherProvider(key)).value,
    );
