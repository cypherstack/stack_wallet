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
