class InscriptionResponse {
  late final Links links;
  late final String address;
  late final int contentLength;
  late final String contentType;
  late final int genesisFee;
  late final int genesisHeight;
  late final String genesisTransaction;
  late final String location;
  late final int number;
  late final int offset;
  late final String output;
  late final String? sat; // Make sure to update the type to allow null
  late final String timestamp;

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

  InscriptionResponse.fromJson(Map<String, dynamic> json) {
    links = Links.fromJson(json['_links'] as Map<String, dynamic>);
    address = json['address'] as String;
    contentLength = json['content_length'] as int;
    contentType = json['content_type'] as String;
    genesisFee = json['genesis_fee'] as int;
    genesisHeight = json['genesis_height'] as int;
    genesisTransaction = json['genesis_transaction'] as String;
    location = json['location'] as String;
    number = json['number'] as int;
    offset = json['offset'] as int;
    output = json['output'] as String;
    sat = json['sat'] as String?;
    timestamp = json['timestamp'] as String;
  }
}

class Links {
  late final Link content;
  late final Link genesisTransaction;
  late final Link next;
  late final Link output;
  late final Link prev;
  late final Link preview;
  late final Link? sat; // Make sure to update the type to allow null
  late final Link self;

  Links({
    required this.content,
    required this.genesisTransaction,
    required this.next,
    required this.output,
    required this.prev,
    required this.preview,
    this.sat,
    required this.self,
  });

  Links.fromJson(Map<String, dynamic> json) {
    content = Link.fromJson(json['content'] as Map<String, dynamic>);
    genesisTransaction = Link.fromJson(json['genesis_transaction'] as Map<String, dynamic>);
    next = Link.fromJson(json['next'] as Map<String, dynamic>);
    output = Link.fromJson(json['output'] as Map<String, dynamic>);
    prev = Link.fromJson(json['prev'] as Map<String, dynamic>);
    preview = Link.fromJson(json['preview'] as Map<String, dynamic>);
    sat = json['sat'] != null ? Link.fromJson(json['sat'] as Map<String, dynamic>) : null;
    self = Link.fromJson(json['self'] as Map<String, dynamic>);
  }
}

class Link {
  late final String href;

  Link({required this.href});

  Link.fromJson(Map<String, dynamic> json) {
    href = json['href'] as String;
  }
}