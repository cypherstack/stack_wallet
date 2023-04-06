import 'dart:math';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:decimal/decimal.dart';
import "package:hex/hex.dart";
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

class GasTracker {
  final Decimal average;
  final Decimal fast;
  final Decimal slow;

  final int numberOfBlocksFast;
  final int numberOfBlocksAverage;
  final int numberOfBlocksSlow;

  final int timestamp;

  const GasTracker({
    required this.average,
    required this.fast,
    required this.slow,
    required this.numberOfBlocksFast,
    required this.numberOfBlocksAverage,
    required this.numberOfBlocksSlow,
    required this.timestamp,
  });

  factory GasTracker.fromJson(Map<String, dynamic> json) {
    final targetTime = Constants.targetBlockTimeInSeconds(Coin.ethereum);
    return GasTracker(
      average: Decimal.parse(json["average"]["price"].toString()),
      fast: Decimal.parse(json["fast"]["price"].toString()),
      slow: Decimal.parse(json["slow"]["price"].toString()),
      numberOfBlocksAverage: (json["average"]["time"] as int) ~/ targetTime,
      numberOfBlocksFast: (json["fast"]["time"] as int) ~/ targetTime,
      numberOfBlocksSlow: (json["slow"]["time"] as int) ~/ targetTime,
      timestamp: json["timestamp"] as int,
    );
  }
}

const hdPathEthereum = "m/44'/60'/0'/0";

// equal to "0x${keccak256("Transfer(address,address,uint256)".toUint8ListFromUtf8).toHex}";
const kTransferEventSignature =
    "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef";

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

Amount estimateFee(int feeRate, int gasLimit, int decimals) {
  final gweiAmount = feeRate / (pow(10, 9));
  final fee = gasLimit * gweiAmount;

  //Convert gwei to ETH
  final feeInWei = fee * (pow(10, 9));
  final ethAmount = feeInWei / (pow(10, decimals));
  return Amount.fromDouble(ethAmount, fractionDigits: decimals);
}
