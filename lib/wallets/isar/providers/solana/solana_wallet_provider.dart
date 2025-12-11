import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../wallet/impl/solana_wallet.dart';
import '../../../../providers/global/wallets_provider.dart';

/// Provider that returns a Solana wallet by ID, or null if the wallet is not a SolanaWallet.
///
/// This provides type-safe access to Solana wallets without needing runtime type checks
/// in every view. If you need to get a Solana wallet, use this provider instead of
/// manually checking the type of the wallet returned by pWallets.
///
/// Example:
/// ```dart
/// final solanaWallet = ref.read(pSolanaWallet(walletId));
/// if (solanaWallet == null) {
///   // Handle error: wallet is not a Solana wallet
///   return;
/// }
/// // Use solanaWallet safely, knowing it's definitely a SolanaWallet
/// ```
final pSolanaWallet = Provider.family<SolanaWallet?, String>((ref, walletId) {
  final wallets = ref.watch(pWallets);
  final wallet = wallets.getWallet(walletId);

  return wallet is SolanaWallet ? wallet : null;
});
