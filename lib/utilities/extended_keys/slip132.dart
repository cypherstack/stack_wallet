/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import '../enums/derive_path_type_enum.dart';

/// SLIP-0132 "Registered HD version bytes" for extended keys.
///
/// See https://github.com/satoshilabs/slips/blob/master/slip-0132.md
///
/// SLIP-0132 encodes the script type of an account into the 4 version bytes
/// (and therefore the human-readable prefix) of a serialized extended key.
/// The key material is otherwise identical, so converting between e.g. `xpub`
/// and `zpub` is a lossless swap of the version bytes followed by a
/// re-base58check-encode. Choosing the wrong prefix does NOT change the key,
/// but it does signal a different script type to other wallets — so on import
/// the prefix is what tells us which addresses to derive.
class Slip132 {
  const Slip132._();

  // Mainnet. Litecoin native segwit reuses the Bitcoin bytes (per Electrum-LTC
  // and the absence of any registered Litecoin native-segwit prefix).
  static const int xpub = 0x0488b21e; // P2PKH / BIP44 (also BIP86 taproot)
  static const int xprv = 0x0488ade4;
  static const int ypub = 0x049d7cb2; // P2WPKH-in-P2SH / BIP49
  static const int yprv = 0x049d7878;
  static const int zpub = 0x04b24746; // P2WPKH native segwit / BIP84
  static const int zprv = 0x04b2430c;

  // Testnet.
  static const int tpub = 0x043587cf; // BIP44
  static const int tprv = 0x04358394;
  static const int upub = 0x044a5262; // BIP49
  static const int uprv = 0x044a4e28;
  static const int vpub = 0x045f1cf6; // BIP84
  static const int vprv = 0x045f18bc;

  // Litecoin legacy SLIP-0132 prefixes. Accepted on import for interop with
  // Trezor/Blockbook exports; NOT emitted by this wallet (which follows
  // Electrum-LTC and reuses the Bitcoin version bytes above).
  static const int ltub = 0x019da462; // LTC mainnet P2PKH / BIP44
  static const int mtub = 0x01b26ef6; // LTC mainnet P2WPKH-in-P2SH / BIP49
  static const int ttub = 0x0436f6e1; // LTC testnet P2PKH / BIP44

  /// The public-key version bytes to emit for [derivePathType] on a
  /// Bitcoin/Litecoin-style coin. `bip44` and `bip86` fall back to the generic
  /// `xpub`/`tpub` since SLIP-0132 registers no taproot prefix.
  static int pubVersion({
    required bool isTestnet,
    required DerivePathType derivePathType,
  }) {
    switch (derivePathType) {
      case DerivePathType.bip49:
        return isTestnet ? upub : ypub;
      case DerivePathType.bip84:
        return isTestnet ? vpub : zpub;
      default:
        return isTestnet ? tpub : xpub;
    }
  }

  /// The private-key analog of [pubVersion].
  static int privVersion({
    required bool isTestnet,
    required DerivePathType derivePathType,
  }) {
    switch (derivePathType) {
      case DerivePathType.bip49:
        return isTestnet ? uprv : yprv;
      case DerivePathType.bip84:
        return isTestnet ? vprv : zprv;
      default:
        return isTestnet ? tprv : xprv;
    }
  }

  /// Inverse of [pubVersion]: the [DerivePathType] implied by the 4 public-key
  /// [version] bytes read from a pasted extended key, or `null` when they are
  /// not an unambiguous script-typed SLIP-0132 prefix.
  ///
  /// The generic `xpub`/`tpub` returns `null` because it is ambiguous between
  /// BIP44 and BIP86 — callers should keep the user's explicit selection in
  /// that case rather than guessing. Set [includeLitecoinLegacy] to also
  /// accept Litecoin's `Ltub`/`Mtub`/`ttub`.
  static DerivePathType? derivePathTypeForPubVersion(
    int version, {
    required bool isTestnet,
    bool includeLitecoinLegacy = false,
  }) {
    if (isTestnet) {
      switch (version) {
        case upub:
          return DerivePathType.bip49;
        case vpub:
          return DerivePathType.bip84;
      }
      if (includeLitecoinLegacy && version == ttub) {
        return DerivePathType.bip44;
      }
      return null;
    }

    switch (version) {
      case ypub:
        return DerivePathType.bip49;
      case zpub:
        return DerivePathType.bip84;
    }
    if (includeLitecoinLegacy) {
      switch (version) {
        case ltub:
          return DerivePathType.bip44;
        case mtub:
          return DerivePathType.bip49;
      }
    }
    return null;
  }

  /// Human-readable prefix (e.g. `"zpub"`) for a public-key [version], for UI
  /// labels, or `null` if [version] is not a known SLIP-0132 prefix. Callers
  /// must handle `null` (e.g. coins with their own HD prefix such as Dogecoin
  /// `dgub` or Particl `PPAR`) rather than assuming `"xpub"`.
  static String? humanPubPrefix(int version) {
    switch (version) {
      case xpub:
        return "xpub";
      case ypub:
        return "ypub";
      case zpub:
        return "zpub";
      case tpub:
        return "tpub";
      case upub:
        return "upub";
      case vpub:
        return "vpub";
      case ltub:
        return "Ltub";
      case mtub:
        return "Mtub";
      case ttub:
        return "ttub";
      default:
        return null;
    }
  }
}
