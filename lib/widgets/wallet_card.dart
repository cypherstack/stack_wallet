import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/token_view/token_view.dart';
import 'package:stackwallet/pages/wallet_view/wallet_view.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/ethereum/ethereum_wallet.dart';
import 'package:stackwallet/services/ethereum/ethereum_token_service.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/show_loading.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/wallet_info_row/wallet_info_row.dart';
import 'package:tuple/tuple.dart';

class WalletSheetCard extends ConsumerWidget {
  const WalletSheetCard({
    Key? key,
    required this.walletId,
    this.contractAddress,
    this.popPrevious = false,
  }) : super(key: key);

  final String walletId;
  final String? contractAddress;
  final bool popPrevious;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(0),
      child: MaterialButton(
        // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
        key: Key("walletsSheetItemButtonKey_$walletId"),
        padding: const EdgeInsets.all(5),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
        ),
        onPressed: () async {
          final nav = Navigator.of(context);

          final manager =
              ref.read(walletsChangeNotifierProvider).getManager(walletId);
          if (manager.coin == Coin.monero || manager.coin == Coin.wownero) {
            await manager.initializeExisting();
          }
          if (context.mounted) {
            if (popPrevious) nav.pop();
            unawaited(
              nav.pushNamed(
                WalletView.routeName,
                arguments: Tuple2(
                    walletId,
                    ref
                        .read(walletsChangeNotifierProvider)
                        .getManagerProvider(walletId)),
              ),
            );

            if (contractAddress != null) {
              final contract = ref
                  .read(mainDBProvider)
                  .getEthContractSync(contractAddress!)!;
              ref.read(tokenServiceStateProvider.state).state = EthTokenWallet(
                token: contract,
                secureStore: ref.read(secureStoreProvider),
                ethWallet: manager.wallet as EthereumWallet,
                tracker: TransactionNotificationTracker(
                  walletId: walletId,
                ),
              );

              await showLoading<void>(
                whileFuture: ref.read(tokenServiceProvider)!.initialize(),
                context: context,
                opaqueBG: true,
                message: "Loading ${contract.name}",
              );

              // pop loading
              nav.pop();

              // if (context.mounted) {
              await nav.pushNamed(
                TokenView.routeName,
                arguments: walletId,
              );
              // }
            }
          }
        },
        child: WalletInfoRow(
          walletId: walletId,
          contractAddress: contractAddress,
        ),
      ),
    );
  }
}
