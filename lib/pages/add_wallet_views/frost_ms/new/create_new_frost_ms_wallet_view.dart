import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../frost_route_generator.dart';
import '../../../../providers/frost_wallet/frost_wallet_providers.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../utilities/util.dart';
import '../../../../wallets/crypto_currency/intermediate/frost_currency.dart';
import '../../../../widgets/background.dart';
import '../../../../widgets/conditional_parent.dart';
import '../../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../../widgets/custom_buttons/blue_text_button.dart';
import '../../../../widgets/desktop/desktop_app_bar.dart';
import '../../../../widgets/desktop/desktop_scaffold.dart';
import '../../../../widgets/desktop/primary_button.dart';
import '../../../../widgets/dialogs/simple_mobile_dialog.dart';
import '../../../../widgets/frost_mascot.dart';
import '../../../../widgets/frost_scaffold.dart';
import '../../../../widgets/rounded_white_container.dart';
import '../../../../widgets/stack_dialog.dart';
import '../../../../wl_gen/interfaces/frost_interface.dart';

class CreateNewFrostMsWalletView extends ConsumerStatefulWidget {
  const CreateNewFrostMsWalletView({
    super.key,
    required this.walletName,
    required this.frostCurrency,
  });

  static const String routeName = "/createNewFrostMsWalletView";

  final String walletName;
  final FrostCurrency frostCurrency;

  @override
  ConsumerState<CreateNewFrostMsWalletView> createState() =>
      _NewFrostMsWalletViewState();
}

class _NewFrostMsWalletViewState
    extends ConsumerState<CreateNewFrostMsWalletView> {
  final _thresholdController = TextEditingController();
  final _participantsController = TextEditingController();

  final List<TextEditingController> controllers = [];

  int _participantsCount = 0;

  String _validateInputData() {
    final threshold = int.tryParse(_thresholdController.text);
    if (threshold == null) {
      return "Choose a threshold";
    }

    final partsCount = int.tryParse(_participantsController.text);
    if (partsCount == null) {
      return "Choose total number of participants";
    }

    if (threshold > partsCount) {
      return "Threshold cannot be greater than the number of participants";
    }

    if (partsCount < 2) {
      return "At least two participants required";
    }

    if (controllers.length != partsCount) {
      return "Participants count error";
    }

    final hasEmptyParticipants = controllers
        .map((e) => e.text.trim().isEmpty)
        .reduce((value, element) => value |= element);
    if (hasEmptyParticipants) {
      return "Participants must not be empty";
    }

    if (controllers.length !=
        controllers.map((e) => e.text.trim()).toSet().length) {
      return "Duplicate participant name found";
    }

    return "valid";
  }

  void _participantsCountChanged(String newValue) {
    final count = int.tryParse(newValue);
    if (count != null) {
      if (count > _participantsCount) {
        for (int i = _participantsCount; i < count; i++) {
          controllers.add(TextEditingController());
        }

        _participantsCount = count;
        setState(() {});
      } else if (count < _participantsCount) {
        for (int i = _participantsCount; i > count; i--) {
          final last = controllers.removeLast();
          last.dispose();
        }

        _participantsCount = count;
        setState(() {});
      }
    }
  }

  void _showWhatIsThresholdDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => SimpleMobileDialog(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("What is a threshold?", style: STextStyles.w600_20(context)),
            const SizedBox(height: 12),
            Text(
              "A threshold is the amount of people required to perform an "
              "action. This does not have to be the same number as the "
              "total number in the group.",
              style: STextStyles.w400_16(context),
            ),
            const SizedBox(height: 6),
            Text(
              "For example, if you have 3 people in the group, but a threshold "
              "of 2, then you only need 2 out of the 3 people to sign for an "
              "action to take place.",
              style: STextStyles.w400_16(context),
            ),
            const SizedBox(height: 6),
            Text(
              "Conversely if you have a group of 3 AND a threshold of 3, you "
              "will need all 3 people in the group to sign to approve any "
              "action.",
              style: STextStyles.w400_16(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    _participantsController.dispose();
    for (final e in controllers) {
      e.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: Util.isDesktop,
      builder: (child) => DesktopScaffold(
        background: Theme.of(context).extension<StackColors>()!.background,
        appBar: const DesktopAppBar(
          isCompactHeight: false,
          leading: AppBarBackButton(),
          // TODO: [prio=high] get rid of placeholder text??
          trailing: FrostMascot(
            title: 'Lorem ipsum',
            body:
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam est justo, ',
          ),
        ),
        body: SizedBox(width: 480, child: child),
      ),
      child: ConditionalParent(
        condition: !Util.isDesktop,
        builder: (child) => Background(
          child: Scaffold(
            backgroundColor: Theme.of(
              context,
            ).extension<StackColors>()!.background,
            appBar: AppBar(
              leading: AppBarBackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: Text(
                "Create new group",
                style: STextStyles.navBarTitle(context),
              ),
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Threshold",
                  style: STextStyles.w500_14(context).copyWith(
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.textDark3,
                  ),
                ),
                CustomTextButton(
                  text: "What is a threshold?",
                  onTap: _showWhatIsThresholdDialog,
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              controller: _thresholdController,
              decoration: InputDecoration(
                hintText: "Enter number of signatures",
                hintStyle: STextStyles.fieldLabel(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Number of participants",
              style: STextStyles.w500_14(context).copyWith(
                color: Theme.of(context).extension<StackColors>()!.textDark3,
              ),
            ),
            const SizedBox(height: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  controller: _participantsController,
                  onChanged: _participantsCountChanged,
                  decoration: InputDecoration(
                    hintText: "Enter number of participants",
                    hintStyle: STextStyles.fieldLabel(context),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: RoundedWhiteContainer(
                        child: Text(
                          "Enter number of signatures required for fund management",
                          style: STextStyles.label(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (controllers.isNotEmpty)
              Text(
                "My name",
                style: STextStyles.w500_14(context).copyWith(
                  color: Theme.of(context).extension<StackColors>()!.textDark3,
                ),
              ),
            if (controllers.isNotEmpty) const SizedBox(height: 10),
            if (controllers.isNotEmpty)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controllers.first,
                    decoration: InputDecoration(
                      hintText: "Enter your name",
                      hintStyle: STextStyles.fieldLabel(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: RoundedWhiteContainer(
                          child: Text(
                            "Type your name in one word without spaces",
                            style: STextStyles.label(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            if (controllers.length > 1) const SizedBox(height: 16),
            if (controllers.length > 1)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Remaining participants",
                    style: STextStyles.w500_14(context).copyWith(
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.textDark3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: RoundedWhiteContainer(
                          child: Text(
                            "Type each name in one word without spaces",
                            style: STextStyles.label(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            if (controllers.length > 1)
              Column(
                children: [
                  for (int i = 1; i < controllers.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: TextField(
                        controller: controllers[i],
                        decoration: InputDecoration(
                          hintText: "Enter name",
                          hintStyle: STextStyles.fieldLabel(context),
                        ),
                      ),
                    ),
                ],
              ),
            if (!Util.isDesktop) const Spacer(),
            const SizedBox(height: 16),
            PrimaryButton(
              label: "Create new group",
              onPressed: () async {
                if (FocusScope.of(context).hasFocus) {
                  FocusScope.of(context).unfocus();
                }

                final validationMessage = _validateInputData();

                if (validationMessage != "valid") {
                  return await showDialog<void>(
                    context: context,
                    builder: (_) => StackOkDialog(
                      title: validationMessage,
                      desktopPopRootNavigator: Util.isDesktop,
                    ),
                  );
                }

                final config = frostInterface.createMultisigConfig(
                  name: controllers.first.text.trim(),
                  threshold: int.parse(_thresholdController.text),
                  participants: controllers.map((e) => e.text.trim()).toList(),
                );

                ref.read(pFrostMyName.notifier).state = controllers.first.text
                    .trim();
                ref.read(pFrostMultisigConfig.notifier).state = config;

                ref.read(pFrostScaffoldArgs.state).state = (
                  info: (
                    walletName: widget.walletName,
                    frostCurrency: widget.frostCurrency,
                  ),
                  walletId: null,
                  stepRoutes: FrostRouteGenerator.createNewConfigStepRoutes,
                  frostInterruptionDialogType:
                      FrostInterruptionDialogType.walletCreation,
                  parentNav: Navigator.of(context),
                  callerRouteName: CreateNewFrostMsWalletView.routeName,
                );

                await Navigator.of(
                  context,
                ).pushNamed(FrostStepScaffold.routeName);
              },
            ),
          ],
        ),
      ),
    );
  }
}
