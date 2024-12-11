abstract interface class NodeQrData {
  final String host;
  final int port;
  final String? label;

  NodeQrData({required this.host, required this.port, this.label});

  String encode();
  String get scheme;
}

abstract class LibMoneroNodeQrData extends NodeQrData {
  final String user;
  final String password;

  LibMoneroNodeQrData({
    required super.host,
    required super.port,
    super.label,
    required this.user,
    required this.password,
  });

  @override
  String encode() {
    String? userInfo;
    if (user.isNotEmpty) {
      userInfo = user;
      if (password.isNotEmpty) {
        userInfo += ":$password";
      }
    }

    final uri = Uri(
      scheme: scheme,
      userInfo: userInfo,
      port: port,
      host: host,
      queryParameters: {"label": label},
    );

    return uri.toString();
  }

  @override
  String toString() {
    return "$runtimeType {"
        "scheme: $scheme, "
        "host: $host, "
        "port: $port, "
        "user: $user, "
        "password: $password, "
        "label: $label"
        "}";
  }
}

class MoneroNodeQrData extends LibMoneroNodeQrData {
  MoneroNodeQrData({
    required super.host,
    required super.port,
    required super.user,
    required super.password,
    super.label,
  });

  @override
  String get scheme => "xmrrpc";
}

class WowneroNodeQrData extends LibMoneroNodeQrData {
  WowneroNodeQrData({
    required super.host,
    required super.port,
    required super.user,
    required super.password,
    super.label,
  });

  @override
  String get scheme => "wowrpc";
}

abstract final class NodeQrUtil {
  static ({String? user, String? password}) _parseUserInfo(String? userInfo) {
    if (userInfo == null || userInfo.isEmpty) {
      return (user: null, password: null);
    }

    final splitIndex = userInfo.indexOf(":");
    if (splitIndex == -1) {
      return (user: userInfo, password: null);
    }

    return (
      user: userInfo.substring(0, splitIndex),
      password: userInfo.substring(splitIndex + 1),
    );
  }

  static NodeQrData decodeUri(String uriString) {
    final uri = Uri.tryParse(uriString);
    if (uri == null) throw Exception("Invalid uri string.");
    if (!uri.hasAuthority) throw Exception("Uri has no authority.");

    final userInfo = _parseUserInfo(uri.userInfo);

    final query = uri.queryParameters;

    switch (uri.scheme) {
      case "xmrrpc":
        return MoneroNodeQrData(
          host: uri.host,
          port: uri.port,
          user: userInfo.user ?? "",
          password: userInfo.password ?? "",
          label: query["label"],
        );
      case "wowrpc":
        return WowneroNodeQrData(
          host: uri.host,
          port: uri.port,
          user: userInfo.user ?? "",
          password: userInfo.password ?? "",
          label: query["label"],
        );

      default:
        throw Exception("Unknown node uri scheme \"${uri.scheme}\" found.");
    }
  }
}
