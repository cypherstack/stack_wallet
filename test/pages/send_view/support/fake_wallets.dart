import 'dart:async';

import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
import 'package:stackwallet/models/isar/models/solana/sol_contract.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/cryptonote_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/cardano_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/epiccash_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/ethereum_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/firo_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/monero_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/solana_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/stellar_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/sub_wallets/eth_token_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/sub_wallets/solana_token_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/wownero_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

/// A wallet answering what the send views read. It records the fee requests
/// and the prepared send.
abstract class FakeWallet<T extends CryptoCurrency> {
  FakeWallet(this.cryptoCurrency, [this.feeRates]);

  final T cryptoCurrency;

  /// Scaled by [feeRateFactor].
  FeeObject? feeRates;
  int feeRateFactor = 1;

  int feeEstimates = 0;
  final feeEstimateAmounts = <Amount>[];
  Object? feeError;
  int feeRateFetches = 0;
  int failingFeeRateFetches = 0;
  Completer<void>? holdFeeRateFetches;
  TxData? prepared;

  String get walletId => cryptoCurrency.identifier;

  late final WalletInfo info = TestWalletInfo(walletId, cryptoCurrency);

  bool get supportsMultiRecipient => false;

  bool get hasFunds => info.cachedBalance.spendable.raw > BigInt.zero;

  /// In the coin's smallest unit. The fee rate itself unless a fake overrides
  /// it.
  BigInt rawFee(Amount amount, BigInt feeRate) => feeRate;

  Future<FeeObject> get fees => recordFeeRateFetch(
    FeeObject(
      numberOfBlocksFast: feeRates!.numberOfBlocksFast,
      numberOfBlocksAverage: feeRates!.numberOfBlocksAverage,
      numberOfBlocksSlow: feeRates!.numberOfBlocksSlow,
      fast: feeRates!.fast * BigInt.from(feeRateFactor),
      medium: feeRates!.medium * BigInt.from(feeRateFactor),
      slow: feeRates!.slow * BigInt.from(feeRateFactor),
    ),
  );

  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) {
    feeEstimateAmounts.add(amount);
    return recordFeeEstimate(
      Amount(
        rawValue: rawFee(amount, feeRate),
        fractionDigits: cryptoCurrency.fractionDigits,
      ),
    );
  }

  Future<Amount> recordFeeEstimate(Amount fee) async {
    feeEstimates++;
    if (feeError != null) throw feeError!;
    return fee;
  }

  Future<R> recordFeeRateFetch<R>(R rates) async {
    final fails = ++feeRateFetches <= failingFeeRateFetches;
    await holdFeeRateFetches?.future;
    if (fails) throw Exception("node down");
    return rates;
  }

  Future<TxData> prepareSend({required TxData txData}) async {
    prepared = txData;
    return txData.copyWith(
      fee: Amount(
        rawValue: BigInt.from(1000),
        fractionDigits: cryptoCurrency.fractionDigits,
      ),
    );
  }

  Future<void> cancelSend({required TxData txData}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Rates in sats per kB, as the UTXO wallets give them.
final testFees = FeeObject(
  numberOfBlocksFast: 1,
  numberOfBlocksAverage: 3,
  numberOfBlocksSlow: 6,
  fast: BigInt.from(30000),
  medium: BigInt.from(20000),
  slow: BigInt.from(10000),
);

FeeObject _feeRates(int slow, int medium, int fast) => FeeObject(
  numberOfBlocksFast: 1,
  numberOfBlocksAverage: 1,
  numberOfBlocksSlow: 1,
  fast: BigInt.from(fast),
  medium: BigInt.from(medium),
  slow: BigInt.from(slow),
);

class TestWalletInfo extends WalletInfo {
  TestWalletInfo(String walletId, this._coin)
    : super(
        walletId: walletId,
        name: "${_coin.prettyName} test wallet",
        mainAddressType: _coin.defaultAddressType,
        coinName: _coin.identifier,
      );

  final CryptoCurrency _coin;

  // Desktop send takes its coin from the wallet info.
  @override
  CryptoCurrency get coin => _coin;

  Balance? balance;

  @override
  Balance get cachedBalance => balance ?? Balance.zeroFor(currency: _coin);
}

Balance testBalance(String spendable, int fractionDigits) {
  final amount = Amount.tryParseCanonicalAmount(
    spendable,
    fractionDigits: fractionDigits,
  )!;
  final zero = Amount.zeroWith(fractionDigits: fractionDigits);
  return Balance(
    total: amount,
    spendable: amount,
    blockedTotal: zero,
    pendingSpendable: zero,
  );
}

const btcAddress = "bc1qu58svs9983e2vuyqh7gq7ratf8k5qehz5k0cn5";
const firoAddress = "a6ESWKz7szru5syLtYAPRhHLdKvMq3Yt1j";
const firoExchangeAddress = "EXXMGtieRLNGfgewJ4jJCN4kZFTUcjYMDdHs";

class FakeBitcoinWallet extends FakeWallet<Bitcoin>
    implements BitcoinWallet<Bitcoin> {
  FakeBitcoinWallet() : super(Bitcoin(CryptoCurrencyNetwork.main), testFees);

  /// A 100-vbyte transaction.
  @override
  BigInt rawFee(Amount amount, BigInt feeRate) =>
      feeRate * BigInt.from(100) ~/ BigInt.from(1000);
}

final testEthFees = EthFeeObject(
  suggestBaseFee: BigInt.from(1000000000),
  numberOfBlocksFast: 1,
  numberOfBlocksAverage: 3,
  numberOfBlocksSlow: 6,
  fast: BigInt.from(3000000000),
  medium: BigInt.from(2000000000),
  slow: BigInt.from(1000000000),
);

final testEthContract = EthContract(
  address: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
  name: "Tether USD",
  symbol: "USDT",
  decimals: 6,
  type: EthContractType.erc20,
);

final testSolContract = SolContract(
  address: "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB",
  name: "Tether USD",
  symbol: "USDT",
  decimals: 6,
);

class FakeEthereumWallet extends FakeWallet<Ethereum>
    implements EthereumWallet {
  FakeEthereumWallet() : super(Ethereum(CryptoCurrencyNetwork.main));

  late final tokenWallet = FakeEthTokenWallet(this);

  @override
  Future<EthFeeObject> get fees => recordFeeRateFetch(testEthFees);

  /// A 21000-gas transfer.
  @override
  BigInt rawFee(Amount amount, BigInt feeRate) => BigInt.from(21000) * feeRate;
}

class FakeEthTokenWallet extends FakeWallet<Ethereum>
    implements EthTokenWallet {
  FakeEthTokenWallet(FakeEthereumWallet ethWallet)
    : super(ethWallet.cryptoCurrency);

  @override
  EthContract get tokenContract => testEthContract;

  @override
  Future<EthFeeObject> get fees => recordFeeRateFetch(testEthFees);

  /// A 65000-gas transfer.
  @override
  BigInt rawFee(Amount amount, BigInt feeRate) => BigInt.from(65000) * feeRate;
}

class FakeSolanaWallet extends FakeWallet<Solana> implements SolanaWallet {
  /// The fee of each priority, in lamports.
  FakeSolanaWallet()
    : super(Solana(CryptoCurrencyNetwork.main), _feeRates(10000, 15000, 20000));

  late final tokenWallet = FakeSolanaTokenWallet(this);

  @override
  BigInt rawFee(Amount amount, BigInt feeRate) =>
      hasFunds ? feeRate : BigInt.zero;
}

class FakeSolanaTokenWallet extends FakeWallet<Solana>
    implements SolanaTokenWallet {
  FakeSolanaTokenWallet(FakeSolanaWallet parentSolanaWallet)
    : super(parentSolanaWallet.cryptoCurrency);

  @override
  SolContract get solContract => testSolContract;

  @override
  String get tokenMint => testSolContract.address;

  @override
  String get tokenSymbol => testSolContract.symbol;

  @override
  int get tokenDecimals => testSolContract.decimals;
}

class FakeFiroWallet extends FakeWallet<Firo> implements FiroWallet<Firo> {
  FakeFiroWallet() : super(Firo(CryptoCurrencyNetwork.main), testFees);

  /// A 50-vbyte transaction.
  @override
  BigInt rawFee(Amount amount, BigInt feeRate) =>
      feeRate * BigInt.from(50) ~/ BigInt.from(1000);

  @override
  int estimateTxFee({required int vSize, required BigInt feeRatePerKB}) =>
      (feeRatePerKB * BigInt.from(vSize) ~/ BigInt.from(1000)).toInt();

  @override
  Future<Amount> estimateFeeForSpark(Amount amount) => recordFeeEstimate(
    Amount(
      rawValue: BigInt.from(amount.raw > BigInt.zero ? 2000 : 0),
      fractionDigits: 8,
    ),
  );
}

class FakeEpiccashWallet extends FakeWallet<Epiccash>
    implements EpiccashWallet {
  FakeEpiccashWallet() : super(Epiccash(CryptoCurrencyNetwork.main), testFees);
}

/// Monero checking only an address prefix, as tests lack its native library.
class TestMonero extends Monero {
  TestMonero() : super(CryptoCurrencyNetwork.main);

  @override
  bool validateAddress(String address) => address.startsWith("address");
}

abstract class FakeSyncDependentFeeWallet<T extends CryptonoteCurrency>
    extends FakeWallet<T>
    implements Wallet<CryptonoteCurrency> {
  /// Cryptonote wallets give their tx priorities as fee rates.
  FakeSyncDependentFeeWallet(T coin) : super(coin, _feeRates(1, 2, 3));

  // The send views of the test-first commit take the Average priority from
  // the wallet.
  int getTxPriorityMedium() => 2;

  /// The real wallet estimates a zero fee until it has synchronized.
  bool isSynced = true;

  bool get canEstimateFee => isSynced;

  @override
  BigInt rawFee(Amount amount, BigInt feeRate) =>
      isSynced && amount.raw > BigInt.zero
      ? feeRate * BigInt.from(10000000)
      : BigInt.zero;
}

class FakeMoneroWallet extends FakeSyncDependentFeeWallet<Monero>
    implements MoneroWallet {
  FakeMoneroWallet() : super(TestMonero());

  @override
  bool get supportsMultiRecipient => true;
}

class FakeWowneroWallet extends FakeSyncDependentFeeWallet<Wownero>
    implements WowneroWallet {
  FakeWowneroWallet() : super(Wownero(CryptoCurrencyNetwork.main));
}

// XelisWallet's fee estimate takes more parameters.
class FakeXelisWallet extends FakeWallet<Xelis> implements Wallet<Xelis> {
  FakeXelisWallet() : super(Xelis(CryptoCurrencyNetwork.main), testFees);
}

class FakeStellarWallet extends FakeWallet<Stellar> implements StellarWallet {
  /// The base fee at every rate, in stroops.
  FakeStellarWallet()
    : super(Stellar(CryptoCurrencyNetwork.main), _feeRates(100, 100, 100));
}

class FakeCardanoWallet extends FakeWallet<Cardano> implements CardanoWallet {
  /// The fee of a basic transaction at every rate, in lovelace.
  FakeCardanoWallet()
    : super(
        Cardano(CryptoCurrencyNetwork.main),
        _feeRates(170000, 170000, 170000),
      );

  @override
  BigInt rawFee(Amount amount, BigInt feeRate) =>
      hasFunds ? feeRate : BigInt.zero;
}
