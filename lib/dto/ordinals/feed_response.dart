import 'package:stackwallet/dto/ordinals/inscription_link.dart';
import 'package:stackwallet/dto/ordinals/ordinals_response.dart';

class FeedResponse extends OrdinalsResponse<FeedResponse> {
  final List<InscriptionLink> inscriptions;

  FeedResponse({required this.inscriptions});
  
  factory FeedResponse.fromJson(OrdinalsResponse json) {
    final List<dynamic> inscriptionsJson = json.data['_links']['inscriptions'] as List<dynamic>;
    final List<InscriptionLink> inscriptions = inscriptionsJson
        .map((json) => InscriptionLink.fromJson(json as Map<String, dynamic>))
        .toList();

    return FeedResponse(inscriptions: inscriptions);
  }
}