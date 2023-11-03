import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';

class FavouriteWalletsWatcher extends ConsumerWidget {
  const FavouriteWalletsWatcher({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext, List<WalletInfo>) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialInfo = ref
        .watch(mainDBProvider)
        .isar
        .walletInfo
        .where()
        .filter()
        .isFavouriteEqualTo(true)
        .findAllSync();

    return StreamBuilder(
      stream: ref
          .watch(mainDBProvider)
          .isar
          .walletInfo
          .where()
          .filter()
          .isFavouriteEqualTo(true)
          .watch(),
      builder: (context, snapshot) {
        return builder(context, snapshot.data ?? initialInfo);
      },
    );
  }
}
