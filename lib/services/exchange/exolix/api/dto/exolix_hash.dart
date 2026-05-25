import 'exolix_base_dto.dart';

/// A transaction hash sub-object (hashIn / hashOut).
class ExolixHash extends ExolixBaseDto {
  final String? hash;
  final String? link;

  ExolixHash({required this.hash, required this.link});

  factory ExolixHash.fromJson(Map<String, dynamic> json) {
    return ExolixHash(
      hash: json["hash"] as String?,
      link: json["link"] as String?,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {"hash": hash, "link": link};
  }
}
