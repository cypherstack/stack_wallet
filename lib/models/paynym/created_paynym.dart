class CreatedPaynym {
  final bool claimed;
  final String nymAvatar;
  final String? nymId;
  final String? nymName;
  final String? token;

  CreatedPaynym(
    this.claimed,
    this.nymAvatar,
    this.nymId,
    this.nymName,
    this.token,
  );

  CreatedPaynym.fromMap(Map<String, dynamic> map)
      : claimed = map["claimed"] as bool,
        nymAvatar = map["nymAvatar"] as String,
        nymId = map["nymId"] as String?,
        nymName = map["nymName"] as String?,
        token = map["token"] as String?;

  Map<String, dynamic> toMap() => {
        "claimed": claimed,
        "nymAvatar": nymAvatar,
        "nymId": nymId,
        "nymName": nymName,
        "token": token,
      };

  @override
  String toString() {
    return toMap().toString();
  }
}
