import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/utilities/amount/amount.dart';

// TODO use something like this instead of Map<String, dynamic> transactionObject

class TxInfo {
  final String hex;
  final List<TxRecipient> recipients;
  final Amount fee;
  final int vSize;
  final List<UTXO>? usedUTXOs;

  TxInfo({
    required this.hex,
    required this.recipients,
    required this.fee,
    required this.vSize,
    required this.usedUTXOs,
  });

  TxInfo copyWith({
    String? hex,
    List<TxRecipient>? recipients,
    Amount? fee,
    int? vSize,
    List<UTXO>? usedUTXOs,
  }) =>
      TxInfo(
        hex: hex ?? this.hex,
        fee: fee ?? this.fee,
        vSize: vSize ?? this.vSize,
        usedUTXOs: usedUTXOs ?? this.usedUTXOs,
        recipients: recipients ?? this.recipients,
      );
}

class TxRecipient {
  final String address;
  final Amount amount;

  TxRecipient({
    required this.address,
    required this.amount,
  });
}
