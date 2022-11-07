import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

import '../../../providers/global/prefs_provider.dart';
import '../../../utilities/constants.dart';
import '../../../widgets/custom_buttons/draggable_switch_button.dart';

class AppearanceOptionSettings extends ConsumerStatefulWidget {
  const AppearanceOptionSettings({Key? key}) : super(key: key);

  static const String routeName = "/settingsMenuAppearance";

  @override
  ConsumerState<AppearanceOptionSettings> createState() =>
      _AppearanceOptionSettings();
}

class _AppearanceOptionSettings
    extends ConsumerState<AppearanceOptionSettings> {
  // late bool isLight;

  // @override
  // void initState() {
  //
  //   super.initState();
  // }
  //
  // @override
  // void dispose() {
  //   super.dispose();
  // }

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  Assets.svg.circleSun,
                  width: 48,
                  height: 48,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: RichText(
                        textAlign: TextAlign.left,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Appearances",
                              style: STextStyles.desktopTextSmall(context),
                            ),
                            TextSpan(
                              text:
                                  "\n\nCustomize how your Stack Wallet looks according to your preferences.",
                              style: STextStyles.desktopTextExtraExtraSmall(
                                  context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Divider(
                    thickness: 0.5,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Display favorite wallets",
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
                                .select((value) => value.showFavoriteWallets),
                          ),
                          onValueChanged: (newValue) {
                            ref
                                .read(prefsChangeNotifierProvider)
                                .showFavoriteWallets = newValue;
                          },
                        ),
                      )
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Divider(
                    thickness: 0.5,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Choose theme",
                        style: STextStyles.desktopTextExtraSmall(context)
                            .copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textDark),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
                ThemeToggle(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ThemeToggle extends StatefulWidget {
  const ThemeToggle({
    Key? key,
  }) : super(key: key);

  // final bool externalCallsEnabled;
  // final void Function(bool)? onChanged;

  @override
  State<StatefulWidget> createState() => _ThemeToggle();
}

class _ThemeToggle extends State<ThemeToggle> {
  // late bool externalCallsEnabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: RawMaterialButton(
            elevation: 0,
            hoverColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color:
                    Theme.of(context).extension<StackColors>()!.infoItemIcons,
                width: 2,
              ),
              // side: !externalCallsEnabled
              //     ? BorderSide.none
              //     : BorderSide(
              //         color: Theme.of(context)
              //             .extension<StackColors>()!
              //             .infoItemIcons,
              //         width: 2,
              //       ),
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius * 2,
              ),
            ),
            onPressed: () {}, //onPressed
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 24,
                        ),
                        child: SvgPicture.asset(
                          Assets.svg.themeLight,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 50,
                          top: 12,
                        ),
                        child: Text(
                          "Light",
                          style: STextStyles.desktopTextExtraSmall(context)
                              .copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark,
                          ),
                        ),
                      )
                    ],
                  ),
                  // if (externalCallsEnabled)
                  Positioned(
                    bottom: 0,
                    left: 6,
                    child: SvgPicture.asset(
                      Assets.svg.checkCircle,
                      width: 20,
                      height: 20,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .infoItemIcons,
                    ),
                  ),
                  // if (!externalCallsEnabled)
                  //   Positioned(
                  //     bottom: 0,
                  //     left: 6,
                  //     child: Container(
                  //       width: 20,
                  //       height: 20,
                  //       decoration: BoxDecoration(
                  //         borderRadius: BorderRadius.circular(1000),
                  //         color: Theme.of(context)
                  //             .extension<StackColors>()!
                  //             .textFieldDefaultBG,
                  //       ),
                  //     ),
                  //   ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(
          width: 1,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: RawMaterialButton(
              elevation: 0,
              hoverColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                // side: !externalCallsEnabled
                //     ? BorderSide.none
                //     : BorderSide(
                //         color: Theme.of(context)
                //             .extension<StackColors>()!
                //             .infoItemIcons,
                //         width: 2,
                //       ),
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius * 2,
                ),
              ),
              onPressed: () {}, //onPressed
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SvgPicture.asset(
                          Assets.svg.themeDark,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 45,
                            top: 12,
                          ),
                          child: Text(
                            "Dark",
                            style: STextStyles.desktopTextExtraSmall(context)
                                .copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // if (externalCallsEnabled)
                    //   Positioned(
                    //     bottom: 0,
                    //     left: 0,
                    //     child: SvgPicture.asset(
                    //       Assets.svg.checkCircle,
                    //       width: 20,
                    //       height: 20,
                    //       color: Theme.of(context)
                    //           .extension<StackColors>()!
                    //           .infoItemIcons,
                    //     ),
                    //   ),
                    // if (!externalCallsEnabled)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1000),
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textFieldDefaultBG,
                        ),
                      ),
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
