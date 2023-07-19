import 'package:stackwallet/dto/ordinals/transaction_response.dart';

class OutputResponse {
  final OutputLinks links;
  final String address;
  final String scriptPubkey;
  final String transaction;
  final int value;

  OutputResponse({
    required this.links,
    required this.address,
    required this.scriptPubkey,
    required this.transaction,
    required this.value,
  });

  factory OutputResponse.fromJson(Map<String, dynamic> json) {
    return OutputResponse(
      links: OutputLinks.fromJson(json['_links'] as Map<String, dynamic>),
      address: json['address'] as String,
      scriptPubkey: json['script_pubkey'] as String,
      transaction: json['transaction'] as String,
      value: json['value'] as int,
    );
  }
}

class OutputLinks {
  final OutputLink? self;
  final TransactionLink? transaction;

  OutputLinks({
    this.self,
    this.transaction,
  });

  factory OutputLinks.fromJson(Map<String, dynamic> json) {
    return OutputLinks(
      self: OutputLink.fromJson(json['self'] as Map<String, dynamic>),
      transaction: TransactionLink.fromJson(json['transaction'] as Map<String, dynamic>),
    );
  }
}
