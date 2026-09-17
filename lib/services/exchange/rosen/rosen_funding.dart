import 'package:wallet/wallet.dart' as eth;
import 'package:web3dart/web3dart.dart' as web3;

import '../../../db/hive/db.dart';
import '../../../models/exchange/response_objects/trade.dart';
import '../../../models/isar/models/ethereum/eth_contract.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/enums/fee_rate_type_enum.dart';
import '../../../utilities/logger.dart';
import '../../../wallets/crypto_currency/crypto_currency.dart';
import '../../../wallets/models/tx_data.dart';
import '../../../wallets/wallet/impl/ethereum_wallet.dart';
import '../../../wallets/wallet/impl/firo_wallet.dart';
import '../../../wallets/wallet/impl/sub_wallets/eth_token_wallet.dart';
import '../../../wallets/wallet/wallet.dart';
import '../../../wallets/wallet/wallet_mixin_interfaces/firo_op_return.dart';
import 'rosen_api.dart';
import 'rosen_exchange.dart';
import 'rosen_protocol.dart';

/// Bridge transactions retain the normal swap confirmation and wallet signing.
class RosenFunding {
  // A null entry is broadcasting; a txid prevents repeat funding after local errors.
  static final Map<String, String?> _funding = {};

  static CryptoCurrency sourceCoin(Trade trade) => RosenExchange.isFiro(trade)
      ? Firo(CryptoCurrencyNetwork.main)
      : Ethereum(CryptoCurrencyNetwork.main);

  static int fractionDigits(Trade trade) => RosenApi.tokenDecimals;

  static bool canFund(Wallet wallet, Trade trade) =>
      !wallet.info.isViewOnly &&
      wallet.cryptoCurrency == sourceCoin(trade) &&
      (RosenExchange.isFiro(trade)
          ? wallet is FiroWallet
          : wallet is EthereumWallet);

  static const _abi = '''[
    {"type":"function","name":"balanceOf","stateMutability":"view","inputs":[{"name":"account","type":"address"}],"outputs":[{"name":"","type":"uint256"}]},
    {"type":"function","name":"decimals","stateMutability":"view","inputs":[],"outputs":[{"name":"","type":"uint8"}]},
    {"type":"function","name":"transfer","stateMutability":"nonpayable","inputs":[{"name":"to","type":"address"},{"name":"amount","type":"uint256"}],"outputs":[{"name":"","type":"bool"}]}
  ]''';

  static EthContract _tokenFor(Wallet wallet) => EthContract(
    address: wallet.info.tokenContractAddresses.firstWhere(
      (address) => address.toLowerCase() == RosenApi.rsFiroContract,
      orElse: () => RosenApi.rsFiroContract,
    ),
    name: 'Rosen Firo',
    symbol: 'rsFIRO',
    decimals: RosenApi.tokenDecimals,
    type: EthContractType.erc20,
    abi: _abi,
  );

  static Future<void> registerToken(Wallet wallet) async {
    if (wallet is! EthereumWallet ||
        wallet.cryptoCurrency.network != CryptoCurrencyNetwork.main) {
      throw StateError('rsFIRO requires an Ethereum mainnet wallet.');
    }
    final token = _tokenFor(wallet);
    final stored = await wallet.mainDB.getEthContract(token.address);
    await wallet.mainDB.putEthContract(token.copyWith(id: stored?.id));
    if (!wallet.info.tokenContractAddresses.any(
      (address) => address.toLowerCase() == RosenApi.rsFiroContract,
    )) {
      await wallet.updateTokenContracts([
        ...wallet.info.tokenContractAddresses,
        RosenApi.rsFiroContract,
      ]);
    }
  }

  static Future<Trade> refreshTrade({
    required Wallet wallet,
    required Trade trade,
  }) async {
    if (_funding.containsKey(trade.uuid)) {
      throw StateError('This bridge swap is already being processed.');
    }
    _funding[trade.uuid] = null;
    try {
      // Refresh the persisted request, including if this screen holds an old quote.
      final current = DB.instance.get<Trade>(
        boxName: DB.boxNameTradesV2,
        key: trade.uuid,
      );
      if (current == null)
        throw StateError('This Rosen swap is no longer available.');
      RosenExchange.requireUnfunded(current);
      RosenExchange.validatedMetadata(current);
      if (!canFund(wallet, current)) {
        throw StateError('Choose a spendable wallet on the source network.');
      }
      final int height;
      if (wallet is FiroWallet) {
        height = await wallet.fetchChainHeight();
      } else {
        final ethereum = wallet as EthereumWallet;
        if (ethereum.prefs.useTor) {
          throw StateError('Ethereum bridge funding is unavailable over Tor.');
        }
        final client = ethereum.getEthClient();
        try {
          if (await client.getChainId() != BigInt.one) {
            throw StateError('The Ethereum node must use mainnet.');
          }
          height = await client.getBlockNumber();
        } finally {
          await client.dispose();
        }
      }
      final quote = await RosenApi.instance.quote(
        fromFiro: RosenExchange.isFiro(current),
        amount: RosenProtocol.parseAmount(current.payInAmount),
        sourceHeight: height,
      );
      return await RosenExchange.saveRefreshedTrade(current, quote);
    } finally {
      _funding.remove(trade.uuid);
    }
  }

  static Future<TxData> prepareSend({
    required Wallet wallet,
    required Trade trade,
  }) async {
    if (!canFund(wallet, trade))
      throw StateError('Choose a spendable wallet on the source network.');
    final metadata = RosenExchange.validatedMetadata(trade);
    final amount = Amount(
      rawValue: RosenProtocol.parseAmount(trade.payInAmount),
      fractionDigits: RosenApi.tokenDecimals,
    );
    final data = TxData(
      recipients: [
        TxRecipient(
          address: trade.payInAddress,
          amount: amount,
          isChange: false,
          addressType: wallet.cryptoCurrency.getAddressType(
            trade.payInAddress,
          )!,
        ),
      ],
      feeRateType: FeeRateType.average,
    );
    if (wallet is FiroWallet) {
      await RosenExchange.validateFunding(
        trade,
        sourceHeight: await wallet.fetchChainHeight(),
      );
      final prepared = await wallet.prepareSend(
        txData: data.copyWith(opReturnData: metadata),
      );
      // Transparent send-all subtracts the mining fee: a bridge deposit must be exact.
      if (prepared.amountWithoutChange != amount) {
        throw StateError(
          'Leave enough transparent FIRO to pay the mining fee.',
        );
      }
      return prepared;
    }

    final ethereum = wallet as EthereumWallet;
    if (ethereum.prefs.useTor)
      throw StateError('Ethereum bridge funding is unavailable over Tor.');
    final client = ethereum.getEthClient();
    try {
      final sender = await ethereum.getMyWeb3Address();
      final prep = await ethereum.internalSharedPrepareSend(
        txData: data,
        myWeb3Address: sender,
      );
      if (prep.chainId != BigInt.one)
        throw StateError('The Ethereum node must use mainnet.');
      await RosenExchange.validateFunding(
        trade,
        sourceHeight: await client.getBlockNumber(),
      );
      final contract = web3.DeployedContract(
        web3.ContractAbi.fromJson(_abi, 'rsFIRO'),
        eth.EthereumAddress.fromHex(RosenApi.rsFiroContract),
      );
      final decimals = await client.call(
        contract: contract,
        function: contract.function('decimals'),
        params: [],
      );
      if (decimals.single != BigInt.from(RosenApi.tokenDecimals)) {
        throw StateError('Unexpected rsFIRO token precision.');
      }
      final balance = await client.call(
        contract: contract,
        function: contract.function('balanceOf'),
        params: [sender],
      );
      if ((balance.single as BigInt) < amount.raw)
        throw StateError('Insufficient rsFIRO balance.');
      final calldata = RosenProtocol.bytes(
        RosenProtocol.transferData(
          lockAddress: RosenApi.ethereumLockAddress,
          amount: amount.raw,
          metadata: metadata,
        ),
      );
      final tokenAddress = eth.EthereumAddress.fromHex(RosenApi.rsFiroContract);
      final gas = await client.estimateGas(
        sender: sender,
        to: tokenAddress,
        data: calldata,
      );
      final gasLimit =
          (gas * BigInt.from(120) + BigInt.from(99)) ~/ BigInt.from(100);
      final maxFee = prep.maxBaseFee + prep.priorityFee;
      final fee = Amount(rawValue: gasLimit * maxFee, fractionDigits: 18);
      final ethBalance = await client.getBalance(
        sender,
        atBlock: const web3.BlockNum.pending(),
      );
      if (ethBalance.getInWei < fee.raw)
        throw StateError('Insufficient ETH for the bridge transaction gas.');
      await registerToken(ethereum);
      return data.copyWith(
        fee: fee,
        chainId: prep.chainId,
        nonce: prep.nonce,
        web3dartTransaction: web3.Transaction(
          to: tokenAddress,
          data: calldata,
          value: eth.EtherAmount.zero(),
          maxGas: gasLimit.toInt(),
          nonce: prep.nonce,
          maxFeePerGas: eth.EtherAmount.inWei(maxFee),
          maxPriorityFeePerGas: eth.EtherAmount.inWei(prep.priorityFee),
        ),
      );
    } finally {
      await client.dispose();
    }
  }

  static Future<TxData> confirmSend({
    required Wallet wallet,
    required Trade trade,
    required TxData txData,
  }) async {
    if (!canFund(wallet, trade))
      throw StateError('Invalid bridge source wallet.');
    final metadata = RosenExchange.validatedMetadata(trade);
    final amount = RosenProtocol.parseAmount(trade.payInAmount);
    if (txData.amountWithoutChange?.raw != amount ||
        txData.recipients?.where((e) => !e.isChange).length != 1 ||
        txData.recipients!.firstWhere((e) => !e.isChange).address !=
            trade.payInAddress) {
      throw StateError('The transaction does not match this bridge swap.');
    }
    if (_funding.containsKey(trade.uuid)) {
      final txid = _funding[trade.uuid];
      if (txid != null) return txData.copyWith(txid: txid, txHash: txid);
      throw StateError('This bridge swap is already being sent.');
    }
    _funding[trade.uuid] = null;
    String? broadcastTxid;
    void onBroadcast(String txid) {
      broadcastTxid = txid;
      _funding[trade.uuid] = txid;
    }

    try {
      if (wallet is FiroWallet) {
        if (txData.opReturnData != metadata) {
          throw StateError('Missing Rosen OP_RETURN.');
        }
        verifyFiroOpReturnTransaction(
          raw: txData.raw ?? '',
          data: metadata,
          paymentScript: RosenProtocol.firoScript(trade.payInAddress),
          paymentAmount: amount,
        );
        await RosenExchange.validateFunding(
          trade,
          sourceHeight: await wallet.fetchChainHeight(),
        );
        return await wallet.confirmSend(
          txData: txData,
          onBroadcast: onBroadcast,
        );
      }
      final ethereum = wallet as EthereumWallet;
      if (ethereum.prefs.useTor) {
        throw StateError('Ethereum bridge funding is unavailable over Tor.');
      }
      final tx = txData.web3dartTransaction;
      final expected = RosenProtocol.transferData(
        lockAddress: RosenApi.ethereumLockAddress,
        amount: amount,
        metadata: metadata,
      );
      if (tx == null ||
          txData.chainId != BigInt.one ||
          tx.to?.with0x.toLowerCase() != RosenApi.rsFiroContract ||
          (tx.value?.getInWei ?? BigInt.zero) != BigInt.zero ||
          RosenProtocol.hex(tx.data ?? []) != expected) {
        throw StateError('Invalid rsFIRO bridge transaction.');
      }
      final client = ethereum.getEthClient();
      try {
        if (await client.getChainId() != BigInt.one) {
          throw StateError('The Ethereum node must use mainnet.');
        }
        await RosenExchange.validateFunding(
          trade,
          sourceHeight: await client.getBlockNumber(),
        );
        if (tx.nonce !=
            await client.getTransactionCount(
              await ethereum.getMyWeb3Address(),
              atBlock: const web3.BlockNum.pending(),
            )) {
          throw StateError(
            'The wallet nonce changed. Prepare this swap again.',
          );
        }
      } finally {
        await client.dispose();
      }
      // Record token history, including the contract, instead of an ETH payment.
      final tokenWallet = Wallet.loadTokenWallet(
        ethWallet: ethereum,
        contract: _tokenFor(wallet),
      ) as EthTokenWallet;
      return await tokenWallet.confirmSend(
        txData: txData,
        onBroadcast: onBroadcast,
      );
    } catch (e, s) {
      if (broadcastTxid == null) rethrow;
      Logging.instance.e(
        'Rosen transaction $broadcastTxid was broadcast; local wallet update failed',
        error: e,
        stackTrace: s,
      );
      return txData.copyWith(txid: broadcastTxid, txHash: broadcastTxid);
    } finally {
      if (_funding[trade.uuid] == null) _funding.remove(trade.uuid);
    }
  }
}
