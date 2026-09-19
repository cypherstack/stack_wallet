import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../wallet/impl/sub_wallets/solana_token_wallet.dart';

/// State provider for the currently active Solana token wallet.
/// 
/// This allows global tracking of which token wallet is being viewed/interacted-with.
final solanaTokenServiceStateProvider =
    StateProvider<SolanaTokenWallet?>((ref) => null);

/// Public provider to read the current active Solana token wallet.
/// 
/// Use this in UI widgets to get the active token wallet.
final pCurrentSolanaTokenWallet =
    Provider<SolanaTokenWallet?>((ref) => ref.watch(solanaTokenServiceStateProvider));
