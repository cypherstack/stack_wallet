class CgTransaction {
  final String coin1;
  final String coin2;
  final String network1;
  final String network2;
  final String address;
  final double estimateAmount;
  final String provider;
  final String id;
  final double sendAmount;
  final String track;
  final String status;
  final String kyc;
  final String token;
  final bool done;
  final String cgid;
  final DateTime createdAt;
  final String affiliate;
  final String memo;
  final String source;
  final String destinationAddress;
  final bool payment;
  final DateTime? completedAt;
  final int estimateId;

  CgTransaction({
    required this.coin1,
    required this.coin2,
    required this.network1,
    required this.network2,
    required this.address,
    required this.estimateAmount,
    required this.provider,
    required this.id,
    required this.sendAmount,
    required this.track,
    required this.status,
    required this.kyc,
    required this.token,
    required this.done,
    required this.cgid,
    required this.createdAt,
    required this.affiliate,
    required this.memo,
    required this.source,
    required this.destinationAddress,
    required this.payment,
    required this.completedAt,
    required this.estimateId,
  });

  // Go's zero time ("0001-01-01T00:00:00Z") is returned when the field isn't
  // set yet; treat it as now rather than storing year 1.
  static DateTime _parseDate(String? s) {
    if (s == null) return DateTime.now();
    final dt = DateTime.tryParse(s);
    if (dt == null || dt.year <= 1) return DateTime.now();
    return dt;
  }

  factory CgTransaction.fromMap(Map<String, dynamic> map) {
    return CgTransaction(
      coin1: map["Coin1"] as String? ?? "",
      coin2: map["Coin2"] as String? ?? "",
      network1: map["Network1"] as String? ?? "",
      network2: map["Network2"] as String? ?? "",
      address: map["Address"] as String? ?? "",
      estimateAmount: (map["EstimateAmount"] as num?)?.toDouble() ?? 0.0,
      provider: map["Provider"] as String? ?? "",
      id: map["Id"] as String? ?? "",
      sendAmount: (map["SendAmount"] as num?)?.toDouble() ?? 0.0,
      track: map["Track"] as String? ?? "",
      status: map["Status"] as String? ?? "waiting",
      kyc: map["KYC"] as String? ?? "",
      token: map["Token"] as String? ?? "",
      done: map["Done"] as bool? ?? false,
      cgid: map["CGID"] as String? ?? "",
      createdAt: _parseDate(map["CreatedAt"] as String?),
      affiliate: map["Affiliate"] as String? ?? "",
      memo: map["Memo"] as String? ?? "",
      source: map["Source"] as String? ?? "",
      destinationAddress: map["DestinationAddress"] as String? ?? "",
      payment: map["Payment"] as bool? ?? false,
      completedAt: map["CompletedAt"] != null
          ? DateTime.tryParse(map["CompletedAt"] as String)
          : null,
      estimateId: (map["EstimateId"] as num?)?.toInt() ?? 0,
    );
  }
}
