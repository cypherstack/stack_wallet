import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/frost_route_generator.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/pages/wallet_view/wallet_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/my_stack_view.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/show_loading.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_copy_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/detail_item.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class FrostSendStep4 extends ConsumerStatefulWidget {
  const FrostSendStep4({super.key});

  static const String routeName = "/FrostSendStep4";
  static const String title = "Preview transaction";

  @override
  ConsumerState<FrostSendStep4> createState() => _FrostSendStep4State();
}

class _FrostSendStep4State extends ConsumerState<FrostSendStep4> {
  bool _broadcastLock = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 220,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                QrImageView(
                  data: ref.watch(pFrostTxData.state).state!.raw!,
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
            height: 12,
          ),
          DetailItem(
            title: "Raw transaction hex",
            detail: ref.watch(pFrostTxData.state).state!.raw!,
            button: Util.isDesktop
                ? IconCopyButton(
                    data: ref.watch(pFrostTxData.state).state!.raw!,
                  )
                : SimpleCopyButton(
                    data: ref.watch(pFrostTxData.state).state!.raw!,
                  ),
          ),
          const SizedBox(
            height: 12,
          ),
          if (!Util.isDesktop) const Spacer(),
          const SizedBox(
            height: 12,
          ),
          PrimaryButton(
            label: "Broadcast Transaction",
            onPressed: () async {
              if (_broadcastLock) {
                return;
              }
              _broadcastLock = true;

              try {
                Exception? ex;
                final txData = await showLoading(
                  whileFuture: ref
                      .read(pWallets)
                      .getWallet(
                        ref.read(pFrostScaffoldArgs)!.walletId!,
                      )
                      .confirmSend(
                        txData: ref.read(pFrostTxData.state).state!,
                      ),
                  context: context,
                  message: "Broadcasting transaction to network",
                  isDesktop: Util.isDesktop,
                  onException: (e) {
                    ex = e;
                  },
                );

                if (ex != null) {
                  throw ex!;
                }

                if (mounted) {
                  if (txData != null) {
                    ref.read(pFrostTxData.state).state = txData;
                    Navigator.of(context).popUntil(
                      ModalRoute.withName(
                        Util.isDesktop
                            ? MyStackView.routeName
                            : WalletView.routeName,
                      ),
                    );
                  }
                }
              } catch (e, s) {
                Logging.instance.log(
                  "$e\n$s",
                  level: LogLevel.Fatal,
                );

                return await showDialog<void>(
                  context: context,
                  builder: (_) => StackOkDialog(
                    title: "Broadcast error",
                    message: e.toString(),
                    desktopPopRootNavigator: Util.isDesktop,
                  ),
                );
              } finally {
                _broadcastLock = false;
              }
            },
          ),
        ],
      ),
    );
  }
}
