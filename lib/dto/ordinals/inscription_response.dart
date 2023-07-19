import 'package:stackwallet/dto/ordinals/ordinals_response.dart';

class InscriptionResponse extends OrdinalsResponse<InscriptionResponse> {
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

  factory InscriptionResponse.fromJson(OrdinalsResponse json) {
    final data = json.data as Map<String, dynamic>;
    return InscriptionResponse(
      links: Links.fromJson(data['_links'] as Map<String, dynamic>),
      address: data['address'] as String,
      contentLength: data['content_length'] as int,
      contentType: data['content_type'] as String,
      genesisFee: data['genesis_fee'] as int,
      genesisHeight: data['genesis_height'] as int,
      genesisTransaction: data['genesis_transaction'] as String,
      location: data['location'] as String,
      number: data['number'] as int,
      offset: data['offset'] as int,
      output: data['output'] as String,
      sat: data['sat'] as String?,
      timestamp: data['timestamp'] as String,
    );
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

  factory Links.fromJson(Map<String, dynamic> json) {
    return Links(
      content: Link.fromJson(json['content'] as Map<String, dynamic>),
      genesisTransaction: Link.fromJson(json['genesis_transaction'] as Map<String, dynamic>),
      next: Link.fromJson(json['next'] as Map<String, dynamic>),
      output: Link.fromJson(json['output'] as Map<String, dynamic>),
      prev: Link.fromJson(json['prev'] as Map<String, dynamic>),
      preview: Link.fromJson(json['preview'] as Map<String, dynamic>),
      sat: json['sat'] != null ? Link.fromJson(json['sat'] as Map<String, dynamic>) : null,
      self: Link.fromJson(json['self'] as Map<String, dynamic>),
    );
  }
}

class Link {
  late final String href;

  Link({required this.href});

  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(href: json['href'] as String);
  }
}
