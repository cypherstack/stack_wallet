class PaynymClaim {
  final String claimed;
  final String token;

  PaynymClaim(this.claimed, this.token);

  PaynymClaim.fromMap(Map<String, dynamic> map)
      : claimed = map["claimed"] as String,
        token = map["token"] as String;

  Map<String, dynamic> toMap() => {
        "claimed": claimed,
        "token": token,
      };

  @override
  String toString() {
    return toMap().toString();
  }
}
