import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/price_provider.dart';
import 'package:stackwallet/services/exchange/exchange_data_loading_service.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

import '../../../../providers/ui/color_theme_provider.dart';

class StackPrivacyDialog extends ConsumerStatefulWidget {
  const StackPrivacyDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<StackPrivacyDialog> createState() => _StackPrivacyDialog();
}

class _StackPrivacyDialog extends ConsumerState<StackPrivacyDialog> {
  late final bool isDesktop;
  late bool isEasy;
  late bool infoToggle;

  @override
  void initState() {
    isDesktop = Util.isDesktop;
    isEasy = ref.read(prefsChangeNotifierProvider).externalCalls;
    infoToggle = isEasy;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      maxHeight: 650,
      maxWidth: 600,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  "Choose Your Stack Experience",
                  style: STextStyles.desktopH3(context),
                  textAlign: TextAlign.center,
                ),
              ),
              const DesktopDialogCloseButton(),
            ],
          ),
          const SizedBox(
            height: 35,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: PrivacyToggle(
              externalCallsEnabled: isEasy,
              onChanged: (externalCalls) {
                isEasy = externalCalls;
                setState(() {
                  infoToggle = isEasy;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: RoundedWhiteContainer(
              borderColor: Theme.of(context)
                  .extension<StackColors>()!
                  .textFieldDefaultBG,
              child: Center(
                child: RichText(
                  textAlign: TextAlign.left,
                  text: TextSpan(
                    style: isDesktop
                        ? STextStyles.desktopTextExtraExtraSmall(context)
                        : STextStyles.label(context).copyWith(
                            fontSize: 12.0,
                          ),
                    children: infoToggle
                        ? [
                            const TextSpan(
                                text:
                                    "Exchange data preloaded for a seamless experience."),
                            const TextSpan(
                                text:
                                    "\n\nCoinGecko enabled: (24 hour price change shown in-app, total wallet value shown in USD or other currency)."),
                            TextSpan(
                              text: "\n\nRecommended for most crypto users.",
                              style: isDesktop
                                  ? STextStyles.desktopTextExtraExtraSmall600(
                                      context)
                                  : TextStyle(
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
                              style: isDesktop
                                  ? STextStyles.desktopTextExtraExtraSmall600(
                                      context)
                                  : TextStyle(
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
          // const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: "Cancel",
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: PrimaryButton(
                    label: "Save",
                    onPressed: () {
                      ref.read(prefsChangeNotifierProvider).externalCalls =
                          isEasy;

                      DB.instance
                          .put<dynamic>(
                              boxName: DB.boxNamePrefs,
                              key: "externalCalls",
                              value: isEasy)
                          .then((_) {
                        if (isEasy) {
                          unawaited(
                            ExchangeDataLoadingService.instance.loadAll(),
                          );
                          ref
                              .read(priceAnd24hChangeNotifierProvider)
                              .start(true);
                        }
                      });
                      if (isDesktop) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyToggle extends ConsumerStatefulWidget {
  const PrivacyToggle({
    Key? key,
    required this.externalCallsEnabled,
    this.onChanged,
  }) : super(key: key);

  final bool externalCallsEnabled;
  final void Function(bool)? onChanged;

  @override
  ConsumerState<PrivacyToggle> createState() => _PrivacyToggleState();
}

class _PrivacyToggleState extends ConsumerState<PrivacyToggle> {
  late bool externalCallsEnabled;

  late final bool isDesktop;
  late final bool isSorbet;
  late final bool isOcean;

  @override
  void initState() {
    isDesktop = Util.isDesktop;
    isSorbet = ref.read(colorThemeProvider.state).state.themeType ==
        ThemeType.fruitSorbet;
    isOcean = ref.read(colorThemeProvider.state).state.themeType ==
        ThemeType.oceanBreeze;
    // initial toggle state
    externalCallsEnabled = widget.externalCallsEnabled;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RawMaterialButton(
            elevation: 0,
            hoverElevation: 0,
            fillColor: Theme.of(context).extension<StackColors>()!.popupBG,
            shape: RoundedRectangleBorder(
              side: !externalCallsEnabled
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
              setState(() {
                // update toggle state
                externalCallsEnabled = true;
              });
              // call callback with newly set value
              widget.onChanged?.call(externalCallsEnabled);
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
                      if (isDesktop)
                        const SizedBox(
                          height: 10,
                        ),
                      (isSorbet)
                          ? Image.asset(
                              Assets.png.personaEasy(context),
                              width: 120,
                              height: 120,
                            )
                          : SvgPicture.asset(
                              Assets.svg.personaEasy(context),
                              width: 120,
                              height: 120,
                            ),
                      if (isDesktop)
                        const SizedBox(
                          height: 12,
                        ),
                      Center(
                        child: Text(
                          "Easy Crypto",
                          style: isDesktop
                              ? STextStyles.desktopTextSmall(context)
                              : STextStyles.label700(context),
                        ),
                      ),
                      Center(
                        child: Text(
                          "Recommended",
                          style: isDesktop
                              ? STextStyles.desktopTextExtraExtraSmall(context)
                              : STextStyles.label(context),
                        ),
                      ),
                      if (isDesktop)
                        const SizedBox(
                          height: 12,
                        ),
                    ],
                  ),
                  if (externalCallsEnabled)
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
                  if (!externalCallsEnabled)
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
        const SizedBox(
          width: 16,
        ),
        Expanded(
          child: RawMaterialButton(
            elevation: 0,
            hoverElevation: 0,
            fillColor: Theme.of(context).extension<StackColors>()!.popupBG,
            shape: RoundedRectangleBorder(
              side: externalCallsEnabled
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
              setState(() {
                // update toggle state
                externalCallsEnabled = false;
              });
              // call callback with newly set value
              widget.onChanged?.call(externalCallsEnabled);
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
                      if (isDesktop)
                        const SizedBox(
                          height: 10,
                        ),
                      (isSorbet)
                          ? Image.asset(
                              Assets.png.personaIncognito(context),
                              width: 120,
                              height: 120,
                            )
                          : SvgPicture.asset(
                              Assets.svg.personaIncognito(context),
                              width: 120,
                              height: 120,
                            ),
                      if (isDesktop)
                        const SizedBox(
                          height: 12,
                        ),
                      Center(
                        child: Text(
                          "Incognito",
                          style: isDesktop
                              ? STextStyles.desktopTextSmall(context)
                              : STextStyles.label700(context),
                        ),
                      ),
                      Center(
                        child: Text(
                          "Privacy conscious",
                          style: isDesktop
                              ? STextStyles.desktopTextExtraExtraSmall(context)
                              : STextStyles.label(context),
                        ),
                      ),
                      if (isDesktop)
                        const SizedBox(
                          height: 12,
                        ),
                    ],
                  ),
                  if (!externalCallsEnabled)
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
                  if (externalCallsEnabled)
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
