import 'dart:typed_data';

import 'package:bip47/bip47.dart';
import 'package:bitcoindart/bitcoindart.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/services/coins/dogecoin/dogecoin_wallet.dart';

extension PayNym on DogecoinWallet {
  // fetch or generate this wallet's bip47 payment code
  Future<PaymentCode> getPaymentCode() async {
    final paymentCodeString = DB.instance
        .get<dynamic>(boxName: walletId, key: "paymentCodeString") as String?;
    PaymentCode paymentCode;
    if (paymentCodeString == null) {
      final node = getBip32Root((await mnemonic).join(" "), network)
          .derivePath("m/47'/0'/0'");
      paymentCode =
          PaymentCode.initFromPubKey(node.publicKey, node.chainCode, network);
      await DB.instance.put<dynamic>(
          boxName: walletId,
          key: "paymentCodeString",
          value: paymentCode.toString());
    } else {
      paymentCode = PaymentCode.fromPaymentCode(paymentCodeString, network);
    }
    return paymentCode;
  }

  Future<Uint8List> signWithNotificationKey(Uint8List data) async {
    final node = getBip32Root((await mnemonic).join(" "), network)
        .derivePath("m/47'/0'/0'");
    final pair = ECPair.fromPrivateKey(node.privateKey!, network: network);
    final signed = pair.sign(SHA256Digest().process(data));
    return signed;
  }
}
