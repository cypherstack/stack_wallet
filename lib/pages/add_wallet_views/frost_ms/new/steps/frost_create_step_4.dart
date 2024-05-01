import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/frost_route_generator.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/tx_v2/transaction_v2_details_view.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_copy_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/detail_item.dart';
import 'package:stackwallet/widgets/frost_step_user_steps.dart';

class FrostCreateStep4 extends ConsumerStatefulWidget {
  const FrostCreateStep4({super.key});

  static const String routeName = "/frostCreateStep4";
  static const String title = "Verify multisig ID";

  @override
  ConsumerState<FrostCreateStep4> createState() => _FrostCreateStep4State();
}

class _FrostCreateStep4State extends ConsumerState<FrostCreateStep4> {
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
              ref.read(pFrostCreateCurrentStep.state).state = 5;
              Navigator.of(context).pushNamed(
                ref
                    .read(pFrostScaffoldArgs)!
                    .stepRoutes[ref.read(pFrostCreateCurrentStep) - 1]
                    .routeName,
              );
            },
          )
        ],
      ),
    );
  }
}
