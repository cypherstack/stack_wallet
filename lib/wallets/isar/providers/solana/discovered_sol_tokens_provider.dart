/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2025 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/isar/models/solana/sol_contract.dart';
import '../../../../providers/global/wallets_provider.dart';
import '../../../../services/solana/solana_token_api.dart';
import '../../../../utilities/logger.dart';
import '../../../../wallets/wallet/impl/solana_wallet.dart';

/// Discovers the SPL tokens held by a wallet and resolves their metadata.
///
/// Returns a list of [SolContract]s for the mints found in the wallet's token
/// accounts. Metadata is fetched per mint, falling back to placeholder values
/// when it cannot be resolved.
final pDiscoveredSolanaTokens = FutureProvider.autoDispose
    .family<List<SolContract>, ({String walletId, String walletAddress})>((
      ref,
      params,
    ) async {
      final wallet = ref.read(pWallets).getWallet(params.walletId);
      if (wallet is! SolanaWallet) {
        throw Exception("Wallet ${params.walletId} is not a Solana wallet");
      }

      final rpcClient = wallet.getRpcClient();
      if (rpcClient == null) {
        throw Exception("RPC client not available for ${params.walletId}");
      }

      final api = SolanaTokenAPI(rpcClient: rpcClient);

      final mintResponse = await api.discoverTokensForWallet(
        walletAddress: params.walletAddress,
      );

      if (!mintResponse.isSuccess || mintResponse.value == null) {
        throw mintResponse.exception ??
            Exception("Token discovery failed for ${params.walletId}");
      }

      final mints = mintResponse.value!;
      Logging.instance.i(
        "Discovered ${mints.length} SPL token mint(s) for ${params.walletId}",
      );

      final tokens = await resolveDiscoveredSolanaContracts(
        mints: mints,
        fetchMetadata: api.fetchTokenMetadataByMint,
      );

      final unresolved = mints.length - tokens.length;
      if (unresolved > 0) {
        Logging.instance.w(
          "Skipped $unresolved Solana token mint(s) with unknown decimals",
        );
      }

      return tokens;
    });

/// Await a [pDiscoveredSolanaTokens] run while holding a subscription to it.
///
/// The provider is autoDispose and nothing in the widget tree watches it, so
/// riverpod schedules the element for disposal as soon as it is read without
/// a listener. Disposal completes `.future` with a [StateError] instead of the
/// discovered tokens, and it always wins the race against an RPC round trip.
/// Closing the subscription once the run finishes lets the element be disposed
/// again, so the next visit rediscovers rather than replaying a cached list.
Future<List<SolContract>> readDiscoveredSolanaTokens(
  ProviderContainer container, {
  required String walletId,
  required String walletAddress,
}) async {
  final subscription = container.listen<Future<List<SolContract>>>(
    pDiscoveredSolanaTokens((
      walletId: walletId,
      walletAddress: walletAddress,
    )).future,
    (_, __) {},
  );
  try {
    return await subscription.read();
  } finally {
    subscription.close();
  }
}

Future<List<SolContract>> resolveDiscoveredSolanaContracts({
  required Iterable<DiscoveredSolMint> mints,
  required Future<SolanaTokenApiResponse<Map<String, dynamic>?>> Function(
    String mint,
  )
  fetchMetadata,
}) => Future.wait(
  mints.where((mint) => mint.decimals != null).map((discovered) async {
    final mint = discovered.mint;
    final metadata = (await fetchMetadata(mint)).value;
    return SolContract(
      address: mint,
      name: metadata?["name"] as String? ?? _placeholderName(mint),
      symbol: metadata?["symbol"] as String? ?? _placeholderSymbol(mint),
      decimals: discovered.decimals!,
      logoUri: metadata?["logoUri"] as String?,
    );
  }),
);

List<SolContract> newDiscoveredSolanaContracts({
  required Iterable<SolContract> knownContracts,
  required Iterable<SolContract> discoveredContracts,
}) {
  final knownMints = knownContracts.map((contract) => contract.address).toSet();
  return discoveredContracts
      .where((contract) => knownMints.add(contract.address))
      .toList();
}

/// Build a short, human readable placeholder name from a mint address when no
/// metadata could be resolved.
String _placeholderName(String mint) {
  if (mint.length <= 10) {
    return "Token $mint";
  }
  return "Token ${mint.substring(0, 4)}...${mint.substring(mint.length - 4)}";
}

/// Build a short placeholder symbol from a mint address when no metadata could
/// be resolved.
String _placeholderSymbol(String mint) {
  if (mint.length <= 4) {
    return mint.toUpperCase();
  }
  return mint.substring(0, 4).toUpperCase();
}
