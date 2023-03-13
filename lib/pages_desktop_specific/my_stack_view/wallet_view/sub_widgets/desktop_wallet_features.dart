import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/paynym/paynym_claim_view.dart';
import 'package:stackwallet/pages/paynym/paynym_home_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/more_features/more_features_dialog.dart';
import 'package:stackwallet/providers/global/paynym_api_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/providers/wallet/my_paynym_account_state_provider.dart';
import 'package:stackwallet/services/mixins/paynym_wallet_interface.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';

class DesktopWalletFeatures extends ConsumerWidget {
  const DesktopWalletFeatures({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  Future<void> onPaynymButtonPressed(
      BuildContext context, WidgetRef ref) async {
    unawaited(
      showDialog(
        context: context,
        builder: (context) => const LoadingIndicator(
          width: 100,
        ),
      ),
    );

    final manager =
        ref.read(walletsChangeNotifierProvider).getManager(walletId);

    final wallet = manager.wallet as PaynymWalletInterface;

    final code =
        await wallet.getPaymentCode(DerivePathTypeExt.primaryFor(manager.coin));

    final account = await ref.read(paynymAPIProvider).nym(code.toString());

    Logging.instance.log(
      "my nym account: $account",
      level: LogLevel.Info,
    );

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();

      // check if account exists and for matching code to see if claimed
      if (account.value != null && account.value!.codes.first.claimed) {
        ref.read(myPaynymAccountStateProvider.state).state = account.value!;

        await Navigator.of(context).pushNamed(
          PaynymHomeView.routeName,
          arguments: walletId,
        );
      } else {
        await Navigator.of(context).pushNamed(
          PaynymClaimView.routeName,
          arguments: walletId,
        );
      }
    }
  }

  Future<void> _onMorePressed(BuildContext context) async {
    await showDialog<void>(
        context: context,
        builder: (context) => MoreFeaturesDialog(walletId: walletId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(
      walletsChangeNotifierProvider.select(
        (value) => value.getManager(walletId),
      ),
    );

    final showMore = manager.hasPaynymSupport ||
        manager.hasCoinControlSupport ||
        manager.coin == Coin.firo ||
        manager.coin == Coin.firoTestNet ||
        manager.hasWhirlpoolSupport;

    return Row(
      children: [
        if (Constants.enableExchange)
          SecondaryButton(
            label: "Swap",
            width: 160,
            buttonHeight: ButtonHeight.l,
            icon: SvgPicture.asset(
              Assets.svg.arrowRotate,
              height: 20,
              width: 20,
              color: Theme.of(context)
                  .extension<StackColors>()!
                  .buttonTextSecondary,
            ),
            onPressed: () => onPaynymButtonPressed(context, ref),
          ),
        if (Constants.enableExchange)
          const SizedBox(
            width: 16,
          ),
        if (Constants.enableExchange)
          SecondaryButton(
            label: "Buy",
            width: 160,
            buttonHeight: ButtonHeight.l,
            icon: SvgPicture.asset(
              Assets.svg.buy(context),
              height: 20,
              width: 20,
              color: Theme.of(context)
                  .extension<StackColors>()!
                  .buttonTextSecondary,
            ),
            onPressed: () => onPaynymButtonPressed(context, ref),
          ),
        if (showMore)
          const SizedBox(
            width: 16,
          ),
        SecondaryButton(
          label: "More",
          width: 160,
          buttonHeight: ButtonHeight.l,
          icon: SvgPicture.asset(
            Assets.svg.iconFor(
              coin: ref.watch(
                walletsChangeNotifierProvider.select(
                  (value) => value.getManager(walletId).coin,
                ),
              ),
            ),
            height: 20,
            width: 20,
            color:
                Theme.of(context).extension<StackColors>()!.buttonTextSecondary,
          ),
          onPressed: () => _onMorePressed(context),
        ),
      ],
    );
  }
}
