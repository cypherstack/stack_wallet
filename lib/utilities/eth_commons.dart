import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart';
import 'package:ethereum_addresses/ethereum_addresses.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
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

class GasTracker {
  final int code;
  final Map<String, dynamic> data;

  const GasTracker({
    required this.code,
    required this.data,
  });

  factory GasTracker.fromJson(Map<String, dynamic> json) {
    return GasTracker(
      code: json['code'] as int,
      data: json['data'] as Map<String, dynamic>,
    );
  }
}

// const blockExplorer = "https://blockscout.com/eth/mainnet/api";
const blockExplorer = "https://api.etherscan.io/api";
const _hdPath = "m/44'/60'/0'/0";
const _gasTrackerUrl = "https://beaconcha.in/api/v1/execution/gasnow";

Future<AccountModule> fetchAccountModule(String action, String address) async {
  final response = await get(Uri.parse(
      "${blockExplorer}module=account&action=$action&address=$address&apikey=EG6J7RJIQVSTP2BS59D3TY2G55YHS5F2HP"));
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

Future<GasTracker> getGasOracle() async {
  final response = await get(Uri.parse(_gasTrackerUrl));

  if (response.statusCode == 200) {
    return GasTracker.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  } else {
    throw Exception('Failed to load gas oracle');
  }
}

Future<FeeObject> getFees() async {
  GasTracker fees = await getGasOracle();
  final feesMap = fees.data;
  return FeeObject(
      numberOfBlocksFast: 1,
      numberOfBlocksAverage: 3,
      numberOfBlocksSlow: 3,
      fast: feesMap['fast'] as int,
      medium: feesMap['standard'] as int,
      slow: feesMap['slow'] as int);
}

double estimateFee(int feeRate, int gasLimit, int decimals) {
  final gweiAmount = feeRate / (pow(10, 9));
  final fee = gasLimit * gweiAmount;

  //Convert gwei to ETH
  final feeInWei = fee * (pow(10, 9));
  final ethAmount = feeInWei / (pow(10, decimals));
  return ethAmount;
}

BigInt amountToBigInt(num amount, int decimal) {
  final amountToSendinDecimal = amount * (pow(10, decimal));
  return BigInt.from(amountToSendinDecimal);
}
