import 'package:decimal/decimal.dart';

/// Thrown when a CypherGoat API response is missing a field the client
/// treats as mandatory, instead of silently substituting a default value.
class CgResponseFormatException implements Exception {
  final String message;
  CgResponseFormatException(this.message);

  @override
  String toString() => "CgResponseFormatException: $message";
}

String requireCgString(Map<String, dynamic> map, String key) {
  final v = map[key];
  if (v is! String || v.isEmpty) {
    throw CgResponseFormatException("Missing or empty required field '$key'");
  }
  return v;
}

String? optionalCgString(Map<String, dynamic> map, String key) {
  final v = map[key];
  if (v is String && v.isNotEmpty) return v;
  return null;
}

Decimal requireCgDecimal(Map<String, dynamic> map, String key) {
  final v = map[key];
  final parsed = v is num || v is String
      ? Decimal.tryParse(v.toString())
      : null;
  if (parsed == null) {
    throw CgResponseFormatException("Missing required numeric field '$key'");
  }
  return parsed;
}

int requireCgInt(Map<String, dynamic> map, String key) {
  final v = map[key];
  if (v is! num) {
    throw CgResponseFormatException("Missing required numeric field '$key'");
  }
  return v.toInt();
}

int? optionalCgInt(Map<String, dynamic> map, String key) {
  final v = map[key];
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

/// The `error` field of a decoded error body, or null if there is none.
String? extractErrorMessage(dynamic json) {
  final error = json is Map ? json["error"]?.toString() : null;
  return error == null || error.isEmpty ? null : error;
}
