import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart';
import 'package:ethereum_addresses/ethereum_addresses.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import "package:hex/hex.dart";

class AddressTransaction {
  final String message;
  final List<dynamic> result;
  final String status;

  const AddressTransaction({
    required this.message,
    required this.result,
    required this.status,
  });

  factory AddressTransaction.fromJson(Map<String, dynamic> json) {
    return AddressTransaction(
      message: json['message'] as String,
      result: json['result'] as List<dynamic>,
      status: json['status'] as String,
    );
  }
}

class GasTracker {
  final double average;
  final double fast;
  final double slow;
  // final Map<String, dynamic> data;

  const GasTracker({
    required this.average,
    required this.fast,
    required this.slow,
  });

  factory GasTracker.fromJson(Map<String, dynamic> json) {
    return GasTracker(
      average: json['average'] as double,
      fast: json['fast'] as double,
      slow: json['slow'] as double,
    );
  }
}

const blockExplorer = "https://blockscout.com/eth/mainnet/api";
const abiUrl =
    "https://api.etherscan.io/api"; //TODO - Once our server has abi functionality update
const _hdPath = "m/44'/60'/0'/0";
const _gasTrackerUrl =
    "https://blockscout.com/eth/mainnet/api/v1/gas-price-oracle";

Future<AddressTransaction> fetchAddressTransactions(
    String address, String action) async {
  final response = await get(Uri.parse(
      "$blockExplorer?module=account&action=$action&address=$address"));

  if (response.statusCode == 200) {
    return AddressTransaction.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  } else {
    throw Exception('Failed to load transactions');
  }
}

Future<List<dynamic>> getWalletTokens(String address) async {
  AddressTransaction tokens =
      await fetchAddressTransactions(address, "tokentx");
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
