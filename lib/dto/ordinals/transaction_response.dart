import 'package:stackwallet/dto/ordinals/inscription_link.dart';
import 'package:stackwallet/dto/ordinals/ordinals_response.dart';

class TransactionResponse extends OrdinalsResponse<TransactionResponse> {
  final TransactionLinks links;
  final List<OutputLink> inputs;
  final InscriptionLink inscription;
  final List<OutputLink> outputs;
  final TransactionLink self;
  final String transaction;

  TransactionResponse({
    required this.links,
    required this.inputs,
    required this.inscription,
    required this.outputs,
    required this.self,
    required this.transaction,
  });

  factory TransactionResponse.fromJson(OrdinalsResponse json) {
    final data = json.data as Map<String, dynamic>;
    final inputsJson = data['_links']['inputs'] as List;
    final inputs = inputsJson
        .map((inputJson) => OutputLink.fromJson(inputJson as Map<String, dynamic>))
        .toList();

    final outputsJson = data['_links']['outputs'] as List;
    final outputs = outputsJson
        .map((outputJson) => OutputLink.fromJson(outputJson as Map<String, dynamic>))
        .toList();

    return TransactionResponse(
      links: TransactionLinks.fromJson(data['_links'] as Map<String, dynamic>),
      inputs: inputs,
      inscription: InscriptionLink.fromJson(data['_links']['inscription'] as Map<String, dynamic>),
      outputs: outputs,
      self: TransactionLink.fromJson(data['_links']['self'] as Map<String, dynamic>),
      transaction: data['transaction'] as String,
    );
  }
}

class TransactionLinks {
  final TransactionLink? block;
  final InscriptionLink? inscription;
  final TransactionLink? self;

  TransactionLinks({
    this.block,
    this.inscription,
    this.self,
  });

  factory TransactionLinks.fromJson(Map<String, dynamic> json) {
    return TransactionLinks(
      block: json['block'] != null ? TransactionLink.fromJson(json['block'] as Map<String, dynamic>) : null,
      inscription: json['inscription'] != null ? InscriptionLink.fromJson(json['inscription'] as Map<String, dynamic>) : null,
      self: json['self'] != null ? TransactionLink.fromJson(json['self'] as Map<String, dynamic>) : null,
    );
  }
}

class TransactionLink {
  final String href;

  TransactionLink({required this.href});

  factory TransactionLink.fromJson(Map<String, dynamic> json) {
    return TransactionLink(href: json['href'] as String);
  }
}

class OutputLink {
  final String href;

  OutputLink({required this.href});

  factory OutputLink.fromJson(Map<String, dynamic> json) {
    return OutputLink(href: json['href'] as String);
  }
}
