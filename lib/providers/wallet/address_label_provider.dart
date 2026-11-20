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

  // (addressString, walletId) is a unique composite index, so at most one row
  // can match a key.
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
  // The initial value is read synchronously because the query stream only
  // delivers its first result asynchronously, while the card has to render in
  // the frame this watcher is created in.
  _AddressLabelWatcher(AddressLabelStore store, AddressLabelKey key)
    : _value = store.find(key) {
    _subscription = store
        .watch(key)
        .listen(
          (labels) {
            _value = labels.firstOrNull;
            notifyListeners();
          },
          // Keep the last known value and stay subscribed when a query fails
          // (e.g. the db is closed under a visible card); without a handler the
          // failure escapes to the root zone. Never log the key: it contains a
          // wallet address.
          onError: (Object error) {
            debugPrint("address label watch failed: $error");
          },
        );
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

/// The label row of an address, or null when there is none.
///
/// A row whose `value` is empty is a normal state — opening the address details
/// view creates one — so consumers must check `value.isNotEmpty` rather than
/// treating a non-null row as "has a label".
final pAddressLabel = Provider.autoDispose
    .family<AddressLabel?, AddressLabelKey>(
      (ref, key) => ref.watch(_addressLabelWatcherProvider(key)).value,
    );
