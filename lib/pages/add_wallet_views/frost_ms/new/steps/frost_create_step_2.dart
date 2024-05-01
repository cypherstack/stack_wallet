import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/new/steps/frost_route_generator.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/tx_v2/transaction_v2_details_view.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/services/frost.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_copy_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/detail_item.dart';
import 'package:stackwallet/widgets/dialogs/frost/frost_step_qr_dialog.dart';
import 'package:stackwallet/widgets/frost_step_user_steps.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/textfields/frost_step_field.dart';

class FrostCreateStep2 extends ConsumerStatefulWidget {
  const FrostCreateStep2({
    super.key,
  });

  static const String routeName = "/frostCreateStep2";
  static const String title = "Commitments";

  @override
  ConsumerState<FrostCreateStep2> createState() => _FrostCreateStep2State();
}

class _FrostCreateStep2State extends ConsumerState<FrostCreateStep2> {
  static const info = [
    "Share your commitment with other group members.",
    "Enter their commitments into the corresponding fields.",
  ];

  final List<TextEditingController> controllers = [];
  final List<FocusNode> focusNodes = [];

  late final List<String> participants;
  late final String myCommitment;
  late final int myIndex;

  final List<bool> fieldIsEmptyFlags = [];
  bool _userVerifyContinue = false;

  Future<void> _showQrCodeDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => FrostStepQrDialog(
        myName: ref.read(pFrostMyName)!,
        title: "Step 2 of 5 - ${FrostCreateStep2.title}",
        data: myCommitment,
      ),
    );
  }

  @override
  void initState() {
    participants = Frost.getParticipants(
      multisigConfig: ref.read(pFrostMultisigConfig.state).state!,
    );
    myIndex = participants.indexOf(ref.read(pFrostMyName.state).state!);
    myCommitment = ref.read(pFrostStartKeyGenData.state).state!.commitments;

    // temporarily remove my name
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
            title: "My commitment",
            detail: myCommitment,
            button: Util.isDesktop
                ? IconCopyButton(
                    data: myCommitment,
                  )
                : SimpleCopyButton(
                    data: myCommitment,
                  ),
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: "View QR code",
            icon: SvgPicture.asset(
              Assets.svg.qrcode,
              colorFilter: ColorFilter.mode(
                Theme.of(context).extension<StackColors>()!.buttonTextSecondary,
                BlendMode.srcIn,
              ),
            ),
            onPressed: _showQrCodeDialog,
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
                hint: "Enter ${participants[i]}'s commitment",
                onChanged: (_) {
                  setState(() {
                    fieldIsEmptyFlags[i] = controllers[i].text.isEmpty;
                  });
                },
              ),
            ),
          if (!Util.isDesktop) const Spacer(),
          const SizedBox(height: 12),
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
                      "I have verified that everyone has all commitments",
                      style: STextStyles.w500_14(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: "Generate shares",
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
                    title: "Missing commitments",
                    desktopPopRootNavigator: Util.isDesktop,
                  ),
                );
              }

              // collect commitment strings and insert my own at the correct index
              final commitments = controllers.map((e) => e.text).toList();
              commitments.insert(myIndex, myCommitment);

              try {
                ref.read(pFrostSecretSharesData.notifier).state =
                    Frost.generateSecretShares(
                  multisigConfigWithNamePtr: ref
                      .read(pFrostStartKeyGenData.state)
                      .state!
                      .multisigConfigWithNamePtr,
                  mySeed: ref.read(pFrostStartKeyGenData.state).state!.seed,
                  secretShareMachineWrapperPtr: ref
                      .read(pFrostStartKeyGenData.state)
                      .state!
                      .secretShareMachineWrapperPtr,
                  commitments: commitments,
                );

                ref.read(pFrostCreateCurrentStep.state).state = 3;
                await Navigator.of(context).pushNamed(
                  ref
                      .read(pFrostScaffoldArgs)!
                      .stepRoutes[ref.read(pFrostCreateCurrentStep) - 1]
                      .routeName,
                );
              } catch (e, s) {
                Logging.instance.log(
                  "$e\n$s",
                  level: LogLevel.Fatal,
                );
                if (context.mounted) {
                  return await showDialog<void>(
                    context: context,
                    builder: (_) => StackOkDialog(
                      title: "Failed to generate shares",
                      message: e.toString(),
                      desktopPopRootNavigator: Util.isDesktop,
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
