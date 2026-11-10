import 'dart:convert';
import 'dart:io';

import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/epiccash_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/mimblewimblecoin_wallet.dart';
import 'package:stackwallet/wallets/wallet/intermediate/cryptonote_wallet.dart';
import 'package:stackwallet/wallets/wallet/intermediate/lib_xelis_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/wl_gen/interfaces/cs_monero_interface.dart';
import 'package:stackwallet/wl_gen/interfaces/cs_salvium_interface.dart';
import 'package:stackwallet/wl_gen/interfaces/cs_wownero_interface.dart';

import 'coin_cases.dart';

/// The original native wallet must answer too: a cached database address and
/// a working recovery probe alone would miss a failed native-file reopen.
Future<void> verifyOpenNativeWallet(Wallet wallet, String expected) async {
  final String actual;
  if (wallet is CryptonoteWallet) {
    actual = await wallet.internalGetAddress(accountIndex: 0, addressIndex: 0);
  } else if (wallet is EpiccashWallet) {
    actual = await wallet.getNativeReceivingAddress();
  } else if (wallet is MimblewimblecoinWallet) {
    actual = (await wallet.thisWalletAddress(
      0,
      await wallet.getMwcMqsConfig(),
    )).value;
  } else if (wallet is LibXelisWallet) {
    wallet.checkInitialized();
    actual = wallet.xelis.getAddress(wallet.wallet!);
  } else {
    return;
  }
  expect(
    actual == expected,
    isTrue,
    reason:
        '${wallet.cryptoCurrency.identifier}: native wallet identity differs',
  );
}

void validatePhrase(CryptoCurrency coin, List<String> words) {
  expect(
    words.length,
    defaultWordCounts[coin.identifier],
    reason: '${coin.identifier}: wrong default recovery phrase length',
  );
  expect(
    words.every((word) => word.isNotEmpty && word == word.trim()),
    isTrue,
    reason: '${coin.identifier}: empty or malformed recovery word',
  );
  expect(coin.defaultSeedPhraseLength, defaultWordCounts[coin.identifier]);
  if (coin is! Monero &&
      coin is! Wownero &&
      coin is! Salvium &&
      coin is! Xelis) {
    expect(
      bip39.validateMnemonic(words.join(' ')),
      isTrue,
      reason: '${coin.identifier}: invalid BIP39 wordlist or checksum',
    );
  }
  // Native seed formats are decoded by the recovery roundtrip below. Merely
  // checking their lengths or accepting the restore screen is insufficient.
}

/// Recover identity from the displayed words without copying cached addresses
/// or native files. This does not scan the blockchain or fund an account.
Future<void> verifyRecoveryIdentity(
  Wallet original,
  String phrase,
  String root,
) async {
  final coin = original.cryptoCurrency;
  final expected = (await original.getCurrentReceivingAddress())!.value;
  if (coin is Monero || coin is Wownero || coin is Salvium) {
    final directory = await Directory(p.join(root, 'recovery'))
        .createTemp('${coin.identifier}_');
    final file = p.join(directory.path, 'wallet');
    const password = 'disposable-recovery-probe';
    WrappedWallet? probe;
    try {
      final String address;
      if (coin is Monero) {
        probe = await csMonero.getRestoredWallet(
          walletId: 'creation-probe',
          path: file,
          password: password,
          mnemonic: phrase,
          seedOffset: '',
        );
        address = await csMonero.getAddress(probe);
      } else if (coin is Wownero) {
        probe = await csWownero.getRestoredWallet(
          walletId: 'creation-probe',
          path: file,
          password: password,
          mnemonic: phrase,
          seedOffset: '',
        );
        address = csWownero.getAddress(probe);
      } else {
        probe = await csSalvium.getRestoredWallet(
          walletId: 'creation-probe',
          path: file,
          password: password,
          mnemonic: phrase,
          seedOffset: '',
        );
        address = csSalvium.getAddress(probe);
      }
      expect(
        address == expected,
        isTrue,
        reason: '${coin.identifier}: displayed seed recovers another address',
      );
    } finally {
      if (probe != null) {
        if (coin is Monero) {
          await csMonero.close(probe);
        } else if (coin is Wownero) {
          await csWownero.close(probe);
        } else {
          await csSalvium.close(probe);
        }
      }
      await directory.delete(recursive: true);
    }
    return;
  }

  // A new ID ensures init() cannot reuse the original wallet's database rows,
  // secure-storage keys, or native files. Use the real factory and libraries.
  final info = WalletInfo.createNew(
    coin: coin,
    name: 'Recovery probe ${coin.identifier}',
    otherDataJsonString: coin is Tezos
        ? jsonEncode({
            WalletInfoKeys.tezosDerivationPath:
                Tezos.standardDerivationPath.value,
          })
        : null,
  );
  Wallet? probe;
  try {
    probe = await Wallet.create(
      walletInfo: info,
      mainDB: original.mainDB,
      secureStorageInterface: original.secureStorageInterface,
      nodeService: original.nodeService,
      prefs: original.prefs,
      mnemonic: phrase,
      mnemonicPassphrase: '',
    );
    // Register solely so the production deletion service also cleans up Epic's
    // native wallet. The probe is never marked as a verified user wallet.
    Wallets.sharedInstance.addWallet(probe);
    await probe.init();
    final address = await probe.getCurrentReceivingAddress();
    expect(
      address != null && address.value == expected,
      isTrue,
      reason: '${coin.identifier}: displayed seed recovers another address',
    );
  } finally {
    if (probe != null) {
      await Wallets.sharedInstance.deleteWallet(
        info,
        original.secureStorageInterface,
      );
    }
  }
}
