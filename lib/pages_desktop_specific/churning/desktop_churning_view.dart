import 'dart:async';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../pages/churning/churning_rounds_selection_sheet.dart';
import '../../providers/churning/churning_service_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/constants.dart';
import '../../utilities/extensions/extensions.dart';
import '../../utilities/text_styles.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/custom_buttons/checkbox_text_button.dart';
import '../../widgets/desktop/desktop_app_bar.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/desktop_scaffold.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_text_field.dart';
import 'sub_widgets/churning_dialog.dart';

class DesktopChurningView extends ConsumerStatefulWidget {
  const DesktopChurningView({
    super.key,
    required this.walletId,
  });

  static const String routeName = "/desktopChurningView";

  final String walletId;

  @override
  ConsumerState<DesktopChurningView> createState() => _DesktopChurning();
}

class _DesktopChurning extends ConsumerState<DesktopChurningView> {
  late final TextEditingController churningRoundController;
  late final FocusNode churningRoundFocusNode;

  bool _enableStartButton = false;

  ChurnOption _option = ChurnOption.continuous;

  Future<void> _startChurn() async {
    final churningService = ref.read(pChurningService(widget.walletId));

    final int rounds = _option == ChurnOption.continuous
        ? 0
        : int.parse(churningRoundController.text);

    churningService.rounds = rounds;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ChurnDialogView(
          walletId: widget.walletId,
        );
      },
    );
  }

  @override
  void initState() {
    churningRoundController = TextEditingController();

    churningRoundFocusNode = FocusNode();

    final rounds = ref.read(pChurningService(widget.walletId)).rounds;

    _option = rounds == 0 ? ChurnOption.continuous : ChurnOption.custom;
    churningRoundController.text = rounds.toString();

    _enableStartButton = churningRoundController.text.isNotEmpty;

    super.initState();
  }

  @override
  void dispose() {
    churningRoundController.dispose();
    churningRoundFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return DesktopScaffold(
      appBar: DesktopAppBar(
        background: Theme.of(context).extension<StackColors>()!.popupBG,
        isCompactHeight: true,
        useSpacers: false,
        leading: Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // const SizedBox(
                    //   width: 32,
                    // ),
                    AppBarIconButton(
                      size: 32,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textFieldDefaultBG,
                      shadows: const [],
                      icon: SvgPicture.asset(
                        Assets.svg.arrowLeft,
                        width: 18,
                        height: 18,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .topNavIconPrimary,
                      ),
                      onPressed: Navigator.of(context).pop,
                    ),
                    const SizedBox(
                      width: 15,
                    ),
                    SvgPicture.asset(
                      Assets.svg.churn,
                      width: 32,
                      height: 32,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textSubtitle1,
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Text(
                      "Churning",
                      style: STextStyles.desktopH3(context),
                    ),
                  ],
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {},
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          Assets.svg.circleQuestion,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .radioButtonIconBorder,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        RichText(
                          text: TextSpan(
                            text: "What is churning?",
                            style: STextStyles.richLink(context).copyWith(
                              fontSize: 16,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                showDialog<dynamic>(
                                  context: context,
                                  useSafeArea: false,
                                  barrierDismissible: true,
                                  builder: (context) {
                                    return DesktopDialog(
                                      maxWidth: 580,
                                      maxHeight: double.infinity,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 10,
                                          left: 20,
                                          bottom: 20,
                                          right: 10,
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "What is churning?",
                                                  style: STextStyles.desktopH2(
                                                    context,
                                                  ),
                                                ),
                                                DesktopDialogCloseButton(
                                                  onPressedOverride: () =>
                                                      Navigator.of(context)
                                                          .pop(true),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 16,
                                            ),
                                            Text(
                                              "Churning in a Monero wallet involves"
                                              " sending Monero to oneself in multiple"
                                              " transactions, which can enhance privacy"
                                              " by making it harder for observers to "
                                              "link your transactions. This process"
                                              " re-mixes the funds within the network,"
                                              " helping obscure transaction history. "
                                              "Churning is optional and mainly beneficial"
                                              " in scenarios where maximum privacy is"
                                              " desired or if you received the Monero from"
                                              " a source from which you'd like to disassociate.",
                                              style:
                                                  STextStyles.desktopTextMedium(
                                                context,
                                              ).copyWith(
                                                color: Theme.of(context)
                                                    .extension<StackColors>()!
                                                    .textDark3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 460,
                  child: RoundedWhiteContainer(
                    child: Row(
                      children: [
                        Text(
                          "Churning helps anonymize your coins by mixing them.",
                          style:
                              STextStyles.desktopTextExtraExtraSmall(context),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                SizedBox(
                  width: 460,
                  child: RoundedWhiteContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Configuration",
                          style:
                              STextStyles.desktopTextExtraExtraSmall(context),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        DropdownButtonHideUnderline(
                          child: DropdownButton2<ChurnOption>(
                            value: _option,
                            items: [
                              ...ChurnOption.values.map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    e.name.capitalize(),
                                    style: STextStyles.smallMed14(context)
                                        .copyWith(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .textDark,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value is ChurnOption) {
                                setState(() {
                                  _option = value;
                                });
                              }
                            },
                            isExpanded: true,
                            iconStyleData: IconStyleData(
                              icon: SvgPicture.asset(
                                Assets.svg.chevronDown,
                                width: 12,
                                height: 6,
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textFieldActiveSearchIconRight,
                              ),
                            ),
                            dropdownStyleData: DropdownStyleData(
                              offset: const Offset(0, -10),
                              elevation: 0,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textFieldActiveBG,
                                borderRadius: BorderRadius.circular(
                                  Constants.size.circularBorderRadius,
                                ),
                              ),
                            ),
                            menuItemStyleData: const MenuItemStyleData(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        if (_option == ChurnOption.custom)
                          const SizedBox(
                            height: 10,
                          ),
                        if (_option == ChurnOption.custom)
                          SizedBox(
                            width: 460,
                            child: RoundedWhiteContainer(
                              padding: EdgeInsets.zero,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      Constants.size.circularBorderRadius,
                                    ),
                                    child: TextField(
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      controller: churningRoundController,
                                      focusNode: churningRoundFocusNode,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _enableStartButton = value.isNotEmpty;
                                        });
                                      },
                                      style: STextStyles.field(context),
                                      decoration: standardInputDecoration(
                                        "Number of churns",
                                        churningRoundFocusNode,
                                        context,
                                        desktopMed: true,
                                      ).copyWith(
                                        labelText: "Enter number of churns..",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(
                          height: 20,
                        ),
                        CheckboxTextButton(
                          label: "Pause on errors",
                          initialValue: !ref
                              .read(pChurningService(widget.walletId))
                              .ignoreErrors,
                          onChanged: (value) {
                            ref
                                .read(pChurningService(widget.walletId))
                                .ignoreErrors = !value;
                          },
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        PrimaryButton(
                          label: "Start",
                          enabled: _enableStartButton,
                          buttonHeight: ButtonHeight.l,
                          onPressed: _startChurn,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
