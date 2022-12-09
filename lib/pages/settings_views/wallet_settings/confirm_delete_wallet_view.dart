import 'dart:async';

import 'package:epicpay/pages/add_wallet_views/create_restore_wallet_view.dart';
import 'package:epicpay/pages/settings_views/wallet_settings/wallet_settings_view.dart';
import 'package:epicpay/providers/global/prefs_provider.dart';
import 'package:epicpay/providers/global/wallet_provider.dart';
import 'package:epicpay/providers/global/wallets_service_provider.dart';
import 'package:epicpay/utilities/assets.dart';
import 'package:epicpay/utilities/flutter_secure_storage_interface.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/widgets/background.dart';
import 'package:epicpay/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicpay/widgets/desktop/primary_button.dart';
import 'package:epicpay/widgets/desktop/secondary_button.dart';
import 'package:epicpay/widgets/fullscreen_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ConfirmWalletDeleteView extends ConsumerWidget {
  const ConfirmWalletDeleteView({
    Key? key,
    this.secureStorageInterface = const SecureStorageWrapper(
      FlutterSecureStorage(),
    ),
  }) : super(key: key);

  static const routeName = "/confirmDeleteWallet";

  final FlutterSecureStorageInterface secureStorageInterface;

  Future<void> _deleteWallet(BuildContext context, WidgetRef ref) async {
    final nav = Navigator.of(context);

    final controller = FullScreenMessageController();

    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) {
          return FullScreenMessage(
            icon: SvgPicture.asset(
              Assets.svg.circleCheck,
            ),
            message: "Your Epic Cash wallet\nhas been deleted",
            controller: controller,
          );
        },
      ),
    );

    final future1 = Future<void>.delayed(const Duration(seconds: 2));

    final future2 = ref
        .read(walletsServiceChangeNotifierProvider)
        .deleteWallet(ref.read(walletProvider)!.walletName, true);

    final future3 = secureStorageInterface.delete(key: "stack_pin");

    ref.read(prefsChangeNotifierProvider).hasPin = false;

    await Future.wait([
      future1,
      future2,
      future3,
    ]);

    controller.forcePop!.call();

    await nav.pushNamedAndRemoveUntil(
      CreateRestoreWalletView.routeName,
      (_) => false,
    );

    await ref.read(walletProvider)!.exitCurrentWallet();
    // wait for widget tree to dispose of any widgets watching the manager
    await Future<void>.delayed(const Duration(seconds: 1));
    ref.read(walletStateProvider.state).state = null;
  }

  Future<bool> back(BuildContext context) async {
    Navigator.of(context).popUntil(
      ModalRoute.withName(
        WalletSettingsView.routeName,
      ),
    );
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WillPopScope(
      onWillPop: () => back(context),
      child: Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: AppBarBackButton(
              onPressed: () => back(context),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    "There is not turning back after this. Are you sure you want to delete your wallet?",
                    style: STextStyles.titleH3(context),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  SecondaryButton(
                    label: "CANCEL",
                    onPressed: () => back(context),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  PrimaryButton(
                    label: "YES, DELETE WALLET",
                    onPressed: () {
                      _deleteWallet(context, ref);
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
