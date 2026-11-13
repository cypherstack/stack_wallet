import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:regtest_support/regtest_support.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import 'zcash_stack_regtest_adapter.dart';

const _minerAddress = 'tmYjAZFpvdDXTaJrq2WikAntitBNJJo9VSo';
const _minerSecretKey =
    '1111111111111111111111111111111111111111111111111111111111111111';
const _companionOrchardAddress =
    'uregtest1t5ljufrslrjkts4ku72pj7cer8qtck0yzv58jna7pg7ygjm2taexqnvcl8eg28ac6'
    'verjfdnsx3p028x2pykav0q2vvp0hu3nk3z72vh2adxjgvp34y47zc2efx98pqvqsp9k30j7cq'
    '9vwx09g9ukzfqxzzcm6sm5qt7l0md4t66uj4fxntqk7mlgy4az57rkk6xwu0ag53g5j2h9rz';

/// Executable and consensus inputs for a deterministic staged NU6.3 chain.
final class ZcashStagedChainConfiguration {
  ZcashStagedChainConfiguration({
    required this.nu63ActivationHeight,
    required this.zebraBinary,
    required this.lightwalletdBinary,
    required this.ffiLibrary,
    this.saplingSpendParams,
    this.saplingOutputParams,
    this.deviceHost = '127.0.0.1',
    this.readinessTimeout = const Duration(seconds: 120),
  }) {
    if (nu63ActivationHeight <= coinbaseMaturity + 2) {
      throw ArgumentError.value(
        nu63ActivationHeight,
        'nu63ActivationHeight',
        'must leave room to mature and fund a pre-activation output',
      );
    }
    for (final entry in {
      'zebraBinary': zebraBinary,
      'lightwalletdBinary': lightwalletdBinary,
      'ffiLibrary': ffiLibrary,
    }.entries) {
      if (entry.value.trim().isEmpty) {
        throw ArgumentError.value(entry.value, entry.key, 'must not be empty');
      }
    }
    if (deviceHost.trim().isEmpty) {
      throw ArgumentError.value(deviceHost, 'deviceHost', 'must not be empty');
    }
    if (readinessTimeout <= Duration.zero) {
      throw ArgumentError.value(
        readinessTimeout,
        'readinessTimeout',
        'must be positive',
      );
    }
  }

  static const coinbaseMaturity = 101;

  final int nu63ActivationHeight;
  final String zebraBinary;
  final String lightwalletdBinary;
  final String ffiLibrary;
  final String? saplingSpendParams;
  final String? saplingOutputParams;
  final String deviceHost;
  final Duration readinessTimeout;
}

/// Zebra/lightwalletd-backed staged chain used by Stack's real wallet fixture.
///
/// The driver owns both processes and their temporary data. Funding uses a
/// real mature coinbase and native transaction builder; mining includes only
/// transactions admitted to Zebra's selected block template.
final class ZcashStagedChainDriver
    implements
        StagedRegtestChainDriver<
          EndpointBundle,
          ZcashRegtestPool,
          ZcashRegtestUpgrade
        > {
  ZcashStagedChainDriver._({
    required this.configuration,
    required this._workspace,
    required this._zebra,
    required this._lightwalletd,
    required this._zebraClient,
    required this._lightwalletdClient,
    required this._ffi,
    required this._lightwalletdLog,
    required this.endpoint,
    required this.consensusIdentity,
  });

  static Future<ZcashStagedChainDriver> open(
    ZcashStagedChainConfiguration configuration,
  ) async {
    final workspace = await TemporaryWorkspace.create(
      prefix: 'stack_zcash_regtest_',
    );
    ManagedProcess? zebra;
    ManagedProcess? lightwalletd;
    zcash.ZebraClient? zebraClient;
    zcash.LightwalletdClient? lightwalletdClient;
    try {
      final ports = await Future.wait([
        PortLease.reserve(),
        PortLease.reserve(),
        PortLease.reserve(),
        PortLease.reserve(),
      ]);
      final zebraRpcPort = ports[0].port;
      final zebraP2pPort = ports[1].port;
      final grpcPort = ports[2].port;
      final httpPort = ports[3].port;
      await Future.wait(ports.map((lease) => lease.release()));

      final zebraConfig = await workspace.writeText(
        'zebrad.toml',
        _zebraConfig(
          rpcPort: zebraRpcPort,
          p2pPort: zebraP2pPort,
          activationHeight: configuration.nu63ActivationHeight,
        ),
      );
      zebra = await ManagedProcess.start(
        name: 'zebrad',
        executable: configuration.zebraBinary,
        arguments: ['--config', zebraConfig.path, 'start'],
        environment: _withoutZebraEnvironment(),
        includeParentEnvironment: false,
        maxLogLines: 300,
        stopTimeout: const Duration(seconds: 12),
      );
      zebraClient = zcash.ZebraClient(
        host: '127.0.0.1',
        port: zebraRpcPort,
        timeout: const Duration(seconds: 5),
      );
      await pollUntil(
        'Zebra RPC readiness',
        () async {
          try {
            await zebraClient!.getInfo();
            return true;
          } catch (_) {
            return false;
          }
        },
        failed: () => zebra!.isRunning ? null : 'zebrad exited during startup',
        diagnostics: zebra.diagnostics,
        timeout: configuration.readinessTimeout,
      );

      final chainInfo = await zebraClient.getBlockchainInfo();
      final reported = {
        for (final upgrade in chainInfo.upgrades.values)
          upgrade.name: upgrade.activationHeight,
      };
      if (reported['NU6.3'] != configuration.nu63ActivationHeight) {
        throw StateError(
          'Zebra reported NU6.3=${reported['NU6.3']}, expected '
          '${configuration.nu63ActivationHeight}',
        );
      }

      final lightwalletdData = await Directory(
        '${workspace.root.path}/lightwalletd',
      ).create();
      final zcashConf = await workspace.writeText(
        'zcash.conf',
        'regtest=1\n'
            'rpcconnect=127.0.0.1\n'
            'rpcport=$zebraRpcPort\n'
            'rpcuser=stack_regtest\n'
            'rpcpassword=stack_regtest_local_only\n',
      );
      final lightwalletdLog = File('${workspace.root.path}/lightwalletd.log');
      lightwalletd = await ManagedProcess.start(
        name: 'lightwalletd',
        executable: configuration.lightwalletdBinary,
        arguments: [
          '--no-tls-very-insecure',
          '--zcash-conf-path',
          zcashConf.path,
          '--data-dir',
          lightwalletdData.path,
          '--log-file',
          lightwalletdLog.path,
          '--grpc-bind-addr',
          '127.0.0.1:$grpcPort',
          '--http-bind-addr',
          '127.0.0.1:$httpPort',
        ],
        maxLogLines: 300,
        stopTimeout: const Duration(seconds: 12),
      );
      lightwalletdClient = zcash.LightwalletdClient(
        host: '127.0.0.1',
        port: grpcPort,
        useTls: false,
      );
      await pollUntil(
        'lightwalletd gRPC readiness',
        () async {
          try {
            await lightwalletdClient!.getInfo();
            return true;
          } catch (_) {
            return false;
          }
        },
        failed: () => lightwalletd!.isRunning
            ? null
            : 'lightwalletd exited during startup',
        diagnostics: () =>
            '${zebra!.diagnostics()}\n${lightwalletd!.diagnostics()}',
        timeout: configuration.readinessTimeout,
      );

      final genesisId = await zebraClient.getBlockHash(0);
      final driver = ZcashStagedChainDriver._(
        configuration: configuration,
        workspace: workspace,
        zebra: zebra,
        lightwalletd: lightwalletd,
        zebraClient: zebraClient,
        lightwalletdClient: lightwalletdClient,
        ffi: zcash.ZcashFfiBindings.open(configuration.ffiLibrary),
        lightwalletdLog: lightwalletdLog,
        endpoint: EndpointBundle.mapHost(
          hostEndpoints: {
            'lightwalletd': Uri.http('127.0.0.1:$grpcPort'),
            'zebra': Uri.http('127.0.0.1:$zebraRpcPort'),
          },
          deviceHost: configuration.deviceHost,
        ),
        consensusIdentity: zcashRegtestConsensusIdentity(
          genesisId: genesisId,
          canonicalPolicy: 'zip-318-v1',
          nu63ActivationHeight: configuration.nu63ActivationHeight,
        ),
      );
      await driver.mine(ZcashStagedChainConfiguration.coinbaseMaturity);
      await driver._waitForLightwalletd(
        ZcashStagedChainConfiguration.coinbaseMaturity,
      );
      return driver;
    } catch (error, stack) {
      await lightwalletdClient?.close();
      zebraClient?.close();
      await lightwalletd?.close();
      await zebra?.close();
      await workspace.close();
      Error.throwWithStackTrace(error, stack);
    }
  }

  final ZcashStagedChainConfiguration configuration;
  final TemporaryWorkspace _workspace;
  final ManagedProcess _zebra;
  final ManagedProcess _lightwalletd;
  final zcash.ZebraClient _zebraClient;
  final zcash.LightwalletdClient _lightwalletdClient;
  final zcash.ZcashFfiBindings _ffi;
  final File _lightwalletdLog;
  final Map<String, ChainTransaction<ZcashRegtestPool>> _transactions = {};
  final Map<String, ({int height, String hash})> _minedTransactions = {};
  final Map<String, String> _rawSourceDiagnostics = {};
  bool _closed = false;

  @override
  final EndpointBundle endpoint;

  @override
  final ConsensusIdentity<ZcashRegtestUpgrade> consensusIdentity;

  @override
  String get name => 'Zcash Zebra/lightwalletd staged chain';

  @override
  Future<int> height() => _zebraClient.getBlockCount();

  @override
  Future<void> mine(int blocks) async {
    if (blocks < 0) {
      throw ArgumentError.value(blocks, 'blocks', 'must not be negative');
    }
    for (var i = 0; i < blocks; i++) {
      await _mineOne();
    }
    await _waitForLightwalletd(await height());
  }

  @override
  Future<FundingReceipt<ZcashRegtestPool>> fund({
    required String address,
    required BigInt value,
    required ZcashRegtestPool pool,
  }) async {
    if (value <= BigInt.zero || value > BigInt.from(0x7fffffffffffffff)) {
      throw ArgumentError.value(value, 'value', 'must be a positive int64');
    }
    if (pool != ZcashRegtestPool.orchard &&
        pool != ZcashRegtestPool.sapling &&
        pool != ZcashRegtestPool.transparent) {
      throw UnsupportedError(
        'preactivation funding supports transparent, Sapling, and Orchard; '
        'got $pool',
      );
    }
    if (pool == ZcashRegtestPool.sapling &&
        ((configuration.saplingSpendParams ?? '').isEmpty ||
            (configuration.saplingOutputParams ?? '').isEmpty)) {
      throw StateError(
        'Sapling funding requires verified spend and output parameter paths',
      );
    }
    final tip = await height();
    if (tip + 1 >= configuration.nu63ActivationHeight) {
      throw StateError('NU6.3 is too close to fund an Orchard output');
    }
    final coins = await _zebraClient.getAddressUtxos([_minerAddress]);
    final spendable = coins.where((coin) => coin.height <= tip - 100).toList();
    if (spendable.isEmpty) {
      throw StateError('no mature miner coinbase is available');
    }
    const fee = 10000;
    final amount = value.toInt();
    var coin = spendable.first;
    var fundingTip = tip;
    if (pool == ZcashRegtestPool.sapling) {
      // The Sapling builder has no transparent change surface. First carve an
      // exact non-coinbase transparent input whose full value is the requested
      // Sapling amount plus its fee, then consume it in the proof-bearing
      // funding transaction. Both transactions remain preactivation.
      final stagedValue = amount + fee;
      final stagedChange = coin.satoshis - stagedValue - fee - 1;
      if (stagedChange < 0) {
        throw StateError('mature coinbase cannot stage Sapling funding $value');
      }
      final tree = await _zebraClient.getTreeState('$tip');
      final staged = zcash.buildNativeOrchardTransaction(
        network: zcash.ZcashNetwork.regtest,
        targetHeight: tip + 1,
        regtestNu63ActivationHeight: configuration.nu63ActivationHeight,
        anchor: zcash.OrchardAnchorSource.tree(tree.orchard?.finalState ?? ''),
        feeZatoshis: fee,
        inputs: [
          zcash.TransparentBuildInput(
            txid: coin.txid,
            vout: coin.outputIndex,
            valueZatoshis: coin.satoshis,
            secretKeyHex: _minerSecretKey,
          ),
        ],
        outputs: [
          zcash.TransparentBuildOutput(
            address: _minerAddress,
            valueZatoshis: stagedValue,
          ),
          if (stagedChange > 0)
            zcash.TransparentBuildOutput(
              address: _minerAddress,
              valueZatoshis: stagedChange,
            ),
        ],
        orchardOutput: const zcash.OrchardBuildOutput(
          address: _companionOrchardAddress,
          valueZatoshis: 1,
        ),
        allowExperimentalOrchardBuild: true,
        bindings: _ffi,
      );
      final stagedTxid = await _zebraClient.sendRawTransaction(
        staged.transactionHex,
      );
      if (stagedTxid != staged.txid) {
        throw StateError('Zebra returned a different staging transaction id');
      }
      await _waitForTemplateTransaction(stagedTxid);
      await mine(1);
      fundingTip = await height();
      final stagedCoins = await _zebraClient.getAddressUtxos([_minerAddress]);
      coin = stagedCoins.singleWhere(
        (candidate) =>
            candidate.txid == stagedTxid && candidate.satoshis == stagedValue,
      );
    }
    final companionOrchardValue = pool == ZcashRegtestPool.transparent ? 1 : 0;
    final change = coin.satoshis - amount - fee - companionOrchardValue;
    if (change < 0) throw StateError('mature coinbase cannot fund $value');
    final input = zcash.TransparentBuildInput(
      txid: coin.txid,
      vout: coin.outputIndex,
      valueZatoshis: coin.satoshis,
      secretKeyHex: _minerSecretKey,
    );
    final changeOutput = zcash.TransparentBuildOutput(
      address: _minerAddress,
      valueZatoshis: change,
    );
    final String transactionHex;
    final String expectedTxid;
    if (pool == ZcashRegtestPool.orchard) {
      final tree = await _zebraClient.getTreeState('$fundingTip');
      final built = zcash.buildNativeOrchardTransaction(
        network: zcash.ZcashNetwork.regtest,
        targetHeight: fundingTip + 1,
        regtestNu63ActivationHeight: configuration.nu63ActivationHeight,
        anchor: zcash.OrchardAnchorSource.tree(tree.orchard?.finalState ?? ''),
        inputs: [input],
        outputs: [if (change > 0) changeOutput],
        orchardOutput: zcash.OrchardBuildOutput(
          address: address,
          valueZatoshis: amount,
        ),
        feeZatoshis: fee,
        allowExperimentalOrchardBuild: true,
        bindings: _ffi,
      );
      if (!built.isConsensusValid || built.orchardOutputZatoshis != amount) {
        throw StateError('native Orchard funding build did not match request');
      }
      transactionHex = built.transactionHex;
      expectedTxid = built.txid;
    } else if (pool == ZcashRegtestPool.sapling) {
      final built = zcash.buildNativeSaplingTransaction(
        network: zcash.ZcashNetwork.regtest,
        targetHeight: fundingTip + 1,
        regtestNu63ActivationHeight: configuration.nu63ActivationHeight,
        seedHex: '00' * 32,
        feeZatoshis: fee,
        inputs: [input],
        outputs: [
          zcash.SaplingBuildOutput(address: address, valueZatoshis: amount),
        ],
        spendParamsPath: configuration.saplingSpendParams,
        outputParamsPath: configuration.saplingOutputParams,
        allowExperimentalSaplingBuild: true,
        bindings: _ffi,
      );
      if (!built.isConsensusValid ||
          built.transparentInputZatoshis !=
              built.totalOutputZatoshis + built.feeZatoshis) {
        throw StateError('native Sapling funding build was not canonical');
      }
      transactionHex = built.transactionHex;
      expectedTxid = built.txid;
    } else {
      // The standalone transparent builder cannot accept local activation
      // parameters. This preactivation mixed-pool build gives the transparent
      // output the exact staged branch ID and reports its companion note.
      final tree = await _zebraClient.getTreeState('$fundingTip');
      final built = zcash.buildNativeOrchardTransaction(
        network: zcash.ZcashNetwork.regtest,
        targetHeight: fundingTip + 1,
        regtestNu63ActivationHeight: configuration.nu63ActivationHeight,
        anchor: zcash.OrchardAnchorSource.tree(tree.orchard?.finalState ?? ''),
        feeZatoshis: fee,
        inputs: [input],
        outputs: [
          zcash.TransparentBuildOutput(address: address, valueZatoshis: amount),
          if (change > 0) changeOutput,
        ],
        orchardOutput: const zcash.OrchardBuildOutput(
          address: _companionOrchardAddress,
          valueZatoshis: 1,
        ),
        allowExperimentalOrchardBuild: true,
        bindings: _ffi,
      );
      if (!built.isConsensusValid || built.orchardOutputZatoshis != 1) {
        throw StateError('mixed transparent funding build was not canonical');
      }
      transactionHex = built.transactionHex;
      expectedTxid = built.txid;
    }
    final txid = await _zebraClient.sendRawTransaction(transactionHex);
    if (txid != expectedTxid) {
      throw StateError('Zebra returned a different funding transaction id');
    }
    await _waitForTemplateTransaction(txid);
    _transactions[txid] = ChainTransaction(
      txid: txid,
      confirmations: 0,
      sources: [
        TransferSource(
          id: '${coin.txid}:${coin.outputIndex}',
          pool: ZcashRegtestPool.transparent,
          value: BigInt.from(coin.satoshis),
        ),
      ],
      outputs: [
        TransferOutput(
          id: '$txid:${pool.wireName}:0',
          pool: pool,
          value: value,
          address: address,
        ),
        if (change > 0)
          TransferOutput(
            id: '$txid:transparent:change',
            pool: ZcashRegtestPool.transparent,
            value: BigInt.from(change),
            address: _minerAddress,
          ),
        if (companionOrchardValue > 0)
          TransferOutput(
            id: '$txid:orchard:companion',
            pool: ZcashRegtestPool.orchard,
            value: BigInt.from(companionOrchardValue),
            address: _companionOrchardAddress,
          ),
      ],
      fee: BigInt.from(fee),
    );
    return FundingReceipt(
      txid: txid,
      outputId: '$txid:${pool.wireName}:0',
      address: address,
      pool: pool,
      value: value,
    );
  }

  /// Registers the exact value flow reported by the Stack adapter at broadcast.
  Future<void> recordBroadcast(
    TransferReceipt<ZcashRegtestPool> receipt,
  ) async {
    _transactions[receipt.txid.toLowerCase()] = ChainTransaction(
      txid: receipt.txid,
      confirmations: 0,
      sources: receipt.sources,
      outputs: [...receipt.destinationOutputs, ...receipt.changeOutputs],
      fee: receipt.fee,
    );
    await _waitForTemplateTransaction(receipt.txid);
  }

  @override
  Future<ChainTransaction<ZcashRegtestPool>> transaction(String txid) async {
    final recorded = _transactions[txid.toLowerCase()];
    if (recorded == null) {
      throw StateError('no value-flow registration for transaction $txid');
    }
    final raw = await _zebraClient.getTransaction(txid);
    final decoded = zcash.decodeNativeTransaction(
      txHex: raw.hex,
      network: zcash.ZcashNetwork.regtest,
      bindings: _ffi,
    );
    authenticateRecordedZcashTransaction(
      recorded: recorded,
      zebra: raw,
      decoded: decoded,
    );
    await _authenticateRawSources(recorded, raw, decoded);
    final confirmations = raw.confirmations ?? 0;
    return ChainTransaction(
      txid: txid,
      confirmations: confirmations,
      sources: recorded.sources,
      outputs: recorded.outputs,
      fee: recorded.fee,
    );
  }

  String rawSourceDiagnostics(String txid) =>
      _rawSourceDiagnostics[txid] ?? 'raw source diagnostics unavailable';

  Future<void> _authenticateRawSources(
    ChainTransaction<ZcashRegtestPool> recorded,
    zcash.TransactionInfo raw,
    zcash.ZcashTransactionSummary decoded,
  ) async {
    final location = _minedTransactions[recorded.txid.toLowerCase()];
    if (location == null) {
      throw StateError(
        'driver did not record a mined block for transaction ${recorded.txid}',
      );
    }
    final block = await _zebraClient.getBlock(location.hash);
    authenticateMinedZcashTransactionBlock(
      txid: recorded.txid,
      expectedHash: location.hash,
      expectedHeight: location.height,
      block: block,
    );
    final blockHeight = location.height;
    final converted = zcash.convertNativeRawBlocks(
      network: 'regtest',
      rawBlockHex: [await _zebraClient.getRawBlock(block.hash)],
      regtestNu63ActivationHeight: configuration.nu63ActivationHeight,
      bindings: _ffi,
    );
    final compact = zcash.CompactBlock.fromBuffer(
      base64Decode(converted.blocks.single.dataBase64),
    );
    final protocolTxid = zcash.reverseTxidByteOrder(recorded.txid);
    final transaction = compact.vtx.singleWhere(
      (entry) => _hexEncode(entry.txid) == protocolTxid,
    );
    final compactTransparent = {
      for (final input in transaction.vin)
        '${_hashEncodeReversed(Uint8List.fromList(input.prevoutTxid))}:'
            '${input.prevoutIndex}',
    };
    final actual = <ZcashRegtestPool, Set<String>>{
      ZcashRegtestPool.transparent: {
        for (final input in decoded.transparent.inputs)
          '${input.prevoutTxid.toLowerCase()}:${input.prevoutIndex}',
      },
      ZcashRegtestPool.sapling: {
        for (final spend in transaction.spends) _hexEncode(spend.nf),
      },
      ZcashRegtestPool.orchard: {
        for (final action in transaction.actions) _hexEncode(action.nullifier),
      },
      ZcashRegtestPool.ironwood: {
        for (final action in transaction.ironwoodActions)
          _hexEncode(action.nullifier),
      },
    };
    final expected = <ZcashRegtestPool, Set<String>>{
      for (final pool in ZcashRegtestPool.values)
        pool: {
          for (final source in recorded.sources)
            if (source.pool == pool) source.id,
        },
    };
    final diagnostic = [
      'height=$blockHeight compactTx=$protocolTxid',
      'transparent raw=${actual[ZcashRegtestPool.transparent]} '
          'compact=$compactTransparent',
      for (final pool in ZcashRegtestPool.values)
        '${pool.wireName}: selected/watch=${expected[pool]} '
            'compact=${actual[pool]} count=${actual[pool]!.length}',
    ].join('\n');
    _rawSourceDiagnostics[recorded.txid] = diagnostic;
    for (final pool in ZcashRegtestPool.values) {
      if (!actual[pool]!.containsAll(expected[pool]!)) {
        throw StateError(
          'raw compact transaction does not consume every selected source\n'
          '$diagnostic',
        );
      }
    }
  }

  Future<void> _waitForTemplateTransaction(String txid) => pollUntil(
    'transaction $txid in Zebra block template',
    () async {
      final template = await _zebraClient.getBlockTemplate();
      return template.transactions.any(
        (entry) => entry['hash'] == txid || entry['txid'] == txid,
      );
    },
    failed: () => _zebra.isRunning ? null : 'zebrad exited',
    diagnostics: diagnostics,
  );

  Future<void> _waitForLightwalletd(int targetHeight) => pollUntil(
    'lightwalletd height $targetHeight',
    () async {
      try {
        final latest = await _lightwalletdClient.getLatestBlock();
        return latest.height.toInt() >= targetHeight;
      } catch (_) {
        return false;
      }
    },
    failed: () => _lightwalletd.isRunning ? null : 'lightwalletd exited',
    diagnostics: diagnostics,
    timeout: configuration.readinessTimeout,
  );

  Future<String> _mineOne() async {
    final template = await _zebraClient.getBlockTemplate();
    final coinbase = template.coinbaseTxn;
    if (coinbase == null) throw StateError('template missing coinbase');
    final commitments = template.blockCommitmentsHash;
    if (commitments == null) {
      throw StateError('template missing block commitments');
    }
    final coinbaseHash = coinbase['hash'] as String;
    final merkleRoot =
        template.transactions.isEmpty && template.defaultMerkleRoot != null
        ? zcash.BlockAssembler.reverseHash(_hex(template.defaultMerkleRoot!))
        : zcash.BlockAssembler.computeMerkleRoot([
            coinbaseHash,
            for (final transaction in template.transactions)
              transaction['hash'] as String,
          ]);
    final prefix = zcash.BlockAssembler.buildHeaderPrefix(
      version: template.version,
      prevBlockHash: zcash.BlockAssembler.reverseHash(
        _hex(template.previousBlockHash),
      ),
      merkleRoot: merkleRoot,
      blockCommitments: zcash.BlockAssembler.reverseHash(_hex(commitments)),
      time: template.curTime ?? template.minTime,
      bits: int.parse(template.bits, radix: 16),
    );
    final solved = zcash.solveEquihash(prefix);
    final header = zcash.BlockAssembler.buildHeader(
      headerPrefix: prefix,
      nonce: solved.nonce,
      solution: solved.solution,
    );
    final blockHex = zcash.BlockAssembler.assembleBlockHex(
      header: header,
      coinbaseHex: coinbase['data'] as String,
      otherTxHex: [
        for (final transaction in template.transactions)
          transaction['data'] as String,
      ],
    );
    final rejection = await _zebraClient.submitBlock(blockHex);
    if (rejection != null && rejection.isNotEmpty) {
      throw StateError('submitblock rejected: $rejection');
    }
    final hash = _hashEncodeReversed(_sha256d(header));
    for (final transaction in template.transactions) {
      final templateIds = zcashTemplateTransactionIds(transaction);
      for (final normalizedTxid in templateIds) {
        _minedTransactions[normalizedTxid] = (
          height: template.height,
          hash: hash,
        );
        final recorded = _transactions[normalizedTxid];
        if (recorded == null) continue;
        _transactions[normalizedTxid] = ChainTransaction(
          txid: recorded.txid,
          confirmations: 1,
          sources: recorded.sources,
          outputs: recorded.outputs,
          fee: recorded.fee,
        );
      }
    }
    return hash;
  }

  @override
  String diagnostics({int maxLines = 100}) =>
      'height=${_closed ? 'closed' : 'open'} root=${_workspace.root.path}\n'
      '[zebrad]\n${_zebra.diagnostics(maxLines: maxLines)}\n'
      '[lightwalletd]\n${_lightwalletd.diagnostics(maxLines: maxLines)}\n'
      '[lightwalletd file]\n${_fileTail(_lightwalletdLog, maxLines)}';

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    Object? firstError;
    StackTrace? firstStack;
    Future<void> attempt(Future<void> Function() action) async {
      try {
        await action();
      } catch (error, stack) {
        firstError ??= error;
        firstStack ??= stack;
      }
    }

    await attempt(_lightwalletdClient.close);
    _zebraClient.close();
    await attempt(_lightwalletd.close);
    await attempt(_zebra.close);
    await attempt(_workspace.close);
    if (firstError != null) Error.throwWithStackTrace(firstError!, firstStack!);
  }
}

Set<String> zcashTemplateTransactionIds(Map<String, dynamic> transaction) => {
  if (transaction['hash'] case final String hash) hash.toLowerCase(),
  if (transaction['txid'] case final String txid) txid.toLowerCase(),
};

void authenticateMinedZcashTransactionBlock({
  required String txid,
  required String expectedHash,
  required int expectedHeight,
  required zcash.BlockInfo block,
}) {
  final normalizedTxid = txid.toLowerCase();
  if (block.hash.toLowerCase() != expectedHash.toLowerCase() ||
      block.height != expectedHeight ||
      !block.transactions.any(
        (candidate) => candidate.toLowerCase() == normalizedTxid,
      )) {
    throw StateError(
      'Zebra block does not match driver-recorded transaction provenance: '
      'txid=$txid expectedHash=$expectedHash actualHash=${block.hash} '
      'expectedHeight=$expectedHeight actualHeight=${block.height} '
      'transactions=${block.transactions}',
    );
  }
}

/// Binds adapter-reported value flow to the exact transaction Zebra accepted.
///
/// Raw transaction decoding cannot reveal shielded values without viewing
/// material, so value/address assertions remain independently supplied by the
/// destination wallet scan. This check proves that the txid is exact and that
/// the claimed destination pool has a matching post-activation bundle shape.
void authenticateRecordedZcashTransaction({
  required ChainTransaction<ZcashRegtestPool> recorded,
  required zcash.TransactionInfo zebra,
  required zcash.ZcashTransactionSummary decoded,
}) {
  if (zebra.txid != recorded.txid || decoded.txid != recorded.txid) {
    throw StateError(
      'Zebra/raw transaction id does not match the recorded broadcast',
    );
  }
  final transparentOutputs = recorded.outputs
      .where((output) => output.pool == ZcashRegtestPool.transparent)
      .toList(growable: false);
  final unmatchedTransparent = decoded.transparent.outputs.toList();
  for (final expected in transparentOutputs) {
    final index = unmatchedTransparent.indexWhere(
      (actual) =>
          actual.valueZatoshis == expected.value.toInt() &&
          (expected.address == null || actual.address == expected.address),
    );
    if (index < 0) {
      throw StateError(
        'recorded transparent destination does not match the raw v6 bundle',
      );
    }
    unmatchedTransparent.removeAt(index);
  }
  final saplingOutputs = recorded.outputs
      .where((output) => output.pool == ZcashRegtestPool.sapling)
      .length;
  if (saplingOutputs > 0 &&
      (!decoded.sapling.present || decoded.sapling.outputs < saplingOutputs)) {
    throw StateError(
      'recorded Sapling destinations do not match the raw v6 bundle',
    );
  }
  final ironwoodOutputs = recorded.outputs
      .where((output) => output.pool == ZcashRegtestPool.ironwood)
      .length;
  if (ironwoodOutputs > 0) {
    if (decoded.version != zcash.ZcashTransactionVersion.v6 ||
        decoded.consensusBranchId != 'nu6.3' ||
        !decoded.ironwood.present ||
        decoded.ironwood.actions < ironwoodOutputs) {
      throw StateError(
        'recorded Ironwood destinations do not match the raw v6 bundle',
      );
    }
  }
  final hasOrchardSource = recorded.sources.any(
    (source) => source.pool == ZcashRegtestPool.orchard,
  );
  final claimsOrchardOutput = recorded.outputs.any(
    (output) => output.pool == ZcashRegtestPool.orchard,
  );
  if (!hasOrchardSource && !claimsOrchardOutput && decoded.orchard.present) {
    throw StateError(
      'raw post-activation transaction contains an unexpected Orchard bundle',
    );
  }
}

String _zebraConfig({
  required int rpcPort,
  required int p2pPort,
  required int activationHeight,
}) =>
    '''
[network]
network = "Regtest"
listen_addr = "127.0.0.1:$p2pPort"
peerset_initial_target_size = 0
initial_mainnet_peers = []
initial_testnet_peers = []

[network.testnet_parameters.activation_heights]
Overwinter = 1
Sapling = 1
Blossom = 1
Heartwood = 1
Canopy = 1
NU5 = 1
NU6 = 1
"NU6.1" = 1
"NU6.2" = 1
"NU6.3" = $activationHeight

[rpc]
listen_addr = "127.0.0.1:$rpcPort"
enable_cookie_auth = false

[state]
ephemeral = true

[mining]
miner_address = "$_minerAddress"
''';

Map<String, String> _withoutZebraEnvironment() => {
  for (final entry in Platform.environment.entries)
    if (!entry.key.startsWith('ZEBRA_')) entry.key: entry.value,
};

Uint8List _hex(String value) => Uint8List.fromList([
  for (var i = 0; i < value.length; i += 2)
    int.parse(value.substring(i, i + 2), radix: 16),
]);

String _hexEncode(List<int> value) =>
    value.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

Uint8List _sha256d(Uint8List value) =>
    Uint8List.fromList(sha256.convert(sha256.convert(value).bytes).bytes);

String _hashEncodeReversed(Uint8List value) =>
    value.reversed.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

String _fileTail(File file, int maxLines) {
  if (!file.existsSync()) return '(no log file)';
  final lines = file.readAsLinesSync();
  return lines
      .skip(lines.length > maxLines ? lines.length - maxLines : 0)
      .join('\n');
}
