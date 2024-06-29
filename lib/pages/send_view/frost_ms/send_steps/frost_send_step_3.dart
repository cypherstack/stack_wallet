import 'package:coinlib_flutter/coinlib_flutter.dart' as cl;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../frost_route_generator.dart';
import '../../../../providers/frost_wallet/frost_wallet_providers.dart';
import '../../../../providers/global/wallets_provider.dart';
import '../../../../services/frost.dart';
import '../../../../utilities/amount/amount.dart';
import '../../../../utilities/logger.dart';
import '../../../../utilities/util.dart';
import '../../../../wallets/wallet/impl/bitcoin_frost_wallet.dart';
import '../../../../widgets/custom_buttons/checkbox_text_button.dart';
import '../../../../widgets/custom_buttons/frost_qr_dialog_button.dart';
import '../../../../widgets/custom_buttons/simple_copy_button.dart';
import '../../../../widgets/desktop/primary_button.dart';
import '../../../../widgets/detail_item.dart';
import '../../../../widgets/dialogs/frost/frost_error_dialog.dart';
import '../../../../widgets/frost_step_user_steps.dart';
import '../../../../widgets/textfields/frost_step_field.dart';
import '../../../wallet_view/transaction_views/transaction_details_view.dart';

class FrostSendStep3 extends ConsumerStatefulWidget {
  const FrostSendStep3({super.key});

  static const String routeName = "/FrostSendStep3";
  static const String title = "Shares";

  @override
  ConsumerState<FrostSendStep3> createState() => _FrostSendStep3State();
}

class _FrostSendStep3State extends ConsumerState<FrostSendStep3> {
  static const info = [
    "Send your share to other signing group members.",
    "Enter their shares into the corresponding fields.",
  ];

  final List<TextEditingController> controllers = [];
  final List<FocusNode> focusNodes = [];

  late final String myName;
  late final List<String> participantsWithoutMe;
  late final List<String> participantsAll;
  late final String myShare;
  late final int myIndex;

  final List<bool> fieldIsEmptyFlags = [];

  bool _userVerifyContinue = false;

  @override
  void initState() {
    final wallet = ref.read(pWallets).getWallet(
          ref.read(pFrostScaffoldArgs)!.walletId!,
        ) as BitcoinFrostWallet;

    final frostInfo = wallet.frostInfo;

    myName = frostInfo.myName;
    participantsAll = frostInfo.participants;
    myIndex = frostInfo.participants.indexOf(frostInfo.myName);
    myShare = ref.read(pFrostContinueSignData.state).state!.share;

    participantsWithoutMe = frostInfo.participants
        .toSet()
        .intersection(
          ref.read(pFrostSelectParticipantsUnordered.state).state!.toSet(),
        )
        .toList();

    participantsWithoutMe.remove(myName);

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
          const FrostStepUserSteps(
            userSteps: info,
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
          const SizedBox(
            height: 12,
          ),
          FrostQrDialogPopupButton(
            data: myShare,
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
                  hint: "Enter ${participantsWithoutMe[i]}'s share",
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
          CheckboxTextButton(
            label: "I have verified that everyone has my share",
            onChanged: (value) {
              setState(() {
                _userVerifyContinue = value;
              });
            },
          ),
          const SizedBox(
            height: 12,
          ),
          PrimaryButton(
            label: "Generate transaction",
            enabled: _userVerifyContinue &&
                !fieldIsEmptyFlags.reduce((v, e) => v |= e),
            onPressed: () async {
              // collect Share strings
              final sharesCollected = controllers.map((e) => e.text).toList();

              final List<String> shares = [];
              for (final participant in participantsAll) {
                if (participantsWithoutMe.contains(participant)) {
                  shares.add(
                    sharesCollected[participantsWithoutMe.indexOf(participant)],
                  );
                } else {
                  shares.add("");
                }
              }

              try {
                final rawTx = Frost.completeSigning(
                  machinePtr:
                      ref.read(pFrostContinueSignData.state).state!.machinePtr,
                  shares: shares,
                );

                final tx = cl.Transaction.fromHex(rawTx);
                final txData = ref.read(pFrostTxData)!;

                final fractionDigits =
                    txData.recipients!.first.amount.fractionDigits;

                final inputTotal = Amount(
                  rawValue: txData.utxos!
                      .map((e) => BigInt.from(e.value))
                      .reduce((v, e) => v += e),
                  fractionDigits: fractionDigits,
                );
                final outputTotal = Amount(
                  rawValue:
                      tx.outputs.map((e) => e.value).reduce((v, e) => v += e),
                  fractionDigits: fractionDigits,
                );

                ref.read(pFrostTxData.state).state = txData.copyWith(
                  raw: rawTx,
                  fee: inputTotal - outputTotal,
                  frostSigners: [
                    myName,
                    ...participantsWithoutMe,
                  ],
                );

                ref.read(pFrostCreateCurrentStep.state).state = 4;
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
                    builder: (_) => const FrostErrorDialog(
                      title: "Failed to complete signing process",
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
