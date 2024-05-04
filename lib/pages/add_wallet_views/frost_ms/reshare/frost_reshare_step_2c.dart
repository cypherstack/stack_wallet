import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/frost_route_generator.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/services/frost.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/textfields/frost_step_field.dart';

class FrostReshareStep2c extends ConsumerStatefulWidget {
  const FrostReshareStep2c({super.key});

  static const String routeName = "/FrostReshareStep2c";
  static const String title = "Resharers";

  @override
  ConsumerState<FrostReshareStep2c> createState() => _FrostReshareStep2cState();
}

class _FrostReshareStep2cState extends ConsumerState<FrostReshareStep2c> {
  final List<TextEditingController> controllers = [];
  final List<FocusNode> focusNodes = [];

  late final Map<String, int> resharers;

  final List<bool> fieldIsEmptyFlags = [];

  bool _buttonLock = false;
  Future<void> _onPressed() async {
    if (_buttonLock) {
      return;
    }
    _buttonLock = true;

    try {
      // collect resharer strings
      final resharerStarts = controllers.map((e) => e.text).toList();

      final result = Frost.beginReshared(
        myName: ref.read(pFrostResharingData).myName!,
        resharerConfig: Frost.decodeRConfig(
          ref.read(pFrostResharingData).resharerRConfig!,
        ),
        resharerStarts: resharerStarts,
      );

      ref.read(pFrostResharingData).startResharedData = result;

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

      await showDialog<void>(
        context: context,
        builder: (_) => StackOkDialog(
          title: "Error",
          message: e.toString(),
          desktopPopRootNavigator: Util.isDesktop,
        ),
      );
    } finally {
      _buttonLock = false;
    }
  }

  @override
  void initState() {
    resharers = ref.read(pFrostResharingData).configData!.resharers;

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
          PrimaryButton(
            label: "Continue",
            enabled: !fieldIsEmptyFlags.reduce((v, e) => v |= e),
            onPressed: _onPressed,
          ),
        ],
      ),
    );
  }
}
