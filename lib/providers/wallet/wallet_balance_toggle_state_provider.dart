import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicmobile/utilities/enums/wallet_balance_toggle_state.dart';

final walletBalanceToggleStateProvider =
    StateProvider.autoDispose<WalletBalanceToggleState>(
        (ref) => WalletBalanceToggleState.full);
