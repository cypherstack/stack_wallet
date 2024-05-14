import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/frost_route_generator.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/pages/wallet_view/wallet_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/desktop_wallet_view.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/services/frost.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/isar/models/frost_wallet_info.dart';
import 'package:stackwallet/widgets/custom_buttons/checkbox_text_button.dart';
import 'package:stackwallet/widgets/custom_buttons/frost_qr_dialog_button.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_copy_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/detail_item.dart';
import 'package:stackwallet/widgets/dialogs/frost/frost_error_dialog.dart';
import 'package:stackwallet/widgets/textfields/frost_step_field.dart';

// was FinishResharingView
class FrostReshareStep4 extends ConsumerStatefulWidget {
  const FrostReshareStep4({super.key});

  static const String routeName = "/frostReshareStep4";
  static const String title = "Resharer completes";

  @override
  ConsumerState<FrostReshareStep4> createState() => _FrostReshareStep4State();
}

class _FrostReshareStep4State extends ConsumerState<FrostReshareStep4> {
  final List<TextEditingController> controllers = [];
  final List<FocusNode> focusNodes = [];

  late final Map<String, int> resharers;
  late final String myName;
  late final int? myResharerIndexIndex;
  late final String? myResharerComplete;
  late final bool amOutgoingParticipant;
  late final bool amNewParticipant;

  final List<bool> fieldIsEmptyFlags = [];

  bool _userVerifyContinue = false;

  bool _buttonLock = false;
  Future<void> _onPressed() async {
    if (_buttonLock) {
      return;
    }
    _buttonLock = true;

    try {
      if (amOutgoingParticipant) {
        ref.read(pFrostResharingData).reset();
        ref.read(pFrostScaffoldCanPopDesktop.notifier).state = true;
        ref.read(pFrostScaffoldArgs)?.parentNav.popUntil(
              ModalRoute.withName(
                Util.isDesktop
                    ? DesktopWalletView.routeName
                    : WalletView.routeName,
              ),
            );
      } else {
        // collect resharer completes strings and insert my own at the correct index
        final resharerCompletes = controllers.map((e) => e.text).toList();
        if (myResharerIndexIndex != null && myResharerComplete != null) {
          resharerCompletes.insert(myResharerIndexIndex!, myResharerComplete!);
        }

        final data = Frost.finishReshared(
          prior: ref.read(pFrostResharingData).startResharedData!.prior.ref,
          resharerCompletes: resharerCompletes,
        );

        ref.read(pFrostResharingData).newWalletData = data;

        ref.read(pFrostCreateCurrentStep.state).state = 5;
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
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => FrostErrorDialog(
            title: "Error",
            message: e.toString(),
          ),
        );
      }
    } finally {
      _buttonLock = false;
    }
  }

  @override
  void initState() {
    amNewParticipant =
        ref.read(pFrostResharingData).startResharerData == null &&
            ref.read(pFrostResharingData).incompleteWallet != null &&
            ref.read(pFrostResharingData).incompleteWallet?.walletId ==
                ref.read(pFrostScaffoldArgs)!.walletId!;

    myName = ref.read(pFrostResharingData).myName!;

    resharers = ref.read(pFrostResharingData).configData!.resharers;

    if (amNewParticipant) {
      myResharerComplete = null;
      myResharerIndexIndex = null;
      amOutgoingParticipant = false;
    } else {
      myResharerComplete = ref.read(pFrostResharingData).resharerComplete!;

      final frostInfo = ref
          .read(mainDBProvider)
          .isar
          .frostWalletInfo
          .getByWalletIdSync(ref.read(pFrostScaffoldArgs)!.walletId!)!;
      final myOldIndex =
          frostInfo.participants.indexOf(ref.read(pFrostResharingData).myName!);

      myResharerIndexIndex = resharers.values.toList().indexOf(myOldIndex);
      if (myResharerIndexIndex! >= 0) {
        // remove my name for now as we don't need a text field for it
        resharers.remove(ref.read(pFrostResharingData).myName!);
      }

      amOutgoingParticipant = !ref
          .read(pFrostResharingData)
          .configData!
          .newParticipants
          .contains(ref.read(pFrostResharingData).myName!);
    }

    for (int i = 0; i < resharers.length; i++) {
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
          if (myResharerComplete != null)
            DetailItem(
              title: "My resharer complete",
              detail: myResharerComplete!,
              button: Util.isDesktop
                  ? IconCopyButton(
                      data: myResharerComplete!,
                    )
                  : SimpleCopyButton(
                      data: myResharerComplete!,
                    ),
            ),
          if (myResharerComplete != null) const SizedBox(height: 12),
          if (myResharerComplete != null)
            FrostQrDialogPopupButton(
              data: myResharerComplete!,
            ),
          if (!amOutgoingParticipant)
            const SizedBox(
              height: 16,
            ),
          if (!amOutgoingParticipant)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < resharers.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: FrostStepField(
                      controller: controllers[i],
                      focusNode: focusNodes[i],
                      showQrScanOption: true,
                      label: resharers.keys.elementAt(i),
                      hint: "Enter "
                          "${resharers.keys.elementAt(i)}"
                          "'s resharer",
                      onChanged: (_) {
                        setState(() {
                          fieldIsEmptyFlags[i] = controllers[i].text.isEmpty;
                        });
                      },
                    ),
                  ),
              ],
            ),
          if (!Util.isDesktop) const Spacer(),
          const SizedBox(
            height: 16,
          ),
          if (!amNewParticipant)
            CheckboxTextButton(
              label: "I have verified that everyone has my resharer complete",
              onChanged: (value) {
                setState(() {
                  _userVerifyContinue = value;
                });
              },
            ),
          if (!amNewParticipant)
            const SizedBox(
              height: 16,
            ),
          PrimaryButton(
            label: amOutgoingParticipant ? "Done" : "Complete",
            enabled: (amNewParticipant || _userVerifyContinue) &&
                (amOutgoingParticipant ||
                    !fieldIsEmptyFlags.reduce((v, e) => v |= e)),
            onPressed: _onPressed,
          ),
        ],
      ),
    );
  }
}
