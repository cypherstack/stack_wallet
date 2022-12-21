import 'package:stackwallet/models/paynym/paynym_code.dart';

class PaynymAccount {
  final String nymID;
  final String nymName;

  final List<PaynymCode> codes;

  /// list of nymId
  final List<String> followers;

  /// list of nymId
  final List<String> following;

  PaynymAccount(
    this.nymID,
    this.nymName,
    this.codes,
    this.followers,
    this.following,
  );

  PaynymAccount.fromMap(Map<String, dynamic> map)
      : nymID = map["nymID"] as String,
        nymName = map["nymName"] as String,
        codes = (map["codes"] as List<dynamic>)
            .map((e) => PaynymCode.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        followers = (map["followers"] as List<dynamic>)
            .map((e) => e["nymId"] as String)
            .toList(),
        following = (map["following"] as List<dynamic>)
            .map((e) => e["nymId"] as String)
            .toList();

  Map<String, dynamic> toMap() => {
        "nymID": nymID,
        "nymName": nymName,
        "codes": codes.map((e) => e.toMap()),
        "followers": followers.map((e) => {"nymId": e}),
        "following": followers.map((e) => {"nymId": e}),
      };

  @override
  String toString() {
    return toMap().toString();
  }
}
