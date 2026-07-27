import 'package:decimal/decimal.dart';

/// Data models for the Open CryptoPay standard.
///
/// See https://github.com/openCryptoPay/landingPage

enum OpenCryptoPaySubmissionFlow {
  /// The wallet broadcasts locally, then sends the resulting txid to `/tx/`.
  txIdAfterLocalBroadcast,

  /// The provider broadcasts after receiving raw signed transaction hex.
  rawHexToProvider,
}

class OpenCryptoPayRecipient {
  final String? name;
  final String? street;
  final String? houseNumber;
  final String? zip;
  final String? city;
  final String? country;

  OpenCryptoPayRecipient({
    this.name,
    this.street,
    this.houseNumber,
    this.zip,
    this.city,
    this.country,
  });

  factory OpenCryptoPayRecipient.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>?;
    return OpenCryptoPayRecipient(
      name: json['name'] as String?,
      street: address?['street'] as String?,
      houseNumber: address?['houseNumber'] as String?,
      zip: address?['zip'] as String?,
      city: address?['city'] as String?,
      country: address?['country'] as String?,
    );
  }

  String get formattedAddress {
    final parts = <String>[];
    if (street != null) {
      parts.add(houseNumber != null ? '$street $houseNumber' : street!);
    }
    if (zip != null || city != null) {
      parts.add([zip, city].whereType<String>().join(' '));
    }
    if (country != null) parts.add(country!);
    return parts.join(', ');
  }
}

class OpenCryptoPayAsset {
  final String asset;
  final String amount;

  OpenCryptoPayAsset({required this.asset, required this.amount});

  factory OpenCryptoPayAsset.fromJson(Map<String, dynamic> json) {
    return OpenCryptoPayAsset(
      asset: json['asset'] as String,
      amount: json['amount'].toString(),
    );
  }
}

class OpenCryptoPayTransferMethod {
  final String method;
  final List<OpenCryptoPayAsset> assets;
  final bool available;
  final Decimal minFee;

  OpenCryptoPayTransferMethod({
    required this.method,
    required this.assets,
    required this.available,
    required this.minFee,
  });

  factory OpenCryptoPayTransferMethod.fromJson(Map<String, dynamic> json) {
    return OpenCryptoPayTransferMethod(
      method: json['method'] as String,
      minFee:
          Decimal.tryParse(json['minFee']?.toString() ?? '0') ?? Decimal.zero,
      assets: (json['assets'] as List<dynamic>)
          .map((e) => OpenCryptoPayAsset.fromJson(e as Map<String, dynamic>))
          .toList(),
      available: json['available'] as bool,
    );
  }
}

class OpenCryptoPayQuote {
  final String id;
  final String paymentId;
  final DateTime expiration;

  OpenCryptoPayQuote({
    required this.id,
    required this.paymentId,
    required this.expiration,
  });

  factory OpenCryptoPayQuote.fromJson(
    Map<String, dynamic> json, {
    String? fallbackPaymentId,
  }) {
    final paymentId = json['payment'] as String? ?? fallbackPaymentId;
    if (paymentId == null || paymentId.isEmpty) {
      throw Exception('OpenCryptoPay: quote payment id is missing');
    }

    return OpenCryptoPayQuote(
      id: json['id'] as String,
      paymentId: paymentId,
      expiration: DateTime.parse(json['expiration'] as String),
    );
  }

  bool get isExpired => expiration.isBefore(DateTime.now());
}

class OpenCryptoPayRequestedAmount {
  final String asset;
  final num amount;

  OpenCryptoPayRequestedAmount({required this.asset, required this.amount});

  factory OpenCryptoPayRequestedAmount.fromJson(Map<String, dynamic> json) {
    return OpenCryptoPayRequestedAmount(
      asset: json['asset'] as String,
      amount: json['amount'] as num,
    );
  }
}

class OpenCryptoPayPaymentDetails {
  final String? standard;
  final List<String> possibleStandards;
  final String? displayName;
  final String callback;
  final OpenCryptoPayRecipient? recipient;
  final OpenCryptoPayQuote? quote;
  final OpenCryptoPayRequestedAmount? requestedAmount;
  final List<OpenCryptoPayTransferMethod> transferAmounts;

  OpenCryptoPayPaymentDetails({
    this.standard,
    required this.possibleStandards,
    this.displayName,
    required this.callback,
    this.recipient,
    this.quote,
    this.requestedAmount,
    required this.transferAmounts,
  });

  factory OpenCryptoPayPaymentDetails.fromJson(Map<String, dynamic> json) {
    final callback = json['callback'] as String? ?? '';
    return OpenCryptoPayPaymentDetails(
      standard: json['standard'] as String?,
      possibleStandards:
          (json['possibleStandards'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      displayName: json['displayName'] as String?,
      callback: callback,
      recipient: json['recipient'] == null
          ? null
          : OpenCryptoPayRecipient.fromJson(
              json['recipient'] as Map<String, dynamic>,
            ),
      quote: json['quote'] == null
          ? null
          : OpenCryptoPayQuote.fromJson(
              json['quote'] as Map<String, dynamic>,
              fallbackPaymentId: _paymentIdFromCallback(callback),
            ),
      requestedAmount: json['requestedAmount'] == null
          ? null
          : OpenCryptoPayRequestedAmount.fromJson(
              json['requestedAmount'] as Map<String, dynamic>,
            ),
      transferAmounts:
          (json['transferAmounts'] as List<dynamic>?)
              ?.map(
                (e) => OpenCryptoPayTransferMethod.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    );
  }

  /// Methods that are available and have at least one asset.
  List<OpenCryptoPayTransferMethod> get availableMethods =>
      transferAmounts.where((m) => m.available && m.assets.isNotEmpty).toList();

  bool get supportsOpenCryptoPay =>
      standard == 'OpenCryptoPay' ||
      possibleStandards.contains('OpenCryptoPay') ||
      (callback.isNotEmpty && quote != null && transferAmounts.isNotEmpty);

  static String? _paymentIdFromCallback(String callback) {
    final segments = Uri.tryParse(callback)?.pathSegments;
    final cbIndex = segments?.lastIndexOf('cb') ?? -1;
    if (segments == null || cbIndex == -1 || cbIndex + 1 >= segments.length) {
      return null;
    }
    return segments[cbIndex + 1];
  }
}

class OpenCryptoPayTransactionDetails {
  final String? blockchain;
  final String? uri;
  final String? hint;
  final DateTime? expiryDate;

  OpenCryptoPayTransactionDetails({
    this.blockchain,
    this.uri,
    this.hint,
    this.expiryDate,
  });

  factory OpenCryptoPayTransactionDetails.fromJson(Map<String, dynamic> json) {
    return OpenCryptoPayTransactionDetails(
      blockchain: json['blockchain'] as String?,
      uri: json['uri'] as String?,
      hint: json['hint'] as String?,
      expiryDate: json['expiryDate'] == null
          ? null
          : DateTime.parse(json['expiryDate'] as String),
    );
  }
}

/// Context required to notify the provider via the `/tx/{paymentId}` endpoint.
class OpenCryptoPayCommit {
  final String callbackUrl;
  final String quoteId;
  final String paymentId;
  final String method;
  final String asset;
  final DateTime expiresAt;
  final OpenCryptoPaySubmissionFlow submissionFlow;
  final Decimal minFee;
  final String recipientAddress;
  final Decimal amount;
  final String? tokenContractAddress;
  final int? tokenDecimals;

  const OpenCryptoPayCommit({
    required this.callbackUrl,
    required this.quoteId,
    required this.paymentId,
    required this.method,
    required this.asset,
    required this.expiresAt,
    required this.submissionFlow,
    required this.minFee,
    required this.recipientAddress,
    required this.amount,
    this.tokenContractAddress,
    this.tokenDecimals,
  });

  bool get isExpired => expiresAt.isBefore(DateTime.now());

  bool get canCommitRawHex =>
      submissionFlow == OpenCryptoPaySubmissionFlow.rawHexToProvider;

  bool get canCommitTxId =>
      submissionFlow == OpenCryptoPaySubmissionFlow.txIdAfterLocalBroadcast ||
      method == 'Firo';
}
