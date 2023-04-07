import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/token_view/sub_widgets/token_summary.dart';
import 'package:stackwallet/pages/token_view/sub_widgets/token_transaction_list_widget.dart';
import 'package:stackwallet/pages/token_view/token_view.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/all_transactions_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_wallet_features.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_wallet_summary.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/my_wallet.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/eth_token_icon.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

/// [eventBus] should only be set during testing
class DesktopTokenView extends ConsumerStatefulWidget {
  const DesktopTokenView({
    Key? key,
    required this.walletId,
    this.eventBus,
  }) : super(key: key);

  static const String routeName = "/desktopTokenView";

  final String walletId;
  final EventBus? eventBus;

  @override
  ConsumerState<DesktopTokenView> createState() => _DesktopTokenViewState();
}

class _DesktopTokenViewState extends ConsumerState<DesktopTokenView> {
  static const double sendReceiveColumnWidth = 460;

  late final WalletSyncStatus initialSyncStatus;

  @override
  void initState() {
    initialSyncStatus = ref.read(tokenServiceProvider)!.isRefreshing
        ? WalletSyncStatus.syncing
        : WalletSyncStatus.synced;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return DesktopScaffold(
      appBar: DesktopAppBar(
        background: Theme.of(context).extension<StackColors>()!.popupBG,
        leading: Expanded(
          flex: 3,
          child: Row(
            children: [
              const SizedBox(
                width: 32,
              ),
              SecondaryButton(
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 18,
                ),
                buttonHeight: ButtonHeight.s,
                label: ref.watch(
                  walletsChangeNotifierProvider.select(
                    (value) => value.getManager(widget.walletId).walletName,
                  ),
                ),
                icon: SvgPicture.asset(
                  Assets.svg.arrowLeft,
                  width: 18,
                  height: 18,
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .topNavIconPrimary,
                ),
                onPressed: Navigator.of(context).pop,
              ),
              const SizedBox(
                width: 15,
              ),
            ],
          ),
        ),
        center: Expanded(
          flex: 4,
          child: Row(
            children: [
              EthTokenIcon(
                contractAddress: ref.watch(
                  tokenServiceProvider.select(
                    (value) => value!.tokenContract.address,
                  ),
                ),
                size: 32,
              ),
              const SizedBox(
                width: 12,
              ),
              Text(
                ref.watch(
                  tokenServiceProvider.select(
                    (value) => value!.tokenContract.name,
                  ),
                ),
                style: STextStyles.desktopH3(context),
              ),
              const SizedBox(
                width: 12,
              ),
              CoinTickerTag(
                walletId: widget.walletId,
              ),
            ],
          ),
        ),
        useSpacers: false,
        isCompactHeight: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            RoundedWhiteContainer(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  EthTokenIcon(
                    contractAddress: ref.watch(
                      tokenServiceProvider.select(
                        (value) => value!.tokenContract.address,
                      ),
                    ),
                    size: 40,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  DesktopWalletSummary(
                    walletId: widget.walletId,
                    isToken: true,
                    initialSyncStatus: ref.watch(
                            walletsChangeNotifierProvider.select((value) =>
                                value.getManager(widget.walletId).isRefreshing))
                        ? WalletSyncStatus.syncing
                        : WalletSyncStatus.synced,
                  ),
                  const Spacer(),
                  DesktopWalletFeatures(
                    walletId: widget.walletId,
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            Row(
              children: [
                SizedBox(
                  width: sendReceiveColumnWidth,
                  child: Text(
                    "My wallet",
                    style: STextStyles.desktopTextExtraSmall(context).copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textFieldActiveSearchIconLeft,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recent transactions",
                        style:
                            STextStyles.desktopTextExtraSmall(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textFieldActiveSearchIconLeft,
                        ),
                      ),
                      CustomTextButton(
                        text: "See all",
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AllTransactionsView.routeName,
                            arguments: widget.walletId,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 14,
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: sendReceiveColumnWidth,
                    child: MyWallet(
                      walletId: widget.walletId,
                      contractAddress: ref.watch(
                        tokenServiceProvider.select(
                          (value) => value!.tokenContract.address,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: TokenTransactionsList(
                      walletId: widget.walletId,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
