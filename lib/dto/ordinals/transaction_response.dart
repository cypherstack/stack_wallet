class TransactionResponse {
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

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    final inputsJson = json['_links']['inputs'] as List;
    final inputs = inputsJson
        .map((inputJson) => OutputLink.fromJson(inputJson))
        .toList();

    final outputsJson = json['_links']['outputs'] as List;
    final outputs = outputsJson
        .map((outputJson) => OutputLink.fromJson(outputJson))
        .toList();

    return TransactionResponse(
      links: TransactionLinks.fromJson(json['_links']),
      inputs: inputs,
      inscription: InscriptionLink.fromJson(json['_links']['inscription']),
      outputs: outputs,
      self: TransactionLink.fromJson(json['_links']['self']),
      transaction: json['transaction'],
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
      block: TransactionLink.fromJson(json['block']),
      inscription: InscriptionLink.fromJson(json['inscription']),
      self: TransactionLink.fromJson(json['self']),
    );
  }
}

class TransactionLink {
  final String href;

  TransactionLink({required this.href});

  factory TransactionLink.fromJson(Map<String, dynamic> json) {
    return TransactionLink(href: json['href']);
  }
}

class OutputLink {
  final String href;

  OutputLink({required this.href});

  factory OutputLink.fromJson(Map<String, dynamic> json) {
    return OutputLink(href: json['href']);
  }
}
