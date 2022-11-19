import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

import 'desktop_delete_wallet_dialog.dart';

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
    final managerProvider =
        ref.read(walletsChangeNotifierProvider).getManagerProvider(walletId);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(1000),
      ),
      onPressed: () {
        showDialog<void>(
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
                )
              ];
            },
          ),
        );
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
