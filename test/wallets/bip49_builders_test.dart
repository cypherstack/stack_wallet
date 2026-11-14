import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:namecoin/namecoin.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/exceptions/wallet/paynym_send_exception.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/utilities/extensions/extensions.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_hd_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/models/name_op_state.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/namecoin_wallet.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_hd_wallet.dart';

import '../support/isar_test_utils.dart';
import '../support/raw_tx_decoder.dart';

// Builder-level BIP49 coverage for the two transaction builders that do not
// go through ElectrumXInterface.buildTransaction: the PayNym notification
// builder and the Namecoin name-op builder. Keys come from the BIP49 test
// vector mnemonic. The Bitcoin UTXOs are the regtest coinbase outputs used in
// bip49_spend_test.dart, so the PayNym transaction can be checked with
// Bitcoin Core `testmempoolaccept` (set BIP49_PAYNYM_TX_OUT to write it).

const _mnemonic =
    'abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon abandon abandon about';
const _otherMnemonic =
    'legal winner thank year wave sausage worth useful legal winner thank '
    'yellow';

const _tipHeight = 105;
const _coinValue = 5000000000;

const _bip49Txid =
    'f59dacc2262f36faad6dbea34eb446a0a1d9a8afb25248cd806e3d991e223f11';
const _bip84Txid =
    '16956110c3bfbd545cbd647b6dbd04367a7aaae52807062cb304e816f1191584';
const _bip86Txid =
    '02e7b319c6e9e83380821b5793eb78bbbddefde6e63da2ac5470e035eccf3983';

// Recorded notification transaction; Bitcoin Core 31.1 accepted it on the
// regtest chain described in bip49_spend_test.dart.
const _expectedPaynymTxid =
    'f942e85f642a782717a3bf2640738d816a22aebde79327d4e83bf79570745e2f';
const _expectedPaynymWtxid =
    'f4e46823f808f4710f4663efb40628082f974bf6993e00a2449b350062d097ed';

mixin _TestKeys<T extends Bip39HDCurrency> on Bip39HDWallet<T> {
  String get mnemonic;
  late final Address change;

  @override
  Future<String> getMnemonic() async => mnemonic;

  @override
  Future<String> getMnemonicPassphrase() async => '';

  @override
  Future<int> get chainHeight async => _tipHeight;

  @override
  Future<void> checkChangeAddressForTransactions() async {}

  @override
  Future<Address?> getCurrentChangeAddress() async => change;
}

class _BtcWallet extends BitcoinWallet with _TestKeys {
  _BtcWallet(this.walletId, this.mnemonic) : super(CryptoCurrencyNetwork.test);

  @override
  final String walletId;
  @override
  final String mnemonic;

  @override
  WalletInfo get info => WalletInfo(
    walletId: walletId,
    name: walletId,
    mainAddressType: AddressType.p2wpkh,
    coinName: cryptoCurrency.identifier,
  );

  @override
  bool get flagOptInRBF => false;

  @override
  Future<int> fetchChainHeight({int retries = 1}) async => _tipHeight;
}

class _NmcWallet extends NamecoinWallet with _TestKeys {
  _NmcWallet() : super(CryptoCurrencyNetwork.main);

  @override
  String get walletId => 'bip49-nmc';
  @override
  String get mnemonic => _mnemonic;
}

Future<Address> _store(
  Bip39HDWallet wallet,
  DerivePathType type,
  int chain,
) async {
  final currency = wallet.cryptoCurrency;
  final path = currency.constructDerivePath(
    derivePathType: type,
    chain: chain,
    index: 0,
  );
  final key = (await wallet.getRootHDNode()).derivePath(path);
  final result = currency.getAddressForPublicKey(
    publicKey: key.publicKey,
    derivePathType: type,
  );
  final address = Address(
    walletId: wallet.walletId,
    value: result.address.toString(),
    publicKey: key.publicKey.data,
    derivationIndex: 0,
    derivationPath: DerivationPath()..value = path,
    type: result.addressType,
    subType: chain == 0 ? AddressSubType.receiving : AddressSubType.change,
  );
  await wallet.mainDB.isar.writeTxn(
    () => wallet.mainDB.isar.addresses.put(address),
  );
  return address;
}

UTXO _utxo(
  String walletId,
  String txid,
  Address address,
  int height, {
  int value = _coinValue,
}) => UTXO(
  walletId: walletId,
  txid: txid,
  vout: 0,
  value: value,
  address: address.value,
  name: '',
  isBlocked: false,
  blockedReason: null,
  isCoinbase: true,
  blockHash: 'regtest-$height',
  blockHeight: height,
  blockTime: height,
);

/// Checks the P2SH-P2WPKH input at [n]: redeem script push, [sig, pubkey]
/// witness, and a BIP143 signature over [value].
void _expectNestedInput(
  DecodedTx tx,
  int n,
  Address address,
  int value,
  coinlib.Network network,
) {
  final pub = Uint8List.fromList(address.publicKey);
  final pkHash = coinlib.hash160(pub);
  expect(tx.inputs[n].scriptSig.toHex, '160014${pkHash.toHex}');
  expect(
    coinlib.Address.fromString(
      address.value,
      network,
    ).program.script.compiled.toHex,
    'a914${coinlib.hash160(tx.inputs[n].scriptSig.sublist(1)).toHex}87',
  );
  final witness = tx.witnesses[n];
  expect(witness, hasLength(2));
  expect(witness[1].toHex, pub.toHex);

  final insig = coinlib.ECDSAInputSignature.fromBytes(witness[0]);
  expect(insig.hashType.all, isTrue);
  final unsigned = coinlib.Transaction.fromBytes(tx.bytes);
  bool verifies(int amount) => insig.signature.verify(
    coinlib.ECPublicKey(pub),
    coinlib.WitnessSignatureHasher(
      coinlib.LegacyWitnessSignDetailsWithScript(
        tx: unsigned,
        inputN: n,
        value: BigInt.from(amount),
        scriptCode: coinlib.P2PKH
            .fromPublicKey(coinlib.ECPublicKey(pub))
            .script,
      ),
    ).hash,
  );
  expect(verifies(value), isTrue);
  expect(verifies(value + 1), isFalse);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(coinlib.loadCoinlib);

  late Isar isar;
  late Directory directory;

  setUpAll(() async {
    await initializeTestIsar();
    directory = await Directory.systemTemp.createTemp('bip49-builders-');
    isar = await Isar.open(
      [AddressSchema, TransactionSchema, UTXOSchema],
      directory: directory.path,
      name: 'bip49-builders',
      inspector: false,
    );
    await MainDB.instance.initMainDB(mock: isar);
  });

  tearDownAll(() async {
    await isar.close();
    await directory.delete(recursive: true);
  });

  group('PayNym notification', () {
    late _BtcWallet wallet;
    late String target;
    late Address bip49;
    late Address bip84;
    late Address bip86;

    setUpAll(() async {
      wallet = _BtcWallet('bip49-paynym', _mnemonic)..mainDB = MainDB.instance;
      bip49 = await _store(wallet, DerivePathType.bip49, 0);
      bip84 = await _store(wallet, DerivePathType.bip84, 0);
      bip86 = await _store(wallet, DerivePathType.bip86, 0);
      wallet.change = await _store(wallet, DerivePathType.bip84, 1);
      final other = _BtcWallet('bip49-paynym-other', _otherMnemonic);
      target = (await other.getPaymentCode(isSegwit: false)).toString();
    });

    Future<TxData> prepare(List<UTXO> utxos, {int additional = 0}) =>
        wallet.prepareNotificationTx(
          selectedTxFeeRate: BigInt.from(2000),
          targetPaymentCodeString: target,
          additionalOutputs: additional,
          utxos: utxos,
        );

    test('refuses when only BIP49 or Taproot UTXOs are available', () async {
      final nested = _utxo(wallet.walletId, _bip49Txid, bip49, 1);
      final taproot = _utxo(wallet.walletId, _bip86Txid, bip86, 5);
      await expectLater(
        prepare([nested]),
        throwsA(
          isA<PaynymSendException>().having(
            (e) => e.message,
            'message',
            contains('Nested SegWit (BIP49)'),
          ),
        ),
      );
      await expectLater(
        prepare([taproot, nested]),
        throwsA(isA<PaynymSendException>()),
      );
    });

    test('designates a native SegWit input ahead of an older BIP49 input '
        'and signs the BIP49 input as nested SegWit', () async {
      final txData = await prepare([
        _utxo(wallet.walletId, _bip49Txid, bip49, 1),
        _utxo(wallet.walletId, _bip84Txid, bip84, 4),
      ], additional: 1);
      final tx = DecodedTx(txData.raw!.toUint8ListFromHex);

      expect(tx.inputs.map((i) => i.txid), [_bip84Txid, _bip49Txid]);
      // Designated input exposes the native SegWit key in its witness.
      expect(tx.inputs[0].scriptSig, isEmpty);
      expect(tx.witnesses[0], hasLength(2));
      expect(
        tx.witnesses[0][1].toHex,
        Uint8List.fromList(bip84.publicKey).toHex,
      );
      _expectNestedInput(
        tx,
        1,
        bip49,
        _coinValue,
        wallet.cryptoCurrency.networkParams,
      );

      // Notification output, OP_RETURN payload, change.
      expect(tx.outputs, hasLength(3));
      expect(tx.outputs[1].value, 0);
      expect(tx.outputs[1].script.first, 0x6a);
      expect(
        tx.outputs[2].script.toHex,
        coinlib.Address.fromString(
          wallet.change.value,
          wallet.cryptoCurrency.networkParams,
        ).program.script.compiled.toHex,
      );
      final fee =
          2 * _coinValue - tx.outputs.fold<int>(0, (t, o) => t + o.value);
      expect(txData.fee!.raw, BigInt.from(fee));
      expect(txData.vSize, tx.vSize);
      expect(tx.txid, _expectedPaynymTxid);
      expect(tx.wtxid, _expectedPaynymWtxid);

      final out = Platform.environment['BIP49_PAYNYM_TX_OUT'];
      if (out != null) {
        await File(out).writeAsString(
          jsonEncode({'paynym-bip84-designated-bip49-second': txData.raw}),
        );
      }
    });
  });

  group('Namecoin name op', () {
    test('builds and signs a NAME_NEW from a BIP49 input', () async {
      final wallet = _NmcWallet()..mainDB = MainDB.instance;
      final bip49 = await _store(wallet, DerivePathType.bip49, 0);
      final recipient = await _store(wallet, DerivePathType.bip84, 0);
      wallet.change = await _store(wallet, DerivePathType.bip84, 1);
      expect(bip49.value, startsWith('6'));

      const name = 'd/stackbip49test';
      final (nameScriptHex, saltHex, commitment) = scriptNameNew(
        name,
        Uint8List(32)..[31] = 1,
      );
      const value = 100000000;
      final utxo = _utxo(wallet.walletId, '11' * 32, bip49, 1, value: value);

      final txData = await wallet.coinSelectionName(
        txData: TxData(
          satsPerVByte: 2,
          feeRateAmount: BigInt.from(-1),
          opNameState: NameOpState(
            name: name,
            type: OpName.nameNew,
            saltHex: saltHex,
            commitment: commitment,
            value: '',
            nameScriptHex: nameScriptHex,
            outputPosition: -1,
          ),
          recipients: [
            TxRecipient(
              address: recipient.value,
              amount: Amount(
                rawValue: BigInt.from(kNameNewAmountSats),
                fractionDigits: 8,
              ),
              isChange: false,
              addressType: AddressType.p2wpkh,
            ),
          ],
        ),
        coinControl: true,
        utxos: [utxo],
      );

      final tx = DecodedTx(txData.raw!.toUint8ListFromHex);
      expect(tx.version, kNameTxVersion);
      expect(tx.inputs.single.txid, '11' * 32);
      _expectNestedInput(
        tx,
        0,
        bip49,
        value,
        wallet.cryptoCurrency.networkParams,
      );

      final network = wallet.cryptoCurrency.networkParams;
      final nameOutput = tx.outputs[txData.opNameState!.outputPosition];
      expect(nameOutput.value, kNameNewAmountSats);
      expect(
        nameOutput.script.toHex,
        nameScriptHex +
            coinlib.Address.fromString(
              recipient.value,
              network,
            ).program.script.compiled.toHex,
      );
      final outputTotal = tx.outputs.fold<int>(0, (t, o) => t + o.value);
      expect(txData.fee!.raw, BigInt.from(value - outputTotal));
      expect(value - outputTotal, greaterThanOrEqualTo(2 * tx.vSize));
    });
  });
}
