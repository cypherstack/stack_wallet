import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../frost_route_generator.dart';
import '../../../../providers/frost_wallet/frost_wallet_providers.dart';
import '../../../../services/frost.dart';
import '../../../../utilities/logger.dart';
import '../../../../utilities/util.dart';
import '../../../../widgets/custom_buttons/checkbox_text_button.dart';
import '../../../../widgets/custom_buttons/frost_qr_dialog_button.dart';
import '../../../../widgets/custom_buttons/simple_copy_button.dart';
import '../../../../widgets/desktop/primary_button.dart';
import '../../../../widgets/detail_item.dart';
import '../../../../widgets/dialogs/frost/frost_error_dialog.dart';
import '../../../../widgets/textfields/frost_step_field.dart';
import '../../../wallet_view/transaction_views/transaction_details_view.dart';

class FrostReshareStep3abd extends ConsumerStatefulWidget {
  const FrostReshareStep3abd({super.key});

  static const String routeName = "/frostReshareStep3abd";
  static const String title = "Encryption keys";

  @override
  ConsumerState<FrostReshareStep3abd> createState() =>
      _FrostReshareStep3abdState();
}

class _FrostReshareStep3abdState extends ConsumerState<FrostReshareStep3abd> {
  final List<TextEditingController> controllers = [];
  final List<FocusNode> focusNodes = [];

  late final List<String> newParticipants;
  late final int myIndex;
  late final String? myEncryptionKey;
  late final bool amOutgoingParticipant;

  final List<bool> fieldIsEmptyFlags = [];

  bool _userVerifyContinue = false;

  bool _buttonLock = false;
  Future<void> _onPressed() async {
    if (_buttonLock) {
      return;
    }
    _buttonLock = true;

    try {
      // collect encryptionKeys strings and insert my own at the correct index
      final encryptionKeys = controllers.map((e) => e.text).toList();
      if (!amOutgoingParticipant) {
        encryptionKeys.insert(myIndex, myEncryptionKey!);
      }

      final result = Frost.finishResharer(
        machine: ref.read(pFrostResharingData).startResharerData!.machine.ref,
        encryptionKeysOfResharedTo: encryptionKeys,
      );

      ref.read(pFrostResharingData).resharerComplete = result;

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
    myEncryptionKey =
        ref.read(pFrostResharingData).startResharedData?.resharedStart;

    newParticipants = ref.read(pFrostResharingData).configData!.newParticipants;
    myIndex = newParticipants.indexOf(ref.read(pFrostResharingData).myName!);

    if (myIndex >= 0) {
      // remove my name for now as we don't need a text field for it
      newParticipants.removeAt(myIndex);
    }

    if (myEncryptionKey == null && myIndex == -1) {
      amOutgoingParticipant = true;
    } else if (myEncryptionKey != null && myIndex >= 0) {
      amOutgoingParticipant = false;
    } else {
      throw Exception("Invalid resharing state");
    }

    for (int i = 0; i < newParticipants.length; i++) {
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
          if (!amOutgoingParticipant)
            DetailItem(
              title: "My encryption key",
              detail: myEncryptionKey!,
              button: Util.isDesktop
                  ? IconCopyButton(
                      data: myEncryptionKey!,
                    )
                  : SimpleCopyButton(
                      data: myEncryptionKey!,
                    ),
            ),
          if (!amOutgoingParticipant) const SizedBox(height: 12),
          if (!amOutgoingParticipant)
            FrostQrDialogPopupButton(
              data: myEncryptionKey!,
            ),
          if (!amOutgoingParticipant)
            const SizedBox(
              height: 12,
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < newParticipants.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: FrostStepField(
                    controller: controllers[i],
                    focusNode: focusNodes[i],
                    showQrScanOption: true,
                    label: newParticipants[i],
                    hint: "Enter "
                        "${newParticipants[i]}"
                        "'s encryption key",
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
          if (!amOutgoingParticipant)
            const SizedBox(
              height: 12,
            ),
          if (!amOutgoingParticipant)
            CheckboxTextButton(
              label: "I have verified that everyone has my encryption key",
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
            label: "Continue",
            enabled: (amOutgoingParticipant || _userVerifyContinue) &&
                !fieldIsEmptyFlags.reduce((v, e) => v |= e),
            onPressed: _onPressed,
          ),
        ],
      ),
    );
  }
}
