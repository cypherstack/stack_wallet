import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/ecc/api.dart';

import 'fusion.pb.dart';
import 'protocol.dart';

class Address {
  String addr = "";

  Address(
      {required this.addr}); // Constructor updated to accept addr as a named parameter

  Address._create({required this.addr});

  static Address fromScriptPubKey(List<int> scriptPubKey) {
    // This is just a placeholder code
    String addr = ""; // This should be computed from the scriptPubKey
    return Address(addr: addr);
  }

  // Public constructor for testing
  static Address fromString(String address) {
    return Address._create(addr: address);
  }

  List<int> toScript() {
    return [];
  }
}

class Tuple<T1, T2> {
  T1 item1;
  T2 item2;

  Tuple(this.item1, this.item2);

  set setItem1(T1 value) {
    this.item1 = value;
  }

  set setItem2(T2 value) {
    this.item2 = value;
  }
}

class Util {
  static Uint8List hexToBytes(String hex) {
    var result = new Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      var byte = int.parse(hex.substring(i, i + 2), radix: 16);
      result[i ~/ 2] = byte;
    }
    return result;
  }

  static void checkInputElectrumX(InputComponent inputComponent) {
    //  Implementation needed here
    //
  }

  static int randPosition(Uint8List seed, int numPositions, int counter) {
    // counter to bytes
    var counterBytes = Uint8List(4);
    var counterByteData = ByteData.sublistView(counterBytes);
    counterByteData.setInt32(0, counter, Endian.big);

    // hash the seed and counter
    var digest = crypto.sha256.convert([...seed, ...counterBytes]);

    // take the first 8 bytes
    var first8Bytes = digest.bytes.take(8).toList();
    var int64 = ByteData.sublistView(Uint8List.fromList(first8Bytes))
        .getUint64(0, Endian.big);

    // perform the modulo operation
    return ((int64 * numPositions) >> 64).toInt();
  }

  static List<String> pubkeysFromPrivkey(String privkey) {
    // This is a placeholder implementation.
    return ['public_key1_dummy', 'public_key2_dummy'];
  }

  static int dustLimit(int length) {
    // This is a dummy implementation.
    return 500;
  }

  static Address getAddressFromOutputScript(Uint8List scriptpubkey) {
    // Dummy implementation...

    // Throw exception if this is not a standard P2PKH address!

    return Address.fromString('dummy_address');
  }

  static bool schnorrVerify(
      ECPoint pubkey, List<int> signature, Uint8List messageHash) {
    // Implementation needed: actual Schnorr signature verification
    return true;
  }

  static String formatSatoshis(sats, {int numZeros = 8}) {
    // To implement
    return "";
  }

  static void updateWalletLabel(String txid, String label) {
    // Call the wallet layer.
  }

  static Uint8List getRandomBytes(int length) {
    final rand = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = rand.nextInt(256);
    }
    return bytes;
  }

  static List<List<T>> zip<T>(List<T> list1, List<T> list2) {
    int length = min(list1.length, list2.length);
    return List<List<T>>.generate(length, (i) => [list1[i], list2[i]]);
  }

  static List<int> calcInitialHash(int tier, Uint8List covertDomainB,
      int covertPort, bool covertSsl, double beginTime) {
    // Converting int to bytes in BigEndian order
    var tierBytes = ByteData(8)..setInt64(0, tier, Endian.big);
    var covertPortBytes = ByteData(4)..setInt32(0, covertPort, Endian.big);
    var beginTimeBytes = ByteData(8)
      ..setInt64(0, beginTime.toInt(), Endian.big);

    // Define constants
    const version = Protocol.VERSION;
    const cashFusionSession = "Cash Fusion Session";

    // Creating the list of bytes
    List<int> elements = [];
    elements.addAll(utf8.encode(cashFusionSession));
    elements.addAll(utf8.encode(version));
    elements.addAll(tierBytes.buffer.asInt8List());
    elements.addAll(covertDomainB);
    elements.addAll(covertPortBytes.buffer.asInt8List());
    elements.add(covertSsl ? 1 : 0);
    elements.addAll(beginTimeBytes.buffer.asInt8List());

    // Hashing the concatenated elements
    var digest = crypto.sha256.convert(elements);

    return digest.bytes;
  }

  static List<int> calcRoundHash(
      List<int> lastHash,
      List<int> roundPubkey,
      int roundTime,
      List<List<int>> allCommitments,
      List<List<int>> allComponents) {
    return listHash([
      utf8.encode('Cash Fusion Round'),
      lastHash,
      roundPubkey,
      bigIntToBytes(BigInt.from(roundTime)),
      listHash(allCommitments),
      listHash(allComponents),
    ]);
  }

  static List<int> listHash(Iterable<List<int>> iterable) {
    var bytes = <int>[];

    for (var x in iterable) {
      var length = ByteData(4)..setUint32(0, x.length, Endian.big);
      bytes.addAll(length.buffer.asUint8List());
      bytes.addAll(x);
    }
    return crypto.sha256.convert(bytes).bytes;
  }

  static Uint8List get_current_genesis_hash() {
    var GENESIS =
        "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f";
    var _lastGenesisHash = hexToBytes(GENESIS).reversed.toList();
    return Uint8List.fromList(_lastGenesisHash);
  }

  static List<Address> unreserve_change_address(Address addr) {
    //implement later based on wallet.
    return [];
  }

  static List<Address> reserve_change_addresses(int number_addresses) {
    //implement later based on wallet.
    return [];
  }

  static bool walletHasTransaction(String txid) {
    // implement later based on wallet.
    return true;
  }

  static Uint8List bigIntToBytes(BigInt bigInt) {
    return Uint8List.fromList(
        bigInt.toRadixString(16).padLeft(32, '0').codeUnits);
  }

  static Tuple<Uint8List, Uint8List> genKeypair() {
    var params = ECDomainParameters('secp256k1');
    var privKeyBigInt = _generatePrivateKey(params.n.bitLength);
    var pubKeyPoint = params.G * privKeyBigInt;

    if (pubKeyPoint == null) {
      throw Exception("Error generating public key.");
    }

    Uint8List privKey = bigIntToBytes(privKeyBigInt);
    Uint8List pubKey = pubKeyPoint.getEncoded(true);

    return Tuple(privKey, pubKey);
  }

// Generates a cryptographically secure private key
  static BigInt _generatePrivateKey(int bitLength) {
    final random = Random.secure();
    var bytes = bitLength ~/ 8; // floor division
    var remBit = bitLength % 8;

    // Generate random BigInt
    List<int> rnd = List<int>.generate(bytes, (_) => random.nextInt(256));
    var rndBit = random.nextInt(1 << remBit);
    rnd.add(rndBit);
    var privateKey = BigInt.parse(
        rnd.map((x) => x.toRadixString(16).padLeft(2, '0')).join(),
        radix: 16);

    return privateKey;
  }

  // Additional helper function to convert bytes to hex
  static String bytesToHex(Uint8List bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  static BigInt bytesToBigInt(Uint8List bytes) {
    String hexString = bytesToHex(bytes);
    return BigInt.parse(hexString, radix: 16);
  }

  static Uint8List sha256(Uint8List bytes) {
    crypto.Digest digest = crypto.sha256.convert(bytes);
    return Uint8List.fromList(digest.bytes);
  }

  static Uint8List tokenBytes([int nbytes = 32]) {
    final Random _random = Random.secure();

    return Uint8List.fromList(
        List<int>.generate(nbytes, (i) => _random.nextInt(256)));
  }

  static int componentFee(int size, int feerate) {
    // feerate in sat/kB
    // size and feerate should both be integer
    // fee is always rounded up
    return ((size * feerate) + 999) ~/ 1000;
  }

  static ECPoint ser_to_point(
      Uint8List serializedPoint, ECDomainParameters params) {
    var point = params.curve.decodePoint(serializedPoint);
    if (point == null) {
      throw FormatException('Point decoding failed');
    }
    return point;
  }

  static Uint8List point_to_ser(ECPoint point, bool compress) {
    return point.getEncoded(compress);
  }

  static BigInt secureRandomBigInt(int bitLength) {
    final random = Random.secure();
    final bytes = (bitLength + 7) ~/ 8; // ceil division
    final Uint8List randomBytes = Uint8List(bytes);

    for (int i = 0; i < bytes; i++) {
      randomBytes[i] = random.nextInt(256);
    }

    BigInt randomNumber = BigInt.parse(
        randomBytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join(),
        radix: 16);
    return randomNumber;
  }

  static ECPoint combinePubKeys(List<ECPoint> pubKeys) {
    if (pubKeys.isEmpty) throw ArgumentError('pubKeys cannot be empty');

    ECPoint combined = pubKeys.first.curve.infinity!;
    for (var pubKey in pubKeys) {
      combined = (combined + pubKey)!;
    }

    if (combined.isInfinity) {
      throw Exception('Combined point is at infinity');
    }

    return combined;
  }

  static bool isPointOnCurve(ECPoint point, ECCurve curve) {
    var x = point.x!.toBigInteger()!;
    var y = point.y!.toBigInteger()!;
    var a = curve.a!.toBigInteger()!;
    var b = curve.b!.toBigInteger()!;

    // Calculate the left and right sides of the equation
    var left = y * y;
    var right = (x * x * x) + (a * x) + b;

    // Check if the point is on the curve
    return left == right;
  }
} //  END OF CLASS
