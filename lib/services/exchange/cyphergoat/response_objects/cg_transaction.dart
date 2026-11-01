import 'package:decimal/decimal.dart';

import 'cg_parse_utils.dart';

class CgTransaction {
  final String coin1;
  final String coin2;
  final String network1;
  final String network2;
  final String address;
  final Decimal estimateAmount;
  final String id;
  final Decimal sendAmount;
  final String? track;
  final String status;
  final String? kyc;
  final String? token;
  final String? cgid;
  final DateTime createdAt;
  final String? affiliate;
  final String? memo;
  final String? source;
  final String destinationAddress;
  final DateTime? completedAt;

  CgTransaction({
    required this.coin1,
    required this.coin2,
    required this.network1,
    required this.network2,
    required this.address,
    required this.estimateAmount,
    required this.id,
    required this.sendAmount,
    required this.track,
    required this.status,
    required this.kyc,
    required this.token,
    required this.cgid,
    required this.createdAt,
    required this.affiliate,
    required this.memo,
    required this.source,
    required this.destinationAddress,
    required this.completedAt,
  });

  // Go's zero time ("0001-01-01T00:00:00Z") is returned when the field isn't
  // set yet; treat it as now rather than storing year 1.
  static DateTime _parseDate(String s) {
    final dt = DateTime.tryParse(s);
    if (dt == null || dt.year <= 1) return DateTime.now();
    return dt;
  }

  // Require only what a Trade is built from. Throwing here loses a swap that
  // already exists server side.
  factory CgTransaction.fromMap(Map<String, dynamic> map) {
    return CgTransaction(
      coin1: requireCgString(map, "Coin1"),
      coin2: requireCgString(map, "Coin2"),
      network1: requireCgString(map, "Network1"),
      network2: requireCgString(map, "Network2"),
      address: requireCgString(map, "Address"),
      estimateAmount: requireCgDecimal(map, "EstimateAmount"),
      id: requireCgString(map, "Id"),
      sendAmount: requireCgDecimal(map, "SendAmount"),
      track: optionalCgString(map, "Track"),
      status: optionalCgString(map, "Status") ?? "waiting",
      kyc: optionalCgString(map, "KYC"),
      token: optionalCgString(map, "Token"),
      cgid: optionalCgString(map, "CGID"),
      createdAt: _parseDate(requireCgString(map, "CreatedAt")),
      affiliate: optionalCgString(map, "Affiliate"),
      memo: optionalCgString(map, "Memo"),
      source: optionalCgString(map, "Source"),
      destinationAddress: requireCgString(map, "DestinationAddress"),
      completedAt: map["CompletedAt"] is String
          ? DateTime.tryParse(map["CompletedAt"] as String)
          : null,
    );
  }
}
