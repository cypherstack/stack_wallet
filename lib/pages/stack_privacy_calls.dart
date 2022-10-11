import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/pinpad_views/create_pin_view.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class StackPrivacyCalls extends ConsumerStatefulWidget {
  const StackPrivacyCalls({
    Key? key,
  }) : super(key: key);

  static const String routeName = "/stackPrivacy";

  @override
  ConsumerState<StackPrivacyCalls> createState() => _StackPrivacyCalls();
}

class _StackPrivacyCalls extends ConsumerState<StackPrivacyCalls> {
  late final bool isDesktop;
  bool isEasy = true;
  final PageController _pageController =
      PageController(initialPage: 0, keepPage: true);

  @override
  void initState() {
    isDesktop = Util.isDesktop;
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).extension<StackColors>()!.background,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Choose your Stack experience",
                  style: STextStyles.pageTitleH1(context),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  "You can change it later in Settings",
                  style: STextStyles.subtitle(context),
                ),
                const SizedBox(
                  height: 36,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: PrivacyToggle(),
                ),
                // Center(
                //   child: CustomRadio((bool isEasy) {
                //     setState(() {
                //       this.isEasy = isEasy;
                //
                //       DB.instance.put<dynamic>(
                //           boxName: DB.boxNamePrefs,
                //           key: "externalCalls",
                //           value: isEasy);
                //     });
                //   }),
                // ),
                const SizedBox(
                  height: 36,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: RoundedWhiteContainer(
                    child: Center(
                      child: RichText(
                        textAlign: TextAlign.left,
                        text: TextSpan(
                          style: STextStyles.label(context)
                              .copyWith(fontSize: 12.0),
                          children: isEasy
                              ? const [
                                  TextSpan(
                                      text:
                                          "Exchange data preloaded for a seamless experience."),
                                  TextSpan(
                                      text:
                                          "\n\nCoinGecko enabled: (24 hour price change shown in-app, total wallet value shown in USD or other currency)."),
                                  TextSpan(
                                      text:
                                          "\n\nRecommended for most crypto users.",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]
                              : const [
                                  TextSpan(
                                      text:
                                          "Exchange data not preloaded (slower experience)."),
                                  TextSpan(
                                      text:
                                          "\n\nCoinGecko disabled (price changes not shown, no wallet value shown in other currencies)."),
                                  TextSpan(
                                      text:
                                          "\n\nRecommended for the privacy conscious.",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(
                  flex: 4,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ContinueButton(
                          isDesktop: isDesktop,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PrivacyToggle extends ConsumerStatefulWidget {
  const PrivacyToggle({Key? key}) : super(key: key);

  @override
  ConsumerState<PrivacyToggle> createState() => _PrivacyToggleState();
}

class _PrivacyToggleState extends ConsumerState<PrivacyToggle> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RawMaterialButton(
            fillColor: Theme.of(context).extension<StackColors>()!.popupBG,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius * 2,
              ),
            ),
            onPressed: () {
              ref.read(prefsChangeNotifierProvider).externalCalls = true;
            },
            child: Padding(
              padding: const EdgeInsets.all(
                12,
              ),
              child: Column(
                children: [
                  SvgPicture.asset(
                    Assets.svg.personaEasy,
                    // color: Theme.of(context).extension<StackColors>()!.textWhite,
                    width: 96,
                    height: 96,
                  ),
                  const Text(
                    "Easy Crypto",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Recommended",
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(
          width: 16,
        ),
        Expanded(
          child: RawMaterialButton(
            elevation: 0,
            fillColor: Theme.of(context).extension<StackColors>()!.popupBG,
            shape: RoundedRectangleBorder(
              side: ref.watch(
                prefsChangeNotifierProvider.select(
                  (value) => value.externalCalls,
                ),
              )
                  ? BorderSide.none
                  : BorderSide(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .infoItemIcons,
                      width: 2,
                    ),
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius * 2,
              ),
            ),
            onPressed: () {
              ref.read(prefsChangeNotifierProvider).externalCalls = false;
            },
            child: Padding(
              padding: const EdgeInsets.all(
                12,
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SvgPicture.asset(
                        Assets.svg.personaIncognito,
                        width: 96,
                        height: 96,
                      ),
                      const Center(
                        child: Text(
                          "Incognito",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          "Privacy conscious",
                        ),
                      ),
                    ],
                  ),
                  if (!ref.watch(
                    prefsChangeNotifierProvider.select(
                      (value) => value.externalCalls,
                    ),
                  ))
                    Positioned(
                      top: 4,
                      right: 4,
                      child: SvgPicture.asset(
                        Assets.svg.checkCircle,
                        width: 20,
                        height: 20,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .infoItemIcons,
                      ),
                    ),
                  if (ref.watch(
                    prefsChangeNotifierProvider.select(
                      (value) => value.externalCalls,
                    ),
                  ))
                    Positioned(
                      top: 4,
                      right: 4,
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
      ],
    );
  }
}

class ContinueButton extends StatelessWidget {
  const ContinueButton({Key? key, required this.isDesktop}) : super(key: key);

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return !isDesktop
        ? TextButton(
            style: Theme.of(context)
                .extension<StackColors>()!
                .getPrimaryEnabledButtonColor(context),
            onPressed: () {
              Navigator.of(context).pushNamed(CreatePinView.routeName);
            },
            child: Text(
              "Continue",
              style: STextStyles.button(context),
            ),
          )
        : SizedBox(
            width: 328,
            height: 70,
            child: TextButton(
              style: Theme.of(context)
                  .extension<StackColors>()!
                  .getPrimaryEnabledButtonColor(context),
              onPressed: () {
                Navigator.of(context).pushNamed(StackPrivacyCalls.routeName);
              },
              child: Text(
                "Continue",
                style: STextStyles.button(context).copyWith(fontSize: 20),
              ),
            ),
          );
  }
}

class CustomRadio extends StatefulWidget {
  CustomRadio(this.upperCall, {Key? key}) : super(key: key);

  Function upperCall;

  @override
  createState() {
    return CustomRadioState();
  }
}

class CustomRadioState extends State<CustomRadio> {
  List<RadioModel> sampleData = <RadioModel>[];

  @override
  void initState() {
    super.initState();
    sampleData.add(
        RadioModel(true, Assets.svg.personaEasy, 'Easy Crypto', 'Recommended'));
    sampleData.add(RadioModel(
        false, Assets.svg.personaIncognito, 'Incognito', 'Privacy conscious'));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              // if (!sampleData[0].isSelected) {
              widget.upperCall.call(true);
              // }
              for (var element in sampleData) {
                element.isSelected = false;
              }
              sampleData[0].isSelected = true;
            });
          },
          child: RadioItem(sampleData[0]),
        ),
        InkWell(
          onTap: () {
            setState(() {
              // if (!sampleData[1].isSelected) {
              widget.upperCall.call(false);
              // }
              for (var element in sampleData) {
                element.isSelected = false;
              }
              sampleData[1].isSelected = true;
            });
          },
          child: RadioItem(sampleData[1]),
        )
      ],
    );
  }
}

class RadioItem extends StatelessWidget {
  final RadioModel _item;
  const RadioItem(this._item, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(15.0),
      child: RoundedWhiteContainer(
        borderColor: _item.isSelected ? const Color(0xFF0056D2) : null,
        child: Center(
            child: Column(
          children: [
            SvgPicture.asset(
              _item.svg,
              // color: Theme.of(context).extension<StackColors>()!.textWhite,
              width: 96,
              height: 96,
            ),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: STextStyles.label(context).copyWith(fontSize: 12.0),
                children: [
                  TextSpan(
                      text: _item.topText,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: "\n${_item.bottomText}"),
                ],
              ),
            ),
          ],
        )),
      ),
    );
  }
}

class RadioModel {
  bool isSelected;
  final String svg;
  final String topText;
  final String bottomText;

  RadioModel(this.isSelected, this.svg, this.topText, this.bottomText);
}
