import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/churning_service.dart';
import '../../wallets/wallet/intermediate/lib_monero_wallet.dart';
import '../global/wallets_provider.dart';

final pChurningService = ChangeNotifierProvider.family<ChurningService, String>(
  (ref, walletId) {
    final wallet = ref.watch(pWallets.select((s) => s.getWallet(walletId)));
    return ChurningService(wallet: wallet as LibMoneroWallet);
  },
);
