import 'package:stackwallet/models/paynym/paynym_account_lite.dart';
import 'package:stackwallet/models/paynym/paynym_code.dart';

class PaynymAccount {
  final String nymID;
  final String nymName;

  final List<PaynymCode> codes;

  /// list of nymId
  final List<PaynymAccountLite> followers;

  /// list of nymId
  final List<PaynymAccountLite> following;

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
            .map((e) =>
                PaynymAccountLite.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        following = (map["following"] as List<dynamic>)
            .map((e) =>
                PaynymAccountLite.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();

  Map<String, dynamic> toMap() => {
        "nymID": nymID,
        "nymName": nymName,
        "codes": codes.map((e) => e.toMap()),
        "followers": followers.map((e) => e.toMap()),
        "following": followers.map((e) => e.toMap()),
      };

  @override
  String toString() {
    return toMap().toString();
  }
}
