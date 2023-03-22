import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/pages/pinpad_views/create_pin_view.dart';
import 'package:stackwallet/pages_desktop_specific/password/create_password_view.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/price_provider.dart';
import 'package:stackwallet/services/exchange/exchange_data_loading_service.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
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
    return MasterScaffold(
      background: Theme.of(context).extension<StackColors>()!.background,
      isDesktop: isDesktop,
      appBar: isDesktop
          ? const DesktopAppBar(
              isCompactHeight: false,
              leading: AppBarBackButton(),
            )
          : AppBar(
              leading: AppBarBackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
      body: SafeArea(
        child: ConditionalParent(
          condition: !isDesktop,
          builder: (child) => LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: child,
                ),
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, isDesktop ? 0 : 40, 0, 0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 480 : double.infinity,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Choose your Stack experience",
                    style: isDesktop
                        ? STextStyles.desktopH2(context)
                        : STextStyles.pageTitleH1(context),
                  ),
                  SizedBox(
                    height: isDesktop ? 16 : 8,
                  ),
                  Text(
                    !widget.isSettings
                        ? "You can change it later in Settings"
                        : "",
                    style: isDesktop
                        ? STextStyles.desktopSubtitleH2(context)
                        : STextStyles.subtitle(context),
                  ),
                  SizedBox(
                    height: isDesktop ? 32 : 36,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 0 : 16,
                    ),
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
                  SizedBox(
                    height: isDesktop ? 16 : 36,
                  ),
                  Padding(
                    padding: isDesktop
                        ? const EdgeInsets.all(0)
                        : const EdgeInsets.all(16.0),
                    child: RoundedWhiteContainer(
                      child: Center(
                        child: RichText(
                          textAlign: TextAlign.left,
                          text: TextSpan(
                            style: isDesktop
                                ? STextStyles.desktopTextExtraExtraSmall(
                                    context)
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
                                      text:
                                          "\n\nRecommended for most crypto users.",
                                      style: isDesktop
                                          ? STextStyles
                                              .desktopTextExtraExtraSmall600(
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
                                          ? STextStyles
                                              .desktopTextExtraExtraSmall600(
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
                  if (!isDesktop)
                    const Spacer(
                      flex: 4,
                    ),
                  if (isDesktop)
                    const SizedBox(
                      height: 32,
                    ),
                  Padding(
                    padding: isDesktop
                        ? const EdgeInsets.all(0)
                        : const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                    child: Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: !widget.isSettings
                                ? "Continue"
                                : "Save changes",
                            onPressed: () {
                              ref
                                  .read(prefsChangeNotifierProvider)
                                  .externalCalls = isEasy;

                              DB.instance
                                  .put<dynamic>(
                                      boxName: DB.boxNamePrefs,
                                      key: "externalCalls",
                                      value: isEasy)
                                  .then((_) {
                                if (isEasy) {
                                  unawaited(
                                    ExchangeDataLoadingService.instance
                                        .init()
                                        .then((_) => ExchangeDataLoadingService
                                            .instance
                                            .loadAll()),
                                  );
                                  // unawaited(
                                  //     BuyDataLoadingService().loadAll(ref));
                                  ref
                                      .read(priceAnd24hChangeNotifierProvider)
                                      .start(true);
                                }
                              });
                              if (!widget.isSettings) {
                                if (isDesktop) {
                                  Navigator.of(context).pushNamed(
                                    CreatePasswordView.routeName,
                                  );
                                } else {
                                  Navigator.of(context).pushNamed(
                                    CreatePinView.routeName,
                                  );
                                }
                              } else {
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDesktop)
                    const SizedBox(
                      height: kDesktopAppBarHeight,
                    ),
                ],
              ),
            ),
          ),
        ),
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

  @override
  void initState() {
    isDesktop = Util.isDesktop;
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
                      // if (isDesktop)
                      //   const SizedBox(
                      //     height: 10,
                      //   ),
                      SvgPicture.asset(
                        Assets.svg.personaEasy(context),
                        width: 140,
                        height: 140,
                      ),
                      // if (isDesktop)
                      //   const SizedBox(
                      //     height: 12,
                      //   ),
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
                      SvgPicture.asset(
                        Assets.svg.personaIncognito(context),
                        width: 140,
                        height: 140,
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
