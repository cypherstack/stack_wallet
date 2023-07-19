import 'package:stackwallet/dto/ordinals/ordinals_response.dart';

class BlockResponse extends OrdinalsResponse<BlockResponse> {
  final BlockLinks links;
  final String hash;
  final String previousBlockhash;
  final int size;
  final String target;
  final String timestamp;
  final int weight;

  BlockResponse({
    required this.links,
    required this.hash,
    required this.previousBlockhash,
    required this.size,
    required this.target,
    required this.timestamp,
    required this.weight,
  });

  factory BlockResponse.fromJson(OrdinalsResponse json) {
    final data = json.data as Map<String, dynamic>;
    return BlockResponse(
      links: BlockLinks.fromJson(data['_links'] as Map<String, dynamic>),
      hash: data['hash'] as String,
      previousBlockhash: data['previous_blockhash'] as String,
      size: data['size'] as int,
      target: data['target'] as String,
      timestamp: data['timestamp'] as String,
      weight: data['weight'] as int,
    );
  }
}

class BlockLinks {
  final BlockLink? prev;
  final BlockLink? self;

  BlockLinks({
    this.prev,
    this.self,
  });

  factory BlockLinks.fromJson(Map<String, dynamic> json) {
    return BlockLinks(
      prev: json['prev'] != null ? BlockLink.fromJson(json['prev'] as Map<String, dynamic>) : null,
      self: json['self'] != null ? BlockLink.fromJson(json['self'] as Map<String, dynamic>) : null,
    );
  }
}

class BlockLink {
  final String href;

  BlockLink({required this.href});

  factory BlockLink.fromJson(Map<String, dynamic> json) {
    return BlockLink(href: json['href'] as String);
  }
}
