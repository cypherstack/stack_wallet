import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/frost_route_generator.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/services/frost.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/frost_step_user_steps.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/textfields/frost_step_field.dart';

class FrostCreateStep1b extends ConsumerStatefulWidget {
  const FrostCreateStep1b({super.key});

  static const String routeName = "/frostCreateStep1b";
  static const String title = "Import group info";

  @override
  ConsumerState<FrostCreateStep1b> createState() => _FrostCreateStep1bState();
}

class _FrostCreateStep1bState extends ConsumerState<FrostCreateStep1b> {
  static const info = [
    "Scan the config QR code or paste the code provided by the group creator.",
    "Enter your name EXACTLY as the group creator entered it. When in doubt, "
        "double check with them. The names are case-sensitive.",
    "Wait for other participants to finish entering their information.",
    "Verify that everyone has filled out their forms before continuing. If you "
        "try to continue before everyone is ready, the process will be canceled.",
    "Check the box and press “Generate keys”.",
  ];

  late final TextEditingController myNameFieldController, configFieldController;
  late final FocusNode myNameFocusNode, configFocusNode;

  bool _nameEmpty = true, _configEmpty = true, _userVerifyContinue = false;

  @override
  void initState() {
    myNameFieldController = TextEditingController();
    configFieldController = TextEditingController();
    myNameFocusNode = FocusNode();
    configFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    myNameFieldController.dispose();
    configFieldController.dispose();
    myNameFocusNode.dispose();
    configFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const FrostStepUserSteps(
            userSteps: info,
          ),
          const SizedBox(
            height: 16,
          ),
          FrostStepField(
            controller: myNameFieldController,
            focusNode: myNameFocusNode,
            showQrScanOption: false,
            label: "My name",
            hint: "Enter your name",
            onChanged: (_) {
              setState(() {
                _nameEmpty = myNameFieldController.text.isEmpty;
              });
            },
          ),
          const SizedBox(
            height: 16,
          ),
          FrostStepField(
            controller: configFieldController,
            focusNode: configFocusNode,
            showQrScanOption: true,
            label: "Enter config",
            hint: "Enter config",
            onChanged: (_) {
              setState(() {
                _configEmpty = configFieldController.text.isEmpty;
              });
            },
          ),
          const SizedBox(
            height: 16,
          ),
          if (!Util.isDesktop) const Spacer(),
          const SizedBox(
            height: 16,
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _userVerifyContinue = !_userVerifyContinue;
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    height: 26,
                    child: Checkbox(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: _userVerifyContinue,
                      onChanged: (value) => setState(
                        () => _userVerifyContinue = value == true,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Text(
                      "I have verified that everyone has joined the group",
                      style: STextStyles.w500_14(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          PrimaryButton(
            label: "Start key generation",
            enabled: _userVerifyContinue && !_nameEmpty && !_configEmpty,
            onPressed: () async {
              if (FocusScope.of(context).hasFocus) {
                FocusScope.of(context).unfocus();
              }

              final config = configFieldController.text;

              if (!Frost.validateEncodedMultisigConfig(encodedConfig: config)) {
                return await showDialog<void>(
                  context: context,
                  builder: (_) => StackOkDialog(
                    title: "Invalid config",
                    desktopPopRootNavigator: Util.isDesktop,
                  ),
                );
              }

              if (!Frost.getParticipants(multisigConfig: config)
                  .contains(myNameFieldController.text)) {
                return await showDialog<void>(
                  context: context,
                  builder: (_) => StackOkDialog(
                    title: "My name not found in config participants",
                    desktopPopRootNavigator: Util.isDesktop,
                  ),
                );
              }

              ref.read(pFrostMyName.state).state = myNameFieldController.text;
              ref.read(pFrostMultisigConfig.notifier).state = config;

              ref.read(pFrostStartKeyGenData.state).state =
                  Frost.startKeyGeneration(
                multisigConfig: ref.read(pFrostMultisigConfig.state).state!,
                myName: ref.read(pFrostMyName.state).state!,
              );
              ref.read(pFrostCreateCurrentStep.state).state = 2;
              await Navigator.of(context).pushNamed(
                ref
                    .read(pFrostScaffoldArgs)!
                    .stepRoutes[ref.read(pFrostCreateCurrentStep) - 1]
                    .routeName,
              );
            },
          )
        ],
      ),
    );
  }
}
