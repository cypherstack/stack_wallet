import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/services/price.dart';

final baseCurrenciesProvider =
    ChangeNotifierProvider<_BaseCurrencies>((_) => _BaseCurrencies());

class _BaseCurrencies extends ChangeNotifier {
  Map<String, String> _map = {..._kCurrencyMap};

  Map<String, String> get map => _map;

  set map(Map<String, String> value) {
    _map = value;
    notifyListeners();
  }

  Future<void> update() async {
    final list = await PriceAPI.availableBaseCurrencies();
    if (list == null) {
      return;
    }

    Map<String, String> newMap = {};

    for (final entry in _kCurrencyMap.entries) {
      if (list.contains(entry.key.toLowerCase())) {
        newMap[entry.key] = entry.value;
      }
    }

    map = newMap;
  }
}

const Map<String, String> _kCurrencyMap = {
  'AUD': 'Australian Dollar',
  'AED': 'United Arab Emirates Dirham',
  'ARS': 'Argentine Peso',
  'BDT': 'Bangladeshi Taka',
  'BHD': 'Bahraini Dinar',
  'BMD': 'Bermudan Dollar',
  'BRL': 'Brazilian Real',
  'CAD': 'Canadian Dollar',
  'CHF': 'Swiss Franc',
  "CLP": 'Chilean Peso',
  'CNY': 'Chinese Yuan',
  "CZK": 'Czech Koruna',
  "DKK": 'Danish Krone',
  'EUR': 'Euro',
  'GBP': 'Pound sterling',
  'HKD': 'Hong Kong Dollar',
  "HUF": 'Hungarian Forint',
  "IDR": 'Indonesian Rupiah',
  "ILS": 'Israeli New Shekel',
  'INR': 'Indian Rupee',
  'JPY': 'Japanese Yen',
  'KRW': 'South Korean won',
  "KWD": 'Kuwaiti Dinar',
  "LKR": 'Sri Lankan Rupee',
  "MMK": 'Myanmar Kyat',
  "MXN": 'Mexican Peso',
  "MYR": 'Malaysian Ringgit',
  "NGN": 'Nigerian Naira',
  "NOK": 'Norwegian Krone',
  "NZD": 'New Zealand Dollar',
  'PHP': 'Philippine peso',
  "PKR": 'Pakistani Rupee',
  "PLN": 'Poland złoty',
  "RUB": 'Russian Ruble',
  "SAR": 'Saudi Riyal ',
  "SEK": 'Swedish Krona',
  'SGD': 'Singapore Dollar',
  "THB": 'Thai Baht',
  'TRY': 'Turkish lira',
  "TWD": 'New Taiwan dollar',
  "UAH": 'Ukrainian hryvnia',
  'USD': 'United States Dollar',
  "VEF": 'Venezuelan Bolívar',
  "VND": 'Vietnamese dong',
  "ZAR": 'South African Rand',
  "XDR": 'Special Drawing Rights',
  "XAG": 'Silver Ounce',
  'XAU': 'Gold Ounce',
  "BTC": "Bitcoin",
  "ETH": "Ethereum",
  "LTC": "Litecoin",
  "BCH": "Bitcoin Cash",
  "BNB": "Binance Coin",
  "EOS": "EOS",
  "XRP": "Ripple",
  "XLM": "Stellar",
  "LINK": "Chainlink",
  "DOT": "Polkadot",
  "YFI": "yearn.finance",
  "sats": "Satoshis",
};
