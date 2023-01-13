// import 'package:stackwallet/models/buy/response_objects/crypto.dart';
// import 'package:stackwallet/models/buy/response_objects/fiat.dart';
// import 'package:stackwallet/models/buy/response_objects/pair.dart';

class SimplexAvailableCurrencies {
  dynamic supportedCryptos = [];
  dynamic supportedFiats = [];

  void updateSupportedCryptos(dynamic newCryptos) {
    supportedCryptos = newCryptos;
  }

  void updateSupportedFiats(dynamic newFiats) {
    supportedFiats = newFiats;
  }
}
