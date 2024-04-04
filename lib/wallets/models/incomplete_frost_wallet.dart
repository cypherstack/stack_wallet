import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/wallets/isar/models/frost_wallet_info.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_frost_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

class IncompleteFrostWallet {
  WalletInfo? info;

  String? get walletId => info?.walletId;

  Future<BitcoinFrostWallet> toBitcoinFrostWallet({
    required MainDB mainDB,
    required SecureStorageInterface secureStorageInterface,
    required NodeService nodeService,
    required Prefs prefs,
  }) async {
    final wallet = await Wallet.create(
      walletInfo: info!,
      mainDB: mainDB,
      secureStorageInterface: secureStorageInterface,
      nodeService: nodeService,
      prefs: prefs,
    );

    // dummy entry so updaters work when `wallet.updateWithResharedData` is called
    final frostInfo = FrostWalletInfo(
      walletId: info!.walletId,
      knownSalts: [],
      participants: [],
      myName: "",
      threshold: -1,
    );

    await mainDB.isar.frostWalletInfo.put(frostInfo);

    return wallet as BitcoinFrostWallet;
  }
}
