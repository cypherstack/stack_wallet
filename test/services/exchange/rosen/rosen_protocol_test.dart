import 'dart:convert';

import 'package:coinlib/coinlib.dart' as coinlib;
import 'package:dart_bs58check/dart_bs58check.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:wallet/wallet.dart' as eth;
import 'package:web3dart/web3dart.dart' as web3;

import '../../../../lib/services/exchange/rosen/rosen_protocol.dart';
import '../../../../lib/utilities/extensions/extensions.dart';

// Decode the signed wire envelope independently of web3dart's RLP encoder.
dynamic _decodeRlp(List<int> bytes) {
  var offset = 0;
  dynamic read() {
    final prefix = bytes[offset++];
    if (prefix < 0x80) return [prefix];
    final isList = prefix >= 0xc0;
    var length = prefix - (isList ? 0xc0 : 0x80);
    if (length > 55) {
      final lengthBytes = length - 55;
      length = 0;
      for (var i = 0; i < lengthBytes; i++) {
        length = length * 256 + bytes[offset++];
      }
    }
    final end = offset + length;
    expect(end, lessThanOrEqualTo(bytes.length));
    if (!isList) {
      final value = bytes.sublist(offset, end);
      offset = end;
      return value;
    }
    final values = <dynamic>[];
    while (offset < end) {
      values.add(read());
    }
    expect(offset, end);
    return values;
  }

  final value = read();
  expect(offset, bytes.length);
  return value;
}

void main() {
  const ethereum = '0x00112233445566778899aabbccddeeff00112233';
  final firo = bs58check.encode('52${'11' * 20}'.toUint8ListFromHex);

  test('Rosen FIRO metadata matches upstream uint64 BE layout', () {
    expect(
      RosenProtocol.metadata(
        fromFiro: true,
        destination: ethereum,
        bridgeFee: BigInt.from(123),
        networkFee: BigInt.from(456),
      ),
      '03000000000000007b00000000000001c81400112233445566778899aabbccddeeff00112233',
    );
    expect(
      RosenProtocol.metadata(
        fromFiro: false,
        destination: firo,
        bridgeFee: BigInt.from(123),
        networkFee: BigInt.from(456),
      ),
      '07000000000000007b00000000000001c81976a914${'11' * 20}88ac',
    );
    final p2sh = bs58check.encode('07${'22' * 20}'.toUint8ListFromHex);
    expect(RosenProtocol.firoScript(p2sh), 'a914${'22' * 20}87');
  });

  for (final version in ['52', '07']) {
    test('signed rsFIRO broadcast preserves FIRO $version metadata', () async {
      const token = '0x2744ea5ac9b11cb5e3cd63d3a88e858336aeddc2';
      const lock = '0x451698faa07fc68301af622a3ad42205f13c6e4b';
      final destination = bs58check.encode(
        '$version${'11' * 20}'.toUint8ListFromHex,
      );
      final metadata = RosenProtocol.metadata(
        fromFiro: false,
        destination: destination,
        bridgeFee: BigInt.from(123),
        networkFee: BigInt.from(456),
      );
      final expectedMetadata =
          '07000000000000007b00000000000001c8'
          '${version == '52' ? '1976a914${'11' * 20}88ac' : '17a914${'11' * 20}87'}';
      final amount = BigInt.parse('9007199254740993');
      final calldata = RosenProtocol.transferData(
        lockAddress: lock,
        amount: amount,
        metadata: metadata,
      );
      final expectedCalldata =
          'a9059cbb${lock.substring(2).padLeft(64, '0')}'
          '${amount.toRadixString(16).padLeft(64, '0')}$expectedMetadata';
      final txid = '0x${'22' * 32}';
      final client = web3.Web3Client(
        'https://ethereum.invalid',
        MockClient(
          expectAsync1((request) async {
            final rpc = jsonDecode(request.body) as Map<String, dynamic>;
            expect(rpc['method'], 'eth_sendRawTransaction');
            final raw =
                ((rpc['params'] as List).single as String).toUint8ListFromHex;
            expect(raw.first, 2); // EIP-1559 transaction envelope.
            final fields = _decodeRlp(raw.sublist(1)) as List;
            expect(fields, hasLength(12));
            expect(fields[0], [1]); // Ethereum mainnet.
            expect(fields[5], token.toUint8ListFromHex);
            expect(fields[6], isEmpty); // No native ETH is sent.
            expect(fields[7], expectedCalldata.toUint8ListFromHex);
            expect(fields[8], isEmpty); // Access list.
            for (final signature in fields.sublist(10)) {
              expect((signature as List<int>).any((byte) => byte != 0), isTrue);
            }
            return http.Response(
              jsonEncode({'jsonrpc': '2.0', 'id': rpc['id'], 'result': txid}),
              200,
            );
          }),
        ),
      );
      addTearDown(client.dispose);
      expect(
        await client.sendTransaction(
          web3.EthPrivateKey.fromHex('01'.padLeft(64, '0')),
          web3.Transaction(
            to: eth.EthereumAddress.fromHex(token),
            value: eth.EtherAmount.zero(),
            data: calldata.toUint8ListFromHex,
            nonce: 7,
            maxGas: 100000,
            maxFeePerGas: eth.EtherAmount.inWei(BigInt.from(3000000000)),
            maxPriorityFeePerGas: eth.EtherAmount.inWei(
              BigInt.from(1000000000),
            ),
          ),
          chainId: 1,
        ),
        txid,
      );
    });
  }

  test('bridge completion requires a payout transaction', () {
    expect(RosenProtocol.swapStatus('processing', null), 'Exchanging');
    expect(RosenProtocol.swapStatus('COMPLETED', null), 'Sending');
    expect(RosenProtocol.swapStatus('COMPLETED', 'invalid'), 'Sending');
    expect(RosenProtocol.swapStatus('COMPLETED', '0x${'11' * 32}'), 'Finished');
    expect(RosenProtocol.swapStatus('successful', '11' * 32), 'Finished');
    expect(RosenProtocol.swapStatus('FRAUD', null), 'Failed');
    expect(RosenProtocol.swapStatus('unknown', null), 'Exchanging');
  });

  test('amounts stay exact beyond floating-point precision', () {
    expect(
      RosenProtocol.parseAmount('90071992.54740993'),
      BigInt.parse('9007199254740993'),
    );
    expect(
      RosenProtocol.formatAmount(BigInt.parse('9007199254740993')),
      '90071992.54740993',
    );
    expect(RosenProtocol.formatAmount(BigInt.one), '0.00000001');
    expect(RosenProtocol.formatAmount(BigInt.from(100000000)), '1');
    for (final amount in [
      '-1',
      '1.000000001',
      'NaN',
      '1e8',
      '184467440737.09551616',
    ]) {
      expect(() => RosenProtocol.parseAmount(amount), throwsFormatException);
    }
  });

  test('invalid network addresses, metadata and fee overflow fail closed', () {
    final testnet = bs58check.encode('41${'11' * 20}'.toUint8ListFromHex);
    expect(() => RosenProtocol.firoScript(testnet), throwsFormatException);
    final witness = coinlib.P2WPKHAddress.fromHash(
      ('11' * 20).toUint8ListFromHex,
      hrp: 'bc',
    );
    expect(
      () => RosenProtocol.firoScript(witness.toString()),
      throwsFormatException,
    );
    expect(
      () => RosenProtocol.firoScript('spark1notatransparentaddress'),
      throwsA(anything),
    );
    expect(
      () => RosenProtocol.ethereumAddress('0x${'00' * 20}'),
      throwsFormatException,
    );
    for (final metadata in ['zz', 'a', 'aa bb', '0xaa', 'aa\n']) {
      expect(
        () => RosenProtocol.transferData(
          lockAddress: ethereum,
          amount: BigInt.one,
          metadata: metadata,
        ),
        throwsFormatException,
      );
    }
    for (final amount in [BigInt.zero, -BigInt.one, BigInt.one << 64]) {
      expect(
        () => RosenProtocol.transferData(
          lockAddress: ethereum,
          amount: amount,
          metadata: '00',
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => RosenProtocol.ethereumAddress(
        '0x52908400098527886E0F7030069857D2E4169Ee7',
      ),
      throwsArgumentError,
    );
    expect(
      () => RosenProtocol.metadata(
        fromFiro: true,
        destination: ethereum,
        bridgeFee: BigInt.one << 64,
        networkFee: BigInt.one,
      ),
      throwsArgumentError,
    );
    expect(
      () => RosenProtocol.metadata(
        fromFiro: true,
        destination: ethereum,
        bridgeFee: BigInt.one,
        networkFee: -BigInt.one,
      ),
      throwsArgumentError,
    );
  });
}
