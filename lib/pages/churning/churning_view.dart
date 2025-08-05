import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../providers/churning/churning_service_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/constants.dart';
import '../../utilities/extensions/extensions.dart';
import '../../utilities/text_styles.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/custom_buttons/checkbox_text_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/rounded_container.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_dialog.dart';
import '../../widgets/stack_text_field.dart';
import 'churning_progress_view.dart';
import 'churning_rounds_selection_sheet.dart';

class ChurningView extends ConsumerStatefulWidget {
  const ChurningView({super.key, required this.walletId});

  static const routeName = "/churnView";

  final String walletId;

  @override
  ConsumerState<ChurningView> createState() => _ChurnViewState();
}

class _ChurnViewState extends ConsumerState<ChurningView> {
  late final TextEditingController churningRoundController;
  late final FocusNode churningRoundFocusNode;

  bool _enableStartButton = false;

  ChurnOption _option = ChurnOption.continuous;

  Future<void> _startChurn() async {
    final churningService = ref.read(pChurningService(widget.walletId));

    final int rounds =
        _option == ChurnOption.continuous
            ? 0
            : int.parse(churningRoundController.text);

    churningService.rounds = rounds;

    await Navigator.of(
      context,
    ).pushNamed(ChurningProgressView.routeName, arguments: widget.walletId);
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
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: const AppBarBackButton(),
          title: Text("Churn", style: STextStyles.navBarTitle(context)),
          titleSpacing: 0,
          actions: [
            AspectRatio(
              aspectRatio: 1,
              child: AppBarIconButton(
                size: 36,
                icon: SvgPicture.asset(
                  Assets.svg.circleQuestion,
                  width: 20,
                  height: 20,
                  color:
                      Theme.of(
                        context,
                      ).extension<StackColors>()!.topNavIconPrimary,
                ),
                onPressed: () async {
                  await showDialog<void>(
                    context: context,
                    builder:
                        (context) => const StackOkDialog(
                          title: "What is churning?",
                          message:
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
                        ),
                  );
                },
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (builderContext, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RoundedWhiteContainer(
                            child: Text(
                              "Churning helps anonymize your coins by mixing them.",
                              style: STextStyles.w500_12(context).copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).extension<StackColors>()!.textSubtitle1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const SizedBox(height: 16),
                          Text(
                            "Configuration",
                            style: STextStyles.w500_14(context).copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).extension<StackColors>()!.textDark3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          RoundedContainer(
                            onPressed: () async {
                              final option =
                                  await showModalBottomSheet<ChurnOption?>(
                                    backgroundColor: Colors.transparent,
                                    context: context,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    builder: (_) {
                                      return ChurnRoundCountSelectSheet(
                                        currentOption: _option,
                                      );
                                    },
                                  );
                              if (option != null) {
                                setState(() {
                                  _option = option;
                                });
                              }
                            },
                            color:
                                Theme.of(
                                  context,
                                ).extension<StackColors>()!.textFieldActiveBG,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _option.name.capitalize(),
                                    style: STextStyles.w500_12(context),
                                  ),
                                  SvgPicture.asset(
                                    Assets.svg.chevronDown,
                                    width: 12,
                                    color:
                                        Theme.of(context)
                                            .extension<StackColors>()!
                                            .textSubtitle1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_option == ChurnOption.custom)
                            const SizedBox(height: 10),
                          if (_option == ChurnOption.custom)
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
                                keyboardType: TextInputType.number,
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
                                ).copyWith(
                                  labelText: "Enter number of churns..",
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          CheckboxTextButton(
                            label: "Pause on errors",
                            initialValue:
                                !ref
                                    .read(pChurningService(widget.walletId))
                                    .ignoreErrors,
                            onChanged: (value) {
                              ref
                                  .read(pChurningService(widget.walletId))
                                  .ignoreErrors = !value;
                            },
                          ),
                          const SizedBox(height: 16),
                          const Spacer(),
                          PrimaryButton(
                            label: "Start",
                            enabled: _enableStartButton,
                            onPressed: _startChurn,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
