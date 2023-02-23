import 'dart:convert';
import 'dart:math';

import 'package:ethereum_addresses/ethereum_addresses.dart';
import 'package:http/http.dart';
import 'package:stackwallet/models/ethereum/erc721_token.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/utilities/eth_commons.dart';
import 'package:stackwallet/utilities/logger.dart';

import '../../models/ethereum/erc20_token.dart';
import '../../models/ethereum/eth_token.dart';

class AbiRequestResponse {
  final String message;
  final String result;
  final String status;

  const AbiRequestResponse({
    required this.message,
    required this.result,
    required this.status,
  });

  factory AbiRequestResponse.fromJson(Map<String, dynamic> json) {
    return AbiRequestResponse(
      message: json['message'] as String,
      result: json['result'] as String,
      status: json['status'] as String,
    );
  }
}

class EthereumResponse<T> {
  final T? value;
  final Exception? exception;

  EthereumResponse(this.value, this.exception);
}

abstract class EthereumAPI {
  static const blockExplorer = "https://blockscout.com/eth/mainnet/api";
  static const abiUrl =
      "https://api.etherscan.io/api"; //TODO - Once our server has abi functionality update

  static const gasTrackerUrl =
      "https://blockscout.com/eth/mainnet/api/v1/gas-price-oracle";

  static Future<AddressTransaction> fetchAddressTransactions(
      String address, String action) async {
    try {
      final response = await get(Uri.parse(
          "$blockExplorer?module=account&action=$action&address=$address"));
      if (response.statusCode == 200) {
        return AddressTransaction.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        throw Exception(
            'ERROR GETTING TRANSACTIONS WITH STATUS ${response.statusCode}');
      }
    } catch (e, s) {
      throw Exception('ERROR GETTING TRANSACTIONS ${e.toString()}');
    }
  }

  static Future<EthereumResponse<List<EthToken>>> getWalletTokens({
    required String address,
  }) async {
    try {
      final uri = Uri.parse(
        "$blockExplorer?module=account&action=tokenlist&address=$address",
      );
      final response = await get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json["message"] == "OK") {
          final result =
              List<Map<String, dynamic>>.from(json["result"] as List);
          final List<EthToken> tokens = [];
          for (final map in result) {
            if (map["type"] == "ERC-20") {
              tokens.add(
                Erc20Token(
                  balance: int.parse(map["balance"] as String),
                  contractAddress: map["contractAddress"] as String,
                  decimals: int.parse(map["decimals"] as String),
                  name: map["name"] as String,
                  symbol: map["symbol"] as String,
                ),
              );
            } else if (map["type"] == "ERC-721") {
              tokens.add(
                Erc721Token(
                  balance: int.parse(map["balance"] as String),
                  contractAddress: map["contractAddress"] as String,
                  decimals: int.parse(map["decimals"] as String),
                  name: map["name"] as String,
                  symbol: map["symbol"] as String,
                ),
              );
            } else {
              throw Exception("Unsupported token type found: ${map["type"]}");
            }
          }

          return EthereumResponse(
            tokens,
            null,
          );
        } else {
          throw Exception(json["message"] as String);
        }
      } else {
        throw Exception(
          "getWalletTokens($address) failed with status code: "
          "${response.statusCode}",
        );
      }
    } catch (e, s) {
      Logging.instance.log(
        "getWalletTokens(): $e\n$s",
        level: LogLevel.Error,
      );
      return EthereumResponse(
        null,
        Exception(e.toString()),
      );
    }
  }

  static Future<List<dynamic>> getWalletTokenTransactions(
      String address) async {
    AddressTransaction tokens =
        await fetchAddressTransactions(address, "tokentx");
    List<dynamic> tokensList = [];
    var tokenMap = {};
    if (tokens.message == "OK") {
      final allTxs = tokens.result;
      allTxs.forEach((element) {
        print("=========================================================");
        print("THING: $element");
        print("=========================================================");

        String key = element["tokenSymbol"] as String;
        tokenMap[key] = {};
        tokenMap[key]["balance"] = 0;

        if (tokenMap.containsKey(key)) {
          tokenMap[key]["contractAddress"] =
              element["contractAddress"] as String;
          tokenMap[key]["decimals"] = element["tokenDecimal"];
          tokenMap[key]["name"] = element["tokenName"];
          tokenMap[key]["symbol"] = element["tokenSymbol"];
          if (checksumEthereumAddress(address) == address) {
            tokenMap[key]["balance"] += int.parse(element["value"] as String);
          } else {
            tokenMap[key]["balance"] -= int.parse(element["value"] as String);
          }
        }
      });

      tokenMap.forEach((key, value) {
        tokensList.add(value as Map<dynamic, dynamic>);
      });
      return tokensList;
    }
    return <dynamic>[];
  }

  static Future<GasTracker> getGasOracle() async {
    final response = await get(Uri.parse(gasTrackerUrl));
    if (response.statusCode == 200) {
      return GasTracker.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load gas oracle');
    }
  }

  static Future<FeeObject> getFees() async {
    GasTracker fees = await getGasOracle();
    final feesFast = fees.fast * (pow(10, 9));
    final feesStandard = fees.average * (pow(10, 9));
    final feesSlow = fees.slow * (pow(10, 9));

    return FeeObject(
        numberOfBlocksFast: 1,
        numberOfBlocksAverage: 3,
        numberOfBlocksSlow: 3,
        fast: feesFast.toInt(),
        medium: feesStandard.toInt(),
        slow: feesSlow.toInt());
  }

  //Validate that a custom token is valid and is ERC-20, a token will be valid
  static Future<EthereumResponse<EthToken>> getTokenByContractAddress(
      String contractAddress) async {
    try {
      final response = await get(Uri.parse(
          "$blockExplorer?module=token&action=getToken&contractaddress=$contractAddress"));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json["message"] == "OK") {
          final map = Map<String, dynamic>.from(json["result"] as Map);
          EthToken? token;
          if (map["type"] == "ERC-20") {
            token = Erc20Token(
              balance: int.parse(map["balance"] as String),
              contractAddress: map["contractAddress"] as String,
              decimals: int.parse(map["decimals"] as String),
              name: map["name"] as String,
              symbol: map["symbol"] as String,
            );
          } else if (map["type"] == "ERC-721") {
            token = Erc721Token(
              balance: int.parse(map["balance"] as String),
              contractAddress: map["contractAddress"] as String,
              decimals: int.parse(map["decimals"] as String),
              name: map["name"] as String,
              symbol: map["symbol"] as String,
            );
          } else {
            throw Exception("Unsupported token type found: ${map["type"]}");
          }

          return EthereumResponse(
            token,
            null,
          );
        } else {
          throw Exception(json["message"] as String);
        }
      } else {
        throw Exception(
          "getTokenByContractAddress($contractAddress) failed with status code: "
          "${response.statusCode}",
        );
      }
    } catch (e, s) {
      Logging.instance.log(
        "getWalletTokens(): $e\n$s",
        level: LogLevel.Error,
      );
      return EthereumResponse(
        null,
        Exception(e.toString()),
      );
    }
  }

  static Future<AbiRequestResponse> fetchTokenAbi(
      String contractAddress) async {
    final response = await get(Uri.parse(
        "$abiUrl?module=contract&action=getabi&address=$contractAddress&apikey=EG6J7RJIQVSTP2BS59D3TY2G55YHS5F2HP"));
    if (response.statusCode == 200) {
      return AbiRequestResponse.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception("ERROR GETTING TOKENABI ${response.reasonPhrase}");
    }
  }
}
