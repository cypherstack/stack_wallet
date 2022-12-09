import 'package:epicpay/models/contact_address_entry.dart';
import 'package:epicpay/utilities/address_utils.dart';
import 'package:epicpay/utilities/enums/coin_enum.dart';
import 'package:flutter/cupertino.dart';

class AddressEntryData extends ChangeNotifier {
  late int id;

  AddressEntryData(this.id)
      : _coin = Coin.epicCash,
        _addressLabel = "";

  String? _addressLabel;
  String? _address;
  Coin? _coin;

  String? get addressLabel => _addressLabel;

  set addressLabel(String? addressLabel) {
    _addressLabel = addressLabel;
    notifyListeners();
  }

  String? get address => _address;

  set address(String? address) {
    _address = address;
    notifyListeners();
  }

  Coin? get coin => _coin;

  set coin(Coin? coin) {
    _coin = coin;
    notifyListeners();
  }

  bool get isValid {
    if (_address == null || coin == null || _addressLabel == null) {
      return false;
    }
    if (_address!.isEmpty) {
      return false;
    }
    return isValidAddress;
  }

  bool get isValidAddress {
    if (_address == null || coin == null) {
      return false;
    }
    return AddressUtils.validateAddress(_address!, _coin!);
  }

  ContactAddressEntry buildAddressEntry() {
    return ContactAddressEntry(
        coin: coin!, address: address!, label: addressLabel!);
  }

  @override
  String toString() {
    return "AddressEntryData: { addressLabel: $addressLabel, address: $address, coin: ${coin?.name} }";
  }
}
