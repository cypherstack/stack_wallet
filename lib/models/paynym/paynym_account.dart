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
        followers = [],
        following = [] {
    final f1 = map["followers"] as List<dynamic>;
    for (final item in f1) {
      followers.add(Map<String, dynamic>.from(item as Map)["nymId"] as String);
    }

    final f2 = map["following"] as List<dynamic>;
    for (final item in f2) {
      final nymId = Map<String, dynamic>.from(item as Map)["nymId"] as String;
      print(nymId + "DDDDDDDDDDDDD");
      following.add(nymId);
    }
  }

  Map<String, dynamic> toMap() => {
        "nymID": nymID,
        "nymName": nymName,
        "codes": codes.map((e) => e.toMap()),
        "followers": followers.map((e) => {"nymId": e}).toList(),
        "following": followers.map((e) => {"nymId": e}).toList(),
      };

  @override
  String toString() {
    return toMap().toString();
  }
}
