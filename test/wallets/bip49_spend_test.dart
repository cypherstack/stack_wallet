import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/coinlib/p2sh_p2wpkh_input.dart';
import 'package:stackwallet/models/input.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/utilities/extensions/extensions.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_wallet.dart';

import '../support/isar_test_utils.dart';
import '../support/raw_tx_decoder.dart';

// The spends below were built by this test and accepted by Bitcoin Core 31.1
// `testmempoolaccept` on a fresh regtest chain where blocks 1-5 pay, in order,
// the coinbase to the BIP49 receive and change, BIP44, BIP84 and BIP86
// receive addresses at index 0, followed by 100 more blocks. Coinbase txids
// do not depend on block time, so the chain is reproducible. Set BIP49_TX_OUT
// to a file path to write the built transactions for that check.
// Regtest shares testnet's base58 prefixes and witness programs, so the
// testnet wallet signs for the same scripts.

const _walletId = 'bip49-spend';

// Mnemonic from the BIP49 test vectors.
const _mnemonic =
    'abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon abandon abandon about';

const _tipHeight = 105;

class _Coin {
  const _Coin(this.type, this.chain, this.txid, this.height);

  final DerivePathType type;
  final int chain;
  final String txid;
  final int height;
}

// Regtest coinbase outputs, vout 0, 50 BTC each.
const _bip49Receive = _Coin(
  DerivePathType.bip49,
  0,
  'f59dacc2262f36faad6dbea34eb446a0a1d9a8afb25248cd806e3d991e223f11',
  1,
);
const _bip49Change = _Coin(
  DerivePathType.bip49,
  1,
  'b093be8cecc3c4bd6a77ffa48b57058f7739e23228d3295028f79b5e10cb27f1',
  2,
);
const _bip44 = _Coin(
  DerivePathType.bip44,
  0,
  'cf5378f51f99adb6eb4760fd30a84bb368e824b1b579d4cde9d89f2db4a1dfcc',
  3,
);
const _bip84 = _Coin(
  DerivePathType.bip84,
  0,
  '16956110c3bfbd545cbd647b6dbd04367a7aaae52807062cb304e816f1191584',
  4,
);
const _bip86 = _Coin(
  DerivePathType.bip86,
  0,
  '02e7b319c6e9e83380821b5793eb78bbbddefde6e63da2ac5470e035eccf3983',
  5,
);

const _coinValue = 5000000000;

class _Wallet extends BitcoinWallet {
  _Wallet() : super(CryptoCurrencyNetwork.test);

  late final Address change;

  @override
  String get walletId => _walletId;

  @override
  Future<String> getMnemonic() async => _mnemonic;

  @override
  Future<String> getMnemonicPassphrase() async => '';

  @override
  Future<int> get chainHeight async => _tipHeight;

  @override
  bool get flagOptInRBF => true;

  @override
  Future<void> checkChangeAddressForTransactions() async {}

  @override
  Future<Address?> getCurrentChangeAddress() async => change;
}

class _Scenario {
  _Scenario(
    this.name, {
    required this.coins,
    required this.amount,
    this.coinControl = false,
    this.sendAll = false,
    this.valueOverride,
  });

  final String name;
  final List<_Coin> coins;
  final int amount;
  final bool coinControl;
  final bool sendAll;
  final int? valueOverride;
}

const _satsPerVByte = 2;

// Recorded app output. Bitcoin Core accepted every transaction except
// bip49-wrong-amount, which failed script verification as intended.
const Map<String, ({String txid, String wtxid, int fee, String raw})>
_expected = {
  'bip49-single': (
    txid: 'fcd25fb2ce8b86f34e31dc4d457c15d767be854ec21c032ba3e27e9d5fa78d5f',
    wtxid: '2575158d569003600520c78cc56e7713e67b17e8e24a036f4199c7b97e442fb5',
    fee: 328,
    raw:
        '01000000000101113f221e993d6e80cd4852b2afa8d9a1a046b44ea3be6dadfa'
        '362f26c2ac9df5000000001716001438971f73930f6c141d977ac4fd4a727c85'
        '4935b3f5ffffff0200e1f505000000001600140fa17461c68ec2241a4c4a5edf'
        '799cbe2f8fb449b80f1024010000001600142f34aa1cf00a53b055a291a03a7d'
        '45f0a6988b5202473044022071b58edc3e05d30a8eee9a84ad4bcb6d901363dd'
        'c1912ca3d592e4b118cda99a022005819da709ec52ba27f7c2f0f888f4261104'
        '9fdfc11b420c88a9662bda62c5c6012103a1af804ac108a8a51782198c2d034b'
        '28bf90c8803f5a53f76276fa69a4eae77f00000000',
  ),
  'bip49-two-inputs': (
    txid: 'e9d4a3aa9bbeddc3745c04052dede7d5aba5387833a3025796dd2dd359b8c6ff',
    wtxid: 'f6d631ee3c4d6f31324b22366e442074be7f1e5808a68b58d4d778f4624c6299',
    fee: 508,
    raw:
        '01000000000102113f221e993d6e80cd4852b2afa8d9a1a046b44ea3be6dadfa'
        '362f26c2ac9df5000000001716001438971f73930f6c141d977ac4fd4a727c85'
        '4935b3f5fffffff127cb105e9bf7285029d32832e239778f05578ba4ff776abd'
        'c4c3ec8cbe93b0000000001716001470beb1e04a500940e9f3abaa66e1a49ac5'
        '5b8f35f5ffffff0200bca065010000001600140fa17461c68ec2241a4c4a5edf'
        '799cbe2f8fb44904266bee000000001600142f34aa1cf00a53b055a291a03a7d'
        '45f0a6988b52024730440220625e5dc7f99170b0efe260691afe153eac94e23e'
        '38fe0e1368fc4df5c9e9e73b022061d2e97008918010417017738a12a3301ed7'
        '3c34e7e5c3cd68bd30fc970660b7012103a1af804ac108a8a51782198c2d034b'
        '28bf90c8803f5a53f76276fa69a4eae77f024730440220353e0201e23e570aaf'
        'f9b678f4055e805d621b0f3f3dfe99db3a5129a5dbf66d02206510b8d1259eaf'
        '0340e3be1c6ed6632a9692d25de9b979d6ae7e6200ae32ae85012102a2fc8996'
        'c5262248b5daefc5a4d0cdcd00c13047d0cb13028136ea630d875a8700000000',
  ),
  'bip49-send-all': (
    txid: '5d9dbe3a06f234ed43378a862b67efef5c5e2cfbba4cbeff65031511bf556b2c',
    wtxid: '597b2eed417c2d6e0acbab71fd0349ed689f719d34b1e5518306cafea939efe2',
    fee: 266,
    raw:
        '01000000000101113f221e993d6e80cd4852b2afa8d9a1a046b44ea3be6dadfa'
        '362f26c2ac9df5000000001716001438971f73930f6c141d977ac4fd4a727c85'
        '4935b3f5ffffff01f6f0052a010000001600140fa17461c68ec2241a4c4a5edf'
        '799cbe2f8fb4490247304402204a9ef3e6832d5ef13cdd27fb68f3c0d8c8da9e'
        '29b78c3b6b38ebe082667a179b022059287b1b00840ca75c03c551c0e7cc06b5'
        '3d0db0d0f0f7c538acda5b4d465cf3012103a1af804ac108a8a51782198c2d03'
        '4b28bf90c8803f5a53f76276fa69a4eae77f00000000',
  ),
  'mixed-all-types': (
    txid: 'ff1d8735ffa1290ae6d93e241970075a56d063a71560371289a20030f19db6bd',
    wtxid: '657eeb39317b42ee6cdff255a8e2da05afa3a7a65a2d21b943fa02d8ab311d52',
    fee: 1054,
    raw:
        '01000000000105113f221e993d6e80cd4852b2afa8d9a1a046b44ea3be6dadfa'
        '362f26c2ac9df5000000001716001438971f73930f6c141d977ac4fd4a727c85'
        '4935b3f5ffffffccdfa1b42d9fd8e9cdd479b5b124e868b34ba830fd6047ebb6'
        'ad991ff57853cf000000006a473044022068ef391f7492213a39eb8aca4e675e'
        'b2fce28d33bdcb7a851bbffd346730048502206589c084cf50fdb502f828e657'
        'cf3c4cca4ebc1b28f116f45307b200d3c42368012102a7451395735369f2ecdf'
        'c829c0f774e88ef1303dfe5b2f04dbaab30a535dfdd6f5ffffff841519f116e8'
        '04b32c060728e5aa7a7a3604bd6d7b64bd5c54bdbfc3106195160000000000f5'
        'ffffff8339cfec35e07054aca23de6e6fddebdbb78eb93571b828033e8e9c619'
        'b3e7020000000000fffffffff127cb105e9bf7285029d32832e239778f05578b'
        'a4ff776abdc4c3ec8cbe93b0000000001716001470beb1e04a500940e9f3abaa'
        '66e1a49ac55b8f35f5ffffff02007841cb020000001600140fa17461c68ec224'
        '1a4c4a5edf799cbe2f8fb449e23ddc06030000001600142f34aa1cf00a53b055'
        'a291a03a7d45f0a6988b5202473044022070ff801804e1c99517aa21ef537509'
        '2810576a320911974586a24c209231223f0220142b23cac16ef50146f90dd92c'
        '20a4f16f92d4b95bce1e0d2e98cb930f07c83b012103a1af804ac108a8a51782'
        '198c2d034b28bf90c8803f5a53f76276fa69a4eae77f000247304402201fe6a8'
        'ff6faaa9b3c6b6bdfcc46752cd65929986222e480647cc2ebec33f54ae022056'
        '0688430394944cbb93025d60504538bde7997499cba61f3eb686e0a46d843501'
        '2102e7ab2537b5d49e970309aae06e9e49f36ce1c9febbd44ec8e0d1cca0b4f9'
        'c31901404bf7fa8329db9a61c55658734a0ce827b2842e4e4b197b92200b369f'
        'f0cec15f96591b197900b379c63886629668cf67e057f8c7b25eeef860562b92'
        'f6362ee9024730440220194f152554a5d7690b48ce2bec28199cb83d14292e6a'
        '2569c6de2b0ce1e2506d02203a1fe9e858c745f242d4c22199188e744e1ba529'
        'dd8e10edf8f7820a259531e1012102a2fc8996c5262248b5daefc5a4d0cdcd00'
        'c13047d0cb13028136ea630d875a8700000000',
  ),
  'legacy-p2pkh': (
    txid: '018f61cf97c4c34bb3cbfd6a223f599bebc6cec4028c90df524d7ef3dff3f29d',
    wtxid: '018f61cf97c4c34bb3cbfd6a223f599bebc6cec4028c90df524d7ef3dff3f29d',
    fee: 438,
    raw:
        '0100000001ccdfa1b42d9fd8e9cdd479b5b124e868b34ba830fd6047ebb6ad99'
        '1ff57853cf000000006a47304402201bbe598593e35b36203dbba4b83babc7d4'
        '4e16a7767c0ca738216013bea402b7022004f0fbd229807a34cd86de34bb9b26'
        '503815b5e7b51cd6660a56c2017297881c012102a7451395735369f2ecdfc829'
        'c0f774e88ef1303dfe5b2f04dbaab30a535dfdd6f5ffffff0200e1f505000000'
        '001600140fa17461c68ec2241a4c4a5edf799cbe2f8fb4494a0f102401000000'
        '1600142f34aa1cf00a53b055a291a03a7d45f0a6988b5200000000',
  ),
  'native-p2wpkh': (
    txid: '431cf036f128f0b318962892c8f0eefe3f35f3f044cacb214eb7e7d86495d359',
    wtxid: 'f4ce360b37d21beab787fcd84657a2745c3c15ea5dbc3d3c7a49b7db5e4029da',
    fee: 282,
    raw:
        '01000000000101841519f116e804b32c060728e5aa7a7a3604bd6d7b64bd5c54'
        'bdbfc3106195160000000000f5ffffff0200e1f505000000001600140fa17461'
        'c68ec2241a4c4a5edf799cbe2f8fb449e60f1024010000001600142f34aa1cf0'
        '0a53b055a291a03a7d45f0a6988b520247304402207e43d6f282eae14ef94e92'
        '14d1cdf1eda8bfdcd281d0798180c949509c907d0f02204e1f758099ad1af7cb'
        '79c1b43da4ef7a2b89ff7da5f262f163e5237af1fb45be012102e7ab2537b5d4'
        '9e970309aae06e9e49f36ce1c9febbd44ec8e0d1cca0b4f9c31900000000',
  ),
  'taproot-p2tr': (
    txid: '3bee73a1b459fe18a7207e0c6b25e1ba81be1808fea11696f484ffdaa65babb3',
    wtxid: 'd1d5bac537885dca16013205f77183a34c4f00b2f513cc438a0bd35d9f535922',
    fee: 260,
    raw:
        '010000000001018339cfec35e07054aca23de6e6fddebdbb78eb93571b828033'
        'e8e9c619b3e7020000000000ffffffff0200e1f505000000001600140fa17461'
        'c68ec2241a4c4a5edf799cbe2f8fb449fc0f1024010000001600142f34aa1cf0'
        '0a53b055a291a03a7d45f0a6988b52014023cee76f565dbf9bba4c589d59c414'
        'f14e261c2a39a50ed8a357ea411db235135a1b4fad527543d76a4036c65af0a2'
        'c8b3f760992a4ea2e03612023a13aec50d00000000',
  ),
  'bip49-wrong-amount': (
    txid: '378b492df2c4f7730e26e342b70294fd4a0875a38c349b1987fcf7510e7f55f0',
    wtxid: '4d7eebca803b49d4f168c8f9fd5a6ca2b6822ed0909f414c32a21b6bfc5fd4ac',
    fee: 328,
    raw:
        '01000000000101113f221e993d6e80cd4852b2afa8d9a1a046b44ea3be6dadfa'
        '362f26c2ac9df5000000001716001438971f73930f6c141d977ac4fd4a727c85'
        '4935b3f5ffffff0200e1f505000000001600140fa17461c68ec2241a4c4a5edf'
        '799cbe2f8fb449b90f1024010000001600142f34aa1cf00a53b055a291a03a7d'
        '45f0a6988b520247304402206b1dc2ec613730b53df6ce205f32f17bdce5e406'
        '310108245800792c36cca2bf02202ee24b17eb92882af6618dc4e17d90b32393'
        '7ce2335f8e63e378541515d74ad5012103a1af804ac108a8a51782198c2d034b'
        '28bf90c8803f5a53f76276fa69a4eae77f00000000',
  ),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(coinlib.loadCoinlib);

  late Isar isar;
  late Directory directory;
  late _Wallet wallet;
  late coinlib.HDPrivateKey root;
  late String recipient;
  final addresses = <_Coin, Address>{};
  final keys = <_Coin, coinlib.HDPrivateKey>{};

  setUpAll(() async {
    await initializeTestIsar();
    directory = await Directory.systemTemp.createTemp('bip49-spend-');
    isar = await Isar.open(
      [AddressSchema, TransactionSchema, UTXOSchema],
      directory: directory.path,
      name: 'bip49-spend',
      inspector: false,
    );
    await MainDB.instance.initMainDB(mock: isar);
    wallet = _Wallet()..mainDB = MainDB.instance;
    root = await wallet.getRootHDNode();

    Address derive(DerivePathType type, int chain, int index) {
      final path = wallet.cryptoCurrency.constructDerivePath(
        derivePathType: type,
        chain: chain,
        index: index,
      );
      final key = root.derivePath(path);
      final result = wallet.cryptoCurrency.getAddressForPublicKey(
        publicKey: key.publicKey,
        derivePathType: type,
      );
      return Address(
        walletId: _walletId,
        value: result.address.toString(),
        publicKey: key.publicKey.data,
        derivationIndex: index,
        derivationPath: DerivationPath()..value = path,
        type: result.addressType,
        subType: chain == 0 ? AddressSubType.receiving : AddressSubType.change,
      );
    }

    for (final coin in [_bip49Receive, _bip49Change, _bip44, _bip84, _bip86]) {
      addresses[coin] = derive(coin.type, coin.chain, 0);
      keys[coin] = root.derivePath(addresses[coin]!.derivationPath!.value);
    }
    wallet.change = derive(DerivePathType.bip84, 1, 0);

    // Account 1 is never stored, so the recipient is external to the wallet.
    recipient = wallet.cryptoCurrency
        .getAddressForPublicKey(
          publicKey: root
              .derivePath(
                wallet.cryptoCurrency.constructDerivePath(
                  derivePathType: DerivePathType.bip84,
                  account: 1,
                  chain: 0,
                  index: 0,
                ),
              )
              .publicKey,
          derivePathType: DerivePathType.bip84,
        )
        .address
        .toString();

    await isar.writeTxn(
      () => isar.addresses.putAll([...addresses.values, wallet.change]),
    );
  });

  tearDownAll(() async {
    await isar.close();
    await directory.delete(recursive: true);
  });

  StandardInput utxoFor(_Coin coin, {int? value}) => StandardInput(
    UTXO(
      walletId: _walletId,
      txid: coin.txid,
      vout: 0,
      value: value ?? _coinValue,
      address: addresses[coin]!.value,
      name: '',
      isBlocked: false,
      blockedReason: null,
      isCoinbase: true,
      // Block hash and time only count confirmations here.
      blockHash: 'regtest-${coin.height}',
      blockHeight: coin.height,
      blockTime: coin.height,
    ),
  );

  Uint8List scriptOf(String address) => coinlib.Address.fromString(
    address,
    wallet.cryptoCurrency.networkParams,
  ).program.script.compiled;

  test('derives the published BIP49 test vector address', () {
    final address = addresses[_bip49Receive]!;
    expect(address.value, '2Mww8dCYPUpKHofjgcXcBCEGmniw9CoaiD2');
    expect(address.derivationPath!.value, "m/49'/1'/0'/0/0");
    expect(
      Uint8List.fromList(address.publicKey).toHex,
      '03a1af804ac108a8a51782198c2d034b28bf90c8803f5a53f76276fa69a4eae77f',
    );
    expect(address.type, AddressType.p2sh);
    expect(
      wallet.cryptoCurrency.addressType(address: address.value),
      DerivePathType.bip49,
    );
  });

  final scenarios = [
    _Scenario('bip49-single', coins: [_bip49Receive], amount: 100000000),
    _Scenario(
      'bip49-two-inputs',
      coins: [_bip49Receive, _bip49Change],
      amount: 6000000000,
      coinControl: true,
    ),
    // Optimal selection shuffles the selected inputs, so this one is not
    // pinned to exact bytes.
    _Scenario(
      'bip49-two-inputs-optimal',
      coins: [_bip49Receive, _bip49Change],
      amount: 6000000000,
    ),
    _Scenario(
      'bip49-send-all',
      coins: [_bip49Receive],
      amount: _coinValue,
      coinControl: true,
      sendAll: true,
    ),
    _Scenario(
      'mixed-all-types',
      coins: [_bip49Receive, _bip44, _bip84, _bip86, _bip49Change],
      amount: 12000000000,
      coinControl: true,
    ),
    _Scenario('legacy-p2pkh', coins: [_bip44], amount: 100000000),
    _Scenario('native-p2wpkh', coins: [_bip84], amount: 100000000),
    _Scenario('taproot-p2tr', coins: [_bip86], amount: 100000000),
    // Signs over the wrong previous amount; Bitcoin Core must reject it.
    _Scenario(
      'bip49-wrong-amount',
      coins: [_bip49Receive],
      amount: 100000000,
      valueOverride: _coinValue + 1,
    ),
  ];

  final built = <String, String>{};

  for (final s in scenarios) {
    test('builds and signs ${s.name} through coinSelection', () async {
      final utxos = [
        for (final coin in s.coins)
          utxoFor(coin, value: coin == _bip49Receive ? s.valueOverride : null),
      ];
      final txData = await wallet.coinSelection(
        txData: TxData(
          satsPerVByte: _satsPerVByte,
          feeRateAmount: BigInt.from(_satsPerVByte * 1000),
          recipients: [
            TxRecipient(
              address: recipient,
              amount: Amount(
                rawValue: BigInt.from(s.amount),
                fractionDigits: 8,
              ),
              isChange: false,
              addressType: AddressType.p2wpkh,
            ),
          ],
        ),
        coinControl: s.coinControl,
        isSendAll: s.sendAll,
        isSendAllCoinControlUtxos: false,
        utxos: utxos,
      );

      final tx = DecodedTx(txData.raw!.toUint8ListFromHex);
      built[s.name] = txData.raw!;

      // Inputs: exactly the expected outpoints (coin control keeps order).
      final outpoints = tx.inputs.map((i) => '${i.txid}:${i.vout}').toList();
      final wanted = s.coins.map((c) => '${c.txid}:0').toList();
      if (s.coinControl) {
        expect(outpoints, wanted);
      } else {
        expect(outpoints, unorderedEquals(wanted));
      }

      for (var i = 0; i < tx.inputs.length; i++) {
        final coin = s.coins.firstWhere((c) => c.txid == tx.inputs[i].txid);
        if (coin.type != DerivePathType.bip86) {
          // Opt-in RBF sequence. Taproot inputs are not checked here: their
          // sequence is a separate fix.
          expect(tx.inputs[i].sequence, 0xffffffff - 10);
        }
        final pub = keys[coin]!.publicKey.data;
        final pkHash = coinlib.hash160(pub);
        final scriptSig = tx.inputs[i].scriptSig;
        final witness = tx.witnesses.isEmpty ? <Uint8List>[] : tx.witnesses[i];
        switch (coin.type) {
          case DerivePathType.bip49:
            // scriptSig is one push of the redeem script OP_0 <hash160(pub)>,
            // which hashes to the spent P2SH output.
            expect(scriptSig.toHex, '160014${pkHash.toHex}');
            final redeem = scriptSig.sublist(1);
            expect(
              scriptOf(addresses[coin]!.value).toHex,
              'a914${coinlib.hash160(redeem).toHex}87',
            );
            expect(witness, hasLength(2));
            expect(witness[0].first, 0x30);
            expect(witness[0].last, 0x01); // SIGHASH_ALL
            expect(witness[1].toHex, pub.toHex);
          case DerivePathType.bip44:
            expect(scriptSig.length, greaterThan(100));
            expect(scriptSig.toHex, endsWith('21${pub.toHex}'));
            expect(witness, isEmpty);
          case DerivePathType.bip84:
            expect(scriptSig, isEmpty);
            expect(witness, hasLength(2));
            expect(witness[1].toHex, pub.toHex);
          case DerivePathType.bip86:
            expect(scriptSig, isEmpty);
            expect(witness, hasLength(1));
            expect(witness[0], hasLength(64));
          default:
            fail('unexpected type ${coin.type}');
        }
      }

      // Outputs: recipient first, then change to the wallet's change address.
      final inputTotal = utxos.fold<int>(0, (t, u) => t + u.utxo.value);
      final outputTotal = tx.outputs.fold<int>(0, (t, o) => t + o.value);
      final fee = inputTotal - outputTotal;
      expect(tx.outputs.first.script.toHex, scriptOf(recipient).toHex);
      if (s.sendAll) {
        expect(tx.outputs, hasLength(1));
        expect(tx.outputs.first.value, inputTotal - fee);
      } else {
        expect(tx.outputs.first.value, s.amount);
        expect(tx.outputs, hasLength(2));
        expect(
          tx.outputs.last.script.toHex,
          scriptOf(wallet.change.value).toHex,
        );
      }

      // Fee is the requested rate over the actual signed size.
      expect(txData.vSize, tx.vSize);
      expect(fee, _satsPerVByte * tx.vSize);
      expect(txData.fee!.raw, BigInt.from(fee));
      expect(txData.tempTx!.txid, tx.txid);
      expect(txData.usedUTXOs!.length, s.coins.length);

      final expected = _expected[s.name];
      if (expected != null) {
        expect(tx.txid, expected.txid);
        expect(tx.wtxid, expected.wtxid);
        expect(fee, expected.fee);
        expect(txData.raw, expected.raw);
      }
    });
  }

  tearDownAll(() async {
    final out = Platform.environment['BIP49_TX_OUT'];
    if (out != null && built.isNotEmpty) {
      await File(out)
          .writeAsString(const JsonEncoder.withIndent('  ').convert(built));
    }
  });

  group('rejects inputs it cannot sign as BIP49', () {
    StandardInput withKey(String address, coinlib.HDPrivateKey key) =>
        StandardInput(
          UTXO(
            walletId: _walletId,
            txid: _bip49Receive.txid,
            vout: 0,
            value: _coinValue,
            address: address,
            name: '',
            isBlocked: false,
            blockedReason: null,
            isCoinbase: false,
            blockHash: null,
            blockHeight: null,
            blockTime: null,
          ),
          derivePathType: DerivePathType.bip49,
          key: key,
        );

    String p2shOf(coinlib.Script redeem) =>
        coinlib.P2SHAddress.fromRedeemScript(
          redeem,
          version: wallet.cryptoCurrency.networkParams.p2shPrefix,
        ).toString();

    test('accepts the matching key and address', () {
      final input = wallet.standardInputToCoinlibInput(
        withKey(addresses[_bip49Receive]!.value, keys[_bip49Receive]!),
      );
      expect(input, isA<P2shP2wpkhInput>());
    });

    test('a BIP49 address of a different key', () {
      expect(
        () => wallet.standardInputToCoinlibInput(
          withKey(addresses[_bip49Change]!.value, keys[_bip49Receive]!),
        ),
        throwsUnsupportedError,
      );
    });

    test('a P2SH multisig output', () {
      final key = keys[_bip49Receive]!.publicKey;
      final multisig = coinlib.MultisigProgram(1, [key]).script;
      expect(
        () => wallet.standardInputToCoinlibInput(
          withKey(p2shOf(multisig), keys[_bip49Receive]!),
        ),
        throwsUnsupportedError,
      );
    });

    test('a P2SH-wrapped P2PKH script', () {
      final key = keys[_bip49Receive]!.publicKey;
      expect(
        () => wallet.standardInputToCoinlibInput(
          withKey(
            p2shOf(coinlib.P2PKH.fromPublicKey(key).script),
            keys[_bip49Receive]!,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('a malformed witness program redeem script', () {
      final pkHash = coinlib.hash160(keys[_bip49Receive]!.publicKey.data);
      final malformed = coinlib.Script.decompile(
        Uint8List.fromList([0x00, 0x13, ...pkHash.sublist(0, 19)]),
      );
      expect(
        () => wallet.standardInputToCoinlibInput(
          withKey(p2shOf(malformed), keys[_bip49Receive]!),
        ),
        throwsUnsupportedError,
      );
    });

    test('a P2SH UTXO with no address', () {
      final input = withKey(
        addresses[_bip49Receive]!.value,
        keys[_bip49Receive]!,
      );
      expect(
        () => wallet.standardInputToCoinlibInput(
          StandardInput(
            UTXO(
              walletId: _walletId,
              txid: input.utxo.txid,
              vout: 0,
              value: _coinValue,
              name: '',
              isBlocked: false,
              blockedReason: null,
              isCoinbase: false,
              blockHash: null,
              blockHeight: null,
              blockTime: null,
            ),
            derivePathType: DerivePathType.bip49,
            key: input.key,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('signing with a key other than the input public key', () {
      final input = P2shP2wpkhInput(
        prevOut: coinlib.OutPoint(Uint8List(32), 0),
        publicKey: keys[_bip49Receive]!.publicKey,
      );
      final tx = coinlib.Transaction(
        inputs: [input],
        outputs: [
          coinlib.Output.fromScriptBytes(BigInt.one, scriptOf(recipient)),
        ],
      );
      expect(
        () => tx.signLegacyWitness(
          inputN: 0,
          key: keys[_bip49Change]!.privateKey,
          value: BigInt.from(_coinValue),
        ),
        throwsA(isA<coinlib.CannotSignInput>()),
      );
    });
  });
}
