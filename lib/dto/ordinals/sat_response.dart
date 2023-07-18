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
      links: SatLinks.fromJson(json['_links']),
      block: json['block'],
      cycle: json['cycle'],
      decimal: json['decimal'],
      degree: json['degree'],
      epoch: json['epoch'],
      name: json['name'],
      offset: json['offset'],
      percentile: json['percentile'],
      period: json['period'],
      rarity: json['rarity'],
      timestamp: json['timestamp'],
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
      block: SatLink.fromJson(json['block']),
      inscription: SatLink.fromJson(json['inscription']),
      next: SatLink.fromJson(json['next']),
      prev: SatLink.fromJson(json['prev']),
      self: SatLink.fromJson(json['self']),
    );
  }
}

class SatLink {
  final String href;

  SatLink({required this.href});

  factory SatLink.fromJson(Map<String, dynamic> json) {
    return SatLink(href: json['href']);
  }
}
