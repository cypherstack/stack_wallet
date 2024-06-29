import '../../utilities/amount/amount.dart';

class TxRecipient {
  final String address;
  final Amount amount;

  TxRecipient({
    required this.address,
    required this.amount,
  });
}
