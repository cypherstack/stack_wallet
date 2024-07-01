import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../frost_route_generator.dart';
import '../../../../../providers/frost_wallet/frost_wallet_providers.dart';
import '../../../../../services/frost.dart';
import '../../../../../themes/stack_colors.dart';
import '../../../../../utilities/assets.dart';
import '../../../../../utilities/text_styles.dart';
import '../../../../../utilities/util.dart';
import '../../../../../widgets/custom_buttons/checkbox_text_button.dart';
import '../../../../../widgets/custom_buttons/simple_copy_button.dart';
import '../../../../../widgets/desktop/primary_button.dart';
import '../../../../../widgets/desktop/secondary_button.dart';
import '../../../../../widgets/detail_item.dart';
import '../../../../../widgets/dialogs/simple_mobile_dialog.dart';
import '../../../../../widgets/frost_step_user_steps.dart';
import '../../../../../widgets/qr.dart';
import '../../../../wallet_view/transaction_views/transaction_details_view.dart';

class FrostCreateStep1a extends ConsumerStatefulWidget {
  const FrostCreateStep1a({super.key});

  static const String routeName = "/frostCreateStep1a";
  static const String title = "Multisig group info";

  @override
  ConsumerState<FrostCreateStep1a> createState() => _FrostCreateStep1aState();
}

class _FrostCreateStep1aState extends ConsumerState<FrostCreateStep1a> {
  static const info = [
    "Share this config with the group participants.",
    "Wait for them to join the group.",
    "Verify that everyone has filled out their forms before continuing. If you "
        "try to continue before everyone is ready, the process will be canceled.",
    "Check the box and press “Generate keys”.",
  ];

  bool _userVerifyContinue = false;

  void _showParticipantsDialog() {
    final participants = Frost.getParticipants(
      multisigConfig: ref.read(pFrostMultisigConfig.state).state!,
    );

    showDialog<void>(
      context: context,
      builder: (_) => SimpleMobileDialog(
        showCloseButton: false,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 24,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Group participants",
                style: STextStyles.w600_20(context),
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "The names are case-sensitive and must be entered exactly.",
                style: STextStyles.w400_16(context).copyWith(
                  color: Theme.of(context).extension<StackColors>()!.textDark3,
                ),
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            for (final participant in participants)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    height: 1.5,
                    color:
                        Theme.of(context).extension<StackColors>()!.background,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textFieldActiveBG,
                            borderRadius: BorderRadius.circular(
                              200,
                            ),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              Assets.svg.user,
                              width: 16,
                              height: 16,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child: Text(
                            participant,
                            style: STextStyles.w500_14(context),
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        IconCopyButton(
                          data: participant,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                ],
              ),
            const SizedBox(
              height: 24,
            ),
          ],
        ),
      ),
    );
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
            height: 20,
          ),
          SizedBox(
            height: 220,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                QR(
                  data: ref.watch(pFrostMultisigConfig.state).state ?? "Error",
                  size: 220,
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          DetailItem(
            title: "Encoded config",
            detail: ref.watch(pFrostMultisigConfig.state).state ?? "Error",
            button: Util.isDesktop
                ? IconCopyButton(
                    data:
                        ref.watch(pFrostMultisigConfig.state).state ?? "Error",
                  )
                : SimpleCopyButton(
                    data:
                        ref.watch(pFrostMultisigConfig.state).state ?? "Error",
                  ),
          ),
          SizedBox(
            height: Util.isDesktop ? 64 : 16,
          ),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: "Show group participants",
                  onPressed: _showParticipantsDialog,
                ),
              ),
            ],
          ),
          if (!Util.isDesktop)
            const Spacer(
              flex: 2,
            ),
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
            label: "Start key generation",
            enabled: _userVerifyContinue,
            onPressed: () async {
              ref.read(pFrostStartKeyGenData.notifier).state =
                  Frost.startKeyGeneration(
                multisigConfig: ref.watch(pFrostMultisigConfig.state).state!,
                myName: ref.read(pFrostMyName.state).state!,
              );

              ref.read(pFrostCreateCurrentStep.state).state = 2;
              await Navigator.of(context).pushNamed(
                ref
                    .read(pFrostScaffoldArgs)!
                    .stepRoutes[ref.read(pFrostCreateCurrentStep) - 1]
                    .routeName,
                // FrostShareCommitmentsView.routeName,
              );
            },
          ),
        ],
      ),
    );
  }
}
