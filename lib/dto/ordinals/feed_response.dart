class FeedResponse {
  final List<InscriptionLink> inscriptions;

  FeedResponse(this.inscriptions);

  factory FeedResponse.fromJson(Map<String, dynamic> json) {
    final inscriptionsJson = json['_links']['inscriptions'] as List;
    final inscriptions = inscriptionsJson
        .map((inscriptionJson) => InscriptionLink.fromJson(inscriptionJson))
        .toList();

    return FeedResponse(inscriptions);
  }
}
