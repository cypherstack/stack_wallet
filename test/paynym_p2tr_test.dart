import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip47/bip47.dart';
import 'package:bitcoindart/bitcoindart.dart' as bitcoindart;
import 'package:stackwallet/models/paynym/paynym_account_lite.dart';
import 'package:test/test.dart';

void main() {
  const mnemonic =
      'response seminar brave million suit skate inhale proud weapon daring champion';

  final networkType = bip32.NetworkType(
    wif: bitcoindart.bitcoin.wif,
    bip32: bip32.Bip32Type(
      public: bitcoindart.bitcoin.bip32.public,
      private: bitcoindart.bitcoin.bip32.private,
    ),
  );

  late String v1PaymentCodeString;
  late String taprootPaymentCodeString;

  setUpAll(() {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed, networkType);
    final paymentCodeNode = root.derivePath("m/47'/0'/0'");

    // Build a standard v1 payment code (no taproot, no segwit).
    final v1Code = PaymentCode.fromBip32Node(
      paymentCodeNode,
      networkType: bitcoindart.bitcoin,
      shouldSetSegwitBit: false,
    );
    v1PaymentCodeString = v1Code.toString();

    // Build a taproot-enabled payment code.
    final taprootCode = PaymentCode.fromBip32Node(
      paymentCodeNode,
      networkType: bitcoindart.bitcoin,
      shouldSetSegwitBit: true,
      shouldSetTaprootBit: true,
    );
    taprootPaymentCodeString = taprootCode.toString();
  });

  group('PaynymAccountLite taproot inference', () {
    test('inferTaproot returns true for taproot-enabled payment code', () {
      final result = PaynymAccountLite.inferTaproot(taprootPaymentCodeString);
      expect(result, isTrue);
    });

    test('inferTaproot returns false for standard v1 payment code', () {
      final result = PaynymAccountLite.inferTaproot(v1PaymentCodeString);
      expect(result, isFalse);
    });

    test('inferTaproot returns false for invalid payment code string', () {
      final result = PaynymAccountLite.inferTaproot('not-a-payment-code');
      expect(result, isFalse);
    });
  });

  group('PaynymAccountLite.fromMap taproot inference', () {
    test('fromMap infers taproot=true when taproot key is absent '
        'but payment code has taproot bit set', () {
      final map = <String, dynamic>{
        'nymId': 'test-id',
        'nymName': 'test-name',
        'code': taprootPaymentCodeString,
        'segwit': true,
        // No 'taproot' key — should be inferred from the code.
      };

      final account = PaynymAccountLite.fromMap(map);
      expect(account.taproot, isTrue);
    });

    test('fromMap infers taproot=false when taproot key is absent '
        'and payment code does not have taproot bit set', () {
      final map = <String, dynamic>{
        'nymId': 'test-id',
        'nymName': 'test-name',
        'code': v1PaymentCodeString,
        'segwit': false,
        // No 'taproot' key — should be inferred from the code.
      };

      final account = PaynymAccountLite.fromMap(map);
      expect(account.taproot, isFalse);
    });

    test('fromMap uses explicit taproot=true from map when provided', () {
      final map = <String, dynamic>{
        'nymId': 'test-id',
        'nymName': 'test-name',
        'code': v1PaymentCodeString,
        'segwit': false,
        'taproot': true,
      };

      final account = PaynymAccountLite.fromMap(map);
      expect(account.taproot, isTrue);
    });

    test('fromMap uses explicit taproot=false from map when provided', () {
      final map = <String, dynamic>{
        'nymId': 'test-id',
        'nymName': 'test-name',
        'code': taprootPaymentCodeString,
        'segwit': true,
        'taproot': false,
      };

      final account = PaynymAccountLite.fromMap(map);
      expect(account.taproot, isFalse);
    });
  });
}
