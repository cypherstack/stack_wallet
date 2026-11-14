import 'dart:convert';

import 'package:hive_ce/hive.dart';

/// Relay server settings handed to the native wallet as a JSON string.
///
/// The JSON keys are dictated by the native library, so each coin encodes
/// its own.
abstract class RelayConfigModel {
  @HiveField(1)
  final String host;
  @HiveField(2)
  final int? port;

  const RelayConfigModel({required this.host, this.port});

  Map<String, dynamic> toJson();

  Map<String, dynamic> toMap() => toJson();

  @override
  String toString() => json.encode(toJson());
}
