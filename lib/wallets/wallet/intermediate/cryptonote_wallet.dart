import 'package:meta/meta.dart';

import '../../../models/input.dart';
import '../../../models/keys/cw_key_data.dart';
import '../../../wl_gen/interfaces/cs_monero_interface.dart'
    show CsOutput, CsPendingTransaction, CsRecipient;
import '../../../wl_gen/interfaces/cs_salvium_interface.dart';
import '../../crypto_currency/intermediate/cryptonote_currency.dart';
import '../wallet_mixin_interfaces/coin_control_interface.dart';
import '../wallet_mixin_interfaces/mnemonic_interface.dart';
import 'external_wallet.dart';

abstract class CryptonoteWallet<T extends CryptonoteCurrency>
    extends ExternalWallet<T>
    with MnemonicInterface<T>, CoinControlInterface<T> {
  CryptonoteWallet(super.currency);

  WrappedWallet? wallet;

  double highestPercentCached = 0;
  int currentKnownChainHeight = 0;

  @mustCallSuper
  @override
  Future<void> init({bool? isRestore, int? wordCount});

  Future<CWKeyData?> getKeys();

  Future<String> getTxKeyFor({required String txid});

  Future<(String, String)>
  hackToCreateNewViewOnlyWalletDataFromNewlyCreatedWalletThisFunctionShouldNotBeCalledUnlessYouKnowWhatYouAreDoing();

  void setRefreshFromBlockHeight(int newHeight);

  Future<int> getRefreshFromBlockHeight();

  Future<String> internalGetAddress({
    required int accountIndex,
    required int addressIndex,
  });

  Future<BigInt> internalGetUnlockedBalance({int accountIndex = 0});
  Future<List<CsOutput>> internalGetOutputs({
    bool refresh = false,
    bool includeSpent = false,
  });

  Future<CsPendingTransaction> internalCreateTx({
    required CsRecipient output,
    required int priority,
    required bool sweep,
    List<StandardInput>? preferredInputs,
    required int accountIndex,
    required int minConfirms,
    required int currentHeight,
  });

  Future<void> internalCommitTx(CsPendingTransaction tx);

  // tx prio forwarding
  int getTxPriorityHigh();
  int getTxPriorityMedium();
  int getTxPriorityNormal();
}
