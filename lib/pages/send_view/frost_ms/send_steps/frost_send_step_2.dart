import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../frost_route_generator.dart';
import '../../../../providers/frost_wallet/frost_wallet_providers.dart';
import '../../../../providers/global/wallets_provider.dart';
import '../../../../services/frost.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/logger.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../utilities/util.dart';
import '../../../../wallets/wallet/impl/bitcoin_frost_wallet.dart';
import '../../../../widgets/custom_buttons/frost_qr_dialog_button.dart';
import '../../../../widgets/custom_buttons/simple_copy_button.dart';
import '../../../../widgets/desktop/primary_button.dart';
import '../../../../widgets/detail_item.dart';
import '../../../../widgets/dialogs/frost/frost_error_dialog.dart';
import '../../../../widgets/rounded_white_container.dart';
import '../../../../widgets/textfields/frost_step_field.dart';
import '../../../wallet_view/transaction_views/transaction_details_view.dart';

class FrostSendStep2 extends ConsumerStatefulWidget {
  const FrostSendStep2({super.key});

  static const String routeName = "/FrostSendStep2";
  static const String title = "Preprocesses";

  @override
  ConsumerState<FrostSendStep2> createState() => _FrostSendStep2State();
}

class _FrostSendStep2State extends ConsumerState<FrostSendStep2> {
  final List<TextEditingController> controllers = [];
  final List<FocusNode> focusNodes = [];

  late final String myName;
  late final List<String> participantsWithoutMe;
  late final String myPreprocess;
  late final int myIndex;
  late final int threshold;

  final List<bool> fieldIsEmptyFlags = [];

  int countPreprocesses() {
    // own preprocess is not included in controllers and must be set here
    int count = 1;

    for (final controller in controllers) {
      if (controller.text.isNotEmpty) {
        count++;
      }
    }

    return count;
  }

  @override
  void initState() {
    final wallet = ref.read(pWallets).getWallet(
          ref.read(pFrostScaffoldArgs)!.walletId!,
        ) as BitcoinFrostWallet;
    final frostInfo = wallet.frostInfo;

    myName = frostInfo.myName;
    threshold = frostInfo.threshold;
    participantsWithoutMe =
        List.from(frostInfo.participants); // Copy so it isn't fixed-length.
    myIndex = participantsWithoutMe.indexOf(frostInfo.myName);
    myPreprocess = ref.read(pFrostAttemptSignData.state).state!.preprocess;

    participantsWithoutMe.removeAt(myIndex);

    for (int i = 0; i < participantsWithoutMe.length; i++) {
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RoundedWhiteContainer(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "1.",
                      style: STextStyles.w500_12(context),
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Expanded(
                      child: Text(
                        "Share your preprocess with other signing group members.",
                        style: STextStyles.w500_12(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 4,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "2.",
                      style: STextStyles.w500_12(context),
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  "Enter their preprocesses into the corresponding fields. ",
                              style: STextStyles.w500_12(context),
                            ),
                            TextSpan(
                              text: "You must have the threshold number of "
                                  "preprocesses (including yours) to send this transaction.",
                              style: STextStyles.w600_12(context).copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .customTextButtonEnabledText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          DetailItem(
            title: "Threshold",
            detail: "$threshold signatures",
            horizontal: true,
          ),
          const SizedBox(
            height: 12,
          ),
          DetailItem(
            title: "My name",
            detail: myName,
            button: Util.isDesktop
                ? IconCopyButton(
                    data: myName,
                  )
                : SimpleCopyButton(
                    data: myName,
                  ),
          ),
          const SizedBox(
            height: 12,
          ),
          DetailItem(
            title: "My preprocess",
            detail: myPreprocess,
            button: Util.isDesktop
                ? IconCopyButton(
                    data: myPreprocess,
                  )
                : SimpleCopyButton(
                    data: myPreprocess,
                  ),
          ),
          const SizedBox(height: 12),
          FrostQrDialogPopupButton(
            data: myPreprocess,
          ),
          const SizedBox(
            height: 12,
          ),
          RoundedWhiteContainer(
            child: Text(
              "You need to obtain ${threshold - 1} preprocess from signing members to send this transaction.",
              style: STextStyles.label(context),
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          Builder(
            builder: (context) {
              final count = countPreprocesses();
              final colors = Theme.of(context).extension<StackColors>()!;
              return DetailItem(
                title: "Required preprocesses",
                detail: "$count of $threshold",
                horizontal: true,
                overrideDetailTextColor: count >= threshold
                    ? colors.accentColorGreen
                    : colors.accentColorRed,
              );
            },
          ),
          const SizedBox(
            height: 12,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < participantsWithoutMe.length; i++)
                FrostStepField(
                  label: participantsWithoutMe[i],
                  hint: "Enter ${participantsWithoutMe[i]}'s preprocess",
                  controller: controllers[i],
                  focusNode: focusNodes[i],
                  onChanged: (_) {
                    setState(() {
                      fieldIsEmptyFlags[i] = controllers[i].text.isEmpty;
                    });
                  },
                  showQrScanOption: true,
                ),
            ],
          ),
          if (!Util.isDesktop) const Spacer(),
          const SizedBox(
            height: 12,
          ),
          PrimaryButton(
            label: "Generate shares",
            enabled: countPreprocesses() >= threshold,
            onPressed: () async {
              // collect Preprocess strings (not including my own)
              final preprocesses = controllers.map((e) => e.text).toList();

              // collect participants who are involved in this transaction
              final List<String> requiredParticipantsUnordered = [];
              for (int i = 0; i < participantsWithoutMe.length; i++) {
                if (preprocesses[i].isNotEmpty) {
                  requiredParticipantsUnordered.add(participantsWithoutMe[i]);
                }
              }
              ref.read(pFrostSelectParticipantsUnordered.notifier).state =
                  requiredParticipantsUnordered;

              // insert an empty string at my index
              preprocesses.insert(myIndex, "");

              try {
                ref.read(pFrostContinueSignData.notifier).state =
                    Frost.continueSigning(
                  machinePtr:
                      ref.read(pFrostAttemptSignData.state).state!.machinePtr,
                  preprocesses: preprocesses,
                );

                ref.read(pFrostCreateCurrentStep.state).state = 3;
                await Navigator.of(context).pushNamed(
                  ref
                      .read(pFrostScaffoldArgs)!
                      .stepRoutes[ref.read(pFrostCreateCurrentStep) - 1]
                      .routeName,
                );

                // await Navigator.of(context).pushNamed(
                //   FrostContinueSignView.routeName,
                //   arguments: widget.walletId,
                // );
              } catch (e, s) {
                Logging.instance.f("$e\n$s", error: e, stackTrace: s,);

                if (context.mounted) {
                  return await showDialog<void>(
                    context: context,
                    builder: (_) => const FrostErrorDialog(
                      title: "Failed to continue signing",
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
