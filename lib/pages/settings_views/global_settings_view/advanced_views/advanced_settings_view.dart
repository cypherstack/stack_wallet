import 'package:epicmobile/pages/settings_views/global_settings_view/advanced_views/debug_view.dart';
import 'package:epicmobile/providers/global/prefs_provider.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/custom_buttons/draggable_switch_button.dart';
import 'package:epicmobile/widgets/rounded_white_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdvancedSettingsView extends StatelessWidget {
  const AdvancedSettingsView({
    Key? key,
  }) : super(key: key);

  static const String routeName = "/advancedSettings";

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            "Advanced",
            style: STextStyles.titleH4(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RoundedWhiteContainer(
                padding: const EdgeInsets.all(0),
                child: RawMaterialButton(
                  // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamed(DebugView.routeName);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 20,
                    ),
                    child: Row(
                      children: [
                        Text(
                          "Debug info",
                          style: STextStyles.bodyBold(context),
                          textAlign: TextAlign.left,
                        ),
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
                      // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          Constants.size.circularBorderRadius,
                        ),
                      ),
                      onPressed: null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Toggle testnet coins",
                              style: STextStyles.bodyBold(context),
                              textAlign: TextAlign.left,
                            ),
                            SizedBox(
                              height: 20,
                              width: 40,
                              child: DraggableSwitchButton(
                                isOn: ref.watch(
                                  prefsChangeNotifierProvider.select(
                                      (value) => value.showTestNetCoins),
                                ),
                                onValueChanged: (newValue) {
                                  ref
                                      .read(prefsChangeNotifierProvider)
                                      .showTestNetCoins = newValue;
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
              const SizedBox(
                height: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
