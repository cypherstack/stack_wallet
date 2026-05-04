class AuthToken {
  final String accessToken;
  final String tokenType;
  final DateTime expiresAt;

  AuthToken({
    required this.accessToken,
    required this.tokenType,
    required this.expiresAt,
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      // Tokens valid for 10 minutes per API docs.
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get expiresSoon =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 1)));
}
