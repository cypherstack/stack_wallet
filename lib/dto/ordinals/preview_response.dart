import 'package:stackwallet/dto/ordinals/ordinals_response.dart';

class PreviewResponse extends OrdinalsResponse<PreviewResponse> {
  final ImageLink imageLink;

  PreviewResponse({required this.imageLink});

  factory PreviewResponse.fromJson(OrdinalsResponse json) {
    final data = json.data as Map<String, dynamic>;
    return PreviewResponse(imageLink: ImageLink.fromJson(data['_links']['image'] as Map<String, dynamic>));
  }
}

class ImageLink {
  final String href;

  ImageLink({required this.href});

  factory ImageLink.fromJson(Map<String, dynamic> json) {
    return ImageLink(href: json['href'] as String);
  }
}
