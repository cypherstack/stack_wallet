import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app_config.dart';
import '../../../../models/keys/view_only_wallet_data.dart';
import '../../../../pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/delete_wallet_keys_popup.dart';
import '../../../../providers/global/secure_store_provider.dart';
import '../../../../providers/global/wallets_provider.dart';
import '../../../../route_generator.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../utilities/util.dart';
import '../../../../wallets/isar/providers/wallet_info_provider.dart';
import '../../../../widgets/conditional_parent.dart';
import '../../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../../widgets/desktop/primary_button.dart';
import '../../../../widgets/rounded_white_container.dart';
import '../../../../widgets/stack_dialog.dart';
import '../../../home_view/home_view.dart';
import '../../sub_widgets/view_only_wallet_data_widget.dart';

class DeleteViewOnlyWalletKeysView extends ConsumerStatefulWidget {
  const DeleteViewOnlyWalletKeysView({
    super.key,
    required this.walletId,
    required this.data,
  });

  static const routeName = "/deleteWalletViewOnlyData";

  final String walletId;
  final ViewOnlyWalletData data;

  @override
  ConsumerState<DeleteViewOnlyWalletKeysView> createState() =>
      _DeleteViewOnlyWalletKeysViewState();
}

class _DeleteViewOnlyWalletKeysViewState
    extends ConsumerState<DeleteViewOnlyWalletKeysView> {
  bool _lock = false;
  void _continuePressed() async {
    if (_lock) {
      return;
    }
    _lock = true;
    try {
      if (Util.isDesktop) {
        await Navigator.of(context).push(
          RouteGenerator.getRoute(
            builder: (context) {
              return ConfirmDelete(
                walletId: widget.walletId,
              );
            },
            settings: const RouteSettings(
              name: "/desktopConfirmDelete",
            ),
          ),
        );
      } else {
        await showDialog<dynamic>(
          barrierDismissible: true,
          context: context,
          builder: (_) => StackDialog(
            title: "Thanks! Your wallet will be deleted.",
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
                      .accentColorDark,
                ),
              ),
            ),
            rightButton: TextButton(
              style: Theme.of(context)
                  .extension<StackColors>()!
                  .getPrimaryEnabledButtonStyle(context),
              onPressed: () async {
                await ref.read(pWallets).deleteWallet(
                      ref.read(pWalletInfo(widget.walletId)),
                      ref.read(secureStoreProvider),
                    );

                if (mounted) {
                  Navigator.of(context).popUntil(
                    ModalRoute.withName(HomeView.routeName),
                  );
                }
              },
              child: Text(
                "Ok",
                style: STextStyles.button(context),
              ),
            ),
          ),
        );
      }
    } finally {
      _lock = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: !Util.isDesktop,
      builder: (child) => Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, cons) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: cons.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: child,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RoundedWhiteContainer(
            child: Text(
              "Please write down your backup data. Keep it safe and "
              "never share it with anyone. "
              "Your backup data is the only way you can access your "
              "wallet if you forget your PIN, lose your phone, etc."
              "\n\n"
              "${AppConfig.appName} does not keep nor is able to restore "
              "your backup data. "
              "Only you have access to your wallet.",
              style: STextStyles.label(context),
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          ViewOnlyWalletDataWidget(
            data: widget.data,
          ),
          if (!Util.isDesktop) const Spacer(),
          const SizedBox(
            height: 16,
          ),
          PrimaryButton(
            label: "Continue",
            onPressed: _continuePressed,
          ),
        ],
      ),
    );
  }
}
