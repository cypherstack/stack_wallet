import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
import 'package:stackwallet/pages/token_view/token_view.dart';
import 'package:stackwallet/pages/wallet_view/wallet_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/desktop_token_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/desktop_wallet_view.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/ethereum/ethereum_wallet.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/ethereum/ethereum_token_service.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/show_loading.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/wallet_info_row/wallet_info_row.dart';
import 'package:tuple/tuple.dart';

class SimpleWalletCard extends ConsumerWidget {
  const SimpleWalletCard({
    Key? key,
    required this.walletId,
    this.contractAddress,
    this.popPrevious = false,
    this.desktopNavigatorState,
  }) : super(key: key);

  final String walletId;
  final String? contractAddress;
  final bool popPrevious;
  final NavigatorState? desktopNavigatorState;

  Future<void> _loadTokenWallet(
    BuildContext context,
    WidgetRef ref,
    Manager manager,
    EthContract contract,
  ) async {
    ref.read(tokenServiceStateProvider.state).state = EthTokenWallet(
      token: contract,
      secureStore: ref.read(secureStoreProvider),
      ethWallet: manager.wallet as EthereumWallet,
      tracker: TransactionNotificationTracker(
        walletId: walletId,
      ),
    );

    await ref.read(tokenServiceProvider)!.initialize();
  }

  void _openWallet(BuildContext context, WidgetRef ref) async {
    final nav = Navigator.of(context);

    final manager =
        ref.read(walletsChangeNotifierProvider).getManager(walletId);
    if (manager.coin == Coin.monero || manager.coin == Coin.wownero) {
      await manager.initializeExisting();
    }
    if (context.mounted) {
      if (popPrevious) nav.pop();

      if (desktopNavigatorState != null) {
        unawaited(
          desktopNavigatorState!.pushNamed(
            DesktopWalletView.routeName,
            arguments: walletId,
          ),
        );
      } else {
        unawaited(
          nav.pushNamed(
            WalletView.routeName,
            arguments: Tuple2(
              walletId,
              ref
                  .read(walletsChangeNotifierProvider)
                  .getManagerProvider(walletId),
            ),
          ),
        );
      }

      if (contractAddress != null) {
        final contract =
            ref.read(mainDBProvider).getEthContractSync(contractAddress!)!;

        await showLoading<void>(
          whileFuture: _loadTokenWallet(context, ref, manager, contract),
          context: context,
          opaqueBG: true,
          message: "Loading ${contract.name}",
        );

        if (desktopNavigatorState == null) {
          // pop loading
          nav.pop();
        }

        if (desktopNavigatorState != null) {
          await desktopNavigatorState!.pushNamed(
            DesktopTokenView.routeName,
            arguments: walletId,
          );
        } else {
          await nav.pushNamed(
            TokenView.routeName,
            arguments: walletId,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConditionalParent(
      condition: !Util.isDesktop,
      builder: (child) => RoundedWhiteContainer(
        padding: const EdgeInsets.all(0),
        child: MaterialButton(
          // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
          key: Key("walletsSheetItemButtonKey_$walletId"),
          padding: const EdgeInsets.all(10),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
          ),
          onPressed: () => _openWallet(context, ref),
          child: child,
        ),
      ),
      child: WalletInfoRow(
        walletId: walletId,
        contractAddress: contractAddress,
        onPressedDesktop:
            Util.isDesktop ? () => _openWallet(context, ref) : null,
      ),
    );
  }
}
