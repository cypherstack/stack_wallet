import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_account_session.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_wallet_state_controller.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

zcash.ZcashTransactionSummary _summary(
  String txid, {
  List<Map<String, Object?>> inputs = const [],
  List<Map<String, Object?>> outputs = const [],
}) => zcash.ZcashTransactionSummary.fromJson({
  'network': 'mainnet',
  'txid': txid,
  'version': 'v5',
  'header': 2147483653,
  'version_group_id': 654776626,
  'consensus_branch_id': 'nu5',
  'consensus_branch_id_hex': 'c2d6d0b4',
  'lock_time': 0,
  'expiry_height': 0,
  'transparent': {
    'present': inputs.isNotEmpty || outputs.isNotEmpty,
    'vin': inputs.length,
    'vout': outputs.length,
    'inputs': inputs,
    'outputs': outputs,
  },
  'sapling': {'present': false, 'spends': 0, 'outputs': 0},
  'orchard': {'present': false, 'actions': 0},
  'ironwood': {'present': false, 'actions': 0},
  'sprout': {'present': false, 'joinsplits': 0},
});

List<int> _bytes(String hex) => [
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
];

zcash.CompactBlock _block({
  required int height,
  required String displayedTxid,
  String blockHash =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
}) => zcash.CompactBlock(
  height: Int64(height),
  hash: _bytes(blockHash),
  time: 1700000000,
  vtx: [
    zcash.CompactTx(txid: _bytes(zcash.reverseTxidByteOrder(displayedTxid))),
  ],
);

void main() {
  const txid =
      '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f';

  ZcashDecodedTransparentTransactionCandidate candidate({
    String summaryTxid = txid,
    String computedTxid = txid,
    int height = 50,
    String rawTransactionHex = '00',
  }) => ZcashDecodedTransparentTransactionCandidate(
    summary: _summary(summaryTxid),
    computedTxid: computedTxid,
    height: height,
    rawTransactionHex: rawTransactionHex,
  );

  test(
    'authenticates exact txid membership and deduplicates raw results',
    () async {
      var loads = 0;
      final authenticated = await authenticateZcashTransparentTransactions(
        candidates: [candidate(), candidate()],
        startHeight: 40,
        chainHeight: 60,
        loadBlock: (height) async {
          loads++;
          return _block(height: height, displayedTxid: txid);
        },
      );

      expect(authenticated, hasLength(1));
      expect(authenticated.single.summary.txid, txid);
      expect(authenticated.single.height, 50);
      expect(loads, 1);
    },
  );

  test('rejects a decoded txid mismatch before loading a block', () async {
    var loaded = false;
    await expectLater(
      authenticateZcashTransparentTransactions(
        candidates: [candidate(computedTxid: 'ff' * 32)],
        startHeight: 40,
        chainHeight: 60,
        loadBlock: (_) async {
          loaded = true;
          return _block(height: 50, displayedTxid: txid);
        },
      ),
      throwsStateError,
    );
    expect(loaded, isFalse);
  });

  test('rejects a transaction served at the wrong block height', () async {
    await expectLater(
      authenticateZcashTransparentTransactions(
        candidates: [candidate()],
        startHeight: 40,
        chainHeight: 60,
        loadBlock: (_) async => _block(height: 51, displayedTxid: txid),
      ),
      throwsStateError,
    );
  });

  test(
    'rejects a transaction absent from the claimed canonical block',
    () async {
      await expectLater(
        authenticateZcashTransparentTransactions(
          candidates: [candidate()],
          startHeight: 40,
          chainHeight: 60,
          loadBlock: (height) async =>
              _block(height: height, displayedTxid: 'ff' * 32),
        ),
        throwsStateError,
      );
    },
  );

  test(
    'rejects duplicate raw transaction ids at conflicting heights',
    () async {
      await expectLater(
        authenticateZcashTransparentTransactions(
          candidates: [candidate(), candidate(height: 51)],
          startHeight: 40,
          chainHeight: 60,
          loadBlock: (height) async =>
              _block(height: height, displayedTxid: txid),
        ),
        throwsStateError,
      );
    },
  );

  test(
    'normalizes uppercase transaction ids before dedupe and membership',
    () async {
      final authenticated = await authenticateZcashTransparentTransactions(
        candidates: [
          candidate(summaryTxid: txid.toUpperCase()),
          candidate(computedTxid: txid.toUpperCase()),
        ],
        startHeight: 40,
        chainHeight: 60,
        loadBlock: (height) async =>
            _block(height: height, displayedTxid: txid),
      );

      expect(authenticated, hasLength(1));
      expect(authenticated.single.summary.txid, txid);
    },
  );

  test('rejects malformed transaction ids before loading blocks', () async {
    await expectLater(
      authenticateZcashTransparentTransactions(
        candidates: [candidate(computedTxid: 'not-a-txid')],
        startHeight: 40,
        chainHeight: 60,
        loadBlock: (_) async => _block(height: 50, displayedTxid: txid),
      ),
      throwsFormatException,
    );
  });

  test(
    'aborts a transaction stream as soon as its unique cap is exceeded',
    () async {
      var yielded = 0;
      Stream<ZcashDecodedTransparentTransactionCandidate> candidates() async* {
        for (var i = 0; i < 100; i++) {
          yielded++;
          final id = i.toRadixString(16).padLeft(64, '0');
          yield candidate(
            summaryTxid: id,
            computedTxid: id,
            rawTransactionHex: i.toRadixString(16).padLeft(2, '0'),
          );
        }
      }

      await expectLater(
        collectZcashTransparentTransactionStream(
          stream: candidates(),
          into: {},
          maxTransactions: 3,
        ),
        throwsStateError,
      );
      expect(yielded, 4);
    },
  );

  test('rejects conflicting metadata for a duplicate owned outpoint', () {
    const address = 't1OwnedAddress';
    const account = zcash.ZcashAccountMetadata(
      network: zcash.ZcashAddressNetwork.mainnet,
      accountIndex: 0,
      ufvk: 'uview-main-account',
      transparentAccountXpub: 'xpub-account',
      receivers: zcash.ZcashAccountReceiverSet(
        orchard: true,
        sapling: true,
        transparent: true,
        p2pkh: true,
        p2sh: false,
        unknown: 0,
        total: 3,
      ),
      receiverKinds: [
        zcash.ZcashAccountReceiverKind(
          kind: zcash.ZcashAddressReceiverType.p2pkh,
          pool: zcash.ZcashAddressPool.transparent,
        ),
      ],
    );
    const viewingKeys = zcash.ZcashViewingKeys(
      network: zcash.ZcashAddressNetwork.mainnet,
      accountIndex: 0,
      transparent: zcash.ZcashTransparentViewingKeys(
        available: true,
        externalIvk: 'external-ivk',
        internalIvk: 'internal-ivk',
        defaultExternalAddress: address,
        defaultExternalIndex: 0,
      ),
      sapling: zcash.ZcashSaplingViewingKey(available: true),
      orchard: zcash.ZcashOrchardViewingKey(available: true),
    );
    final state = zcash.ZcashTransparentState.fromAccount(
      account: account,
      viewingKeys: viewingKeys,
    );
    final summary = _summary(
      txid,
      outputs: const [
        {
          'output_index': 0,
          'address': address,
          'script_hex': '51',
          'value_zatoshis': 1,
        },
        {
          'output_index': 0,
          'address': address,
          'script_hex': '52',
          'value_zatoshis': 2,
        },
      ],
    );
    final refresh = zcash.ZcashTransparentRefresh(
      network: state.network,
      accountFingerprint: state.accountFingerprint,
      queriedAddresses: state.addresses,
      chainHeight: 50,
      chainTipHash: 'aa' * 32,
      canonicalBlockHashes: {50: 'aa' * 32},
      unspentOutputs: const [],
      observedSpends: const [],
    );

    expect(
      () => mergeAuthenticatedTransparentHistory(
        state: state,
        refresh: refresh,
        transactions: [
          ZcashAuthenticatedTransparentTransaction(
            summary: summary,
            height: 50,
            blockHash: 'aa' * 32,
            blockTime: null,
          ),
        ],
      ),
      throwsStateError,
    );
  });

  test(
    'an incremental spend joins against an output from the prior refresh',
    () {
      const address = 't1OwnedAddress';
      const spendTxid =
          '111112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f';
      const account = zcash.ZcashAccountMetadata(
        network: zcash.ZcashAddressNetwork.mainnet,
        accountIndex: 0,
        ufvk: 'uview-main-account',
        transparentAccountXpub: 'xpub-account',
        receivers: zcash.ZcashAccountReceiverSet(
          orchard: true,
          sapling: true,
          transparent: true,
          p2pkh: true,
          p2sh: false,
          unknown: 0,
          total: 3,
        ),
        receiverKinds: [
          zcash.ZcashAccountReceiverKind(
            kind: zcash.ZcashAddressReceiverType.p2pkh,
            pool: zcash.ZcashAddressPool.transparent,
          ),
        ],
      );
      const viewingKeys = zcash.ZcashViewingKeys(
        network: zcash.ZcashAddressNetwork.mainnet,
        accountIndex: 0,
        transparent: zcash.ZcashTransparentViewingKeys(
          available: true,
          externalIvk: 'external-ivk',
          internalIvk: 'internal-ivk',
          defaultExternalAddress: address,
          defaultExternalIndex: 0,
        ),
        sapling: zcash.ZcashSaplingViewingKey(available: true),
        orchard: zcash.ZcashOrchardViewingKey(available: true),
      );
      final state = zcash.ZcashTransparentState.fromAccount(
        account: account,
        viewingKeys: viewingKeys,
      );
      final fundingProtocolTxid = zcash.reverseTxidByteOrder(txid);
      final first = mergeAuthenticatedTransparentHistory(
        state: state,
        refresh: zcash.ZcashTransparentRefresh(
          network: state.network,
          accountFingerprint: state.accountFingerprint,
          queriedAddresses: state.addresses,
          chainHeight: 50,
          chainTipHash: 'aa' * 32,
          canonicalBlockHashes: {50: 'aa' * 32},
          unspentOutputs: [
            zcash.ZcashTransparentOutputObservation(
              address: address,
              protocolTxid: fundingProtocolTxid,
              outputIndex: 0,
              scriptHex: '51',
              valueZatoshis: 100000,
              minedHeight: 50,
              blockHash: 'aa' * 32,
              blockTime: 1700000000,
              isCoinbase: false,
            ),
          ],
          observedSpends: const [],
        ),
        transactions: [
          ZcashAuthenticatedTransparentTransaction(
            summary: _summary(
              txid,
              outputs: const [
                {
                  'output_index': 0,
                  'address': address,
                  'script_hex': '51',
                  'value_zatoshis': 100000,
                },
              ],
            ),
            height: 50,
            blockHash: 'aa' * 32,
            blockTime: 1700000000,
          ),
        ],
      );
      state.applyRefresh(first);

      final second = mergeAuthenticatedTransparentHistory(
        state: state,
        refresh: zcash.ZcashTransparentRefresh(
          network: state.network,
          accountFingerprint: state.accountFingerprint,
          queriedAddresses: state.addresses,
          chainHeight: 51,
          chainTipHash: 'bb' * 32,
          canonicalBlockHashes: {50: 'aa' * 32, 51: 'bb' * 32},
          unspentOutputs: const [],
          observedSpends: const [],
        ),
        transactions: [
          ZcashAuthenticatedTransparentTransaction(
            summary: _summary(
              spendTxid,
              inputs: const [
                {'prevout_txid': txid, 'prevout_index': 0},
              ],
            ),
            height: 51,
            blockHash: 'bb' * 32,
            blockTime: 1700000100,
          ),
        ],
      );
      state.applyRefresh(second);

      expect(second.observedSpends, hasLength(1));
      expect(
        second.observedSpends.single.spentOutpoint,
        '$fundingProtocolTxid:0',
      );
      expect(
        state.outputs.single.spendingProtocolTxid,
        zcash.reverseTxidByteOrder(spendTxid),
      );
    },
  );
}
