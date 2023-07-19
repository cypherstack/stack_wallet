class SatResponse {
  final SatLinks links;
  final int block;
  final int cycle;
  final String decimal;
  final String degree;
  final int epoch;
  final String name;
  final int offset;
  final String percentile;
  final int period;
  final String rarity;
  final String timestamp;

  SatResponse({
    required this.links,
    required this.block,
    required this.cycle,
    required this.decimal,
    required this.degree,
    required this.epoch,
    required this.name,
    required this.offset,
    required this.percentile,
    required this.period,
    required this.rarity,
    required this.timestamp,
  });

  factory SatResponse.fromJson(Map<String, dynamic> json) {
    return SatResponse(
      links: SatLinks.fromJson(json['_links'] as Map<String, dynamic>),
      block: json['block'] as int,
      cycle: json['cycle'] as int,
      decimal: json['decimal'] as String,
      degree: json['degree'] as String,
      epoch: json['epoch'] as int,
      name: json['name'] as String,
      offset: json['offset'] as int,
      percentile: json['percentile'] as String,
      period: json['period'] as int,
      rarity: json['rarity'] as String,
      timestamp: json['timestamp'] as String,
    );
  }
}

class SatLinks {
  final SatLink? block;
  final SatLink? inscription;
  final SatLink? next;
  final SatLink? prev;
  final SatLink? self;

  SatLinks({
    this.block,
    this.inscription,
    this.next,
    this.prev,
    this.self,
  });

  factory SatLinks.fromJson(Map<String, dynamic> json) {
    return SatLinks(
      block: SatLink.fromJson(json['block'] as Map<String, dynamic>),
      inscription: SatLink.fromJson(json['inscription'] as Map<String, dynamic>),
      next: SatLink.fromJson(json['next'] as Map<String, dynamic>),
      prev: SatLink.fromJson(json['prev'] as Map<String, dynamic>),
      self: SatLink.fromJson(json['self'] as Map<String, dynamic>),
    );
  }
}

class SatLink {
  final String href;

  SatLink({required this.href});

  factory SatLink.fromJson(Map<String, dynamic> json) {
    return SatLink(href: json['href'] as String);
  }
}
