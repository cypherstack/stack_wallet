import '../../models/isar/models/blockchain_data/address.dart';
import '../../utilities/amount/amount.dart';

class TxRecipient {
  final String address;
  final Amount amount;
  final bool isChange;
  final AddressType? addressType;

  TxRecipient({
    required this.address,
    required this.amount,
    required this.isChange,
    this.addressType,
  });
}
