import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/db/main_db_provider.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../wallets/isar/models/wallet_info.dart';
import '../../../../wallets/isar/providers/wallet_info_provider.dart';
import '../../../../widgets/background.dart';
import '../../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../../widgets/custom_buttons/draggable_switch_button.dart';

class RbfSettingsView extends ConsumerStatefulWidget {
  const RbfSettingsView({super.key, required this.walletId});

  static const String routeName = "/rbfSettings";

  final String walletId;

  @override
  ConsumerState<RbfSettingsView> createState() => _RbfSettingsViewState();
}

class _RbfSettingsViewState extends ConsumerState<RbfSettingsView> {
  bool _switchRbfToggledLock = false; // Mutex.
  Future<void> _switchRbfToggled(bool newValue) async {
    if (_switchRbfToggledLock) {
      return;
    }
    _switchRbfToggledLock = true; // Lock mutex.

    try {
      // Toggle enableOptInRbf in wallet info.
      await ref
          .read(pWalletInfo(widget.walletId))
          .updateOtherData(
            newEntries: {WalletInfoKeys.enableOptInRbf: newValue},
            isar: ref.read(mainDBProvider).isar,
          );
    } finally {
      // ensure _switchRbfToggledLock is set to false no matter what
      _switchRbfToggledLock = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text("RBF settings", style: STextStyles.navBarTitle(context)),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 3),
                    SizedBox(
                      height: 20,
                      width: 40,
                      child: DraggableSwitchButton(
                        isOn:
                            ref.watch(
                                  pWalletInfo(
                                    widget.walletId,
                                  ).select((value) => value.otherData),
                                )[WalletInfoKeys.enableOptInRbf]
                                as bool? ??
                            false,
                        onValueChanged: _switchRbfToggled,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Enable opt-in RBF",
                          style: STextStyles.w600_20(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
