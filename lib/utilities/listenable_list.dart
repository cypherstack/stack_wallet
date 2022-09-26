import 'package:flutter/foundation.dart';

class ListenableList<T> extends ChangeNotifier {
  final List<T> _list = [];

  int get length => _list.length;

  T operator [](int index) {
    return _list[index];
  }

  void add(T value, bool shouldNotifyListeners) {
    _list.add(value);
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  void insert(int index, T value, bool shouldNotifyListeners) {
    _list.insert(index, value);
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  T removeAt(int index, bool shouldNotifyListeners) {
    final T value = _list.removeAt(index);
    if (shouldNotifyListeners) {
      notifyListeners();
    }
    return value;
  }

  void remove(Object? object, bool shouldNotifyListeners) {
    _list.remove(object);
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  bool contains(Object? element) {
    return _list.contains(element);
  }

  void reorder(int oldIndex, int newIndex, bool shouldNotifyListeners) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final T value = _list.removeAt(oldIndex);
    _list.insert(newIndex, value);
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Iterable<E> map<E>(E Function(T) toElement) {
    return _list.map(toElement);
  }
}
