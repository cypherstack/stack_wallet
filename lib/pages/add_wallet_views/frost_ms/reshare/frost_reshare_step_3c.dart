import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../frost_route_generator.dart';
import '../../../../providers/frost_wallet/frost_wallet_providers.dart';
import '../../../../utilities/util.dart';
import '../../../../widgets/custom_buttons/checkbox_text_button.dart';
import '../../../../widgets/custom_buttons/frost_qr_dialog_button.dart';
import '../../../../widgets/custom_buttons/simple_copy_button.dart';
import '../../../../widgets/desktop/primary_button.dart';
import '../../../../widgets/detail_item.dart';
import '../../../wallet_view/transaction_views/transaction_details_view.dart';

class FrostReshareStep3c extends ConsumerStatefulWidget {
  const FrostReshareStep3c({super.key});

  static const String routeName = "/frostReshareStep3c";
  static const String title = "Encryption keys";

  @override
  ConsumerState<FrostReshareStep3c> createState() => _FrostReshareStep3cState();
}

class _FrostReshareStep3cState extends ConsumerState<FrostReshareStep3c> {
  bool _userVerifyContinue = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DetailItem(
            title: "My encryption key",
            detail:
                ref.watch(pFrostResharingData).startResharedData!.resharedStart,
            button: Util.isDesktop
                ? IconCopyButton(
                    data: ref
                        .watch(pFrostResharingData)
                        .startResharedData!
                        .resharedStart,
                  )
                : SimpleCopyButton(
                    data: ref
                        .watch(pFrostResharingData)
                        .startResharedData!
                        .resharedStart,
                  ),
          ),
          const SizedBox(height: 12),
          FrostQrDialogPopupButton(
            data:
                ref.watch(pFrostResharingData).startResharedData!.resharedStart,
          ),
          if (!Util.isDesktop) const Spacer(),
          const SizedBox(
            height: 16,
          ),
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
            enabled: _userVerifyContinue,
            onPressed: () {
              ref.read(pFrostCreateCurrentStep.state).state = 4;
              Navigator.of(context).pushNamed(
                ref
                    .read(pFrostScaffoldArgs)!
                    .stepRoutes[ref.read(pFrostCreateCurrentStep) - 1]
                    .routeName,
              );
            },
          ),
        ],
      ),
    );
  }
}
