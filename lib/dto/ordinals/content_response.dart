class ContentResponse {
  final FileLink fileLink;

  ContentResponse({required this.fileLink});

  factory ContentResponse.fromJson(Map<String, dynamic> json) {
    return ContentResponse(fileLink: FileLink.fromJson(json['_links']['file'] as Map<String, dynamic>));
  }
}

class FileLink {
  final String href;

  FileLink({required this.href});

  factory FileLink.fromJson(Map<String, dynamic> json) {
    return FileLink(href: json['href'] as String);
  }
}
