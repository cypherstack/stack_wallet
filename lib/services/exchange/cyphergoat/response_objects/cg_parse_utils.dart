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
    throw CgResponseFormatException(
      "Missing or empty required field '$key'",
    );
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
  if (v is! num && v is! String) {
    throw CgResponseFormatException(
      "Missing required numeric field '$key'",
    );
  }
  return Decimal.parse(v.toString());
}

int requireCgInt(Map<String, dynamic> map, String key) {
  final v = map[key];
  if (v is! num) {
    throw CgResponseFormatException(
      "Missing required numeric field '$key'",
    );
  }
  return v.toInt();
}

bool requireCgBool(Map<String, dynamic> map, String key) {
  final v = map[key];
  if (v is! bool) {
    throw CgResponseFormatException(
      "Missing required boolean field '$key'",
    );
  }
  return v;
}
