import '../../models/isar/models/blockchain_data/address.dart';
import '../../utilities/amount/amount.dart';

class TxRecipient {
  final String address;
  final Amount amount;
  final bool isChange;
  final AddressType addressType;

  TxRecipient({
    required this.address,
    required this.amount,
    required this.isChange,
    required this.addressType,
  });

  TxRecipient copyWith({
    String? address,
    Amount? amount,
    bool? isChange,
    AddressType? addressType,
  }) {
    return TxRecipient(
      address: address ?? this.address,
      amount: amount ?? this.amount,
      isChange: isChange ?? this.isChange,
      addressType: addressType ?? this.addressType,
    );
  }

  @override
  String toString() {
    return "TxRecipient{"
        "address: $address, "
        "amount: $amount, "
        "isChange: $isChange, "
        "addressType: $addressType"
        "}";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TxRecipient &&
          address == other.address &&
          amount == other.amount &&
          isChange == other.isChange &&
          addressType == other.addressType;

  @override
  int get hashCode => Object.hash(address, amount, isChange, addressType);
}
