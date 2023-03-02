import 'dart:math';

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

  factory AddressTransaction.fromJson(List<dynamic> json) {
    return AddressTransaction(
      message: "",
      result: json,
      status: "",
    );
  }

  @override
  String toString() {
    return "AddressTransaction: {"
        "\n\t message: $message,"
        "\n\t status: $status,"
        "\n\t result: $result,"
        "\n}";
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

const hdPathEthereum = "m/44'/60'/0'/0";

String getPrivateKey(String mnemonic, String mnemonicPassphrase) {
  final isValidMnemonic = bip39.validateMnemonic(mnemonic);
  if (!isValidMnemonic) {
    throw 'Invalid mnemonic';
  }

  final seed = bip39.mnemonicToSeed(mnemonic, passphrase: mnemonicPassphrase);
  final root = bip32.BIP32.fromSeed(seed);
  const index = 0;
  final addressAtIndex = root.derivePath("$hdPathEthereum/$index");

  return HEX.encode(addressAtIndex.privateKey as List<int>);
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
