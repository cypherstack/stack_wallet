import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:stackwallet/models/ethereum/erc20_token.dart';
import 'package:stackwallet/models/ethereum/erc721_token.dart';

abstract class EthContractInfo extends Equatable {
  const EthContractInfo({
    required this.contractAddress,
    required this.name,
    required this.symbol,
    required this.decimals,
  });

  final String contractAddress;
  final String name;
  final String symbol;
  final int decimals;

  static EthContractInfo? fromMap(Map<String, dynamic> map) {
    switch (map["runtimeType"]) {
      case "Erc20ContractInfo":
        return Erc20ContractInfo(
          contractAddress: map["contractAddress"] as String,
          name: map["name"] as String,
          symbol: map["symbol"] as String,
          decimals: map["decimals"] as int,
        );
      case "Erc721ContractInfo":
        return Erc721ContractInfo(
          contractAddress: map["contractAddress"] as String,
          name: map["name"] as String,
          symbol: map["symbol"] as String,
          decimals: map["decimals"] as int,
        );
      default:
        return null;
    }
  }

  static EthContractInfo? fromJson(String json) => fromMap(
        Map<String, dynamic>.from(
          jsonDecode(json) as Map,
        ),
      );

  Map<String, dynamic> toMap() => {
        "runtimeType": "$runtimeType",
        "contractAddress": contractAddress,
        "name": name,
        "symbol": symbol,
        "decimals": decimals,
      };

  String toJson() => jsonEncode(toMap());

  @override
  String toString() => toMap().toString();

  @override
  List<Object?> get props => [contractAddress];
}
