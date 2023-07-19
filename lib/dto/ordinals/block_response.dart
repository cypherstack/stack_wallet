class BlockResponse {
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

  factory BlockResponse.fromJson(Map<String, dynamic> json) {
    return BlockResponse(
      links: BlockLinks.fromJson(json['_links'] as Map<String, dynamic>),
      hash: json['hash'] as String,
      previousBlockhash: json['previous_blockhash'] as String,
      size: json['size'] as int,
      target: json['target'] as String,
      timestamp: json['timestamp'] as String,
      weight: json['weight'] as int,
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
      prev: BlockLink.fromJson(json['prev'] as Map<String, dynamic>),
      self: BlockLink.fromJson(json['self'] as Map<String, dynamic>),
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
