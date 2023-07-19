import 'package:stackwallet/dto/ordinals/transaction_response.dart';
import 'package:stackwallet/dto/ordinals/ordinals_response.dart';

class OutputResponse extends OrdinalsResponse<OutputResponse> {
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

  factory OutputResponse.fromJson(OrdinalsResponse json) {
    final data = json.data as Map<String, dynamic>;

    return OutputResponse(
      links: OutputLinks.fromJson(data['_links'] as Map<String, dynamic>),
      address: data['address'] as String,
      scriptPubkey: data['script_pubkey'] as String,
      transaction: data['transaction'] as String,
      value: data['value'] as int,
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
      self: json['self'] != null ? OutputLink.fromJson(json['self'] as Map<String, dynamic>) : null,
      transaction: json['transaction'] != null ? TransactionLink.fromJson(json['transaction'] as Map<String, dynamic>) : null,
    );
  }
}
