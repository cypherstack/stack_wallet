import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/frost_route_generator.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
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
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/textfields/frost_step_field.dart';

class FrostReshareStep2abd extends ConsumerStatefulWidget {
  const FrostReshareStep2abd({super.key});

  static const String routeName = "/FrostReshareStep2abd";
  static const String title = "Resharers";

  @override
  ConsumerState<FrostReshareStep2abd> createState() =>
      _FrostReshareStep2abdState();
}

class _FrostReshareStep2abdState extends ConsumerState<FrostReshareStep2abd> {
  final List<TextEditingController> controllers = [];
  final List<FocusNode> focusNodes = [];

  late final Map<String, int> resharers;
  late final int myResharerIndexIndex;
  late final String myResharerStart;
  late final bool amOutgoingParticipant;

  final List<bool> fieldIsEmptyFlags = [];

  bool _buttonLock = false;

  bool _userVerifyContinue = false;

  Future<void> _onPressed() async {
    if (_buttonLock) {
      return;
    }
    _buttonLock = true;

    try {
      if (!amOutgoingParticipant) {
        // collect resharer strings
        final resharerStarts = controllers.map((e) => e.text).toList();
        if (myResharerIndexIndex >= 0) {
          // only insert my own at the correct index if I am a resharer
          resharerStarts.insert(myResharerIndexIndex, myResharerStart);
        }

        final result = Frost.beginReshared(
          myName: ref.read(pFrostResharingData).myName!,
          resharerConfig: Frost.decodeRConfig(
            ref.read(pFrostResharingData).resharerRConfig!,
          ),
          resharerStarts: resharerStarts,
        );

        ref.read(pFrostResharingData).startResharedData = result;
      }

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

      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => StackOkDialog(
            title: "Error",
            message: e.toString(),
            desktopPopRootNavigator: Util.isDesktop,
          ),
        );
      }
    } finally {
      _buttonLock = false;
    }
  }

  @override
  void initState() {
    // TODO: optimize this by creating watcher providers (similar to normal WalletInfo)
    final frostInfo = ref
        .read(mainDBProvider)
        .isar
        .frostWalletInfo
        .getByWalletIdSync(ref.read(pFrostScaffoldArgs)!.walletId!)!;
    final myOldIndex =
        frostInfo.participants.indexOf(ref.read(pFrostResharingData).myName!);

    myResharerStart =
        ref.read(pFrostResharingData).startResharerData!.resharerStart;

    resharers = ref.read(pFrostResharingData).configData!.resharers;
    myResharerIndexIndex = resharers.values.toList().indexOf(myOldIndex);
    if (myResharerIndexIndex >= 0) {
      // remove my name for now as we don't need a text field for it
      resharers.remove(ref.read(pFrostResharingData).myName!);
    }

    amOutgoingParticipant = !ref
        .read(pFrostResharingData)
        .configData!
        .newParticipants
        .contains(ref.read(pFrostResharingData).myName!);

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
          DetailItem(
            title: "My resharer",
            detail: myResharerStart,
            button: Util.isDesktop
                ? IconCopyButton(
                    data: myResharerStart,
                  )
                : SimpleCopyButton(
                    data: myResharerStart,
                  ),
          ),
          const SizedBox(height: 12),
          FrostQrDialogPopupButton(
            data: myResharerStart,
          ),
          const SizedBox(
            height: 12,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < resharers.length; i++)
                FrostStepField(
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
            ],
          ),
          if (!Util.isDesktop) const Spacer(),
          const SizedBox(
            height: 12,
          ),
          CheckboxTextButton(
            label: "I have verified that everyone has my resharer",
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
            enabled: _userVerifyContinue &&
                (amOutgoingParticipant ||
                    !fieldIsEmptyFlags.reduce((v, e) => v |= e)),
            onPressed: _onPressed,
          ),
        ],
      ),
    );
  }
}
