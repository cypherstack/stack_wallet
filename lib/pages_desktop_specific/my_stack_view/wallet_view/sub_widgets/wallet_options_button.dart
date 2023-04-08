import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/xpub_view.dart';
import 'package:stackwallet/pages_desktop_specific/addresses/desktop_wallet_addresses_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_delete_wallet_dialog.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

enum _WalletOptions {
  addressList,
  deleteWallet,
  showXpub;

  String get prettyName {
    switch (this) {
      case _WalletOptions.addressList:
        return "Address list";
      case _WalletOptions.deleteWallet:
        return "Delete wallet";
      case _WalletOptions.showXpub:
        return "Show xPub";
    }
  }
}

class WalletOptionsButton extends StatelessWidget {
  const WalletOptionsButton({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      constraints: const BoxConstraints(
        minHeight: 32,
        minWidth: 32,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(1000),
      ),
      onPressed: () async {
        final func = await showDialog<_WalletOptions?>(
          context: context,
          barrierColor: Colors.transparent,
          builder: (context) {
            return WalletOptionsPopupMenu(
              onDeletePressed: () async {
                Navigator.of(context).pop(_WalletOptions.deleteWallet);
              },
              onAddressListPressed: () async {
                Navigator.of(context).pop(_WalletOptions.addressList);
              },
              onShowXpubPressed: () async {
                Navigator.of(context).pop(_WalletOptions.showXpub);
              },
              walletId: walletId,
            );
          },
        );

        if (context.mounted && func != null) {
          switch (func) {
            case _WalletOptions.addressList:
              unawaited(
                Navigator.of(context).pushNamed(
                  DesktopWalletAddressesView.routeName,
                  arguments: walletId,
                ),
              );
              break;
            case _WalletOptions.deleteWallet:
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
                          arguments: walletId,
                        ),
                      ),
                    ];
                  },
                ),
              );

              if (result == true) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
              break;
            case _WalletOptions.showXpub:
              final result = await showDialog<bool?>(
                context: context,
                barrierDismissible: false,
                builder: (context) => Navigator(
                  initialRoute: XPubView.routeName,
                  onGenerateRoute: RouteGenerator.generateRoute,
                  onGenerateInitialRoutes: (_, __) {
                    return [
                      RouteGenerator.generateRoute(
                        RouteSettings(
                          name: XPubView.routeName,
                          arguments: walletId,
                        ),
                      ),
                    ];
                  },
                ),
              );

              if (result == true) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
              break;
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 19,
          horizontal: 32,
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              Assets.svg.ellipsis,
              width: 20,
              height: 20,
              color: Theme.of(context)
                  .extension<StackColors>()!
                  .buttonTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class WalletOptionsPopupMenu extends ConsumerWidget {
  const WalletOptionsPopupMenu({
    Key? key,
    required this.onDeletePressed,
    required this.onAddressListPressed,
    required this.onShowXpubPressed,
    required this.walletId,
  }) : super(key: key);

  final VoidCallback onDeletePressed;
  final VoidCallback onAddressListPressed;
  final VoidCallback onShowXpubPressed;
  final String walletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool xpubEnabled = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(walletId).hasXPub));

    return Stack(
      children: [
        Positioned(
          top: 24,
          left: MediaQuery.of(context).size.width - 234,
          child: Container(
            width: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius * 2,
              ),
              color: Theme.of(context).extension<StackColors>()!.popupBG,
              boxShadow: [
                Theme.of(context).extension<StackColors>()!.standardBoxShadow,
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TransparentButton(
                    onPressed: onAddressListPressed,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SvgPicture.asset(
                            Assets.svg.list,
                            width: 20,
                            height: 20,
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textFieldActiveSearchIconLeft,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              _WalletOptions.addressList.prettyName,
                              style: STextStyles.desktopTextExtraExtraSmall(
                                      context)
                                  .copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (xpubEnabled)
                    const SizedBox(
                      height: 8,
                    ),
                  if (xpubEnabled)
                    TransparentButton(
                      onPressed: onShowXpubPressed,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SvgPicture.asset(
                              Assets.svg.eye,
                              width: 20,
                              height: 20,
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textFieldActiveSearchIconLeft,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _WalletOptions.showXpub.prettyName,
                                style: STextStyles.desktopTextExtraExtraSmall(
                                        context)
                                    .copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(
                    height: 8,
                  ),
                  TransparentButton(
                    onPressed: onDeletePressed,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SvgPicture.asset(
                            Assets.svg.trash,
                            width: 20,
                            height: 20,
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textFieldActiveSearchIconLeft,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              _WalletOptions.deleteWallet.prettyName,
                              style: STextStyles.desktopTextExtraExtraSmall(
                                      context)
                                  .copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TransparentButton extends StatelessWidget {
  const TransparentButton({
    Key? key,
    required this.child,
    this.onPressed,
  }) : super(key: key);

  final Widget child;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      constraints: const BoxConstraints(
        minHeight: 32,
        minWidth: 32,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          Constants.size.circularBorderRadius,
        ),
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}
