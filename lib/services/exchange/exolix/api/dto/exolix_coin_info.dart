import 'exolix_base_dto.dart';

/// The "coinFrom" / "coinTo" sub-object inside a transaction.
class ExolixCoinInfo extends ExolixBaseDto {
  final String coinCode;
  final String coinName;
  final String network;
  final String networkName;
  final String? networkShortName;
  final String? icon;
  final String? memoName;
  final String? contract;

  ExolixCoinInfo({
    required this.coinCode,
    required this.coinName,
    required this.network,
    required this.networkName,
    required this.networkShortName,
    required this.icon,
    required this.memoName,
    required this.contract,
  });

  factory ExolixCoinInfo.fromJson(Map<String, dynamic> json) {
    return ExolixCoinInfo(
      coinCode: json["coinCode"] as String? ?? "",
      coinName: json["coinName"] as String? ?? "",
      network: json["network"] as String? ?? "",
      networkName: json["networkName"] as String? ?? "",
      networkShortName: json["networkShortName"] as String?,
      icon: json["icon"] as String?,
      memoName: json["memoName"] as String?,
      contract: json["contract"] as String?,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "coinCode": coinCode,
      "coinName": coinName,
      "network": network,
      "networkName": networkName,
      "networkShortName": networkShortName,
      "icon": icon,
      "memoName": memoName,
      "contract": contract,
    };
  }
}
