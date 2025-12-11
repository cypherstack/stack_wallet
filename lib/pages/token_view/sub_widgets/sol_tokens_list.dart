/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2025 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../models/isar/models/solana/sol_contract.dart';
import '../../../providers/db/main_db_provider.dart';
import '../../../utilities/util.dart';
import 'sol_token_select_item.dart';

class SolanaTokensList extends StatelessWidget {
  const SolanaTokensList({
    super.key,
    required this.walletId,
    required this.searchTerm,
    required this.tokenMints,
  });

  final String walletId;
  final String searchTerm;
  final List<String> tokenMints;

  List<SolContract> _filter(String searchTerm, List<SolContract> allTokens) {
    if (tokenMints.isEmpty) {
      return [];
    }

    // Filter to only tokens in the wallet's token list.
    var filtered = allTokens
        .where((token) => tokenMints.contains(token.address))
        .toList();

    // Apply search filter if provided.
    if (searchTerm.isNotEmpty) {
      final term = searchTerm.toLowerCase();
      filtered = filtered
          .where(
            (token) =>
                token.name.toLowerCase().contains(term) ||
                token.symbol.toLowerCase().contains(term) ||
                token.address.toLowerCase().contains(term),
          )
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Util.isDesktop;

    return Consumer(
      builder: (_, ref, __) {
        // Get all available SOL tokens.
        final db = ref.watch(mainDBProvider);

        final allTokens = db.getSolContracts().findAllSync();

        final tokens = _filter(searchTerm, allTokens);

        if (tokens.isEmpty) {
          return Center(
            child: Text(
              "No tokens in this wallet",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        return ListView.builder(
          itemCount: tokens.length,
          itemBuilder: (ctx, index) {
            final token = tokens[index];
            return Padding(
              key: Key(token.address),
              padding: isDesktop
                  ? const EdgeInsets.symmetric(vertical: 5)
                  : const EdgeInsets.all(4),
              child: SolTokenSelectItem(walletId: walletId, token: token),
            );
          },
        );
      },
    );
  }
}
