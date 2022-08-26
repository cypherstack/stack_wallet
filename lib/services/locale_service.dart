import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/material.dart';

class LocaleService extends ChangeNotifier {
  String _locale = "en_US"; // use default

  String get locale => _locale;

  Future<void> loadLocale({bool notify = true}) async {
    _locale = await Devicelocale.currentLocale ?? "en_US";
    if (notify) {
      notifyListeners();
    }
  }
}
