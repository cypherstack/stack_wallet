import 'dart:typed_data';

import 'package:fusiondart/src/encrypt.dart';
import 'package:fusiondart/src/exceptions.dart';
import 'package:fusiondart/src/extensions/on_string.dart';
import 'package:fusiondart/src/extensions/on_uint8list.dart';
import 'package:test/test.dart';

// based on https://github.com/Electron-Cash/Electron-Cash/blob/master/electroncash_plugins/fusion/tests/test_encrypt.py

void main() {
  late final Uint8List aPriv;
  late final Uint8List aPub;
  late final Uint8List msg12;

  setUp(() {
    aPriv = '0000000000000000000000000000000000000000000000000000000000000005'
        .toUint8ListFromHex;
    aPub = '022f8bde4d1a07209355b4a7250a5c5128e88b84bddc619ab7cba8d569b240efe4'
        .toUint8ListFromHex;
    msg12 = 'test message'.toUint8ListFromUtf8;
  });

  test('encrypt.dart tests', () async {
    // ============== short message ============================================

    expect(msg12.length, 12);

    Uint8List e12 = await encrypt(msg12, aPub);
    expect(e12.length, 65);

    e12 = await encrypt(msg12, aPub, padToLength: 16);
    expect(e12.length, 65);

    final result = await decrypt(e12, aPriv);

    final k = result.symmetricKey;
    Uint8List d12 = result.decrypted;

    expect(d12.equals(msg12), true);

    d12 = await decryptWithSymmkey(e12, k);
    expect(d12.equals(msg12), true);

    // ============== tweak the nonce point's oddness bit ======================

    Uint8List e12Bad = Uint8List.fromList(e12); // create copy to modify
    e12Bad[0] = e12Bad[0] ^ 1;

    Object? e;
    try {
      await decrypt(e12Bad, aPriv);
    } catch (err) {
      e = err;
    }
    expect(e, isA<DecryptionFailed>());

    d12 = await decryptWithSymmkey(e12Bad, k);
    expect(d12.equals(msg12), true);

    // ============== tweak the hmac ===========================================

    e12Bad = Uint8List.fromList(e12); // create copy to modify
    e12Bad[e12Bad.length - 1] = e12Bad[e12Bad.length - 1] ^ 1;

    e = null;
    try {
      await decrypt(e12Bad, aPriv);
    } catch (err) {
      e = err;
    }
    expect(e, isA<DecryptionFailed>());

    e = null;
    try {
      await decryptWithSymmkey(e12Bad, k);
    } catch (err) {
      e = err;
    }
    expect(e, isA<DecryptionFailed>());

    // ============== tweak the message ========================================

    e12Bad = Uint8List.fromList(e12); // create copy to modify
    e12Bad[35] = e12Bad[35] ^ 1;

    e = null;
    try {
      await decrypt(e12Bad, aPriv);
    } catch (err) {
      e = err;
    }
    expect(e, isA<DecryptionFailed>());

    e = null;
    try {
      await decryptWithSymmkey(e12Bad, k);
    } catch (err) {
      e = err;
    }
    expect(e, isA<DecryptionFailed>());

    // ============== drop a byte ==============================================

    e12Bad = Uint8List.fromList(e12); // create copy to modify
    e12Bad = e12Bad.sublist(0, e12Bad.length - 1);
    e = null;
    try {
      await decrypt(e12Bad, aPriv);
    } catch (err) {
      e = err;
    }
    expect(e, isA<DecryptionFailed>());

    e = null;
    try {
      await decryptWithSymmkey(e12Bad, k);
    } catch (err) {
      e = err;
    }
    expect(e, isA<DecryptionFailed>());

    // =========================================================================

    final msg13 = Uint8List.fromList([
      ...msg12,
      ..."!".toUint8ListFromUtf8,
    ]);

    Uint8List e13 = await encrypt(msg13, aPub);
    expect(e13.length, 81); // need another block

    e = null;
    try {
      await encrypt(msg13, aPub, padToLength: 16);
    } catch (err) {
      e = err;
    }
    expect(e, isA<ArgumentError>());

    e13 = await encrypt(msg13, aPub, padToLength: 32);
    expect(e13.length, 81);

    e = null;
    try {
      await decrypt(e13, aPriv);
    } catch (err) {
      e = err;
    }
    expect(e, null);

    // =========================================================================

    final msgBig = ("a" * 1234).toUint8ListFromUtf8;

    final eBig = await encrypt(msgBig, aPub);
    expect(eBig.length, 33 + (1234 + 4 + 10) + 16);

    final result2 = await decrypt(eBig, aPriv);
    expect(result2.decrypted.equals(msgBig), true);

    // =========================================================================

    final enc = await encrypt("".toUint8ListFromUtf8, aPub);
    expect(enc.length, 65);

    final enc2 = await encrypt("".toUint8ListFromUtf8, aPub, padToLength: 1248);
    expect(enc2.length, 1297);

    e = null;
    try {
      await encrypt("".toUint8ListFromUtf8, aPub, padToLength: 0);
    } catch (err) {
      e = err;
    }
    expect(e, isA<ArgumentError>());
  });
}
