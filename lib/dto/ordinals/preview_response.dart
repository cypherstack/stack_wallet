class PreviewResponse {
  final ImageLink imageLink;

  PreviewResponse({required this.imageLink});

  factory PreviewResponse.fromJson(Map<String, dynamic> json) {
    return PreviewResponse(imageLink: ImageLink.fromJson(json['_links']['image'] as Map<String, dynamic>));
  }
}

class ImageLink {
  final String href;

  ImageLink({required this.href});

  factory ImageLink.fromJson(Map<String, dynamic> json) {
    return ImageLink(href: json['href'] as String);
  }
}