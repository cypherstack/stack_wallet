import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../../isar_id_interface.dart';

class Watcher<T extends IsarId> extends ChangeNotifier {
  late final StreamSubscription<T?> _streamSubscription;

  T _value;

  T get value => _value;

  Watcher(
    this._value, {
    required IsarCollection<T> collection,
  }) {
    _streamSubscription = collection.watchObject(_value.id).listen((event) {
      if (event != null) {
        _value = event;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }
}
