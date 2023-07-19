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

class InscriptionLink {
  final String href;
  final String title;

  InscriptionLink({required this.href, required this.title});

  factory InscriptionLink.fromJson(Map<String, dynamic> json) {
    return InscriptionLink(
      href: json['href'] as String ?? '',
      title: json['title'] as String ?? '',
    );
  }
}
