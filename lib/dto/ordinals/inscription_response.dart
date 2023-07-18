class InscriptionResponse {
  final InscriptionLinks links;
  final String address;
  final int contentLength;
  final String contentType;
  final int genesisFee;
  final int genesisHeight;
  final String genesisTransaction;
  final String location;
  final int number;
  final int offset;
  final String output;
  final dynamic sat; // Change to appropriate type if available
  final String timestamp;

  InscriptionResponse({
    required this.links,
    required this.address,
    required this.contentLength,
    required this.contentType,
    required this.genesisFee,
    required this.genesisHeight,
    required this.genesisTransaction,
    required this.location,
    required this.number,
    required this.offset,
    required this.output,
    required this.sat,
    required this.timestamp,
  });

  factory InscriptionResponse.fromJson(Map<String, dynamic> json) {
    return InscriptionResponse(
      links: InscriptionLinks.fromJson(json['_links']),
      address: json['address'],
      contentLength: json['content_length'],
      contentType: json['content_type'],
      genesisFee: json['genesis_fee'],
      genesisHeight: json['genesis_height'],
      genesisTransaction: json['genesis_transaction'],
      location: json['location'],
      number: json['number'],
      offset: json['offset'],
      output: json['output'],
      sat: json['sat'],
      timestamp: json['timestamp'],
    );
  }
}

class InscriptionLinks {
  final InscriptionLink? content;
  final InscriptionLink? genesisTransaction;
  final InscriptionLink? next;
  final InscriptionLink? output;
  final InscriptionLink? prev;
  final InscriptionLink? preview;
  final InscriptionLink? sat;
  final InscriptionLink? self;

  InscriptionLinks({
    this.content,
    this.genesisTransaction,
    this.next,
    this.output,
    this.prev,
    this.preview,
    this.sat,
    this.self,
  });

  factory InscriptionLinks.fromJson(Map<String, dynamic> json) {
    return InscriptionLinks(
      content: InscriptionLink.fromJson(json['content']),
      genesisTransaction: InscriptionLink.fromJson(json['genesis_transaction']),
      next: InscriptionLink.fromJson(json['next']),
      output: InscriptionLink.fromJson(json['output']),
      prev: InscriptionLink.fromJson(json['prev']),
      preview: InscriptionLink.fromJson(json['preview']),
      sat: InscriptionLink.fromJson(json['sat']),
      self: InscriptionLink.fromJson(json['self']),
    );
  }
}

class InscriptionLink {
  final String href;
  final String title;

  InscriptionLink({required this.href, required this.title});

  factory InscriptionLink.fromJson(Map<String, dynamic> json) {
    return InscriptionLink(href: json['href'], title: json['title']);
  }
}
