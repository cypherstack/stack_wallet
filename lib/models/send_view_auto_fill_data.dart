import 'package:decimal/decimal.dart';

class SendViewAutoFillData {
  final String address;
  final String contactLabel;
  final Decimal? amount;
  final String note;

  SendViewAutoFillData({
    required this.address,
    required this.contactLabel,
    this.amount,
    this.note = "",
  });

  Map<String, dynamic> toJson() {
    return {
      "address": address,
      "contactLabel": contactLabel,
      "amount": amount,
      "note": note,
    };
  }

  @override
  String toString() {
    return toJson().toString();
  }
}
