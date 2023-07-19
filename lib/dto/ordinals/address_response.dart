import 'package:stackwallet/dto/ordinals/inscription_link.dart';
import 'package:stackwallet/dto/ordinals/ordinals_response.dart';

class AddressResponse extends OrdinalsResponse<AddressResponse> {
  final AddressLinks links;
  final String address;
  final List<InscriptionLink> inscriptions;

  AddressResponse({
    required this.links,
    required this.address,
    required this.inscriptions,
  });

  factory AddressResponse.fromJson(OrdinalsResponse json) {
    final data = json.data as Map<String, dynamic>;
    final inscriptionsJson = data['inscriptions'] as List;
    final inscriptions = inscriptionsJson
        .map((inscriptionJson) => InscriptionLink.fromJson(inscriptionJson as Map<String, dynamic>))
        .toList();

    return AddressResponse(
      links: AddressLinks.fromJson(data['_links'] as Map<String, dynamic>),
      address: data['address'] as String,
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
      self: json['self'] != null ? AddressLink.fromJson(json['self'] as Map<String, dynamic>) : null,
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
