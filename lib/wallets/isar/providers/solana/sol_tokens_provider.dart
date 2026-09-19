/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2025 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a list of Solana token mint addresses for a specific wallet.
///
/// This provider returns the list of Solana token mint addresses
/// that the wallet has selected. Token details are not currently persisted
/// in the database - only the mint addresses are stored in WalletInfo's otherData.
///
/// Example usage:
/// ```
/// final tokenAddresses = ref.watch(pSolanaWalletTokenAddresses('wallet_id'));
/// ```
/// Note: For full token details (name, symbol, decimals), these would need to be
/// fetched from the Solana token metadata or a token list API.
final pSolanaWalletTokens = Provider.family<List<String>, String>(
  (ref, walletId) {
    // TODO: Implement token details fetching from Solana metadata or API.
    // For now, just return an empty list as token details are not persisted.
    return [];
  },
);
