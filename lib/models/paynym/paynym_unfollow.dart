class PaynymUnfollow {
  final String follower;
  final String unfollowing;
  final String token;

  PaynymUnfollow(this.follower, this.unfollowing, this.token);

  PaynymUnfollow.fromMap(Map<String, dynamic> map)
      : follower = map["follower"] as String,
        unfollowing = map["unfollowing"] as String,
        token = map["token"] as String;

  Map<String, dynamic> toMap() => {
        "follower": follower,
        "unfollowing": unfollowing,
        "token": token,
      };

  @override
  String toString() {
    return toMap().toString();
  }
}
