import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages_desktop_specific/home/my_stack_view/wallet_view/sub_widgets/desktop_delete_wallet_dialog.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

class DeleteWalletButton extends ConsumerStatefulWidget {
  const DeleteWalletButton({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  @override
  ConsumerState<DeleteWalletButton> createState() => _DeleteWalletButton();
}

class _DeleteWalletButton extends ConsumerState<DeleteWalletButton> {
  late final String walletId;

  @override
  void initState() {
    walletId = widget.walletId;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(1000),
      ),
      onPressed: () async {
        final shouldOpenDeleteDialog = await showDialog<bool?>(
          context: context,
          barrierColor: Colors.transparent,
          builder: (context) {
            return DeletePopupButton(
              onTap: () async {
                Navigator.of(context).pop(true);
              },
            );
          },
        );

        if (shouldOpenDeleteDialog == true) {
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
            if (mounted) {
              Navigator.of(context).pop();
            }
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

class DeletePopupButton extends StatefulWidget {
  const DeletePopupButton({
    Key? key,
    this.onTap,
  }) : super(key: key);

  final VoidCallback? onTap;

  @override
  State<DeletePopupButton> createState() => _DeletePopupButtonState();
}

class _DeletePopupButtonState extends State<DeletePopupButton> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 24,
          left: MediaQuery.of(context).size.width - 234,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: 210,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius * 2,
                  ),
                  color: Theme.of(context).extension<StackColors>()!.popupBG,
                  boxShadow: [
                    Theme.of(context)
                        .extension<StackColors>()!
                        .standardBoxShadow,
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(width: 24),
                    SvgPicture.asset(
                      Assets.svg.trash,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      "Delete wallet",
                      style: STextStyles.desktopTextExtraExtraSmall(context)
                          .copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textDark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
