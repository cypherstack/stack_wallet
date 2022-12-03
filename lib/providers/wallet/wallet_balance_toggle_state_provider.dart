import 'package:epicmobile/utilities/enums/wallet_balance_toggle_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final walletBalanceToggleStateProvider =
    StateProvider<WalletBalanceToggleState>(
        (ref) => WalletBalanceToggleState.locked);
