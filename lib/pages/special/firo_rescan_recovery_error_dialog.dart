import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/pages/pinpad_views/lock_screen_view.dart';
import 'package:stackwallet/pages/settings_views/wallet_settings_view/wallet_backup_views/wallet_backup_view.dart';
import 'package:stackwallet/pages/settings_views/wallet_settings_view/wallet_settings_wallet_settings/delete_wallet_warning_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_delete_wallet_dialog.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/unlock_wallet_keys_desktop.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:tuple/tuple.dart';

enum FiroRescanRecoveryErrorViewOption {
  retry,
  showMnemonic,
  deleteWallet;
}

class FiroRescanRecoveryErrorView extends ConsumerStatefulWidget {
  const FiroRescanRecoveryErrorView({
    super.key,
    required this.walletId,
  });

  static const String routeName = "/firoRescanRecoveryErrorView";

  final String walletId;

  @override
  ConsumerState<FiroRescanRecoveryErrorView> createState() =>
      _FiroRescanRecoveryErrorViewState();
}

class _FiroRescanRecoveryErrorViewState
    extends ConsumerState<FiroRescanRecoveryErrorView> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: ConditionalParent(
        condition: Util.isDesktop,
        builder: (child) {
          return DesktopScaffold(
            appBar: DesktopAppBar(
              background: Theme.of(context).extension<StackColors>()!.popupBG,
              isCompactHeight: true,
              // useSpacers: false,
              trailing: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CustomTextButton(
                  text: "Delete wallet",
                  onTap: () async {
                    final result = await showDialog<bool?>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => Navigator(
                        initialRoute: DesktopDeleteWalletDialog.routeName,
                        onGenerateRoute: RouteGenerator.generateRoute,
                        onGenerateInitialRoutes: (_, __) {
                          return [
                            RouteGenerator.generateRoute(
                              RouteSettings(
                                name: DesktopDeleteWalletDialog.routeName,
                                arguments: widget.walletId,
                              ),
                            ),
                          ];
                        },
                      ),
                    );

                    if (result == true) {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      }
                    }
                  },
                ),
              ),
            ),
            body: SizedBox(width: 328, child: child),
          );
        },
        child: ConditionalParent(
          condition: !Util.isDesktop,
          builder: (child) {
            return Background(
              child: Scaffold(
                backgroundColor:
                    Theme.of(context).extension<StackColors>()!.background,
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 10,
                        bottom: 10,
                        right: 10,
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: AppBarIconButton(
                          semanticsLabel: "Delete wallet button. "
                              "Start process of deleting current wallet.",
                          key: const Key("walletViewRadioButton"),
                          size: 36,
                          shadows: const [],
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .background,
                          icon: SvgPicture.asset(
                            Assets.svg.trash,
                            width: 20,
                            height: 20,
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .topNavIconPrimary,
                          ),
                          onPressed: () async {
                            await showDialog<void>(
                              barrierDismissible: true,
                              context: context,
                              builder: (_) => StackDialog(
                                title:
                                    "Do you want to delete ${ref.read(walletsChangeNotifierProvider).getManager(widget.walletId).walletName}?",
                                leftButton: TextButton(
                                  style: Theme.of(context)
                                      .extension<StackColors>()!
                                      .getSecondaryEnabledButtonStyle(context),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    "Cancel",
                                    style: STextStyles.button(context).copyWith(
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .accentColorDark),
                                  ),
                                ),
                                rightButton: TextButton(
                                  style: Theme.of(context)
                                      .extension<StackColors>()!
                                      .getPrimaryEnabledButtonStyle(context),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      RouteGenerator.getRoute(
                                        shouldUseMaterialRoute:
                                            RouteGenerator.useMaterialPageRoute,
                                        builder: (_) => LockscreenView(
                                          routeOnSuccessArguments:
                                              widget.walletId,
                                          showBackButton: true,
                                          routeOnSuccess:
                                              DeleteWalletWarningView.routeName,
                                          biometricsCancelButtonString:
                                              "CANCEL",
                                          biometricsLocalizedReason:
                                              "Authenticate to delete wallet",
                                          biometricsAuthenticationTitle:
                                              "Delete wallet",
                                        ),
                                        settings: const RouteSettings(
                                            name: "/deleteWalletLockscreen"),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Delete",
                                    style: STextStyles.button(context),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: child,
                ),
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!Util.isDesktop) const Spacer(),
              Text(
                "Failed to rescan firo wallet",
                style: STextStyles.pageTitleH2(context),
              ),
              Util.isDesktop
                  ? const SizedBox(
                      height: 60,
                    )
                  : const Spacer(),
              BranchedParent(
                condition: Util.isDesktop,
                conditionBranchBuilder: (children) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
                otherBranchBuilder: (children) => Row(
                  children: [
                    Expanded(child: children[0]),
                    children[1],
                    Expanded(child: children[2]),
                  ],
                ),
                children: [
                  SecondaryButton(
                    label: "Show mnemonic",
                    buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
                    onPressed: () async {
                      if (Util.isDesktop) {
                        await showDialog<void>(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => Navigator(
                            initialRoute: UnlockWalletKeysDesktop.routeName,
                            onGenerateRoute: RouteGenerator.generateRoute,
                            onGenerateInitialRoutes: (_, __) {
                              return [
                                RouteGenerator.generateRoute(
                                  RouteSettings(
                                    name: UnlockWalletKeysDesktop.routeName,
                                    arguments: widget.walletId,
                                  ),
                                )
                              ];
                            },
                          ),
                        );
                      } else {
                        final mnemonic = await ref
                            .read(walletsChangeNotifierProvider)
                            .getManager(widget.walletId)
                            .mnemonic;

                        if (mounted) {
                          await Navigator.push(
                            context,
                            RouteGenerator.getRoute(
                              shouldUseMaterialRoute:
                                  RouteGenerator.useMaterialPageRoute,
                              builder: (_) => LockscreenView(
                                routeOnSuccessArguments:
                                    Tuple2(widget.walletId, mnemonic),
                                showBackButton: true,
                                routeOnSuccess: WalletBackupView.routeName,
                                biometricsCancelButtonString: "CANCEL",
                                biometricsLocalizedReason:
                                    "Authenticate to view recovery phrase",
                                biometricsAuthenticationTitle:
                                    "View recovery phrase",
                              ),
                              settings: const RouteSettings(
                                  name: "/viewRecoverPhraseLockscreen"),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(
                    width: 16,
                    height: 16,
                  ),
                  PrimaryButton(
                    label: "Retry",
                    buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
                    onPressed: () {
                      Navigator.of(context).pop(
                        true,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
