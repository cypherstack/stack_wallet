import 'package:stackwallet/dto/ordinals/inscription_response.dart';

class AddressResponse {
  final AddressLinks links;
  final String address;
  final List<InscriptionLink> inscriptions;

  AddressResponse({
    required this.links,
    required this.address,
    required this.inscriptions,
  });

  factory AddressResponse.fromJson(Map<String, dynamic> json) {
    final inscriptionsJson = json['inscriptions'] as List;
    final inscriptions = inscriptionsJson
        .map((inscriptionJson) => InscriptionLink.fromJson(inscriptionJson as Map<String, dynamic>))
        .toList();

    return AddressResponse(
      links: AddressLinks.fromJson(json['_links'] as Map<String, dynamic>),
      address: json['address'] as String,
      inscriptions: inscriptions,
    );
  }
}

class AddressLinks {
  final AddressLink? self;

  AddressLinks({
    this.self,
  });

  factory AddressLinks.fromJson(Map<String, dynamic> json) {
    return AddressLinks(
      self: AddressLink.fromJson(json['self'] as Map<String, dynamic>),
    );
  }
}

class AddressLink {
  final String href;

  AddressLink({required this.href});

  factory AddressLink.fromJson(Map<String, dynamic> json) {
    return AddressLink(href: json['href'] as String);
  }
}

class InscriptionLink {
  final String href;
  final String title;

  InscriptionLink(this.href, this.title);

  factory InscriptionLink.fromJson(Map<String, dynamic> json) {
    return InscriptionLink(json['href'] as String, json['title'] as String);
  }
}
