import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/frost_route_generator.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/show_loading.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/models/incomplete_frost_wallet.dart';
import 'package:stackwallet/widgets/custom_buttons/checkbox_text_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/frost_step_user_steps.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/textfields/frost_step_field.dart';

class FrostReshareStep1c extends ConsumerStatefulWidget {
  const FrostReshareStep1c({super.key});

  static const String routeName = "/frostReshareStep1c";
  static const String title = "Import reshare config";

  @override
  ConsumerState<FrostReshareStep1c> createState() => _FrostReshareStep1cState();
}

class _FrostReshareStep1cState extends ConsumerState<FrostReshareStep1c> {
  static const info = [
    "Scan the config QR code or paste the code provided by the group creator.",
    "Enter your name EXACTLY as the group creator entered it. When in doubt, "
        "double check with them. The names are case-sensitive.",
    "Wait for other participants to finish entering their information.",
    "Verify that everyone has filled out their forms before continuing. If you "
        "try to continue before everyone is ready, the process could be canceled.",
    "Check the box and press “Join group”.",
  ];

  late final TextEditingController myNameFieldController, configFieldController;
  late final FocusNode myNameFocusNode, configFocusNode;

  bool _nameEmpty = true,
      _configEmpty = true,
      _userVerifyContinue = false,
      _buttonLock = false;

  Future<IncompleteFrostWallet> _createWallet() async {
    final data = ref.read(pFrostScaffoldArgs)!;

    final info = WalletInfo.createNew(
      name: data.info.walletName,
      coin: data.info.frostCurrency.coin,
    );

    final wallet = IncompleteFrostWallet();
    wallet.info = info;

    return wallet;
  }

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
          CheckboxTextButton(
            label: "I have verified that everyone has joined the group",
            onChanged: (value) {
              setState(() {
                _userVerifyContinue = value;
              });
            },
          ),
          const SizedBox(
            height: 16,
          ),
          PrimaryButton(
            label: "Join group",
            enabled: _userVerifyContinue && !_nameEmpty && !_configEmpty,
            onPressed: () async {
              if (FocusScope.of(context).hasFocus) {
                FocusScope.of(context).unfocus();
              }
              if (_buttonLock) {
                return;
              }
              _buttonLock = true;

              try {
                ref.read(pFrostResharingData).reset();
                ref.read(pFrostResharingData).myName =
                    myNameFieldController.text;
                ref.read(pFrostResharingData).resharerRConfig =
                    configFieldController.text;

                if (!ref
                    .read(pFrostResharingData)
                    .configData!
                    .newParticipants
                    .contains(ref.read(pFrostResharingData).myName!)) {
                  ref.read(pFrostResharingData).reset();
                  return await showDialog<void>(
                    context: context,
                    builder: (_) => StackOkDialog(
                      title: "My name not found in config participants",
                      desktopPopRootNavigator: Util.isDesktop,
                    ),
                  );
                }

                Exception? ex;
                final wallet = await showLoading(
                  whileFuture: _createWallet(),
                  context: context,
                  message: "Setting up wallet",
                  rootNavigator: true,
                  onException: (e) => ex = e,
                );

                if (ex != null) {
                  throw ex!;
                }

                if (context.mounted) {
                  ref.read(pFrostResharingData).incompleteWallet = wallet!;
                  final data = ref.read(pFrostScaffoldArgs)!;
                  ref.read(pFrostScaffoldArgs.state).state = (
                    info: data.info,
                    walletId: wallet.walletId,
                    stepRoutes: data.stepRoutes,
                    parentNav: data.parentNav,
                    frostInterruptionDialogType:
                        FrostInterruptionDialogType.resharing,
                  );
                  ref.read(pFrostMyName.state).state =
                      ref.read(pFrostResharingData).myName!;
                  ref.read(pFrostCreateCurrentStep.state).state = 2;
                  await Navigator.of(context).pushNamed(
                    ref
                        .read(pFrostScaffoldArgs)!
                        .stepRoutes[ref.read(pFrostCreateCurrentStep) - 1]
                        .routeName,
                  );
                }
              } catch (e, s) {
                Logging.instance.log(
                  "$e\n$s",
                  level: LogLevel.Fatal,
                );

                if (context.mounted) {
                  await showDialog<void>(
                    context: context,
                    builder: (_) => StackOkDialog(
                      title: e.toString(),
                      desktopPopRootNavigator: Util.isDesktop,
                    ),
                  );
                }
              } finally {
                _buttonLock = false;
              }
            },
          )
        ],
      ),
    );
  }
}
