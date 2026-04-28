import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip47/bip47.dart';
import 'package:coin/coin.dart' as coin;
import 'package:isar_community/isar.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/ecc_fp.dart' as ecc_fp;
import 'package:tuple/tuple.dart';

import '../../../exceptions/wallet/insufficient_balance_exception.dart';
import '../../../exceptions/wallet/paynym_send_exception.dart';
import '../../../models/input.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/isar/models/isar_models.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/bip32_utils.dart';
import '../../../utilities/bip47_utils.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../../../utilities/extensions/extensions.dart';
import '../../../utilities/format.dart';
import '../../../utilities/logger.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../crypto_currency/interfaces/paynym_currency_interface.dart';
import '../../models/tx_data.dart';
import '../intermediate/bip39_hd_wallet.dart';
import 'electrumx_interface.dart';

const String kPCodeKeyPrefix = "pCode_key_";

String _basePaynymDerivePath({required bool testnet}) =>
    "m/47'/${testnet ? "1" : "0"}'/0'";
String _notificationDerivationPath({required bool testnet}) =>
    "${_basePaynymDerivePath(testnet: testnet)}/0";

String _receivingPaynymAddressDerivationPath(
  int index, {
  required bool testnet,
}) => "${_basePaynymDerivePath(testnet: testnet)}/$index/0";
String _sendPaynymAddressDerivationPath(int index, {required bool testnet}) =>
    "${_basePaynymDerivePath(testnet: testnet)}/0/$index";

mixin PaynymInterface<T extends PaynymCurrencyInterface>
    on Bip39HDWallet<T>, ElectrumXInterface<T> {
  NetworkType get networkType => NetworkType(
    messagePrefix: cryptoCurrency.networkParams.messagePrefix,
    bech32: cryptoCurrency.networkParams.bech32Hrp,
    bip32: Bip32Type(
      public: cryptoCurrency.networkParams.pubHDPrefix,
      private: cryptoCurrency.networkParams.privHDPrefix,
    ),
    pubKeyHash: cryptoCurrency.networkParams.p2pkhPrefix,
    scriptHash: cryptoCurrency.networkParams.p2shPrefix,
    wif: cryptoCurrency.networkParams.wifPrefix,
  );

  Future<bip32.BIP32> getBip47BaseNode() async {
    final root = await _getRootNode();
    final node = root.derivePath(
      _basePaynymDerivePath(testnet: info.coin.network.isTestNet),
    );
    return node;
  }

  /// Returns the BIP-47 scalar-added private key b' = b + s (mod n).
  ///
  /// For P2TR PayNym addresses, this key is NOT taproot-tweaked here.
  /// The signing pipeline in electrumx_interface applies the BIP-341
  /// taproot tweak via coin.Taproot.tweakSecretKey() when it
  /// detects a TaprootKeyInput (DerivePathType.bip86 case).
  ///
  /// Key derivation chain for P2TR PayNym UTXOs:
  ///   1. BIP-47 base node: m/47'/0'/0'/{index}
  ///   2. BIP-47 scalar addition: b' = b + s (mod n) [returned here]
  ///   3. BIP-341 taproot tweak: b'' = b' + t (mod n) [applied at sign time]
  ///   4. Schnorr signature with b''
  Future<Uint8List> getPrivateKeyForPaynymReceivingAddress({
    required String paymentCodeString,
    required int index,
  }) async {
    final bip47base = await getBip47BaseNode();

    final paymentAddress = PaymentAddress(
      bip32Node: bip47base.derive(index),
      paymentCode: PaymentCode.fromPaymentCode(
        paymentCodeString,
        networkType: networkType,
      ),
      networkType: networkType,
      index: 0,
    );

    final pair = paymentAddress.getReceiveAddressKeyPair();

    return pair.privateKey;
  }

  /// Maps a PaymentCode's feature byte capabilities to the preferred
  /// DerivePathType for address generation. Per D-04: single source of
  /// truth for capability-to-type mapping.
  /// Preference order: P2TR > P2WPKH > P2PKH (per D-01, D-05).
  DerivePathType _preferredDerivePathType(PaymentCode code) {
    if (code.isTaprootEnabled()) return DerivePathType.bip86;
    if (code.isSegWitEnabled()) return DerivePathType.bip84;
    return DerivePathType.bip44;
  }

  Future<Address> currentReceivingPaynymAddress({
    required PaymentCode sender,
    required DerivePathType derivePathType,
  }) async {
    final keys = await lookupKey(sender.toString());

    final address =
        await mainDB
            .getAddresses(walletId)
            .filter()
            .subTypeEqualTo(AddressSubType.paynymReceive)
            .and()
            .group((q) {
              return switch (derivePathType) {
                DerivePathType.bip86 => q.typeEqualTo(AddressType.p2tr),
                DerivePathType.bip84 => q
                    .typeEqualTo(AddressType.p2sh)
                    .or()
                    .typeEqualTo(AddressType.p2wpkh),
                _ => q.typeEqualTo(AddressType.p2pkh),
              };
            })
            .and()
            .anyOf<String, Address>(
              keys,
              (q, String e) => q.otherDataEqualTo(e),
            )
            .sortByDerivationIndexDesc()
            .findFirst();

    if (address == null) {
      final generatedAddress = await _generatePaynymReceivingAddress(
        sender: sender,
        index: 0,
        derivePathType: derivePathType,
      );

      final existing =
          await mainDB
              .getAddresses(walletId)
              .filter()
              .valueEqualTo(generatedAddress.value)
              .findFirst();

      if (existing == null) {
        // Add that new address
        await mainDB.putAddress(generatedAddress);
      } else {
        // we need to update the address
        await mainDB.updateAddress(existing, generatedAddress);
      }

      return currentReceivingPaynymAddress(
        derivePathType: derivePathType,
        sender: sender,
      );
    } else {
      return address;
    }
  }

  Future<Address> _generatePaynymReceivingAddress({
    required PaymentCode sender,
    required int index,
    required DerivePathType derivePathType,
  }) async {
    final root = await _getRootNode();
    final node = root.derivePath(
      _basePaynymDerivePath(testnet: info.coin.network.isTestNet),
    );

    final paymentAddress = PaymentAddress(
      bip32Node: node.derive(index),
      paymentCode: sender,
      networkType: networkType,
      index: 0,
    );

    final addressString = switch (derivePathType) {
      DerivePathType.bip86 => paymentAddress.getReceiveAddressP2TR(),
      DerivePathType.bip84 => paymentAddress.getReceiveAddressP2WPKH(),
      _ => paymentAddress.getReceiveAddressP2PKH(),
    };

    final address = Address(
      walletId: walletId,
      value: addressString,
      publicKey: [],
      derivationIndex: index,
      derivationPath:
          DerivationPath()
            ..value = _receivingPaynymAddressDerivationPath(
              index,
              testnet: info.coin.network.isTestNet,
            ),
      type: derivePathType.getAddressType(),
      subType: AddressSubType.paynymReceive,
      otherData: await storeCode(sender.toString()),
    );

    return address;
  }

  Future<Address> _generatePaynymSendAddress({
    required PaymentCode other,
    required int index,
    required DerivePathType derivePathType,
    bip32.BIP32? mySendBip32Node,
  }) async {
    final node = mySendBip32Node ?? await deriveNotificationBip32Node();

    final paymentAddress = PaymentAddress(
      bip32Node: node,
      paymentCode: other,
      networkType: networkType,
      index: index,
    );

    final addressString = switch (derivePathType) {
      DerivePathType.bip86 => paymentAddress.getSendAddressP2TR(),
      DerivePathType.bip84 => paymentAddress.getSendAddressP2WPKH(),
      _ => paymentAddress.getSendAddressP2PKH(),
    };

    final address = Address(
      walletId: walletId,
      value: addressString,
      publicKey: [],
      derivationIndex: index,
      derivationPath:
          DerivationPath()
            ..value = _sendPaynymAddressDerivationPath(
              index,
              testnet: info.coin.network.isTestNet,
            ),
      type: AddressType.nonWallet,
      subType: AddressSubType.paynymSend,
      otherData: await storeCode(other.toString()),
    );

    return address;
  }

  Future<void> checkCurrentPaynymReceivingAddressForTransactions({
    required PaymentCode sender,
    required DerivePathType derivePathType,
  }) async {
    final address = await currentReceivingPaynymAddress(
      sender: sender,
      derivePathType: derivePathType,
    );

    final txCount = await fetchTxCount(
      addressScriptHash: cryptoCurrency.addressToScriptHash(
        address: address.value,
      ),
    );
    if (txCount > 0) {
      // generate next address and add to db
      final nextAddress = await _generatePaynymReceivingAddress(
        sender: sender,
        index: address.derivationIndex + 1,
        derivePathType: derivePathType,
      );

      final existing =
          await mainDB
              .getAddresses(walletId)
              .filter()
              .valueEqualTo(nextAddress.value)
              .findFirst();

      if (existing == null) {
        // Add that new address
        await mainDB.putAddress(nextAddress);
      } else {
        // we need to update the address
        await mainDB.updateAddress(existing, nextAddress);
      }
      // keep checking until address with no tx history is set as current
      await checkCurrentPaynymReceivingAddressForTransactions(
        sender: sender,
        derivePathType: derivePathType,
      );
    }
  }

  Future<void> checkAllCurrentReceivingPaynymAddressesForTransactions() async {
    final codes = await getAllPaymentCodesFromNotificationTransactions();
    final List<Future<void>> futures = [];
    for (final code in codes) {
      // Always check P2PKH (bip44)
      futures.add(
        checkCurrentPaynymReceivingAddressForTransactions(
          sender: code,
          derivePathType: DerivePathType.bip44,
        ),
      );
      // Check P2WPKH if segwit enabled (bip84)
      if (code.isSegWitEnabled()) {
        futures.add(
          checkCurrentPaynymReceivingAddressForTransactions(
            sender: code,
            derivePathType: DerivePathType.bip84,
          ),
        );
      }
      // Check P2TR if taproot enabled (bip86)
      if (code.isTaprootEnabled()) {
        futures.add(
          checkCurrentPaynymReceivingAddressForTransactions(
            sender: code,
            derivePathType: DerivePathType.bip86,
          ),
        );
      }
    }
    await Future.wait(futures);
  }

  // generate bip32 payment code root
  Future<bip32.BIP32> _getRootNode() async {
    return _cachedRootNode ??= await Bip32Utils.getBip32Root(
      (await getMnemonic()),
      (await getMnemonicPassphrase()),
      bip32.NetworkType(
        wif: networkType.wif,
        bip32: bip32.Bip32Type(
          public: networkType.bip32.public,
          private: networkType.bip32.private,
        ),
      ),
    );
  }

  bip32.BIP32? _cachedRootNode;

  Future<bip32.BIP32> deriveNotificationBip32Node() async {
    final root = await _getRootNode();
    final node = root
        .derivePath(_basePaynymDerivePath(testnet: info.coin.network.isTestNet))
        .derive(0);
    return node;
  }

  /// fetch or generate this wallet's bip47 payment code
  Future<PaymentCode> getPaymentCode({
    bool isSegwit = false,
    bool isTaproot = false,
  }) async {
    final node = await _getRootNode();

    final paymentCode = PaymentCode.fromBip32Node(
      node.derivePath(
        _basePaynymDerivePath(testnet: info.coin.network.isTestNet),
      ),
      networkType: networkType,
      shouldSetSegwitBit: isSegwit || isTaproot,
      shouldSetTaprootBit: isTaproot,
    );

    return paymentCode;
  }

  Future<Uint8List> signWithNotificationKey(Uint8List data) async {
    final myPrivateKeyNode = await deriveNotificationBip32Node();
    final sk = coin.SecretKey.fromHex(
      coin.hexEncode(myPrivateKeyNode.privateKey!),
    );
    final signed = coin.EcdsaSig.sign(
      SHA256Digest().process(data),
      sk.bytes,
    );
    return signed.bytes;
  }

  Future<String> signStringWithNotificationKey(String data) async {
    final myPrivateKeyNode = await deriveNotificationBip32Node();
    final privKeyBytes = myPrivateKeyNode.privateKey!;

    // Build the Bitcoin message hash: SHA256(SHA256(prefix + message))
    // The messagePrefix includes a leading length byte (e.g. \x18 = 24).
    final prefix = cryptoCurrency.networkParams.messagePrefix!;
    final msgBytes = utf8.encode(data);

    // Varint-encode length
    Uint8List varint(int n) {
      if (n < 0xfd) return Uint8List.fromList([n]);
      if (n <= 0xffff) {
        return Uint8List.fromList([0xfd, n & 0xff, (n >> 8) & 0xff]);
      }
      throw ArgumentError('message too long');
    }

    final prefixBytes = utf8.encode(prefix);
    final payload = Uint8List.fromList([
      ...prefixBytes,
      ...varint(msgBytes.length),
      ...msgBytes,
    ]);

    final hash = SHA256Digest().process(SHA256Digest().process(payload));

    // Sign with coin's ECDSA
    final sig = coin.EcdsaSig.sign(hash, privKeyBytes);

    // Extract r and s from the 64-byte compact signature
    final sigBytes = sig.bytes;
    final r = _bytesToBigInt(sigBytes.sublist(0, 32));
    final s = _bytesToBigInt(sigBytes.sublist(32, 64));

    // Determine recovery byte by trying both candidates
    final pubKey = coin.SecretKey(privKeyBytes).publicKey.bytes;
    int recId = -1;
    for (int i = 0; i < 2; i++) {
      final recovered = _recoverPubKey(hash, r, s, i);
      if (recovered != null && _uint8ListEquals(recovered, pubKey)) {
        recId = i;
        break;
      }
    }
    if (recId < 0) {
      throw StateError('Could not determine signature recovery id');
    }

    // Bitcoin message signature: [27 + recId + 4(compressed)] [r:32] [s:32]
    final compact = Uint8List(65);
    compact[0] = 27 + recId + 4; // 4 = compressed pubkey flag
    compact.setRange(1, 33, sigBytes.sublist(0, 32));
    compact.setRange(33, 65, sigBytes.sublist(32, 64));

    return base64Encode(compact);
  }

  static Uint8List _bigIntToBytes(BigInt n, int length) {
    final hex = n.toRadixString(16).padLeft(length * 2, '0');
    return Uint8List.fromList([
      for (int i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ]);
  }

  static bool _uint8ListEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Recover compressed public key from ECDSA signature.
  static Uint8List? _recoverPubKey(
    Uint8List hash,
    BigInt r,
    BigInt s,
    int recId,
  ) {
    final curve = ECDomainParameters('secp256k1');
    final n = curve.n;
    final p = (curve.curve as ecc_fp.ECCurve).q!; // field prime
    final g = curve.G;

    final x = r + BigInt.from(recId ~/ 2) * n;
    if (x >= p) return null;

    // Reconstruct the curve point R from x
    final xCubed = (x * x * x) % p;
    // y^2 = x^3 + 7 (secp256k1: a=0, b=7)
    final ySquared = (xCubed + BigInt.from(7)) % p;
    final y = _modSqrt(ySquared, p);
    if (y == null) return null;

    final yToUse = (y.isEven == ((recId & 1) == 0)) ? y : p - y;

    final rPoint = curve.curve.createPoint(x, yToUse);

    // Q = r^(-1) * (s*R - hash*G)
    final rInv = r.modInverse(n);
    final hashBig = _bytesToBigInt(hash);

    final sR = (rPoint * s)!;
    final hashG = (g * (n - hashBig % n))!;
    final q = (sR + hashG)! * rInv;
    if (q == null) return null;

    return q.getEncoded(true);
  }

  static BigInt _bytesToBigInt(Uint8List bytes) {
    var result = BigInt.zero;
    for (final b in bytes) {
      result = (result << 8) | BigInt.from(b);
    }
    return result;
  }

  /// Tonelli-Shanks modular square root.
  static BigInt? _modSqrt(BigInt a, BigInt p) {
    if (a == BigInt.zero) return BigInt.zero;
    if (p == BigInt.two) return a % p;

    // Check if a is a quadratic residue
    if (a.modPow((p - BigInt.one) >> 1, p) != BigInt.one) return null;

    // Simple case: p == 3 (mod 4)
    if (p % BigInt.from(4) == BigInt.from(3)) {
      return a.modPow((p + BigInt.one) >> 2, p);
    }

    // Factor out powers of 2 from p-1
    var s = BigInt.zero;
    var q = p - BigInt.one;
    while (q.isEven) {
      q >>= 1;
      s += BigInt.one;
    }

    // Find a non-residue z
    var z = BigInt.two;
    while (z.modPow((p - BigInt.one) >> 1, p) != p - BigInt.one) {
      z += BigInt.one;
    }

    var m = s;
    var c = z.modPow(q, p);
    var t = a.modPow(q, p);
    var r = a.modPow((q + BigInt.one) >> 1, p);

    while (true) {
      if (t == BigInt.one) return r;
      var i = BigInt.one;
      var tmp = (t * t) % p;
      while (tmp != BigInt.one) {
        tmp = (tmp * tmp) % p;
        i += BigInt.one;
        if (i == m) return null;
      }
      final b = c.modPow(BigInt.one << (m - i - BigInt.one).toInt(), p);
      m = i;
      c = (b * b) % p;
      t = (t * c) % p;
      r = (r * b) % p;
    }
  }

  Future<TxData> preparePaymentCodeSend({
    required TxData txData,
    // required PaymentCode paymentCode,
    // required bool isSegwit,
    // required Amount amount,
    // Map<String, dynamic>? args,
  }) async {
    // TODO: handle asserts in a better manner
    assert(txData.recipients != null && txData.recipients!.length == 1);
    assert(txData.paynymAccountLite!.code == txData.recipients!.first.address);

    final paymentCode = PaymentCode.fromPaymentCode(
      txData.paynymAccountLite!.code,
      networkType: networkType,
    );

    if (!(await hasConnected(txData.paynymAccountLite!.code.toString()))) {
      throw PaynymSendException(
        "No notification transaction sent to $paymentCode,",
      );
    } else {
      final myPrivateKeyNode = await deriveNotificationBip32Node();
      final sendToAddress = await nextUnusedSendAddressFrom(
        pCode: paymentCode,
        privateKeyNode: myPrivateKeyNode,
        derivePathType: _preferredDerivePathType(paymentCode),
      );

      return prepareSend(
        txData: txData.copyWith(
          recipients: [
            TxRecipient(
              address: sendToAddress.value,
              amount: txData.recipients!.first.amount,
              isChange: false,
              addressType: sendToAddress.type,
            ),
          ],
        ),
      );
    }
  }

  /// get the next unused address to send to given the receiver's payment code
  /// and your own private key
  Future<Address> nextUnusedSendAddressFrom({
    required PaymentCode pCode,
    required DerivePathType derivePathType,
    required bip32.BIP32 privateKeyNode,
    int startIndex = 0,
  }) async {
    // https://en.bitcoin.it/wiki/BIP_0047#Path_levels
    const maxCount = 2147483647;

    for (int i = startIndex; i < maxCount; i++) {
      final keys = await lookupKey(pCode.toString());
      final address =
          await mainDB
              .getAddresses(walletId)
              .filter()
              .subTypeEqualTo(AddressSubType.paynymSend)
              .and()
              .anyOf<String, Address>(
                keys,
                (q, String e) => q.otherDataEqualTo(e),
              )
              .and()
              .derivationIndexEqualTo(i)
              .findFirst();

      if (address != null) {
        final count = await fetchTxCount(
          addressScriptHash: cryptoCurrency.addressToScriptHash(
            address: address.value,
          ),
        );
        // return address if unused, otherwise continue to next index
        if (count == 0) {
          return address;
        }
      } else {
        final address = await _generatePaynymSendAddress(
          other: pCode,
          index: i,
          derivePathType: derivePathType,
          mySendBip32Node: privateKeyNode,
        );

        final storedAddress = await mainDB.getAddress(walletId, address.value);
        if (storedAddress == null) {
          await mainDB.putAddress(address);
        } else {
          await mainDB.updateAddress(storedAddress, address);
        }
        final count = await fetchTxCount(
          addressScriptHash: cryptoCurrency.addressToScriptHash(
            address: address.value,
          ),
        );
        // return address if unused, otherwise continue to next index
        if (count == 0) {
          return address;
        }
      }
    }

    throw PaynymSendException("Exhausted unused send addresses!");
  }

  Future<TxData> prepareNotificationTx({
    required BigInt selectedTxFeeRate,
    required String targetPaymentCodeString,
    int additionalOutputs = 0,
    List<UTXO>? utxos,
  }) async {
    try {
      final amountToSend = cryptoCurrency.dustLimitP2PKH;
      final List<UTXO> availableOutputs =
          utxos ?? await mainDB.getUTXOs(walletId).findAll();
      final List<UTXO> spendableOutputs = [];
      BigInt spendableSatoshiValue = BigInt.zero;

      // Build list of spendable outputs and totaling their satoshi amount
      for (var i = 0; i < availableOutputs.length; i++) {
        if (availableOutputs[i].isBlocked == false &&
            availableOutputs[i].isConfirmed(
                  await fetchChainHeight(),
                  cryptoCurrency.minConfirms,
                  cryptoCurrency.minCoinbaseConfirms,
                ) ==
                true) {
          spendableOutputs.add(availableOutputs[i]);
          spendableSatoshiValue += BigInt.from(availableOutputs[i].value);
        }
      }

      if (spendableSatoshiValue < amountToSend.raw) {
        // insufficient balance
        throw InsufficientBalanceException(
          "Spendable balance is less than the minimum required for a notification transaction.",
        );
      } else if (spendableSatoshiValue == amountToSend.raw) {
        // insufficient balance due to missing amount to cover fee
        throw InsufficientBalanceException(
          "Remaining balance does not cover the network fee.",
        );
      }

      // Sort spendable by age (oldest first), but push taproot (bip86)
      // UTXOs to the end. BIP47 notification tx requires the sender's
      // public key to be extractable from the first input's scriptSig or
      // witness. Taproot key-path spends only include a signature in the
      // witness (no pubkey), so the receiver can't extract it for ECDH.
      spendableOutputs.sort((a, b) {
        final aIsTaproot =
            a.address?.startsWith('bc1p') == true ||
            a.address?.startsWith('tb1p') == true;
        final bIsTaproot =
            b.address?.startsWith('bc1p') == true ||
            b.address?.startsWith('tb1p') == true;
        if (aIsTaproot != bIsTaproot) {
          return aIsTaproot ? 1 : -1; // taproot goes last
        }
        return b.blockTime!.compareTo(a.blockTime!);
      });

      BigInt satoshisBeingUsed = BigInt.zero;
      int outputsBeingUsed = 0;
      final List<UTXO> utxoObjectsToUse = [];

      for (
        int i = 0;
        satoshisBeingUsed < amountToSend.raw && i < spendableOutputs.length;
        i++
      ) {
        utxoObjectsToUse.add(spendableOutputs[i]);
        satoshisBeingUsed += BigInt.from(spendableOutputs[i].value);
        outputsBeingUsed += 1;
      }

      // add additional outputs if required
      for (
        int i = 0;
        i < additionalOutputs && outputsBeingUsed < spendableOutputs.length;
        i++
      ) {
        utxoObjectsToUse.add(spendableOutputs[outputsBeingUsed]);
        satoshisBeingUsed += BigInt.from(
          spendableOutputs[outputsBeingUsed].value,
        );
        outputsBeingUsed += 1;
      }

      // gather required signing data
      final inputsWithKeys =
          (await addSigningKeys(
            utxoObjectsToUse.map((e) => StandardInput(e)).toList(),
          )).whereType<StandardInput>().toList();

      final vSizeForNoChange = BigInt.from(
        (await _createNotificationTx(
          targetPaymentCodeString: targetPaymentCodeString,
          inputsWithKeys: inputsWithKeys,
          change: BigInt.zero,
          // override amount to get around absurd fees error
          overrideAmountForTesting: satoshisBeingUsed,
        )).item2,
      );

      final vSizeForWithChange = BigInt.from(
        (await _createNotificationTx(
          targetPaymentCodeString: targetPaymentCodeString,
          inputsWithKeys: inputsWithKeys,
          change: satoshisBeingUsed - amountToSend.raw,
        )).item2,
      );

      // Assume 2 outputs, for recipient and payment code script
      BigInt feeForNoChange = BigInt.from(
        estimateTxFee(
          vSize: vSizeForNoChange.toInt(),
          feeRatePerKB: selectedTxFeeRate,
        ),
      );

      // Assume 3 outputs, for recipient, payment code script, and change
      BigInt feeForWithChange = BigInt.from(
        estimateTxFee(
          vSize: vSizeForWithChange.toInt(),
          feeRatePerKB: selectedTxFeeRate,
        ),
      );

      if (info.coin is Dogecoin) {
        if (feeForNoChange < vSizeForNoChange * BigInt.from(1000)) {
          feeForNoChange = vSizeForNoChange * BigInt.from(1000);
        }
        if (feeForWithChange < vSizeForWithChange * BigInt.from(1000)) {
          feeForWithChange = vSizeForWithChange * BigInt.from(1000);
        }
      }

      if (satoshisBeingUsed - amountToSend.raw >
          feeForNoChange + cryptoCurrency.dustLimitP2PKH.raw) {
        // try to add change output due to "left over" amount being greater than
        // the estimated fee + the dust limit
        BigInt changeAmount =
            satoshisBeingUsed - amountToSend.raw - feeForWithChange;

        // check estimates are correct and build notification tx
        if (changeAmount >= cryptoCurrency.dustLimitP2PKH.raw &&
            satoshisBeingUsed - amountToSend.raw - changeAmount ==
                feeForWithChange) {
          var txn = await _createNotificationTx(
            targetPaymentCodeString: targetPaymentCodeString,
            inputsWithKeys: inputsWithKeys,
            change: changeAmount,
          );

          BigInt feeBeingPaid =
              satoshisBeingUsed - amountToSend.raw - changeAmount;

          // make sure minimum fee is accurate if that is being used
          if (txn.item2 - feeBeingPaid.toInt() == 1) {
            changeAmount -= BigInt.one;
            feeBeingPaid += BigInt.one;
            txn = await _createNotificationTx(
              targetPaymentCodeString: targetPaymentCodeString,
              inputsWithKeys: inputsWithKeys,
              change: changeAmount,
            );
          }

          final txData = TxData(
            raw: txn.item1,
            recipients: [
              TxRecipient(
                address: targetPaymentCodeString,
                amount: amountToSend,
                isChange: false,
                addressType: AddressType.unknown,
              ),
            ],
            fee: Amount(
              rawValue: feeBeingPaid,
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
            vSize: txn.item2,
            utxos: inputsWithKeys.toSet(),
            note: "PayNym connect",
          );

          return txData;
        } else {
          // something broke during fee estimation or the change amount is smaller
          // than the dust limit. Try without change
          final txn = await _createNotificationTx(
            targetPaymentCodeString: targetPaymentCodeString,
            inputsWithKeys: inputsWithKeys,
            change: BigInt.zero,
          );

          final BigInt feeBeingPaid = satoshisBeingUsed - amountToSend.raw;

          final txData = TxData(
            raw: txn.item1,
            recipients: [
              TxRecipient(
                address: targetPaymentCodeString,
                amount: amountToSend,
                isChange: false,
                addressType: AddressType.unknown,
              ),
            ],
            fee: Amount(
              rawValue: feeBeingPaid,
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
            vSize: txn.item2,
            utxos: inputsWithKeys.toSet(),
            note: "PayNym connect",
          );

          return txData;
        }
      } else if (satoshisBeingUsed - amountToSend.raw >= feeForNoChange) {
        // since we already checked if we need to add a change output we can just
        // build without change here
        final txn = await _createNotificationTx(
          targetPaymentCodeString: targetPaymentCodeString,
          inputsWithKeys: inputsWithKeys,
          change: BigInt.zero,
        );

        final BigInt feeBeingPaid = satoshisBeingUsed - amountToSend.raw;

        final txData = TxData(
          raw: txn.item1,
          recipients: [
            TxRecipient(
              address: targetPaymentCodeString,
              amount: amountToSend,
              isChange: false,
              addressType: AddressType.unknown,
            ),
          ],
          fee: Amount(
            rawValue: feeBeingPaid,
            fractionDigits: cryptoCurrency.fractionDigits,
          ),
          vSize: txn.item2,
          utxos: inputsWithKeys.toSet(),
          note: "PayNym connect",
        );

        return txData;
      } else {
        // if we get here we do not have enough funds to cover the tx total so we
        // check if we have any more available outputs and try again
        if (spendableOutputs.length > outputsBeingUsed) {
          return prepareNotificationTx(
            selectedTxFeeRate: selectedTxFeeRate,
            targetPaymentCodeString: targetPaymentCodeString,
            additionalOutputs: additionalOutputs + 1,
          );
        } else {
          throw InsufficientBalanceException(
            "Remaining balance does not cover the network fee.",
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // return tuple with string value equal to the raw tx hex and the int value
  // equal to its vSize
  Future<Tuple2<String, int>> _createNotificationTx({
    required String targetPaymentCodeString,
    required List<StandardInput> inputsWithKeys,
    required BigInt change,
    BigInt? overrideAmountForTesting,
  }) async {
    try {
      final targetPaymentCode = PaymentCode.fromPaymentCode(
        targetPaymentCodeString,
        networkType: networkType,
      );
      final myCode = await getPaymentCode();

      final utxo = inputsWithKeys.first.utxo;
      final txPoint = utxo.txid.toUint8ListFromHex.reversed.toList();
      final txPointIndex = utxo.vout;

      final rev = Uint8List(txPoint.length + 4);
      _copyBytes(Uint8List.fromList(txPoint), 0, rev, 0, txPoint.length);
      final buffer = rev.buffer.asByteData();
      buffer.setUint32(txPoint.length, txPointIndex, Endian.little);

      final myKeyPair = inputsWithKeys.first.key! as coin.DerivedSecretKey;

      final S = SecretPoint(
        myKeyPair.secretKey.bytes,
        targetPaymentCode.notificationPublicKey(),
      );

      final blindingMask = PaymentCode.getMask(S.ecdhSecret(), rev);

      final blindedPaymentCode = PaymentCode.blind(
        payload: myCode.getPayload(),
        mask: blindingMask,
        unBlind: false,
      );

      final opReturnScript = coin.Script([
        coin.OpCode(coin.Op.returnOp),
        coin.PushData(blindedPaymentCode),
      ]).compiled;

      // build a notification tx

      final List<coin.TxOutput> prevOuts = [];
      final List<coin.RawInput> unsignedInputs = [];
      final List<coin.TxOutput> txOutputs = [];

      // Track per-input signing metadata
      final List<({
        DerivePathType? type,
        coin.SecretKey? secretKey,
        coin.PublicKey? publicKey,
        BigInt value,
      })> inputMeta = [];

      final sequence = 0xffffffff - 1;

      for (var i = 0; i < inputsWithKeys.length; i++) {
        final txid = inputsWithKeys[i].utxo.txid;

        final hash = Uint8List.fromList(
          txid.toUint8ListFromHex.reversed.toList(),
        );

        final outpoint = coin.Outpoint(
          txid: hash,
          vout: inputsWithKeys[i].utxo.vout,
        );

        final utxoAddr = coin.Addr.fromString(
          inputsWithKeys[i].utxo.address!,
          cryptoCurrency.networkParams,
        );
        final prevOutput = coin.TxOutput(
          value: BigInt.from(inputsWithKeys[i].utxo.value),
          scriptPubKey: utxoAddr.scriptPubKey,
        );
        prevOuts.add(prevOutput);

        unsignedInputs.add(
          coin.RawInput(prevOut: outpoint, sequence: sequence),
        );

        final derivedKey =
            inputsWithKeys[i].key! as coin.DerivedSecretKey;

        inputMeta.add((
          type: inputsWithKeys[i].derivePathType,
          secretKey: derivedKey.secretKey,
          publicKey: derivedKey.publicKey,
          value: BigInt.from(inputsWithKeys[i].utxo.value),
        ));
      }

      final String notificationAddress =
          targetPaymentCode.notificationAddressP2PKH();

      final notifAddr = coin.Addr.fromString(
        normalizeAddress(notificationAddress),
        cryptoCurrency.networkParams,
      );

      txOutputs.add(
        coin.TxOutput(
          value: overrideAmountForTesting ?? cryptoCurrency.dustLimitP2PKH.raw,
          scriptPubKey: notifAddr.scriptPubKey,
        ),
      );

      txOutputs.add(
        coin.TxOutput(value: BigInt.zero, scriptPubKey: opReturnScript),
      );

      // TODO: add possible change output and mark output as dangerous
      if (change > BigInt.zero) {
        // generate new change address if current change address has been used
        await checkChangeAddressForTransactions();
        final String changeAddress = (await getCurrentChangeAddress())!.value;

        final changeAddr = coin.Addr.fromString(
          normalizeAddress(changeAddress),
          cryptoCurrency.networkParams,
        );

        txOutputs.add(
          coin.TxOutput(
            value: change,
            scriptPubKey: changeAddr.scriptPubKey,
          ),
        );
      }

      // Build unsigned tx for sighash computation
      final unsignedTx = coin.Tx(
        version: cryptoCurrency.transactionVersion,
        inputs: unsignedInputs,
        outputs: txOutputs,
      );

      // Sign each input using the sign-then-assemble pattern
      final List<coin.TxInput> signedInputs = [];

      for (var i = 0; i < inputsWithKeys.length; i++) {
        final meta = inputMeta[i];
        final outpoint = unsignedInputs[i].prevOut;

        switch (meta.type) {
          case DerivePathType.bip44:
          case DerivePathType.bch44:
            // P2PKH: Legacy sighash
            final prevScript = prevOuts[i].scriptPubKey;
            final hasher = coin.LegacySigHasher();
            final digest = hasher.hash(
              unsignedTx,
              i,
              coin.SigHashType.all,
              prevScript: prevScript,
            );
            final sig = coin.EcdsaSig.sign(digest, meta.secretKey!.bytes);
            final inputSig = coin.InputSig(
              derSig: sig.toDer(),
              hashType: coin.SigHashType.all,
            );
            signedInputs.add(
              coin.P2pkhInput(
                prevOut: outpoint,
                inputSig: inputSig,
                publicKey: meta.publicKey!.bytes,
                sequence: sequence,
              ),
            );

          case DerivePathType.bip49:
            // P2SH-P2WPKH: BIP-143 witness sighash with P2PKH script code
            final pubKeyHash = coin.hash160(meta.publicKey!.bytes);
            final scriptCode = coin.PayToPubKeyHash(pubKeyHash).compiled;
            final hasher = coin.WitnessSigHasher();
            final digest = hasher.hash(
              unsignedTx,
              i,
              coin.SigHashType.all,
              prevScript: scriptCode,
              amount: meta.value,
            );
            final sig = coin.EcdsaSig.sign(digest, meta.secretKey!.bytes);
            final inputSig = coin.InputSig(
              derSig: sig.toDer(),
              hashType: coin.SigHashType.all,
            );
            final witnessProgram = Uint8List.fromList(
              [0x00, 0x14, ...pubKeyHash],
            );
            final scriptSig = Uint8List.fromList(
              [witnessProgram.length, ...witnessProgram],
            );
            signedInputs.add(
              _P2shP2wpkhInput(
                prevOut: outpoint,
                scriptSig: scriptSig,
                inputSig: inputSig,
                publicKey: meta.publicKey!.bytes,
                sequence: sequence,
              ),
            );

          case DerivePathType.bip84:
            // P2WPKH: BIP-143 witness sighash
            final pubKeyHash = coin.hash160(meta.publicKey!.bytes);
            final scriptCode = coin.PayToPubKeyHash(pubKeyHash).compiled;
            final hasher = coin.WitnessSigHasher();
            final digest = hasher.hash(
              unsignedTx,
              i,
              coin.SigHashType.all,
              prevScript: scriptCode,
              amount: meta.value,
            );
            final sig = coin.EcdsaSig.sign(digest, meta.secretKey!.bytes);
            final inputSig = coin.InputSig(
              derSig: sig.toDer(),
              hashType: coin.SigHashType.all,
            );
            signedInputs.add(
              coin.P2wpkhInput(
                prevOut: outpoint,
                inputSig: inputSig,
                publicKey: meta.publicKey!.bytes,
                sequence: sequence,
              ),
            );

          case DerivePathType.bip86:
            // Taproot: BIP-341 sighash with key tweak
            final hasher = coin.TaprootSigHasher(prevOuts: prevOuts);
            final digest = hasher.hash(
              unsignedTx,
              i,
              coin.SigHashType.all,
            );
            final taproot = coin.Taproot(internalKey: meta.publicKey!);
            final tweakedKey = taproot.tweakSecretKey(meta.secretKey!);
            final sig = coin.SchnorrSig.sign(digest, tweakedKey.bytes);
            final inputSig = coin.SchnorrInputSig(
              sig: sig.bytes,
              hashType: coin.SigHashType.all,
            );
            signedInputs.add(
              coin.TaprootKeyInput(
                prevOut: outpoint,
                inputSig: inputSig,
                sequence: sequence,
              ),
            );

          default:
            throw UnsupportedError(
              "Unknown derivation path type found: ${meta.type}",
            );
        }
      }

      // Assemble final signed transaction
      final signedTx = coin.Tx(
        version: cryptoCurrency.transactionVersion,
        inputs: signedInputs,
        outputs: txOutputs,
      );

      return Tuple2(signedTx.toHex(), signedTx.vSize());
    } catch (e, s) {
      Logging.instance.e("_createNotificationTx(): ", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<TxData> broadcastNotificationTx({required TxData txData}) async {
    try {
      Logging.instance.d("confirmNotificationTx txData: $txData");
      final txHash = await electrumXClient.broadcastTransaction(
        rawTx: txData.raw!,
      );
      Logging.instance.d("Sent txHash: $txHash");

      try {
        await updateTransactions();
      } catch (e, s) {
        Logging.instance.e(
          "refresh() failed in confirmNotificationTx (${info.name}::$walletId): $e",
          error: e,
          stackTrace: s,
        );
      }

      return txData.copyWith(txid: txHash, txHash: txHash);
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown from confirmSend(): ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  // Future<bool?> _checkHasConnectedCache(String paymentCodeString) async {
  //   final value = await secureStorageInterface.read(
  //       key: "$_connectedKeyPrefix$paymentCodeString");
  //   if (value == null) {
  //     return null;
  //   } else {
  //     final int rawBool = int.parse(value);
  //     return rawBool > 0;
  //   }
  // }
  //
  // Future<void> _setConnectedCache(
  //     String paymentCodeString, bool hasConnected) async {
  //   await secureStorageInterface.write(
  //       key: "$_connectedKeyPrefix$paymentCodeString",
  //       value: hasConnected ? "1" : "0");
  // }

  // TODO optimize
  Future<bool> hasConnected(String paymentCodeString) async {
    // final didConnect = await _checkHasConnectedCache(paymentCodeString);
    // if (didConnect == true) {
    //   return true;
    // }
    //
    // final keys = await lookupKey(paymentCodeString);
    //
    // final tx = await mainDB
    //     .getTransactions(walletId)
    //     .filter()
    //     .subTypeEqualTo(TransactionSubType.bip47Notification).and()
    //     .address((q) =>
    //         q.anyOf<String, Transaction>(keys, (q, e) => q.otherDataEqualTo(e)))
    //     .findAll();

    final myNotificationAddress = await getMyNotificationAddress();

    final txns =
        await mainDB.isar.transactionV2s
            .where()
            .walletIdEqualTo(walletId)
            .filter()
            .subTypeEqualTo(TransactionSubType.bip47Notification)
            .findAll();

    for (final tx in txns) {
      switch (tx.type) {
        case TransactionType.incoming:
          for (final output in tx.outputs) {
            for (final outputAddress in output.addresses) {
              if (outputAddress == myNotificationAddress.value) {
                final unBlindedPaymentCode =
                    await unBlindedPaymentCodeFromTransaction(transaction: tx);

                if (unBlindedPaymentCode != null &&
                    paymentCodeString == unBlindedPaymentCode.toString()) {
                  // await _setConnectedCache(paymentCodeString, true);
                  return true;
                }

                final unBlindedPaymentCodeBad =
                    await unBlindedPaymentCodeFromTransactionBad(
                      transaction: tx,
                    );

                if (unBlindedPaymentCodeBad != null &&
                    paymentCodeString == unBlindedPaymentCodeBad.toString()) {
                  // await _setConnectedCache(paymentCodeString, true);
                  return true;
                }
              }
            }
          }

        case TransactionType.outgoing:
          for (final output in tx.outputs) {
            for (final outputAddress in output.addresses) {
              final address =
                  await mainDB.isar.addresses
                      .where()
                      .walletIdEqualTo(walletId)
                      .filter()
                      .subTypeEqualTo(AddressSubType.paynymNotification)
                      .and()
                      .valueEqualTo(outputAddress)
                      .findFirst();

              if (address?.otherData != null) {
                final code = await paymentCodeStringByKey(address!.otherData!);
                if (code == paymentCodeString) {
                  // await _setConnectedCache(paymentCodeString, true);
                  return true;
                }
              }
            }
          }
        default:
          break;
      }
    }

    // otherwise return no
    // await _setConnectedCache(paymentCodeString, false);
    return false;
  }

  Uint8List? _pubKeyFromInput(InputV2 input) {
    final scriptSigComponents = input.scriptSigAsm?.split(" ") ?? [];
    if (scriptSigComponents.length > 1) {
      return scriptSigComponents[1].toUint8ListFromHex;
    }
    if (input.witness != null) {
      try {
        final witnessComponents = jsonDecode(input.witness!) as List;
        if (witnessComponents.length == 2) {
          return (witnessComponents[1] as String).toUint8ListFromHex;
        }
      } catch (e, s) {
        Logging.instance.e("_pubKeyFromInput()", error: e, stackTrace: s);
      }
    }
    return null;
  }

  Future<PaymentCode?> unBlindedPaymentCodeFromTransaction({
    required TransactionV2 transaction,
  }) async {
    try {
      final blindedCodeBytes = Bip47Utils.getBlindedPaymentCodeBytesFrom(
        transaction,
      );

      // transaction does not contain a payment code
      if (blindedCodeBytes == null) {
        return null;
      }

      final designatedInput = transaction.inputs.first;

      final txPoint =
          designatedInput.outpoint!.txid.toUint8ListFromHex.reversed.toList();
      final txPointIndex = designatedInput.outpoint!.vout;

      final rev = Uint8List(txPoint.length + 4);
      _copyBytes(Uint8List.fromList(txPoint), 0, rev, 0, txPoint.length);
      final buffer = rev.buffer.asByteData();
      buffer.setUint32(txPoint.length, txPointIndex, Endian.little);

      final pubKey = _pubKeyFromInput(designatedInput);

      // Taproot (bip86) inputs don't expose the public key in scriptSig
      // or witness -- only a signature. Can't compute ECDH shared secret.
      if (pubKey == null) {
        return null;
      }

      final myPrivateKey = (await deriveNotificationBip32Node()).privateKey!;

      final S = SecretPoint(myPrivateKey, pubKey);

      final mask = PaymentCode.getMask(S.ecdhSecret(), rev);

      final unBlindedPayload = PaymentCode.blind(
        payload: blindedCodeBytes,
        mask: mask,
        unBlind: true,
      );

      final unBlindedPaymentCode = PaymentCode.fromPayload(
        unBlindedPayload,
        networkType: networkType,
      );

      return unBlindedPaymentCode;
    } catch (e, s) {
      Logging.instance.e(
        "unBlindedPaymentCodeFromTransaction()",
        error: e,
        stackTrace: s,
      );
      Logging.instance.d(
        "unBlindedPaymentCodeFromTransaction() failed for tx: $transaction",
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  Future<PaymentCode?> unBlindedPaymentCodeFromTransactionBad({
    required TransactionV2 transaction,
  }) async {
    try {
      final blindedCodeBytes = Bip47Utils.getBlindedPaymentCodeBytesFrom(
        transaction,
      );

      // transaction does not contain a payment code
      if (blindedCodeBytes == null) {
        return null;
      }

      final designatedInput = transaction.inputs.first;

      final txPoint =
          designatedInput.outpoint!.txid.toUint8ListFromHex.toList();
      final txPointIndex = designatedInput.outpoint!.vout;

      final rev = Uint8List(txPoint.length + 4);
      _copyBytes(Uint8List.fromList(txPoint), 0, rev, 0, txPoint.length);
      final buffer = rev.buffer.asByteData();
      buffer.setUint32(txPoint.length, txPointIndex, Endian.little);

      final pubKey = _pubKeyFromInput(designatedInput);

      if (pubKey == null) {
        return null;
      }

      final myPrivateKey = (await deriveNotificationBip32Node()).privateKey!;

      final S = SecretPoint(myPrivateKey, pubKey);

      final mask = PaymentCode.getMask(S.ecdhSecret(), rev);

      final unBlindedPayload = PaymentCode.blind(
        payload: blindedCodeBytes,
        mask: mask,
        unBlind: true,
      );

      final unBlindedPaymentCode = PaymentCode.fromPayload(
        unBlindedPayload,
        networkType: networkType,
      );

      return unBlindedPaymentCode;
    } catch (e, s) {
      Logging.instance.e(
        "unBlindedPaymentCodeFromTransactionBad()n",
        error: e,
        stackTrace: s,
      );
      Logging.instance.d(
        "unBlindedPaymentCodeFromTransactionBad() failed: $e\nFor tx: $transaction",
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  Future<List<PaymentCode>>
  getAllPaymentCodesFromNotificationTransactions() async {
    final txns =
        await mainDB.isar.transactionV2s
            .where()
            .walletIdEqualTo(walletId)
            .filter()
            .subTypeEqualTo(TransactionSubType.bip47Notification)
            .findAll();

    final List<PaymentCode> codes = [];

    for (final tx in txns) {
      // tx is sent so we can check the address's otherData for the code String
      if (tx.type == TransactionType.outgoing) {
        for (final output in tx.outputs) {
          for (final outputAddress in output.addresses.where(
            (e) => e.isNotEmpty,
          )) {
            final address =
                await mainDB.isar.addresses
                    .where()
                    .walletIdEqualTo(walletId)
                    .filter()
                    .subTypeEqualTo(AddressSubType.paynymNotification)
                    .and()
                    .valueEqualTo(outputAddress)
                    .findFirst();

            if (address?.otherData != null) {
              final codeString = await paymentCodeStringByKey(
                address!.otherData!,
              );
              if (codeString != null &&
                  codes.where((e) => e.toString() == codeString).isEmpty) {
                codes.add(
                  PaymentCode.fromPaymentCode(
                    codeString,
                    networkType: networkType,
                  ),
                );
              }
            }
          }
        }
      } else {
        // otherwise we need to un blind the code
        final unBlinded = await unBlindedPaymentCodeFromTransaction(
          transaction: tx,
        );
        if (unBlinded != null &&
            codes.where((e) => e.toString() == unBlinded.toString()).isEmpty) {
          codes.add(unBlinded);
        }

        final unBlindedBad = await unBlindedPaymentCodeFromTransactionBad(
          transaction: tx,
        );
        if (unBlindedBad != null &&
            codes
                .where((e) => e.toString() == unBlindedBad.toString())
                .isEmpty) {
          codes.add(unBlindedBad);
        }
      }
    }

    return codes;
  }

  Future<void> checkForNotificationTransactionsTo(
    Set<String> otherCodeStrings,
  ) async {
    final sentNotificationTransactions =
        await mainDB.isar.transactionV2s
            .where()
            .walletIdEqualTo(walletId)
            .filter()
            .subTypeEqualTo(TransactionSubType.bip47Notification)
            .and()
            .typeEqualTo(TransactionType.outgoing)
            .findAll();

    final List<PaymentCode> codes = [];
    for (final codeString in otherCodeStrings) {
      codes.add(
        PaymentCode.fromPaymentCode(codeString, networkType: networkType),
      );
    }

    for (final tx in sentNotificationTransactions) {
      for (final output in tx.outputs) {
        for (final outputAddress in output.addresses) {
          if (outputAddress.isNotEmpty) {
            for (final code in codes) {
              final notificationAddress = code.notificationAddressP2PKH();

              if (outputAddress == notificationAddress) {
                Address? storedAddress = await mainDB.getAddress(
                  walletId,
                  outputAddress,
                );
                if (storedAddress == null) {
                  // most likely not mine
                  storedAddress = Address(
                    walletId: walletId,
                    value: notificationAddress,
                    publicKey: [],
                    derivationIndex: 0,
                    derivationPath: null,
                    type: AddressType.nonWallet,
                    subType: AddressSubType.paynymNotification,
                    otherData: await storeCode(code.toString()),
                  );
                } else {
                  storedAddress = storedAddress.copyWith(
                    subType: AddressSubType.paynymNotification,
                    otherData: await storeCode(code.toString()),
                  );
                }

                await mainDB.updateOrPutAddresses([storedAddress]);
              }
            }
          }
        }
      }
    }
  }

  Future<void> restoreAllHistory({
    required int maxUnusedAddressGap,
    required int maxNumberOfIndexesToCheck,
    required Set<String> paymentCodeStrings,
  }) async {
    final codes = await getAllPaymentCodesFromNotificationTransactions();
    final List<PaymentCode> extraCodes = [];
    for (final codeString in paymentCodeStrings) {
      if (codes.where((e) => e.toString() == codeString).isEmpty) {
        final extraCode = PaymentCode.fromPaymentCode(
          codeString,
          networkType: networkType,
        );
        if (extraCode.isValid()) {
          extraCodes.add(extraCode);
        }
      }
    }

    codes.addAll(extraCodes);

    final List<Future<void>> futures = [];
    for (final code in codes) {
      futures.add(
        _restoreHistoryWith(
          other: code,
          maxUnusedAddressGap: maxUnusedAddressGap,
          maxNumberOfIndexesToCheck: maxNumberOfIndexesToCheck,
        ),
      );
    }

    await Future.wait(futures);
  }

  Future<void> _restoreHistoryWith({
    required PaymentCode other,
    required int maxUnusedAddressGap,
    required int maxNumberOfIndexesToCheck,
  }) async {
    // https://en.bitcoin.it/wiki/BIP_0047#Path_levels
    const maxCount = 2147483647;
    assert(maxNumberOfIndexesToCheck < maxCount);

    final mySendBip32Node = await deriveNotificationBip32Node();

    final List<Address> addresses = [];
    int receivingGapCounter = 0;
    int outgoingGapCounter = 0;

    // non segwit receiving
    for (
      int i = 0;
      i < maxNumberOfIndexesToCheck &&
          receivingGapCounter < maxUnusedAddressGap;
      i++
    ) {
      if (receivingGapCounter < maxUnusedAddressGap) {
        final address = await _generatePaynymReceivingAddress(
          sender: other,
          index: i,
          derivePathType: DerivePathType.bip44,
        );

        addresses.add(address);

        final count = await fetchTxCount(
          addressScriptHash: cryptoCurrency.addressToScriptHash(
            address: address.value,
          ),
        );

        if (count > 0) {
          receivingGapCounter = 0;
        } else {
          receivingGapCounter++;
        }
      }
    }

    // non segwit sends
    for (
      int i = 0;
      i < maxNumberOfIndexesToCheck && outgoingGapCounter < maxUnusedAddressGap;
      i++
    ) {
      if (outgoingGapCounter < maxUnusedAddressGap) {
        final address = await _generatePaynymSendAddress(
          other: other,
          index: i,
          derivePathType: DerivePathType.bip44,
          mySendBip32Node: mySendBip32Node,
        );

        addresses.add(address);

        final count = await fetchTxCount(
          addressScriptHash: cryptoCurrency.addressToScriptHash(
            address: address.value,
          ),
        );

        if (count > 0) {
          outgoingGapCounter = 0;
        } else {
          outgoingGapCounter++;
        }
      }
    }

    if (other.isSegWitEnabled()) {
      int receivingGapCounterSegwit = 0;
      int outgoingGapCounterSegwit = 0;
      // segwit receiving
      for (
        int i = 0;
        i < maxNumberOfIndexesToCheck &&
            receivingGapCounterSegwit < maxUnusedAddressGap;
        i++
      ) {
        if (receivingGapCounterSegwit < maxUnusedAddressGap) {
          final address = await _generatePaynymReceivingAddress(
            sender: other,
            index: i,
            derivePathType: DerivePathType.bip84,
          );

          addresses.add(address);

          final count = await fetchTxCount(
            addressScriptHash: cryptoCurrency.addressToScriptHash(
              address: address.value,
            ),
          );

          if (count > 0) {
            receivingGapCounterSegwit = 0;
          } else {
            receivingGapCounterSegwit++;
          }
        }
      }

      // segwit sends
      for (
        int i = 0;
        i < maxNumberOfIndexesToCheck &&
            outgoingGapCounterSegwit < maxUnusedAddressGap;
        i++
      ) {
        if (outgoingGapCounterSegwit < maxUnusedAddressGap) {
          final address = await _generatePaynymSendAddress(
            other: other,
            index: i,
            derivePathType: DerivePathType.bip84,
            mySendBip32Node: mySendBip32Node,
          );

          addresses.add(address);

          final count = await fetchTxCount(
            addressScriptHash: cryptoCurrency.addressToScriptHash(
              address: address.value,
            ),
          );

          if (count > 0) {
            outgoingGapCounterSegwit = 0;
          } else {
            outgoingGapCounterSegwit++;
          }
        }
      }
    }

    // TODO: Consider scanning all three types unconditionally to catch
    //   contacts that upgraded their payment code after initial connection.
    if (other.isTaprootEnabled()) {
      int receivingGapCounterTaproot = 0;
      int outgoingGapCounterTaproot = 0;
      // taproot receiving
      for (
        int i = 0;
        i < maxNumberOfIndexesToCheck &&
            receivingGapCounterTaproot < maxUnusedAddressGap;
        i++
      ) {
        if (receivingGapCounterTaproot < maxUnusedAddressGap) {
          final address = await _generatePaynymReceivingAddress(
            sender: other,
            index: i,
            derivePathType: DerivePathType.bip86,
          );

          addresses.add(address);

          final count = await fetchTxCount(
            addressScriptHash: cryptoCurrency.addressToScriptHash(
              address: address.value,
            ),
          );

          if (count > 0) {
            receivingGapCounterTaproot = 0;
          } else {
            receivingGapCounterTaproot++;
          }
        }
      }

      // taproot sends
      for (
        int i = 0;
        i < maxNumberOfIndexesToCheck &&
            outgoingGapCounterTaproot < maxUnusedAddressGap;
        i++
      ) {
        if (outgoingGapCounterTaproot < maxUnusedAddressGap) {
          final address = await _generatePaynymSendAddress(
            other: other,
            index: i,
            derivePathType: DerivePathType.bip86,
            mySendBip32Node: mySendBip32Node,
          );

          addresses.add(address);

          final count = await fetchTxCount(
            addressScriptHash: cryptoCurrency.addressToScriptHash(
              address: address.value,
            ),
          );

          if (count > 0) {
            outgoingGapCounterTaproot = 0;
          } else {
            outgoingGapCounterTaproot++;
          }
        }
      }
    }

    await mainDB.updateOrPutAddresses(addresses);
  }

  Future<Address> getMyNotificationAddress() async {
    final storedAddress =
        await mainDB
            .getAddresses(walletId)
            .filter()
            .subTypeEqualTo(AddressSubType.paynymNotification)
            .and()
            .typeEqualTo(AddressType.p2pkh)
            .and()
            .not()
            .typeEqualTo(AddressType.nonWallet)
            .findFirst();

    if (storedAddress != null) {
      return storedAddress;
    } else {
      final root = await _getRootNode();
      final node = root.derivePath(
        _basePaynymDerivePath(testnet: info.coin.network.isTestNet),
      );
      final paymentCode = PaymentCode.fromBip32Node(
        node,
        networkType: networkType,
        shouldSetSegwitBit: false,
      );

      final pubKeyHash = coin.hash160(paymentCode.notificationPublicKey());
      final chain = coin.Chain(
        wifPrefix: cryptoCurrency.networkParams.wifPrefix,
        p2pkhPrefix: cryptoCurrency.networkParams.p2pkhPrefix,
        p2shPrefix: cryptoCurrency.networkParams.p2shPrefix,
        bech32Hrp: cryptoCurrency.networkParams.bech32Hrp,
        privHDPrefix: cryptoCurrency.networkParams.privHDPrefix,
        pubHDPrefix: cryptoCurrency.networkParams.pubHDPrefix,
        name: '',
        bip44CoinType: 0,
      );
      final addressString = coin.P2pkhAddr(pubKeyHash).encode(chain);

      Address address = Address(
        walletId: walletId,
        value: addressString,
        publicKey: paymentCode.getPubKey(),
        derivationIndex: 0,
        derivationPath:
            DerivationPath()
              ..value = _notificationDerivationPath(
                testnet: info.coin.network.isTestNet,
              ),
        type: AddressType.p2pkh,
        subType: AddressSubType.paynymNotification,
        otherData: await storeCode(paymentCode.toString()),
      );

      // check against possible race condition. Ff this function was called
      // multiple times an address could've been saved after the check at the
      // beginning to see if there already was notification address. This would
      // lead to a Unique Index violation  error
      await mainDB.isar.writeTxn(() async {
        final storedAddress =
            await mainDB
                .getAddresses(walletId)
                .filter()
                .subTypeEqualTo(AddressSubType.paynymNotification)
                .and()
                .typeEqualTo(AddressType.p2pkh)
                .and()
                .not()
                .typeEqualTo(AddressType.nonWallet)
                .findFirst();

        if (storedAddress == null) {
          await mainDB.isar.addresses.put(address);
        } else {
          address = storedAddress;
        }
      });

      return address;
    }
  }

  /// look up a key that corresponds to a payment code string
  Future<List<String>> lookupKey(String paymentCodeString) async {
    final keys = (await secureStorageInterface.keys).where(
      (e) => e.startsWith(kPCodeKeyPrefix),
    );
    final List<String> result = [];
    for (final key in keys) {
      final value = await secureStorageInterface.read(key: key);
      if (value == paymentCodeString) {
        result.add(key);
      }
    }
    return result;
  }

  /// fetch a payment code string
  Future<String?> paymentCodeStringByKey(String key) async {
    final value = await secureStorageInterface.read(key: key);
    return value;
  }

  /// store payment code string and return the generated key used
  Future<String> storeCode(String paymentCodeString) async {
    final key = _generateKey();
    await secureStorageInterface.write(key: key, value: paymentCodeString);
    return key;
  }

  void _copyBytes(
    Uint8List source,
    int sourceStartingIndex,
    Uint8List destination,
    int destinationStartingIndex,
    int numberOfBytes,
  ) {
    for (int i = 0; i < numberOfBytes; i++) {
      destination[i + destinationStartingIndex] =
          source[i + sourceStartingIndex];
    }
  }

  /// generate a new payment code string storage key
  String _generateKey() {
    final bytes = _randomBytes(24);
    return "$kPCodeKeyPrefix${bytes.toHex}";
  }

  // https://github.com/AaronFeickert/stack_wallet_backup/blob/master/lib/secure_storage.dart#L307-L311
  /// Generate cryptographically-secure random bytes
  Uint8List _randomBytes(int n) {
    final Random rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(n, (_) => rng.nextInt(0xFF + 1)),
    );
  }

  // ================== Overrides ==============================================

  @override
  Future<void> updateTransactions({List<Address>? overrideAddresses}) async {
    // Get all addresses.
    final List<Address> allAddressesOld =
        overrideAddresses ?? await fetchAddressesForElectrumXScan();

    // Separate receiving and change addresses.
    final Set<String> receivingAddresses =
        allAddressesOld
            .where(
              (e) =>
                  e.subType == AddressSubType.receiving ||
                  e.subType == AddressSubType.paynymNotification ||
                  e.subType == AddressSubType.paynymReceive,
            )
            .map((e) => e.value)
            .toSet();
    final Set<String> changeAddresses =
        allAddressesOld
            .where((e) => e.subType == AddressSubType.change)
            .map((e) => e.value)
            .toSet();

    // Remove duplicates.
    final allAddressesSet = {...receivingAddresses, ...changeAddresses};

    // Fetch history from ElectrumX.
    final List<Map<String, dynamic>> allTxHashes = await fetchHistory(
      allAddressesSet,
    );

    final unconfirmedTxs =
        await mainDB.isar.transactionV2s
            .where()
            .walletIdEqualTo(walletId)
            .filter()
            .heightIsNull()
            .or()
            .heightEqualTo(0)
            .txidProperty()
            .findAll();

    allTxHashes.addAll(unconfirmedTxs.map((e) => {"tx_hash": e}));

    // Only parse new txs (not in db yet).
    final List<Map<String, dynamic>> allTransactions = [];
    for (final txHash in allTxHashes) {
      // Check for duplicates by searching for tx by tx_hash in db.
      // final storedTx = await mainDB.isar.transactionV2s
      //     .where()
      //     .txidWalletIdEqualTo(txHash["tx_hash"] as String, walletId)
      //     .findFirst();
      //
      // if (storedTx == null ||
      //     storedTx.height == null ||
      //     (storedTx.height != null && storedTx.height! <= 0)) {
      // Tx not in db yet.
      final txid = txHash["tx_hash"] as String;
      final Map<String, dynamic> tx;
      try {
        tx = await electrumXCachedClient.getTransaction(
          txHash: txid,
          verbose: true,
          cryptoCurrency: cryptoCurrency,
        );
      } catch (e) {
        // tx no longer exists then delete from local db
        if (e.toString().contains(
          "JSON-RPC error 2: daemon error: DaemonError({'code': -5, "
          "'message': 'No such mempool or blockchain transaction",
        )) {
          await mainDB.isar.writeTxn(
            () async =>
                await mainDB.isar.transactionV2s
                    .where()
                    .walletIdEqualTo(walletId)
                    .filter()
                    .txidEqualTo(txid)
                    .deleteFirst(),
          );
          continue;
        } else {
          rethrow;
        }
      }

      // Only tx to list once.
      if (allTransactions.indexWhere((e) => e["txid"] == txid) == -1) {
        tx["height"] = txHash["height"];
        allTransactions.add(tx);
      }
      // }
    }

    // Parse all new txs.
    final List<TransactionV2> txns = [];
    for (final txData in allTransactions) {
      bool wasSentFromThisWallet = false;
      // Set to true if any inputs were detected as owned by this wallet.

      bool wasReceivedInThisWallet = false;
      // Set to true if any outputs were detected as owned by this wallet.

      // Parse inputs.
      BigInt amountReceivedInThisWallet = BigInt.zero;
      BigInt changeAmountReceivedInThisWallet = BigInt.zero;
      final List<InputV2> inputs = [];
      for (final jsonInput in txData["vin"] as List) {
        final map = Map<String, dynamic>.from(jsonInput as Map);

        final List<String> addresses = [];
        String valueStringSats = "0";
        OutpointV2? outpoint;

        final coinbase = map["coinbase"] as String?;

        if (coinbase == null) {
          // Not a coinbase (ie a typical input).
          final txid = map["txid"] as String;
          final vout = map["vout"] as int;

          final inputTx = await electrumXCachedClient.getTransaction(
            txHash: txid,
            cryptoCurrency: cryptoCurrency,
          );

          final prevOutJson = Map<String, dynamic>.from(
            (inputTx["vout"] as List).firstWhere((e) => e["n"] == vout) as Map,
          );

          final prevOut = OutputV2.fromElectrumXJson(
            prevOutJson,
            decimalPlaces: cryptoCurrency.fractionDigits,
            isFullAmountNotSats: true,
            walletOwns: false, // Doesn't matter here as this is not saved.
          );

          outpoint = OutpointV2.isarCantDoRequiredInDefaultConstructor(
            txid: txid,
            vout: vout,
          );
          valueStringSats = prevOut.valueStringSats;
          addresses.addAll(prevOut.addresses);
        }

        InputV2 input = InputV2.fromElectrumxJson(
          json: map,
          outpoint: outpoint,
          valueStringSats: valueStringSats,
          addresses: addresses,
          coinbase: coinbase,
          // Need addresses before we can know if the wallet owns this input.
          walletOwns: false,
        );

        // Check if input was from this wallet.
        if (allAddressesSet.intersection(input.addresses.toSet()).isNotEmpty) {
          wasSentFromThisWallet = true;
          input = input.copyWith(walletOwns: true);
        }

        inputs.add(input);
      }

      // Parse outputs.
      final List<OutputV2> outputs = [];
      for (final outputJson in txData["vout"] as List) {
        OutputV2 output = OutputV2.fromElectrumXJson(
          Map<String, dynamic>.from(outputJson as Map),
          decimalPlaces: cryptoCurrency.fractionDigits,
          isFullAmountNotSats: true,
          // Need addresses before we can know if the wallet owns this input.
          walletOwns: false,
        );

        // If output was to my wallet, add value to amount received.
        if (receivingAddresses
            .intersection(output.addresses.toSet())
            .isNotEmpty) {
          wasReceivedInThisWallet = true;
          amountReceivedInThisWallet += output.value;
          output = output.copyWith(walletOwns: true);
        } else if (changeAddresses
            .intersection(output.addresses.toSet())
            .isNotEmpty) {
          wasReceivedInThisWallet = true;
          changeAmountReceivedInThisWallet += output.value;
          output = output.copyWith(walletOwns: true);
        }

        outputs.add(output);
      }

      final totalOut = outputs
          .map((e) => e.value)
          .fold(BigInt.zero, (value, element) => value + element);

      TransactionType type;
      TransactionSubType subType = TransactionSubType.none;
      if (outputs.length > 1 && inputs.isNotEmpty) {
        for (int i = 0; i < outputs.length; i++) {
          final List<String>? scriptChunks = outputs[i].scriptPubKeyAsm?.split(
            " ",
          );
          if (scriptChunks?.length == 2 && scriptChunks?[0] == "OP_RETURN") {
            final blindedPaymentCode = scriptChunks![1];
            final bytes = blindedPaymentCode.toUint8ListFromHex;

            // https://en.bitcoin.it/wiki/BIP_0047#Sending
            if (bytes.length == 80 && bytes.first == 1) {
              subType = TransactionSubType.bip47Notification;
              break;
            }
          }
        }
      }

      // At least one input was owned by this wallet.
      if (wasSentFromThisWallet) {
        type = TransactionType.outgoing;

        if (wasReceivedInThisWallet) {
          if (changeAmountReceivedInThisWallet + amountReceivedInThisWallet ==
              totalOut) {
            // Definitely sent all to self.
            type = TransactionType.sentToSelf;
          } else if (amountReceivedInThisWallet == BigInt.zero) {
            // Most likely just a typical send, do nothing here yet.
          }
        }
      } else if (wasReceivedInThisWallet) {
        // Only found outputs owned by this wallet.
        type = TransactionType.incoming;

        // TODO: [prio=none] Check for special Bitcoin outputs like ordinals.
      } else {
        Logging.instance.w("Unexpected tx found (ignoring it)");
        Logging.instance.d("Unexpected tx found (ignoring it): $txData");
        continue;
      }

      String? otherData;
      if (txData["size"] is int || txData["vsize"] is int) {
        otherData = jsonEncode({
          TxV2OdKeys.size: txData["size"] as int?,
          TxV2OdKeys.vSize: txData["vsize"] as int?,
        });
      }

      final tx = TransactionV2(
        walletId: walletId,
        blockHash: txData["blockhash"] as String?,
        hash: txData["hash"] as String,
        txid: txData["txid"] as String,
        height: txData["height"] as int?,
        version: txData["version"] as int,
        timestamp:
            txData["blocktime"] as int? ??
            DateTime.timestamp().millisecondsSinceEpoch ~/ 1000,
        inputs: List.unmodifiable(inputs),
        outputs: List.unmodifiable(outputs),
        type: type,
        subType: subType,
        otherData: otherData,
      );

      txns.add(tx);
    }

    await mainDB.updateOrPutTransactionV2s(txns);
  }

  @override
  Future<({String? blockedReason, bool blocked, String? utxoLabel})>
  checkBlockUTXO(
    Map<String, dynamic> jsonUTXO,
    String? scriptPubKeyHex,
    Map<String, dynamic>? jsonTX,
    String? utxoOwnerAddress,
  ) async {
    bool blocked = false;
    String? blockedReason;
    String? utxoLabel;

    // check for bip47 notification
    if (jsonTX != null) {
      final outputs = jsonTX["vout"] as List;
      for (int i = 0; i < outputs.length; i++) {
        final output = outputs[i];
        final List<String>? scriptChunks =
            (output['scriptPubKey']?['asm'] as String?)?.split(" ");
        if (scriptChunks?.length == 2 && scriptChunks?[0] == "OP_RETURN") {
          final blindedPaymentCode = scriptChunks![1];
          final bytes = blindedPaymentCode.toUint8ListFromHex;

          // https://en.bitcoin.it/wiki/BIP_0047#Sending
          if (bytes.length == 80 && bytes.first == 1) {
            final myNotificationAddress = await getMyNotificationAddress();
            if (utxoOwnerAddress == myNotificationAddress.value) {
              blocked = true;
              blockedReason = "Incoming paynym notification transaction.";
            } else {
              blockedReason =
                  "Paynym notification change output. Incautious "
                  "handling of change outputs from notification transactions "
                  "may cause unintended loss of privacy.";
              utxoLabel = blockedReason;
            }

            break;
          }
        }
      }
    }

    return (
      blockedReason: blockedReason,
      blocked: blocked,
      utxoLabel: utxoLabel,
    );
  }

  @override
  FilterOperation? get transactionFilterOperation => FilterGroup.not(
    const FilterGroup.and([
      FilterCondition.equalTo(
        property: r"subType",
        value: TransactionSubType.bip47Notification,
      ),
      FilterCondition.equalTo(
        property: r"type",
        value: TransactionType.incoming,
      ),
    ]),
  );
}

/// P2SH-P2WPKH input: scriptSig pushes the witness program, witness
/// contains [sig, pubkey]. This is the standard BIP49 wrapped-segwit input.
class _P2shP2wpkhInput extends coin.TxInput {
  @override
  final coin.Outpoint prevOut;
  @override
  final Uint8List scriptSig;
  @override
  final int sequence;
  final coin.InputSig inputSig;
  final Uint8List publicKey;

  _P2shP2wpkhInput({
    required this.prevOut,
    required this.scriptSig,
    required this.inputSig,
    required this.publicKey,
    this.sequence = coin.TxInput.sequenceFinal,
  });

  @override
  List<Uint8List> get witness => [inputSig.toBytes(), publicKey];
  @override
  bool get complete => true;
  @override
  int get signedSize => 91; // typical P2SH-P2WPKH input size
}
