class PaynymAccountLite {
  final String nymId;
  final String nymName;
  final String code;
  final bool segwit;

  PaynymAccountLite(
    this.nymId,
    this.nymName,
    this.code,
    this.segwit,
  );

  PaynymAccountLite.fromMap(Map<String, dynamic> map)
      : nymId = map["nymId"] as String,
        nymName = map["nymName"] as String,
        code = map["code"] as String,
        segwit = map["segwit"] as bool;

  Map<String, dynamic> toMap() => {
        "nymId": nymId,
        "nymName": nymName,
        "code": code,
        "segwit": segwit,
      };

  @override
  String toString() {
    return toMap().toString();
  }
}
