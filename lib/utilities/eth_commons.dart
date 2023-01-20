import 'dart:convert';

import 'package:http/http.dart';

class AccountModule {
  final String message;
  final List<dynamic> result;
  final String status;

  const AccountModule({
    required this.message,
    required this.result,
    required this.status,
  });

  factory AccountModule.fromJson(Map<String, dynamic> json) {
    return AccountModule(
      message: json['message'] as String,
      result: json['result'] as List<dynamic>,
      status: json['status'] as String,
    );
  }
}

const _blockExplorer = "https://blockscout.com/eth/mainnet/api?";

Future<AccountModule> fetchAccountModule(String action, String address) async {
  final response = await get(Uri.parse(
      "${_blockExplorer}module=account&action=$action&address=$address"));
  if (response.statusCode == 200) {
    return AccountModule.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  } else {
    throw Exception('Failed to load transactions');
  }
}

Future<List<dynamic>> getWalletTokens(String address) async {
  AccountModule tokens = await fetchAccountModule("tokenlist", address);
  //THIS IS ONLY HARD CODED UNTIL API WORKS AGAIN - TODO REMOVE HARDCODED
  return [
    {
      "balance": "369039500000000000",
      "contractAddress": "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984",
      "decimals": "18",
      "name": "Uniswap",
      "symbol": "UNI",
      "type": "ERC-20"
    }
  ];

  if (tokens.message == "OK") {
    return tokens.result as List<String>;
  }
  return <String>[];
}
