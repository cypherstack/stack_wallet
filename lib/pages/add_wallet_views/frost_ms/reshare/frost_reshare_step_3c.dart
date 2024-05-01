import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/frost_route_generator.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_copy_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/detail_item.dart';

class FrostReshareStep3c extends ConsumerStatefulWidget {
  const FrostReshareStep3c({super.key});

  static const String routeName = "/frostReshareStep3c";
  static const String title = "Encryption keys";

  @override
  ConsumerState<FrostReshareStep3c> createState() => _FrostReshareStep3bState();
}

class _FrostReshareStep3bState extends ConsumerState<FrostReshareStep3c> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                QrImageView(
                  data: ref
                      .watch(pFrostResharingData)
                      .startResharedData!
                      .resharedStart,
                  size: 220,
                  backgroundColor:
                      Theme.of(context).extension<StackColors>()!.background,
                  foregroundColor: Theme.of(context)
                      .extension<StackColors>()!
                      .accentColorDark,
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 16,
          ),
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
          if (!Util.isDesktop) const Spacer(),
          const SizedBox(
            height: 16,
          ),
          PrimaryButton(
            label: "Continue",
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
