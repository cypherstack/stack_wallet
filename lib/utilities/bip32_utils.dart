import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:bitcoindart/bitcoindart.dart';
import 'package:flutter/foundation.dart';
import 'package:tuple/tuple.dart';

abstract class Bip32Utils {
  // =============================== get root ==================================
  static bip32.BIP32 getBip32RootSync(
    String mnemonic,
    String mnemonicPassphrase,
    NetworkType networkType,
  ) {
    final seed = bip39.mnemonicToSeed(mnemonic, passphrase: mnemonicPassphrase);
    final _networkType = bip32.NetworkType(
      wif: networkType.wif,
      bip32: bip32.Bip32Type(
        public: networkType.bip32.public,
        private: networkType.bip32.private,
      ),
    );

    final root = bip32.BIP32.fromSeed(seed, _networkType);
    return root;
  }

  static Future<bip32.BIP32> getBip32Root(
    String mnemonic,
    String mnemonicPassphrase,
    NetworkType networkType,
  ) async {
    final root = await compute(
      _getBip32RootWrapper,
      Tuple3(
        mnemonic,
        mnemonicPassphrase,
        networkType,
      ),
    );
    return root;
  }

  /// wrapper for compute()
  static bip32.BIP32 _getBip32RootWrapper(
    Tuple3<String, String, NetworkType> args,
  ) {
    return getBip32RootSync(
      args.item1,
      args.item2,
      args.item3,
    );
  }

  // =========================== get node from root ============================
  static bip32.BIP32 getBip32NodeFromRootSync(
    bip32.BIP32 root,
    String derivePath,
  ) {
    return root.derivePath(derivePath);
  }

  static Future<bip32.BIP32> getBip32NodeFromRoot(
    bip32.BIP32 root,
    String derivePath,
  ) async {
    final node = await compute(
      _getBip32NodeFromRootWrapper,
      Tuple2(
        root,
        derivePath,
      ),
    );
    return node;
  }

  /// wrapper for compute()
  static bip32.BIP32 _getBip32NodeFromRootWrapper(
    Tuple2<bip32.BIP32, String> args,
  ) {
    return getBip32NodeFromRootSync(
      args.item1,
      args.item2,
    );
  }

  // =============================== get node ==================================
  static bip32.BIP32 getBip32NodeSync(
    String mnemonic,
    String mnemonicPassphrase,
    NetworkType network,
    String derivePath,
  ) {
    final root = getBip32RootSync(mnemonic, mnemonicPassphrase, network);

    final node = getBip32NodeFromRootSync(root, derivePath);
    return node;
  }

  static Future<bip32.BIP32> getBip32Node(
    String mnemonic,
    String mnemonicPassphrase,
    NetworkType networkType,
    String derivePath,
  ) async {
    final node = await compute(
      _getBip32NodeWrapper,
      Tuple4(
        mnemonic,
        mnemonicPassphrase,
        networkType,
        derivePath,
      ),
    );
    return node;
  }

  /// wrapper for compute()
  static bip32.BIP32 _getBip32NodeWrapper(
    Tuple4<String, String, NetworkType, String> args,
  ) {
    return getBip32NodeSync(
      args.item1,
      args.item2,
      args.item3,
      args.item4,
    );
  }
}
