import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/syncing_preferences_views/syncing_options_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/sync_type_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/draggable_switch_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class SyncingPreferencesView extends ConsumerWidget {
  const SyncingPreferencesView({Key? key}) : super(key: key);

  static const String routeName = "/syncingPreferences";

  String _currentTypeDescription(SyncingType type) {
    switch (type) {
      case SyncingType.currentWalletOnly:
        return "Sync only currently open wallet";
      case SyncingType.selectedWalletsAtStartup:
        return "Sync only selected wallets at startup";
      case SyncingType.allWalletsOnStartup:
        return "Sync all wallets at startup";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: CFColors.almostWhite,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "Syncing preferences",
          style: STextStyles.navBarTitle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RoundedWhiteContainer(
                        padding: const EdgeInsets.all(0),
                        child: RawMaterialButton(
                          // splashColor: CFColors.splashLight,
                          padding: const EdgeInsets.all(0),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Constants.size.circularBorderRadius,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context)
                                .pushNamed(SyncingOptionsView.routeName);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Syncing",
                                      style: STextStyles.titleBold12,
                                      textAlign: TextAlign.left,
                                    ),
                                    Text(
                                      _currentTypeDescription(ref.watch(
                                          prefsChangeNotifierProvider.select(
                                              (value) => value.syncType))),
                                      style: STextStyles.itemSubtitle,
                                      textAlign: TextAlign.left,
                                    )
                                  ],
                                ),
                                const Spacer(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      RoundedWhiteContainer(
                        child: Consumer(
                          builder: (_, ref, __) {
                            return RawMaterialButton(
                              // splashColor: CFColors.splashLight,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Constants.size.circularBorderRadius,
                                ),
                              ),
                              onPressed: null,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "AutoSync only on Wi-Fi",
                                      style: STextStyles.titleBold12,
                                      textAlign: TextAlign.left,
                                    ),
                                    SizedBox(
                                      height: 20,
                                      width: 40,
                                      child: DraggableSwitchButton(
                                        isOn: ref.watch(
                                          prefsChangeNotifierProvider.select(
                                              (value) => value.wifiOnly),
                                        ),
                                        onValueChanged: (newValue) {
                                          ref
                                              .read(prefsChangeNotifierProvider)
                                              .wifiOnly = newValue;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
