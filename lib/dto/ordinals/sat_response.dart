import 'package:stackwallet/dto/ordinals/ordinals_response.dart';

class SatResponse extends OrdinalsResponse<SatResponse> {
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

  factory SatResponse.fromJson(OrdinalsResponse json) {
    final data = json.data as Map<String, dynamic>;
    return SatResponse(
      links: SatLinks.fromJson(data['_links'] as Map<String, dynamic>),
      block: data['block'] as int,
      cycle: data['cycle'] as int,
      decimal: data['decimal'] as String,
      degree: data['degree'] as String,
      epoch: data['epoch'] as int,
      name: data['name'] as String,
      offset: data['offset'] as int,
      percentile: data['percentile'] as String,
      period: data['period'] as int,
      rarity: data['rarity'] as String,
      timestamp: data['timestamp'] as String,
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
      block: json['block'] != null ? SatLink.fromJson(json['block'] as Map<String, dynamic>) : null,
      inscription: json['inscription'] != null ? SatLink.fromJson(json['inscription'] as Map<String, dynamic>) : null,
      next: json['next'] != null ? SatLink.fromJson(json['next'] as Map<String, dynamic>) : null,
      prev: json['prev'] != null ? SatLink.fromJson(json['prev'] as Map<String, dynamic>) : null,
      self: json['self'] != null ? SatLink.fromJson(json['self'] as Map<String, dynamic>) : null,
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
