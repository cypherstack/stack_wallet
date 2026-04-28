import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip47/bip47.dart';
import 'package:bip47/src/network_type.dart';
import 'package:bip47/src/util.dart';
import 'package:coin/coin.dart' as coin;
import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/sha512.dart';
import 'package:pointycastle/macs/hmac.dart';

class PaymentCode {
  static const int PUBLIC_KEY_Y_OFFSET = 2;
  static const int PUBLIC_KEY_X_OFFSET = 3;
  static const int CHAIN_OFFSET = 35;
  static const int PUBLIC_KEY_X_LEN = 32;
  static const int PUBLIC_KEY_Y_LEN = 1;
  static const int CHAIN_LEN = 32;
  static const int PAYLOAD_LEN = 80;
  static const int CHECKSUM_LEN = 4;

  static const int SAMOURAI_FEATURE_BYTE = 79;
  static const int SAMOURAI_SEGWIT_BIT = 0;
  static const int SAMOURAI_TAPROOT_BIT = 1;

  late String _paymentCodeString;
  late final bip32.BIP32 _bip32Node;
  final NetworkType networkType;

  PaymentCode._() : networkType = bitcoin;

  // initialize payment code given a payment code string
  PaymentCode.fromPaymentCode(
    this._paymentCodeString, {
    required this.networkType,
  }) {
    final parsed = _parse();
    _bip32Node = bip32.BIP32.fromPublicKey(
      parsed[0],
      parsed[1],
      _getBip32NetworkTypeFrom(networkType),
    );
  }

  PaymentCode.fromPayload(
    Uint8List payload, {
    required this.networkType,
  }) {
    if (payload.length != PAYLOAD_LEN) {
      throw Exception("Invalid payload size: ${payload.length}");
    }

    if (payload.first != 1) {
      throw Exception("Unsupported payment code version: ${payload.first}");
    }

    final publicKey = Uint8List(PUBLIC_KEY_Y_LEN + PUBLIC_KEY_X_LEN);
    final chainCode = Uint8List(CHAIN_LEN);

    Util.copyBytes(payload, PUBLIC_KEY_Y_OFFSET, publicKey, 0,
        PUBLIC_KEY_Y_LEN + PUBLIC_KEY_X_LEN);
    Util.copyBytes(payload, CHAIN_OFFSET, chainCode, 0, CHAIN_LEN);

    _bip32Node = bip32.BIP32.fromPublicKey(
      publicKey,
      chainCode,
      _getBip32NetworkTypeFrom(networkType),
    );

    // Always initialize V1 first -- _makeSamouraiPaymentCode() and
    // _makeTaprootPaymentCode() call getPayload() which needs
    // _paymentCodeString to already be set.
    _paymentCodeString = _makeV1();

    final bool isSamouraiTaproot = Util.isBitSet(
      payload[SAMOURAI_FEATURE_BYTE],
      SAMOURAI_TAPROOT_BIT,
    );
    final bool isSamouraiSegwit = Util.isBitSet(
      payload[SAMOURAI_FEATURE_BYTE],
      SAMOURAI_SEGWIT_BIT,
    );

    if (isSamouraiTaproot) {
      _paymentCodeString = _makeTaprootPaymentCode();
    } else if (isSamouraiSegwit) {
      _paymentCodeString = _makeSamouraiPaymentCode();
    }
  }

  // initialize payment code given a bip32 object
  PaymentCode.fromBip32Node(
    bip32.BIP32 bip32Node, {
    required this.networkType,
    required bool shouldSetSegwitBit,
    bool shouldSetTaprootBit = false,
  }) {
    if (bip32Node.network.wif != networkType.wif ||
        bip32Node.network.bip32.public != networkType.bip32.public ||
        bip32Node.network.bip32.private != networkType.bip32.private) {
      throw Exception(
          "BIP32 network info does not match provided networkType info");
    }
    _bip32Node = bip32Node;
    _paymentCodeString = _makeV1();

    if (shouldSetTaprootBit) {
      _paymentCodeString = _makeTaprootPaymentCode();
    } else if (shouldSetSegwitBit) {
      _paymentCodeString = _makeSamouraiPaymentCode();
    }
  }

  // returns the P2PKH address at index 0
  String notificationAddressP2PKH() {
    final publicKey = derivePublicKey(0);
    final pkHash = coin.hash160(publicKey);
    final chain = coin.Chain(
      wifPrefix: networkType.wif,
      p2pkhPrefix: networkType.pubKeyHash,
      p2shPrefix: networkType.scriptHash,
      bech32Hrp: networkType.bech32,
      name: 'bip47',
      bip44CoinType: 0,
      privHDPrefix: networkType.bip32.private,
      pubHDPrefix: networkType.bip32.public,
    );
    return coin.P2pkhAddr(pkHash).encode(chain);
  }

  /// get the notification address pub key
  Uint8List notificationPublicKey() {
    return derivePublicKey(0);
  }

  /// derive child pub key at the given [index] using the payment code's bip32
  /// object
  Uint8List derivePublicKey(int index) {
    return _bip32Node.derive(index).publicKey;
  }

  Uint8List getPayload() {
    Uint8List pcBytes = _paymentCodeString.fromBase58Check;

    Uint8List payload = Uint8List(PAYLOAD_LEN);
    Util.copyBytes(pcBytes, 1, payload, 0, payload.length);

    return payload;
  }

  int getType() => getPayload().first;

  bool isSegWitEnabled() => Util.isBitSet(
        getPayload()[SAMOURAI_FEATURE_BYTE],
        SAMOURAI_SEGWIT_BIT,
      );

  bool isTaprootEnabled() => Util.isBitSet(
        getPayload()[SAMOURAI_FEATURE_BYTE],
        SAMOURAI_TAPROOT_BIT,
      );

  Uint8List getPubKey() => _bip32Node.publicKey;

  Uint8List getChain() => _bip32Node.chainCode;

  @override
  String toString() => _paymentCodeString;

  /// generate mask to blind payment code
  static Uint8List getMask(Uint8List sPoint, Uint8List oPoint) {
    final hmac = HMac(SHA512Digest(), 128);
    hmac.init(KeyParameter(oPoint));
    return hmac.process(sPoint);
  }

  /// blind the payment code for inclusion in OP_RETURN script
  static Uint8List blind({
    required Uint8List payload,
    required Uint8List mask,
    required bool unBlind,
  }) {
    Uint8List ret = Uint8List(PAYLOAD_LEN);
    Uint8List pubkey = Uint8List(PUBLIC_KEY_X_LEN);
    Uint8List chain = Uint8List(CHAIN_LEN);
    Uint8List buf0 = Uint8List(PUBLIC_KEY_X_LEN);
    Uint8List buf1 = Uint8List(CHAIN_LEN);

    Util.copyBytes(payload, 0, ret, 0, PAYLOAD_LEN);

    Util.copyBytes(payload, PUBLIC_KEY_X_OFFSET, pubkey, 0, PUBLIC_KEY_X_LEN);
    Util.copyBytes(payload, CHAIN_OFFSET, chain, 0, CHAIN_LEN);
    Util.copyBytes(mask, 0, buf0, 0, PUBLIC_KEY_X_LEN);
    Util.copyBytes(mask, PUBLIC_KEY_X_LEN, buf1, 0, CHAIN_LEN);

    // xor first 32 bytes
    final x = Util.xor(pubkey, buf0);
    // xor last 32 bytes
    final c = Util.xor(chain, buf1);

    if (unBlind) {
      // If the updated x value is a member of the secp256k1 group, the payment
      // code is valid. Otherwise the payment code should be ignored.
      if (!x.toBigInt.isScalarGroupMemberOf(PaymentAddress.curveParams)) {
        throw Exception(
            "Updated x value is not a member of the secp256k1 group");
      }
    }

    Util.copyBytes(x, 0, ret, PUBLIC_KEY_X_OFFSET, PUBLIC_KEY_X_LEN);
    Util.copyBytes(c, 0, ret, CHAIN_OFFSET, CHAIN_LEN);

    return ret;
  }

  bip32.NetworkType _getBip32NetworkTypeFrom(
    NetworkType networkType,
  ) {
    return bip32.NetworkType(
      wif: networkType.wif,
      bip32: bip32.Bip32Type(
        public: networkType.bip32.public,
        private: networkType.bip32.private,
      ),
    );
  }

  // parse pub key and chaincode from payment code
  List<Uint8List> _parse() {
    Uint8List pcBytes = _paymentCodeString.fromBase58Check;

    if (pcBytes[0] != 0x47) {
      throw Exception("invalid payment code version");
    }

    Uint8List chain = Uint8List(CHAIN_LEN);
    Uint8List pub = Uint8List(PUBLIC_KEY_X_LEN + PUBLIC_KEY_Y_LEN);

    Util.copyBytes(pcBytes, 3, pub, 0, pub.length);
    Util.copyBytes(pcBytes, 3 + pub.length, chain, 0, chain.length);

    return [pub, chain];
  }

  // generate v1 payment code from the chaincode and pub key
  String _makeV1() {
    // validate pubkey length
    if (_bip32Node.publicKey.length != PUBLIC_KEY_X_LEN + PUBLIC_KEY_Y_LEN) {
      throw Exception(
          "Invalid public key length: ${_bip32Node.publicKey.length}");
    }

    // validate chaincode length
    if (_bip32Node.chainCode.length != CHAIN_LEN) {
      throw Exception(
          "Invalid chain code length: ${_bip32Node.chainCode.length}");
    }

    Uint8List payload = Uint8List(PAYLOAD_LEN);
    Uint8List paymentCode = Uint8List(PAYLOAD_LEN + 1);

    for (int i = 0; i < payload.length; i++) {
      payload[i] = 0x00;
    }

    // byte 0: type. required value: 0x01
    payload[0] = 0x01;
    // byte 1: features bit field. All bits must be zero except where specified elsewhere in this specification
    //      bit 0: Bitmessage notification
    //      bits 1-7: reserved
    payload[1] = 0x00;

    // replace sign & x code (33 bytes)
    Util.copyBytes(_bip32Node.publicKey, 0, payload, PUBLIC_KEY_Y_OFFSET,
        PUBLIC_KEY_X_LEN + PUBLIC_KEY_Y_LEN);
    // replace chain code (32 bytes)
    Util.copyBytes(_bip32Node.chainCode, 0, payload, CHAIN_OFFSET, CHAIN_LEN);

    // add version byte
    paymentCode[0] = 0x47;
    Util.copyBytes(payload, 0, paymentCode, 1, PAYLOAD_LEN);

    return paymentCode.toBase58Check;
  }

  String _makeSamouraiPaymentCode() {
    final payload = getPayload();
    // set bit0 = 1 in 'Samourai byte' for segwit. Can send/receive P2PKH, P2SH-P2WPKH, P2WPKH (bech32)
    payload[SAMOURAI_FEATURE_BYTE] =
        Util.setBit(payload[SAMOURAI_FEATURE_BYTE], SAMOURAI_SEGWIT_BIT);
    Uint8List paymentCode = Uint8List(PAYLOAD_LEN + 1);
    // add version byte
    paymentCode[0] = 0x47;
    Util.copyBytes(payload, 0, paymentCode, 1, PAYLOAD_LEN);

    // append checksum
    return paymentCode.toBase58Check;
  }

  String _makeTaprootPaymentCode() {
    final payload = getPayload();
    // Set both taproot (bit 1) and segwit (bit 0) -- taproot implies segwit
    payload[SAMOURAI_FEATURE_BYTE] =
        Util.setBit(payload[SAMOURAI_FEATURE_BYTE], SAMOURAI_SEGWIT_BIT);
    payload[SAMOURAI_FEATURE_BYTE] =
        Util.setBit(payload[SAMOURAI_FEATURE_BYTE], SAMOURAI_TAPROOT_BIT);
    Uint8List paymentCode = Uint8List(PAYLOAD_LEN + 1);
    paymentCode[0] = 0x47;
    Util.copyBytes(payload, 0, paymentCode, 1, PAYLOAD_LEN);
    return paymentCode.toBase58Check;
  }

  /// Use at own risk. Not fully tested
  bool isValid() {
    try {
      Uint8List pcodeBytes = _paymentCodeString.fromBase58Check;

      if (pcodeBytes[0] != 0x47) {
        throw Exception("invalid version: $_paymentCodeString");
      } else {
        int firstByte = pcodeBytes[3];
        if (firstByte == 0x02 || firstByte == 0x03) {
          return true;
        } else {
          return false;
        }
      }
    } catch (e) {
      return false;
    }
  }
}
