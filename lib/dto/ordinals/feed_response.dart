import 'package:stackwallet/dto/ordinals/inscription_link.dart';

class FeedResponse {
  final List<InscriptionLink> inscriptions;

  FeedResponse({required this.inscriptions});

  factory FeedResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> inscriptionsJson = json['_links']['inscriptions'] as List<dynamic>;
    final List<InscriptionLink> inscriptions = inscriptionsJson
        .map((json) => InscriptionLink.fromJson(json as Map<String, dynamic>))
        .toList();

    return FeedResponse(inscriptions: inscriptions);
  }
}
