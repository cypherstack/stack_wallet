import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/desktop_wallet_view.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/coins/firo/firo_wallet.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_loading_overlay.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

class MoreFeaturesDialog extends ConsumerWidget {
  const MoreFeaturesDialog({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  Future<void> _onAnonymizeAllPressed(
      BuildContext context, WidgetRef ref,) async {
    Navigator.of(context, rootNavigator: true).pop();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DesktopDialog(
        maxWidth: 500,
        maxHeight: 210,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Column(
            children: [
              Text(
                "Attention!",
                style: STextStyles.desktopH2(context),
              ),
              const SizedBox(height: 16),
              Text(
                "You're about to anonymize all of your public funds.",
                style: STextStyles.desktopTextSmall(context),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SecondaryButton(
                    width: 200,
                    buttonHeight: ButtonHeight.l,
                    label: "Cancel",
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 20),
                  PrimaryButton(
                    width: 200,
                    buttonHeight: ButtonHeight.l,
                    label: "Continue",
                    onPressed: () {
                      Navigator.of(context).pop();

                      unawaited(
                        _attemptAnonymize(context, ref),
                      );
                    },
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _attemptAnonymize(BuildContext context, WidgetRef ref) async {
    final managerProvider =
        ref.read(walletsChangeNotifierProvider).getManagerProvider(walletId);

    bool shouldPop = false;
    unawaited(
      showDialog(
        context: context,
        builder: (context) => WillPopScope(
          child: const CustomLoadingOverlay(
            message: "Anonymizing balance",
            eventBus: null,
          ),
          onWillPop: () async => shouldPop,
        ),
      ),
    );
    final firoWallet = ref.read(managerProvider).wallet as FiroWallet;

    final publicBalance = firoWallet.availablePublicBalance();
    if (publicBalance <= Decimal.zero) {
      shouldPop = true;
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.of(context).popUntil(
          ModalRoute.withName(DesktopWalletView.routeName),
        );
        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.info,
            message: "No funds available to anonymize!",
            context: context,
          ),
        );
      }
      return;
    }

    try {
      await firoWallet.anonymizeAllPublicFunds();
      shouldPop = true;
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.of(context).popUntil(
          ModalRoute.withName(DesktopWalletView.routeName),
        );
        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.success,
            message: "Anonymize transaction submitted",
            context: context,
          ),
        );
      }
    } catch (e) {
      shouldPop = true;
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.of(context).popUntil(
          ModalRoute.withName(DesktopWalletView.routeName),
        );
        await showDialog<dynamic>(
          context: context,
          builder: (_) => DesktopDialog(
            maxWidth: 400,
            maxHeight: 300,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Anonymize all failed",
                    style: STextStyles.desktopH3(context),
                  ),
                  const Spacer(
                    flex: 1,
                  ),
                  Text(
                    "Reason: $e",
                    style: STextStyles.desktopTextSmall(context),
                  ),
                  const Spacer(
                    flex: 2,
                  ),
                  Row(
                    children: [
                      const Spacer(),
                      const SizedBox(
                        width: 16,
                      ),
                      Expanded(
                        child: PrimaryButton(
                          label: "Ok",
                          buttonHeight: ButtonHeight.l,
                          onPressed:
                              Navigator.of(context, rootNavigator: true).pop,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      }
    }
  }

  void _onWhirlpoolPressed(
      BuildContext context, WidgetRef ref,) {
    Navigator.of(context, rootNavigator: true).pop();}
  void _onCoinControlPressed(
      BuildContext context, WidgetRef ref,) {
    Navigator.of(context, rootNavigator: true).pop();}
  void _onPaynymPressed(
      BuildContext context, WidgetRef ref,) {
    Navigator.of(context, rootNavigator: true).pop();}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(
      walletsChangeNotifierProvider.select(
        (value) => value.getManager(walletId),
      ),
    );

    return DesktopDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 32,
                ),
                child: Text(
                  "More features",
                  style: STextStyles.desktopH3(context),
                ),
              ),
              const DesktopDialogCloseButton(),
            ],
          ),
          if (manager.coin == Coin.firo || manager.coin == Coin.firoTestNet)
            _MoreFeaturesItem(
              label: "Anonymize funds",
              detail: "Anonymize funds",
              iconAsset: Assets.svg.anonymize,
              onPressed: () => _onAnonymizeAllPressed(context, ref),
            ),
          if (manager.hasWhirlpoolSupport)
            _MoreFeaturesItem(
              label: "Whirlpool",
              detail: "Powerful Bitcoin privacy enhancer",
              iconAsset: Assets.svg.whirlPool,
              onPressed:  () =>_onWhirlpoolPressed(context, ref),
            ),
          if (manager.hasCoinControlSupport)
            _MoreFeaturesItem(
              label: "Coin control",
              detail: "Control, freeze, and utilize outputs at your discretion",
              iconAsset: Assets.svg.coinControl.gamePad,
              onPressed:  () =>_onCoinControlPressed(context, ref),
            ),
          if (manager.hasPaynymSupport)
            _MoreFeaturesItem(
              label: "PayNym",
              detail: "Increased address privacy using BIP47",
              iconAsset: Assets.svg.robotHead,
              onPressed: () => _onPaynymPressed(context, ref),
            ),
          const SizedBox(
            height: 28,
          ),
        ],
      ),
    );
  }
}

class _MoreFeaturesItem extends StatelessWidget {
  const _MoreFeaturesItem({
    Key? key,
    required this.label,
    required this.detail,
    required this.iconAsset,
    this.onPressed,
  }) : super(key: key);

  static const double iconSizeBG = 46;
  static const double iconSize = 26;

  final String label;
  final String detail;
  final String iconAsset;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 32,
      ),
      child: RoundedContainer(
        color: Colors.transparent,
        borderColor:
            Theme.of(context).extension<StackColors>()!.textFieldDefaultBG,
        onPressed: onPressed,
        child: Row(
          children: [
            RoundedContainer(
              padding: const EdgeInsets.all(0),
              color:
                  Theme.of(context).extension<StackColors>()!.settingsIconBack,
              width: iconSizeBG,
              height: iconSizeBG,
              radiusMultiplier: iconSizeBG,
              child: Center(
                child: SvgPicture.asset(
                  iconAsset,
                  width: iconSize,
                  height: iconSize,
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .settingsIconIcon,
                ),
              ),
            ),
            const SizedBox(
              width: 16,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: STextStyles.w600_20(context),
                ),
                Text(
                  detail,
                  style: STextStyles.desktopTextExtraExtraSmall(context),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
