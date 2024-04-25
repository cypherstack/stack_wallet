import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/new/steps/frost_create_step_4.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/new/steps/frost_route_generator.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/tx_v2/transaction_v2_details_view.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_copy_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/detail_item.dart';
import 'package:stackwallet/widgets/frost_step_user_steps.dart';

class FrostCreateStep3 extends ConsumerStatefulWidget {
  const FrostCreateStep3({super.key});

  static const String routeName = "/frostCreateStep3";
  static const String title = "Verify multisig ID";

  @override
  ConsumerState<FrostCreateStep3> createState() => _FrostCreateStep3State();
}

class _FrostCreateStep3State extends ConsumerState<FrostCreateStep3> {
  static const info = [
    "Ensure your multisig ID matches that of each other participant.",
  ];

  late final Uint8List multisigId;

  @override
  void initState() {
    multisigId = ref.read(pFrostCompletedKeyGenData.state).state!.multisigId;

    super.initState();
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
            title: "Multisig ID",
            detail: multisigId.toString(),
            button: Util.isDesktop
                ? IconCopyButton(
                    data: multisigId.toString(),
                  )
                : SimpleCopyButton(
                    data: multisigId.toString(),
                  ),
          ),
          if (!Util.isDesktop) const Spacer(),
          const SizedBox(height: 12),
          PrimaryButton(
            label: "Confirm",
            onPressed: () {
              ref.read(pFrostCreateCurrentStep.state).state = 4;
              Navigator.of(context).pushNamed(
                FrostCreateStep4.routeName,
              );
            },
          )
        ],
      ),
    );
  }
}
