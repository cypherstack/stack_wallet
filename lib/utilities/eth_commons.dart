import 'dart:convert';

import 'package:http/http.dart';
import 'package:ethereum_addresses/ethereum_addresses.dart';
import 'flutter_secure_storage_interface.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import "package:hex/hex.dart";

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

const _blockExplorer = "https://api.etherscan.io/api?";
late SecureStorageInterface _secureStore;
const _hdPath = "m/44'/60'/0'/0";

Future<AccountModule> fetchAccountModule(String action, String address) async {
  final response = await get(Uri.parse(
      "${_blockExplorer}module=account&action=$action&address=$address&apikey=EG6J7RJIQVSTP2BS59D3TY2G55YHS5F2HP"));
  if (response.statusCode == 200) {
    return AccountModule.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  } else {
    throw Exception('Failed to load transactions');
  }
}

Future<List<dynamic>> getWalletTokens(String address) async {
  AccountModule tokens = await fetchAccountModule("tokentx", address);
  List<dynamic> tokensList = [];
  var tokenMap = {};
  if (tokens.message == "OK") {
    final allTxs = tokens.result;
    print("RESULT IS $allTxs");
    allTxs.forEach((element) {
      String key = element["tokenSymbol"] as String;
      tokenMap[key] = {};
      tokenMap[key]["balance"] = 0;

      if (tokenMap.containsKey(key)) {
        tokenMap[key]["contractAddress"] = element["contractAddress"] as String;
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

String getPrivateKey(String mnemonic) {
  final isValidMnemonic = bip39.validateMnemonic(mnemonic);
  if (!isValidMnemonic) {
    throw 'Invalid mnemonic';
  }

  final seed = bip39.mnemonicToSeed(mnemonic);
  final root = bip32.BIP32.fromSeed(seed);
  const index = 0;
  final addressAtIndex = root.derivePath("$_hdPath/$index");

  return HEX.encode(addressAtIndex.privateKey as List<int>);
}
