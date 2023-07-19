import 'package:stackwallet/dto/ordinals/ordinals_response.dart';

class ContentResponse extends OrdinalsResponse<ContentResponse> {
  final FileLink fileLink;

  ContentResponse({required this.fileLink});

  factory ContentResponse.fromJson(OrdinalsResponse json) {
    final data = json.data as Map<String, dynamic>;
    return ContentResponse(fileLink: FileLink.fromJson(data['_links']['file'] as Map<String, dynamic>)); // TODO don't cast as Map<String, dynamic>
  }
}

class FileLink {
  final String href;

  FileLink({required this.href});

  factory FileLink.fromJson(Map<String, dynamic> json) {
    return FileLink(href: json['href'] as String);
  }
}
