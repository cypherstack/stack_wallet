class PaynymCode {
  final bool claimed;
  final bool segwit;
  final String code;

  PaynymCode(
    this.claimed,
    this.segwit,
    this.code,
  );

  PaynymCode.fromMap(Map<String, dynamic> map)
      : claimed = map["claimed"] as bool,
        segwit = map["segwit"] as bool,
        code = map["code"] as String;

  Map<String, dynamic> toMap() => {
        "claimed": claimed,
        "segwit": segwit,
        "code": code,
      };

  @override
  String toString() {
    return toMap().toString();
  }
}
