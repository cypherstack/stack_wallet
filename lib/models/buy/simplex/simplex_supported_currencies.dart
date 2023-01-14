import 'package:stackwallet/models/buy/response_objects/crypto.dart';
import 'package:stackwallet/models/buy/response_objects/fiat.dart';
// import 'package:stackwallet/models/buy/response_objects/pair.dart';

class SimplexSupportedCurrencies {
  List<Crypto> supportedCryptos = [];
  List<Fiat> supportedFiats = [];

  void updateSupportedCryptos(List<Crypto> newCryptos) {
    supportedCryptos = newCryptos;
  }

  void updateSupportedFiats(List<Fiat> newFiats) {
    supportedFiats = newFiats;
  }
}
