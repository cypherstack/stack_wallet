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
        .map((inscriptionJson) => InscriptionLink.fromJson(inscriptionJson))
        .toList();

    return AddressResponse(
      links: AddressLinks.fromJson(json['_links']),
      address: json['address'],
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
      self: AddressLink.fromJson(json['self']),
    );
  }
}

class AddressLink {
  final String href;

  AddressLink({required this.href});

  factory AddressLink.fromJson(Map<String, dynamic> json) {
    return AddressLink(href: json['href']);
  }
}
