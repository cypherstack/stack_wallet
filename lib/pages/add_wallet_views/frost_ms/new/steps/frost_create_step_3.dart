import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../frost_route_generator.dart';
import '../../../../../providers/frost_wallet/frost_wallet_providers.dart';
import '../../../../../services/frost.dart';
import '../../../../../utilities/logger.dart';
import '../../../../../utilities/util.dart';
import '../../../../../widgets/custom_buttons/checkbox_text_button.dart';
import '../../../../../widgets/custom_buttons/frost_qr_dialog_button.dart';
import '../../../../../widgets/custom_buttons/simple_copy_button.dart';
import '../../../../../widgets/desktop/primary_button.dart';
import '../../../../../widgets/detail_item.dart';
import '../../../../../widgets/dialogs/frost/frost_error_dialog.dart';
import '../../../../../widgets/frost_step_user_steps.dart';
import '../../../../../widgets/stack_dialog.dart';
import '../../../../../widgets/textfields/frost_step_field.dart';
import '../../../../wallet_view/transaction_views/tx_v2/transaction_v2_details_view.dart';

class FrostCreateStep3 extends ConsumerStatefulWidget {
  const FrostCreateStep3({super.key});

  static const String routeName = "/frostCreateStep3";
  static const String title = "Shares";

  @override
  ConsumerState<FrostCreateStep3> createState() => _FrostCreateStep3State();
}

class _FrostCreateStep3State extends ConsumerState<FrostCreateStep3> {
  static const info = [
    "Send your share to other group members.",
    "Enter their shares into the corresponding fields.",
  ];

  bool _userVerifyContinue = false;

  final List<TextEditingController> controllers = [];
  final List<FocusNode> focusNodes = [];

  late final List<String> participants;
  late final String myShare;
  late final int myIndex;

  final List<bool> fieldIsEmptyFlags = [];

  @override
  void initState() {
    participants = Frost.getParticipants(
      multisigConfig: ref.read(pFrostMultisigConfig.state).state!,
    );
    myIndex = participants.indexOf(ref.read(pFrostMyName.state).state!);
    myShare = ref.read(pFrostSecretSharesData.state).state!.share;

    // temporarily remove my name. Added back later
    participants.removeAt(myIndex);

    for (int i = 0; i < participants.length; i++) {
      controllers.add(TextEditingController());
      focusNodes.add(FocusNode());
      fieldIsEmptyFlags.add(true);
    }
    super.initState();
  }

  @override
  void dispose() {
    for (int i = 0; i < controllers.length; i++) {
      controllers[i].dispose();
    }
    for (int i = 0; i < focusNodes.length; i++) {
      focusNodes[i].dispose();
    }
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
          const SizedBox(height: 12),
          DetailItem(
            title: "My name",
            detail: ref.watch(pFrostMyName.state).state!,
          ),
          const SizedBox(height: 12),
          DetailItem(
            title: "My share",
            detail: myShare,
            button: Util.isDesktop
                ? IconCopyButton(
                    data: myShare,
                  )
                : SimpleCopyButton(
                    data: myShare,
                  ),
          ),
          const SizedBox(height: 12),
          FrostQrDialogPopupButton(
            data: myShare,
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < participants.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: FrostStepField(
                controller: controllers[i],
                focusNode: focusNodes[i],
                showQrScanOption: true,
                label: participants[i],
                hint: "Enter ${participants[i]}'s share",
                onChanged: (_) {
                  setState(() {
                    fieldIsEmptyFlags[i] = controllers[i].text.isEmpty;
                  });
                },
              ),
            ),
          if (!Util.isDesktop) const Spacer(),
          const SizedBox(height: 12),
          CheckboxTextButton(
            label: "I have verified that everyone has my share",
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
            label: "Generate",
            enabled: _userVerifyContinue &&
                !fieldIsEmptyFlags.reduce((v, e) => v |= e),
            onPressed: () async {
              // check for empty commitments
              if (controllers
                  .map((e) => e.text.isEmpty)
                  .reduce((value, element) => value |= element)) {
                return await showDialog<void>(
                  context: context,
                  builder: (_) => StackOkDialog(
                    title: "Missing shares",
                    desktopPopRootNavigator: Util.isDesktop,
                  ),
                );
              }

              // collect commitment strings and insert my own at the correct index
              final shares = controllers.map((e) => e.text).toList();
              shares.insert(myIndex, myShare);

              try {
                ref.read(pFrostCompletedKeyGenData.notifier).state =
                    Frost.completeKeyGeneration(
                  multisigConfigWithNamePtr: ref
                      .read(pFrostStartKeyGenData.state)
                      .state!
                      .multisigConfigWithNamePtr,
                  secretSharesResPtr: ref
                      .read(pFrostSecretSharesData.state)
                      .state!
                      .secretSharesResPtr,
                  shares: shares,
                );

                ref.read(pFrostCreateCurrentStep.state).state = 4;
                await Navigator.of(context).pushNamed(
                  ref
                      .read(pFrostScaffoldArgs)!
                      .stepRoutes[ref.read(pFrostCreateCurrentStep) - 1]
                      .routeName,
                );
              } catch (e, s) {
                Logging.instance.logd(
                  "$e\n$s",
                  level: LogLevel.Fatal,
                );

                if (context.mounted) {
                  return await showDialog<void>(
                    context: context,
                    builder: (_) => const FrostErrorDialog(
                      title: "Failed to complete key generation",
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
