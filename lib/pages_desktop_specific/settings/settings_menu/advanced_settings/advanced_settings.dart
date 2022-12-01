import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages_desktop_specific/settings/settings_menu/advanced_settings/debug_info_dialog.dart';
import 'package:stackwallet/pages_desktop_specific/settings/settings_menu/advanced_settings/stack_privacy_dialog.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/draggable_switch_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class AdvancedSettings extends ConsumerStatefulWidget {
  const AdvancedSettings({Key? key}) : super(key: key);

  static const String routeName = "/settingsMenuAdvanced";

  @override
  ConsumerState<AdvancedSettings> createState() => _AdvancedSettings();
}

class _AdvancedSettings extends ConsumerState<AdvancedSettings> {
  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            right: 30,
          ),
          child: RoundedWhiteContainer(
            radiusMultiplier: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SvgPicture.asset(
                    Assets.svg.circleSliders,
                    width: 48,
                    height: 48,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: RichText(
                        textAlign: TextAlign.start,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Advanced",
                              style: STextStyles.desktopTextSmall(context),
                            ),
                            TextSpan(
                              text:
                                  "\n\nConfigurate these settings only if you know what you are doing!",
                              style: STextStyles.desktopTextExtraExtraSmall(
                                  context),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Divider(
                        thickness: 0.5,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Toggle testnet coins",
                            style: STextStyles.desktopTextExtraSmall(context)
                                .copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textDark),
                            textAlign: TextAlign.left,
                          ),
                          SizedBox(
                            height: 20,
                            width: 40,
                            child: DraggableSwitchButton(
                              isOn: ref.watch(
                                prefsChangeNotifierProvider
                                    .select((value) => value.showTestNetCoins),
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
                    const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Divider(
                        thickness: 0.5,
                      ),
                    ),

                    /// TODO: Make a dialog popup
                    Consumer(builder: (_, ref, __) {
                      final externalCalls = ref.watch(
                        prefsChangeNotifierProvider
                            .select((value) => value.externalCalls),
                      );
                      return Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Stack Experience",
                                  style:
                                      STextStyles.desktopTextExtraSmall(context)
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .textDark),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  externalCalls ? "Easy crypto" : "Incognito",
                                  style: STextStyles.desktopTextExtraExtraSmall(
                                      context),
                                ),
                              ],
                            ),
                            PrimaryButton(
                              label: "Change",
                              buttonHeight: ButtonHeight.xs,
                              width: 86,
                              onPressed: () async {
                                await showDialog<dynamic>(
                                  context: context,
                                  useSafeArea: false,
                                  barrierDismissible: true,
                                  builder: (context) {
                                    return const StackPrivacyDialog();
                                  },
                                );
                              },
                            )
                          ],
                        ),
                      );
                    }),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Divider(
                    thickness: 0.5,
                  ),
                ),

                /// TODO: Make a dialog popup
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Debug info",
                        style: STextStyles.desktopTextExtraSmall(context)
                            .copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textDark),
                        textAlign: TextAlign.left,
                      ),
                      PrimaryButton(
                        buttonHeight: ButtonHeight.xs,
                        label: "Show logs",
                        width: 101,
                        onPressed: () async {
                          await showDialog<dynamic>(
                            context: context,
                            useSafeArea: false,
                            barrierDismissible: true,
                            builder: (context) {
                              return const DebugInfoDialog();
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
