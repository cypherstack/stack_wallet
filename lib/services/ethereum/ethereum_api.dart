import 'dart:convert';
import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:http/http.dart';
import 'package:stackwallet/dto/ethereum/eth_token_tx_dto.dart';
import 'package:stackwallet/dto/ethereum/eth_token_tx_extra_dto.dart';
import 'package:stackwallet/dto/ethereum/eth_tx_dto.dart';
import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/eth_commons.dart';
import 'package:stackwallet/utilities/logger.dart';

class EthApiException with Exception {
  EthApiException(this.message);

  final String message;

  @override
  String toString() => "$runtimeType: $message";
}

class EthereumResponse<T> {
  EthereumResponse(this.value, this.exception);

  final T? value;
  final EthApiException? exception;

  @override
  toString() => "EthereumResponse: { value: $value, exception: $exception }";
}

abstract class EthereumAPI {
  static String get stackBaseServer => DefaultNodes.ethereum.host;

  static String stackURI = "$stackBaseServer/eth/mainnet/api";

  // static const etherscanApi =
  //     "https://api.etherscan.io/api"; //TODO - Once our server has abi functionality update

  static const gasTrackerUrl =
      "https://blockscout.com/eth/mainnet/api/v1/gas-price-oracle";

  static Future<EthereumResponse<List<EthTxDTO>>> getEthTransactions(
      String address) async {
    try {
      final response = await get(
        Uri.parse(
          "$stackBaseServer/export?addrs=$address",
        ),
      );

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final json = jsonDecode(response.body) as Map;
          final list = json["data"] as List?;

          final List<EthTxDTO> txns = [];
          for (final map in list!) {
            final txn = EthTxDTO.fromMap(Map<String, dynamic>.from(map as Map));

            if (txn.hasToken == 0) {
              txns.add(txn);
            }
          }
          return EthereumResponse(
            txns,
            null,
          );
        } else {
          throw EthApiException(
            "getEthTransactions($address) response is empty but status code is "
            "${response.statusCode}",
          );
        }
      } else {
        throw EthApiException(
          "getEthTransactions($address) failed with status code: "
          "${response.statusCode}",
        );
      }
    } on EthApiException catch (e) {
      return EthereumResponse(
        null,
        e,
      );
    } catch (e, s) {
      Logging.instance.log(
        "getEthTransactions($address): $e\n$s",
        level: LogLevel.Error,
      );
      return EthereumResponse(
        null,
        EthApiException(e.toString()),
      );
    }
  }

  static Future<EthereumResponse<List<EthTokenTxExtraDTO>>>
      getEthTokenTransactionsByTxids(List<String> txids) async {
    try {
      final response = await get(
        Uri.parse(
          "$stackBaseServer/transactions?transactions=${txids.join(" ")}",
        ),
      );

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final json = jsonDecode(response.body) as Map;
          final list = json["data"] as List?;

          final List<EthTokenTxExtraDTO> txns = [];
          for (final map in list!) {
            final txn = EthTokenTxExtraDTO.fromMap(
              Map<String, dynamic>.from(map as Map),
            );

            txns.add(txn);
          }
          return EthereumResponse(
            txns,
            null,
          );
        } else {
          throw EthApiException(
            "getEthTransaction($txids) response is empty but status code is "
            "${response.statusCode}",
          );
        }
      } else {
        throw EthApiException(
          "getEthTransaction($txids) failed with status code: "
          "${response.statusCode}",
        );
      }
    } on EthApiException catch (e) {
      return EthereumResponse(
        null,
        e,
      );
    } catch (e, s) {
      Logging.instance.log(
        "getEthTransaction($txids): $e\n$s",
        level: LogLevel.Error,
      );
      return EthereumResponse(
        null,
        EthApiException(e.toString()),
      );
    }
  }

  static Future<EthereumResponse<List<EthTokenTxDto>>> getTokenTransactions({
    required String address,
    required String tokenContractAddress,
  }) async {
    try {
      final response = await get(
        Uri.parse(
          "$stackBaseServer/export?addrs=$address&emitter=$tokenContractAddress&logs=true",
        ),
      );

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final json = jsonDecode(response.body) as Map;
          final list = json["data"] as List?;

          final List<EthTokenTxDto> txns = [];
          for (final map in list!) {
            final txn =
                EthTokenTxDto.fromMap(Map<String, dynamic>.from(map as Map));

            txns.add(txn);
          }
          return EthereumResponse(
            txns,
            null,
          );
        } else {
          throw EthApiException(
            "getTokenTransactions($address, $tokenContractAddress) response is empty but status code is "
            "${response.statusCode}",
          );
        }
      } else {
        throw EthApiException(
          "getTokenTransactions($address, $tokenContractAddress) failed with status code: "
          "${response.statusCode}",
        );
      }
    } on EthApiException catch (e) {
      return EthereumResponse(
        null,
        e,
      );
    } catch (e, s) {
      Logging.instance.log(
        "getTokenTransactions($address, $tokenContractAddress): $e\n$s",
        level: LogLevel.Error,
      );
      return EthereumResponse(
        null,
        EthApiException(e.toString()),
      );
    }
  }

// ONLY FETCHES WALLET TOKENS WITH A NON ZERO BALANCE
  // static Future<EthereumResponse<List<EthToken>>> getWalletTokens({
  //   required String address,
  // }) async {
  //   try {
  //     final uri = Uri.parse(
  //       "$blockExplorer?module=account&action=tokenlist&address=$address",
  //     );
  //     final response = await get(uri);
  //
  //     if (response.statusCode == 200) {
  //       final json = jsonDecode(response.body);
  //       if (json["message"] == "OK") {
  //         final result =
  //             List<Map<String, dynamic>>.from(json["result"] as List);
  //         final List<EthToken> tokens = [];
  //         for (final map in result) {
  //           if (map["type"] == "ERC-20") {
  //             tokens.add(
  //               Erc20Token(
  //                 balance: int.parse(map["balance"] as String),
  //                 contractAddress: map["contractAddress"] as String,
  //                 decimals: int.parse(map["decimals"] as String),
  //                 name: map["name"] as String,
  //                 symbol: map["symbol"] as String,
  //               ),
  //             );
  //           } else if (map["type"] == "ERC-721") {
  //             tokens.add(
  //               Erc721Token(
  //                 balance: int.parse(map["balance"] as String),
  //                 contractAddress: map["contractAddress"] as String,
  //                 decimals: int.parse(map["decimals"] as String),
  //                 name: map["name"] as String,
  //                 symbol: map["symbol"] as String,
  //               ),
  //             );
  //           } else {
  //             throw EthApiException(
  //                 "Unsupported token type found: ${map["type"]}");
  //           }
  //         }
  //
  //         return EthereumResponse(
  //           tokens,
  //           null,
  //         );
  //       } else {
  //         throw EthApiException(json["message"] as String);
  //       }
  //     } else {
  //       throw EthApiException(
  //         "getWalletTokens($address) failed with status code: "
  //         "${response.statusCode}",
  //       );
  //     }
  //   } on EthApiException catch (e) {
  //     return EthereumResponse(
  //       null,
  //       e,
  //     );
  //   } catch (e, s) {
  //     Logging.instance.log(
  //       "getWalletTokens(): $e\n$s",
  //       level: LogLevel.Error,
  //     );
  //     return EthereumResponse(
  //       null,
  //       EthApiException(e.toString()),
  //     );
  //   }
  // }

  static Future<EthereumResponse<int>> getWalletTokenBalance({
    required String address,
    required String contractAddress,
  }) async {
    try {
      final uri = Uri.parse(
        "$stackBaseServer/tokens?addrs=$contractAddress $address",
      );
      final response = await get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json["data"] is List) {
          final map = json["data"].first as Map;

          final bal = Decimal.tryParse(map["balance"].toString());
          final int balance;
          if (bal == null) {
            balance = 0;
          } else {
            final int decimals = map["decimals"] as int;
            balance = (bal * Decimal.fromInt(pow(10, decimals).truncate()))
                .toBigInt()
                .toInt();
          }

          return EthereumResponse(
            balance,
            null,
          );
        } else {
          throw EthApiException(json["message"] as String);
        }
      } else {
        throw EthApiException(
          "getWalletTokenBalance($address) failed with status code: "
          "${response.statusCode}",
        );
      }
    } on EthApiException catch (e) {
      return EthereumResponse(
        null,
        e,
      );
    } catch (e, s) {
      Logging.instance.log(
        "getWalletTokenBalance(): $e\n$s",
        level: LogLevel.Error,
      );
      return EthereumResponse(
        null,
        EthApiException(e.toString()),
      );
    }
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

  static Future<EthereumResponse<EthContract>> getTokenContractInfoByAddress(
      String contractAddress) async {
    try {
      final response = await get(
        Uri.parse(
          "$stackBaseServer/tokens?addrs=$contractAddress&parts=all",
        ),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json["message"] == "OK") {
          final map = Map<String, dynamic>.from(json["result"] as Map);
          EthContract? token;
          if (map["isErc20"] == true) {
            token = EthContract(
              address: map["address"] as String,
              decimals: map["decimals"] as int,
              name: map["name"] as String,
              symbol: map["symbol"] as String,
              type: EthContractType.erc20,
            );
          } else if (map["isErc721"] == true) {
            token = EthContract(
              address: map["address"] as String,
              decimals: map["decimals"] as int,
              name: map["name"] as String,
              symbol: map["symbol"] as String,
              type: EthContractType.erc721,
            );
          } else {
            throw EthApiException(
                "Unsupported token type found: ${map["type"]}");
          }

          return EthereumResponse(
            token,
            null,
          );
        } else {
          throw EthApiException(json["message"] as String);
        }
      } else {
        throw EthApiException(
          "getTokenByContractAddress($contractAddress) failed with status code: "
          "${response.statusCode}",
        );
      }
    } on EthApiException catch (e) {
      return EthereumResponse(
        null,
        e,
      );
    } catch (e, s) {
      Logging.instance.log(
        "getTokenByContractAddress(): $e\n$s",
        level: LogLevel.Error,
      );
      return EthereumResponse(
        null,
        EthApiException(e.toString()),
      );
    }
  }

  static Future<EthereumResponse<String>> getTokenAbi({
    required String name,
    required String contractAddress,
  }) async {
    try {
      final response = await get(
        Uri.parse(
          "$stackBaseServer/abis?addrs=$contractAddress&verbose=true",
        ),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body)["data"] as List;

        return EthereumResponse(
          jsonEncode(json),
          null,
        );
      } else {
        throw EthApiException(
          "getTokenAbi($name, $contractAddress) failed with status code: "
          "${response.statusCode}",
        );
      }
    } on EthApiException catch (e) {
      return EthereumResponse(
        null,
        e,
      );
    } catch (e, s) {
      Logging.instance.log(
        "getTokenAbi($name, $contractAddress): $e\n$s",
        level: LogLevel.Error,
      );
      return EthereumResponse(
        null,
        EthApiException(e.toString()),
      );
    }
  }

  /// Fetch the underlying contract address that a proxy contract points to
  static Future<EthereumResponse<String>> getProxyTokenImplementation(
      String contractAddress) async {
    try {
      final response = await get(Uri.parse(
          // "$stackURI?module=contract&action=getsourcecode&address=$contractAddress"));
          "$etherscanApi?module=contract&action=getsourcecode&address=$contractAddress&apikey=EG6J7RJIQVSTP2BS59D3TY2G55YHS5F2HP"));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json["message"] == "OK") {
          final list = json["result"] as List;
          final map = Map<String, dynamic>.from(list.first as Map);

          return EthereumResponse(
            map["Implementation"] as String,
            null,
          );
        } else {
          throw EthApiException(json["message"] as String);
        }
      } else {
        throw EthApiException(
          "fetchProxyTokenImplementation($contractAddress) failed with status code: "
          "${response.statusCode}",
        );
      }
    } on EthApiException catch (e) {
      return EthereumResponse(
        null,
        e,
      );
    } catch (e, s) {
      Logging.instance.log(
        "fetchProxyTokenImplementation(): $e\n$s",
        level: LogLevel.Error,
      );
      return EthereumResponse(
        null,
        EthApiException(e.toString()),
      );
    }
  }
}
