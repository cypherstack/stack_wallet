import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/services/event_bus/events/global/updated_in_background_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/bitcoin.dart';
import 'package:stackwallet/wallets/wallet/bip39_hd_wallet.dart';
import 'package:stackwallet/wallets/wallet/mixins/electrumx_mixin.dart';
import 'package:tuple/tuple.dart';

class BitcoinWallet extends Bip39HDWallet with ElectrumXMixin {
  BitcoinWallet(
    super.cryptoCurrency, {
    required NodeService nodeService,
    required Prefs prefs,
  }) {
    // TODO: [prio=low] ensure this hack isn't needed
    assert(cryptoCurrency is Bitcoin);

    this.prefs = prefs;
    this.nodeService = nodeService;
  }

  // ===========================================================================

  Future<List<Address>> _fetchAllOwnAddresses() async {
    final allAddresses = await mainDB
        .getAddresses(walletId)
        .filter()
        .not()
        .group(
          (q) => q
              .typeEqualTo(AddressType.nonWallet)
              .or()
              .subTypeEqualTo(AddressSubType.nonWallet),
        )
        .findAll();
    return allAddresses;
  }

  // ===========================================================================

  @override
  Future<void> refresh() {
    // TODO: implement refresh
    throw UnimplementedError();
  }

  @override
  Future<void> updateBalance() {
    // TODO: implement updateBalance
    throw UnimplementedError();
  }

  @override
  Future<void> updateTransactions() async {
    final currentChainHeight = await fetchChainHeight();

    final data = await fetchTransactions(
      addresses: await _fetchAllOwnAddresses(),
      currentChainHeight: currentChainHeight,
    );

    await mainDB.addNewTransactionData(
      data
          .map(
            (e) => Tuple2(
              e.transaction,
              e.address,
            ),
          )
          .toList(),
      walletId,
    );

    // TODO: [prio=med] get rid of this and watch isar instead
    // quick hack to notify manager to call notifyListeners if
    // transactions changed
    if (data.isNotEmpty) {
      GlobalEventBus.instance.fire(
        UpdatedInBackgroundEvent(
          "Transactions updated/added for: $walletId ${walletInfo.name}",
          walletId,
        ),
      );
    }
  }

  @override
  Future<void> updateUTXOs() {
    // TODO: implement updateUTXOs
    throw UnimplementedError();
  }
}
