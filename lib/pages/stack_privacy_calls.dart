import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/pages/pinpad_views/create_pin_view.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class StackPrivacyCalls extends ConsumerStatefulWidget {
  const StackPrivacyCalls({
    Key? key,
    required this.isSettings,
  }) : super(key: key);

  final bool isSettings;

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
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 40, 0, 0),
              child: Column(
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
                  Center(
                    child: CustomRadio((bool isEasy) {
                      setState(() {
                        this.isEasy = isEasy;
                      });
                    }),
                  ),
                  const SizedBox(
                    height: 36,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: RoundedWhiteContainer(
                      child: Center(
                        child: RichText(
                          textAlign: TextAlign.left,
                          text: TextSpan(
                            style: STextStyles.label(context)
                                .copyWith(fontSize: 12.0),
                            children: isEasy
                                ? [
                                    const TextSpan(
                                        text:
                                            "Exchange data preloaded for a seamless experience."),
                                    const TextSpan(
                                        text:
                                            "\n\nCoinGecko enabled: (24 hour price change shown in-app, total wallet value shown in USD or other currency)."),
                                    TextSpan(
                                      text:
                                          "\n\nRecommended for most crypto users.",
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .textDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ]
                                : [
                                    const TextSpan(
                                        text:
                                            "Exchange data not preloaded (slower experience)."),
                                    const TextSpan(
                                        text:
                                            "\n\nCoinGecko disabled (price changes not shown, no wallet value shown in other currencies)."),
                                    TextSpan(
                                      text:
                                          "\n\nRecommended for the privacy conscious.",
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .textDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
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
                            isSettings: widget.isSettings,
                            isEasy: isEasy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContinueButton extends StatelessWidget {
  const ContinueButton(
      {Key? key,
      required this.isDesktop,
      required this.isSettings,
      required this.isEasy})
      : super(key: key);

  final bool isDesktop;
  final bool isSettings;
  final bool isEasy;

  @override
  Widget build(BuildContext context) {
    return !isDesktop
        ? TextButton(
            style: Theme.of(context)
                .extension<StackColors>()!
                .getPrimaryEnabledButtonColor(context),
            onPressed: () {
              print("Output of isEasy:");
              print(isEasy);

              DB.instance.put<dynamic>(
                boxName: DB.boxNamePrefs,
                key: "externalCalls",
                value: isEasy,
              );
              if (!isSettings) {
                Navigator.of(context).pushNamed(CreatePinView.routeName);
              }
            },
            child: Text(
              !isSettings ? "Continue" : "Save changes",
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
                print("Output of isEasy:");
                print(isEasy);

                DB.instance.put<dynamic>(
                  boxName: DB.boxNamePrefs,
                  key: "externalCalls",
                  value: isEasy,
                );

                if (!isSettings) {
                  Navigator.of(context).pushNamed(StackPrivacyCalls.routeName);
                }
              },
              child: Text(
                !isSettings ? "Continue" : "Save changes",
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
              width: 140,
              height: 140,
            ),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: STextStyles.label(context).copyWith(fontSize: 12.0),
                children: [
                  TextSpan(
                      text: _item.topText,
                      style: TextStyle(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textDark,
                          fontWeight: FontWeight.bold)),
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
