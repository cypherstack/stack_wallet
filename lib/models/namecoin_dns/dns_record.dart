import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:namecoin/namecoin.dart';

import '../../utilities/extensions/extensions.dart';
import 'dns_a_record_address_type.dart';
import 'dns_record_type.dart';

@Immutable()
final class DNSRecord {
  final DNSRecordType type;
  final Map<String, dynamic> data;

  DNSRecord({
    required this.type,
    required this.data,
  });

  String getValueString() {
    // TODO error handling
    dynamic value = data;
    while (value is Map) {
      value = value[value.keys.first];
    }

    return value.toString();
  }

  DNSRecord copyWith({
    DNSRecordType? type,
    DNSAddressType? addressType,
    Map<String, dynamic>? data,
  }) {
    return DNSRecord(
      type: type ?? this.type,
      data: data ?? this.data,
    );
  }

  @override
  String toString() {
    return "DNSRecord(type: $type, data: $data)";
  }

  static String merge(List<DNSRecord> records) {
    final Map<String, dynamic> result = {};

    for (final record in records) {
      switch (record.type) {
        case DNSRecordType.CNAME:
          if (result[record.data.keys.first] != null) {
            throw Exception("CNAME record already exists");
          }
          _deepMerge(result, record.data);
          break;

        case DNSRecordType.TLS:
        case DNSRecordType.NS:
        case DNSRecordType.DS:
        case DNSRecordType.SRV:
        case DNSRecordType.SSH:
        case DNSRecordType.TXT:
        case DNSRecordType.IMPORT:
        case DNSRecordType.A:
          _deepMerge(result, record.data);
          break;
      }
    }

    final string = jsonEncode(result);
    if (string.toUint8ListFromUtf8.length > valueMaxLength) {
      throw Exception(
        "Value length (${string.toUint8ListFromUtf8.length}) exceeds maximum"
        " allowed ($valueMaxLength)",
      );
    }

    return string;
  }
}

void _deepMerge(Map<String, dynamic> base, Map<String, dynamic> updates) {
  updates.forEach((key, value) {
    if (value is Map<String, dynamic> && base[key] is Map<String, dynamic>) {
      _deepMerge(base[key] as Map<String, dynamic>, value);
    } else if (value is List && base[key] is List) {
      (base[key] as List).addAll(value);
    } else {
      if (base[key] != null) {
        throw Exception(
          "Attempted to overwrite value: ${base[key]} where key=$key",
        );
      }
      if (value is Map) {
        base[key] = Map<String, dynamic>.from(value);
      } else if (value is List) {
        base[key] = List<dynamic>.from(value);
      } else {
        base[key] = value;
      }
    }
  });
}
