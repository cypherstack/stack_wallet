import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:bitcoindart/bitcoindart.dart';
import 'package:flutter/foundation.dart';
import 'package:tuple/tuple.dart';

abstract class Bip32Utils {
  static bip32.BIP32 getBip32RootSync(String mnemonic, NetworkType network) {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final networkType = bip32.NetworkType(
      wif: network.wif,
      bip32: bip32.Bip32Type(
        public: network.bip32.public,
        private: network.bip32.private,
      ),
    );

    final root = bip32.BIP32.fromSeed(seed, networkType);
    return root;
  }

  static Future<bip32.BIP32> getBip32Root(
      String mnemonic, NetworkType network) async {
    final root = await compute(_getBip32RootWrapper, Tuple2(mnemonic, network));
    return root;
  }

  /// wrapper for compute()
  static bip32.BIP32 _getBip32RootWrapper(Tuple2<String, NetworkType> args) {
    return getBip32RootSync(args.item1, args.item2);
  }
}
