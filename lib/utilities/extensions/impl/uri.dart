// Logged errors end up in the log export users attach to support threads.
const _sensitiveQueryParams = {"api_key", "apikey", "address"};

extension UriExt on Uri {
  /// For logging: this uri without key or address query parameters.
  Uri get redacted {
    bool isSensitive(String key) =>
        _sensitiveQueryParams.contains(key.toLowerCase());

    if (!queryParameters.keys.any(isSensitive)) {
      return this;
    }

    return replace(
      queryParameters: Map.of(queryParameters)
        ..removeWhere((k, _) => isSensitive(k)),
    );
  }
}
