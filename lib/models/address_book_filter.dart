import 'package:flutter/material.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';

class AddressBookFilter extends ChangeNotifier {
  AddressBookFilter(Set<Coin> coins) {
    _coins = coins;
  }

  Set<Coin> _coins = {};

  Set<Coin> get coins => _coins;

  set coins(Set<Coin> coins) {
    _coins = coins;
    notifyListeners();
  }

  void add(Coin coin, bool shouldNotifyListeners) {
    _coins.add(coin);
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  void addAll(Iterable<Coin> coins, bool shouldNotifyListeners) {
    _coins.addAll(coins);
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  void remove(Coin coin, bool shouldNotifyListeners) {
    _coins.removeWhere((e) => e.name == coin.name);
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  void removeMany(Set<Coin> coins, bool shouldNotifyListeners) {
    for (final coin in coins) {
      _coins.removeWhere((e) => e.name == coin.name);
    }
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }
}
