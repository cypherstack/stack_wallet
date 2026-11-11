import 'dart:typed_data';
import 'dart:io';

import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/models/coinlib/p2sh_p2wpkh_input.dart';
import 'package:stackwallet/models/input.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/utilities/extensions/extensions.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/litecoin_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/electrumx_interface.dart';

import '../../support/isar_test_utils.dart';

class _LitecoinWallet extends LitecoinWallet {
  _LitecoinWallet() : super(CryptoCurrencyNetwork.main);
  @override
  String get walletId => 'bip49';
  @override
  bool get flagOptInRBF => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(coinlib.loadCoinlib);

  late coinlib.Transaction unsigned;
  late coinlib.ECPrivateKey key;
  late P2shP2wpkhInput input;

  setUp(() {
    unsigned = coinlib.Transaction(
      version: 1,
      locktime: 1170,
      inputs: [
        coinlib.RawInput(
          prevOut: coinlib.OutPoint(
            ('db6b1b20aa0fd7b23880be2ecbd4a981'
                    '30974cf4748fb66092ac4d3ceb1a5477')
                .toUint8ListFromHex,
            1,
          ),
          scriptSig: Uint8List(0),
          sequence: 0xfffffffe,
        ),
      ],
      outputs: [
        coinlib.Output.fromScriptBytes(
          BigInt.from(199996600),
          '76a914a457b684d7f0d539a46a45bbc043f35b59d0d96388ac'
              .toUint8ListFromHex,
        ),
        coinlib.Output.fromScriptBytes(
          BigInt.from(800000000),
          '76a914fd270b1ee6abcaea97fea7ad0402e8bd8ad6d77c88ac'
              .toUint8ListFromHex,
        ),
      ],
    );
    key = coinlib.ECPrivateKey.fromHex(
      'eb696a065ef48a2192da5b28b694f87544b30fae8327c4510137a922f32c'
      '6dcf',
    );
    input = P2shP2wpkhInput(
      prevOut: unsigned.inputs.single.prevOut,
      publicKey: key.pubkey,
      sequence: unsigned.inputs.single.sequence,
    );
  });

  String nestedAddress(ElectrumXInterface wallet) =>
      coinlib.P2SHAddress.fromRedeemScript(
        coinlib.P2WPKH.fromPublicKey(key.pubkey).script,
        version: wallet.cryptoCurrency.networkParams.p2shPrefix,
      ).toString();

  coinlib.Transaction sign(coinlib.Input input) => coinlib.Transaction(
    version: unsigned.version,
    locktime: unsigned.locktime,
    inputs: [input],
    outputs: unsigned.outputs,
  ).signLegacyWitness(inputN: 0, key: key, value: BigInt.from(1000000000));

  test('matches the BIP143 P2SH-P2WPKH signed transaction', () {
    final signed = sign(input);
    final signature = (signed.inputs.single as P2shP2wpkhInput).insig!;
    expect(
      signature.signature.verify(
        key.pubkey,
        ('64f3b0f4dd2bb3aa1ce8566d220cc74d'
                'da9df97d8490cc81d89d735c92e59fb6')
            .toUint8ListFromHex,
      ),
      isTrue,
    );
    final referenceInput = input.addSignature(
      coinlib.ECDSAInputSignature.fromBytes(
        ('3044022047ac8e878352d3ebbde1c94ce3a10d057c24175747116f8288e5'
                'd794d'
                '12d482f0220217f36a485cae903c713331d877c1f64677e3622ad4010726'
                '870'
                '540656fe9dcb01')
            .toUint8ListFromHex,
      ),
    );
    final reference = coinlib.Transaction(
      version: unsigned.version,
      locktime: unsigned.locktime,
      inputs: [referenceInput],
      outputs: unsigned.outputs,
    );
    expect(
      reference.toHex(),
      '01000000000101db6b1b20aa0fd7b23880be2ecbd4a98130974cf4748fb6'
      '6092'
      'ac4d3ceb1a5477010000001716001479091972186c449eb1ded22b78e40d'
      '009b'
      'df0089feffffff02b8b4eb0b000000001976a914a457b684d7f0d539a46a'
      '45bb'
      'c043f35b59d0d96388ac0008af2f000000001976a914fd270b1ee6abcaea'
      '97fe'
      'a7ad0402e8bd8ad6d77c88ac02473044022047ac8e878352d3ebbde1c94c'
      'e3a1'
      '0d057c24175747116f8288e5d794d12d482f0220217f36a485cae903c713'
      '331d'
      '877c1f64677e3622ad4010726870540656fe9dcb012103ad1d8e89212f0b'
      '92c7'
      '4d23bb710c00662ad1470198ac48c43f7d6f93a2a2687392040000',
    );
    expect(signed.inputs.single.complete, isTrue);
  });

  test('retains the redeem script when invalidated and signed again', () {
    final signed = sign(input).inputs.single as P2shP2wpkhInput;
    final cleared = signed.filterSignatures((_) => false);
    expect(cleared.complete, isFalse);
    expect(cleared.scriptSig, input.scriptSig);
    expect(cleared.sequence, input.sequence);
    expect(sign(cleared).toHex(), sign(input).toHex());
  });

  test('includes the redeem script in transaction size and fee selection', () {
    final native = coinlib.P2WPKHInput(
      prevOut: input.prevOut,
      publicKey: key.pubkey,
      sequence: input.sequence,
    );
    final signed = sign(input).inputs.single as P2shP2wpkhInput;
    final actualSize =
        signed.toBytes().length +
        1 +
        signed.witness.fold<int>(0, (size, item) => size + 1 + item.length);
    expect(input.signedSize, greaterThanOrEqualTo(actualSize));
    expect(sign(input).vSize(), sign(native).vSize() + 23);
    coinlib.CoinSelection select(coinlib.Input candidate) =>
        coinlib.CoinSelection.optimal(
          candidates: [
            coinlib.InputCandidate(
              input: candidate,
              value: BigInt.from(2000000000),
            ),
          ],
          recipients: unsigned.outputs,
          changeProgram: coinlib.P2WPKH.fromPublicKey(key.pubkey),
          feePerKb: BigInt.from(1000),
          minFee: BigInt.zero,
          minChange: BigInt.from(546),
        );
    expect(
      select(input).fee,
      select(native).fee + BigInt.from(input.signedSize - native.signedSize!),
    );
  });

  for (final wallet in <ElectrumXInterface>[
    BitcoinWallet(CryptoCurrencyNetwork.main),
    LitecoinWallet(CryptoCurrencyNetwork.main),
  ]) {
    test('${wallet.cryptoCurrency.ticker} converts and signs BIP49 inputs', () {
      final standard = StandardInput(
        UTXO(
          walletId: 'test',
          txid: Uint8List.fromList(input.prevOut.hash.reversed.toList()).toHex,
          vout: input.prevOut.n,
          value: 1000000000,
          address: nestedAddress(wallet),
          name: '',
          isBlocked: false,
          blockedReason: null,
          isCoinbase: false,
          blockHash: null,
          blockHeight: null,
          blockTime: null,
        ),
        derivePathType: DerivePathType.bip49,
        key: coinlib.HDPrivateKey(
          privateKey: key,
          chaincode: Uint8List(32),
          depth: 0,
          index: 0,
          parentFingerprint: 0,
        ),
      );
      final converted = wallet.standardInputToCoinlibInput(
        standard,
        sequence: input.sequence,
      );
      expect(converted, isA<P2shP2wpkhInput>());
      expect(sign(converted).toHex(), sign(input).toHex());
    });
  }
  test(
    'restores mixed MWEB funding inputs without losing transaction data',
    () {
      final nativeInput = coinlib.P2WPKHInput(
        prevOut: coinlib.OutPoint(input.prevOut.hash, 2),
        publicKey: key.pubkey,
        sequence: 0xfffffffd,
      );
      final original =
          coinlib.Transaction(
                version: 2,
                inputs: [input, nativeInput],
                outputs: unsigned.outputs,
                locktime: 1170,
                mwebBytes: Uint8List.fromList([0, 3, 1]),
              )
              .signLegacyWitness(
                inputN: 0,
                key: key,
                value: BigInt.from(1000000000),
              )
              .signLegacyWitness(
                inputN: 1,
                key: key,
                value: BigInt.from(1000000000),
              );
      final parsed = coinlib.Transaction.fromBytes(original.toBytes());
      expect(parsed.inputs.first, isNot(isA<coinlib.WitnessInput>()));
      final funding = [
        for (var i = 0; i < original.inputs.length; i++)
          StandardInput(
            UTXO(
              walletId: 'mweb',
              txid: Uint8List.fromList(input.prevOut.hash.reversed.toList())
                  .toHex,
              vout: i + 1,
              value: 1000000000,
              address: i == 0 ? nestedAddress(_LitecoinWallet()) : null,
              name: '',
              isBlocked: false,
              blockedReason: null,
              isCoinbase: false,
              blockHash: null,
              blockHeight: null,
              blockTime: null,
            ),
            derivePathType: i == 0
                ? DerivePathType.bip49
                : DerivePathType.bip84,
            key: coinlib.HDPrivateKey(
              privateKey: key,
              chaincode: Uint8List(32),
              depth: 0,
              index: 0,
              parentFingerprint: 0,
            ),
          ),
      ];
      final wallet = _LitecoinWallet();
      final restored = wallet.restoreMwebPegInInputs(parsed, funding);
      expect(restored.inputs.first, isA<P2shP2wpkhInput>());
      expect(restored.inputs.first.complete, isFalse);
      expect(restored.inputs.last, same(parsed.inputs.last));
      expect(restored.inputs.map((input) => input.sequence), [
        0xfffffffe,
        0xfffffffd,
      ]);
      expect(
        restored.outputs.map((output) => output.toHex()),
        original.outputs.map((output) => output.toHex()),
      );
      expect(restored.mwebBytes, original.mwebBytes);
      expect(restored.locktime, original.locktime);
      expect(
        restored
            .signLegacyWitness(
              inputN: 0,
              key: key,
              value: BigInt.from(1000000000),
            )
            .toHex(),
        original.toHex(),
      );
      expect(
        () => wallet.restoreMwebPegInInputs(parsed, funding.reversed.toList()),
        throwsStateError,
      );
    },
  );

  test('builds a signed Litecoin payment from a wrapped SegWit UTXO', () async {
    await initializeTestIsar();
    final directory = await Directory.systemTemp.createTemp('bip49-payment-');
    final isar = await Isar.open(
      [AddressSchema, TransactionSchema],
      directory: directory.path,
      name: 'bip49-payment',
      inspector: false,
    );
    addTearDown(() async {
      await isar.close();
      await directory.delete(recursive: true);
    });
    await MainDB.instance.initMainDB(mock: isar);
    final wallet = _LitecoinWallet()..mainDB = MainDB.instance;
    final source = coinlib.P2SHAddress.fromRedeemScript(
      coinlib.P2WPKH.fromPublicKey(key.pubkey).script,
      version: wallet.cryptoCurrency.networkParams.p2shPrefix,
    ).toString();
    final destination = coinlib.P2WPKHAddress.fromPublicKey(
      key.pubkey,
      hrp: wallet.cryptoCurrency.networkParams.bech32Hrp,
    ).toString();
    final standard = StandardInput(
      UTXO(
        walletId: wallet.walletId,
        txid: Uint8List.fromList(input.prevOut.hash.reversed.toList()).toHex,
        vout: input.prevOut.n,
        value: 1000000000,
        address: source,
        name: '',
        isBlocked: false,
        blockedReason: null,
        isCoinbase: false,
        blockHash: null,
        blockHeight: null,
        blockTime: null,
      ),
      derivePathType: DerivePathType.bip49,
      key: coinlib.HDPrivateKey(
        privateKey: key,
        chaincode: Uint8List(32),
        depth: 0,
        index: 0,
        parentFingerprint: 0,
      ),
    );
    final payment = await wallet.buildTransaction(
      inputsWithKeys: [standard],
      txData: TxData(
        recipients: [
          TxRecipient(
            address: destination,
            amount: Amount(rawValue: BigInt.from(999990000), fractionDigits: 8),
            isChange: false,
            addressType: AddressType.p2wpkh,
          ),
        ],
      ),
    );
    final expected = coinlib.Transaction(
      version: wallet.cryptoCurrency.transactionVersion,
      inputs: [input],
      outputs: [
        coinlib.Output.fromAddress(
          BigInt.from(999990000),
          coinlib.Address.fromString(
            destination,
            wallet.cryptoCurrency.networkParams,
          ),
        ),
      ],
    ).signLegacyWitness(inputN: 0, key: key, value: BigInt.from(1000000000));
    expect(payment.raw, expected.toHex());
    expect(payment.vSize, expected.vSize());
    expect(payment.tempTx!.inputs.single.scriptSigHex, input.scriptSig.toHex);
  });
}
