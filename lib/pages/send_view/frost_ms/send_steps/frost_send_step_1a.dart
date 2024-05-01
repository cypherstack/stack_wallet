import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/frost_route_generator.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_frost_wallet.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_copy_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/detail_item.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class FrostSendStep1a extends ConsumerStatefulWidget {
  const FrostSendStep1a({super.key});

  static const String routeName = "/FrostSendStep1a";
  static const String title = "FROST transaction";

  @override
  ConsumerState<FrostSendStep1a> createState() => _FrostSendStep1aState();
}

class _FrostSendStep1aState extends ConsumerState<FrostSendStep1a> {
  static const steps2to4 = [
    "Wait for them to import the transaction config.",
    "Verify that everyone has filled out their forms before continuing. If you "
        "try to continue before everyone is ready, the process will be "
        "canceled.",
    "Check the box and press “Attempt sign”.",
  ];

  bool _attemptSignLock = false;

  Future<void> _attemptSign() async {
    if (_attemptSignLock) {
      return;
    }

    _attemptSignLock = true;

    try {
      final wallet = ref.read(pWallets).getWallet(
            ref.read(pFrostScaffoldArgs)!.walletId!,
          ) as BitcoinFrostWallet;

      final attemptSignRes = await wallet.frostAttemptSignConfig(
        config: ref.read(pFrostTxData.state).state!.frostMSConfig!,
      );

      ref.read(pFrostAttemptSignData.notifier).state = attemptSignRes;

      ref.read(pFrostCreateCurrentStep.state).state = 2;
      await Navigator.of(context).pushNamed(
        ref
            .read(pFrostScaffoldArgs)!
            .stepRoutes[ref.read(pFrostCreateCurrentStep) - 1]
            .routeName,
      );
    } catch (e, s) {
      Logging.instance.log(
        "$e\n$s",
        level: LogLevel.Error,
      );
    } finally {
      _attemptSignLock = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double qrImageSize =
        Util.isDesktop ? 360 : MediaQuery.of(context).size.width - 32;

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
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  "Share this config with the group members. ",
                              style: STextStyles.w600_12(context),
                            ),
                            TextSpan(
                              text:
                                  "You must have the threshold number of signatures (including yours) to send the transaction.",
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
                for (int i = 0; i < steps2to4.length; i++)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${i + 2}.",
                        style: STextStyles.w500_12(context),
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Expanded(
                        child: Text(
                          steps2to4[i],
                          style: STextStyles.w500_12(context),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          SizedBox(
            height: Util.isDesktop ? 20 : 16,
          ),
          SizedBox(
            height: qrImageSize,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                QrImageView(
                  data: ref.watch(pFrostTxData.state).state!.frostMSConfig!,
                  size: qrImageSize,
                  backgroundColor:
                      Theme.of(context).extension<StackColors>()!.background,
                  foregroundColor: Theme.of(context)
                      .extension<StackColors>()!
                      .accentColorDark,
                ),
              ],
            ),
          ),
          if (!Util.isDesktop)
            const SizedBox(
              height: 32,
            ),
          DetailItem(
            title: "Encoded config",
            detail: ref.watch(pFrostTxData.state).state!.frostMSConfig!,
            button: Util.isDesktop
                ? IconCopyButton(
                    data: ref.watch(pFrostTxData.state).state!.frostMSConfig!,
                  )
                : SimpleCopyButton(
                    data: ref.watch(pFrostTxData.state).state!.frostMSConfig!,
                  ),
          ),
          SizedBox(
            height: Util.isDesktop ? 20 : 16,
          ),
          if (!Util.isDesktop)
            const Spacer(
              flex: 2,
            ),
          PrimaryButton(
            label: "Attempt sign",
            onPressed: () {
              _attemptSign();
            },
          ),
        ],
      ),
    );
  }
}
