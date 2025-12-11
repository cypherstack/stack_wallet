/* 
 * This file is part of Stack Wallet.
 * 
 * Copyright (c) 2025 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tuple/tuple.dart';

import '../../../pages/send_view/sub_widgets/transaction_fee_selection_sheet.dart';
import '../../../pages/token_view/solana_token_contract_details_view.dart';
import '../../../pages/token_view/sub_widgets/token_transaction_list_widget_sol.dart';
import '../../../services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/text_styles.dart';
import '../../../wallets/isar/providers/solana/current_sol_token_wallet_provider.dart';
import '../../../wallets/isar/providers/solana/solana_wallet_provider.dart';
import '../../../wallets/isar/providers/wallet_info_provider.dart';
import '../../../widgets/coin_ticker_tag.dart';
import '../../../widgets/custom_buttons/blue_text_button.dart';
import '../../../widgets/desktop/desktop_app_bar.dart';
import '../../../widgets/desktop/desktop_scaffold.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/icon_widgets/sol_token_icon.dart';
import '../../../widgets/rounded_white_container.dart';
import 'sub_widgets/desktop_wallet_features.dart';
import 'sub_widgets/desktop_wallet_summary.dart';
import 'sub_widgets/my_wallet.dart';

/// [eventBus] should only be set during testing.
class DesktopSolTokenView extends ConsumerStatefulWidget {
  const DesktopSolTokenView({
    super.key,
    required this.walletId,
    required this.tokenMint,
    this.eventBus,
  });

  static const String routeName = "/desktopSolTokenView";

  final String walletId;
  final String tokenMint;
  final EventBus? eventBus;

  @override
  ConsumerState<DesktopSolTokenView> createState() => _DesktopTokenViewState();
}

class _DesktopTokenViewState extends ConsumerState<DesktopSolTokenView> {
  static const double sendReceiveColumnWidth = 460;

  late final WalletSyncStatus initialSyncStatus;

  @override
  void initState() {
    // Get the initial sync status from the Solana wallet's refresh mutex.
    final solanaWallet = ref.read(pSolanaWallet(widget.walletId));
    initialSyncStatus = solanaWallet?.refreshMutex.isLocked ?? false
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
              const SizedBox(width: 32),
              SecondaryButton(
                padding: const EdgeInsets.only(left: 12, right: 18),
                buttonHeight: ButtonHeight.s,
                label: ref.watch(pWalletName(widget.walletId)),
                icon: SvgPicture.asset(
                  Assets.svg.arrowLeft,
                  width: 18,
                  height: 18,
                  color: Theme.of(
                    context,
                  ).extension<StackColors>()!.topNavIconPrimary,
                ),
                onPressed: () {
                  ref.refresh(feeSheetSessionCacheProvider);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(width: 15),
            ],
          ),
        ),
        center: Expanded(
          flex: 4,
          child: Consumer(
            builder: (context, ref, _) {
              final tokenWallet = ref.watch(pCurrentSolanaTokenWallet);
              final tokenName = tokenWallet?.tokenName ?? "Token";
              final tokenSymbol = tokenWallet?.tokenSymbol ?? "SOL";
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed(
                    SolanaTokenContractDetailsView.routeName,
                    arguments: Tuple2(
                      widget.tokenMint,
                      widget.walletId,
                    ),
                  );
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    children: [
                      SolTokenIcon(mintAddress: widget.tokenMint, size: 32),
                      const SizedBox(width: 12),
                      Text(tokenName, style: STextStyles.desktopH3(context)),
                      const SizedBox(width: 12),
                      CoinTickerTag(ticker: tokenSymbol),
                    ],
                  ),
                ),
              );
            },
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
                  SolTokenIcon(mintAddress: widget.tokenMint, size: 40),
                  const SizedBox(width: 10),
                  DesktopWalletSummary(
                    walletId: widget.walletId,
                    isToken: true,
                    initialSyncStatus: initialSyncStatus,
                  ),
                  const Spacer(),
                  DesktopWalletFeatures(walletId: widget.walletId),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                SizedBox(
                  width: sendReceiveColumnWidth,
                  child: Text(
                    "My wallet",
                    style: STextStyles.desktopTextExtraSmall(context).copyWith(
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.textFieldActiveSearchIconLeft,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recent transactions",
                        style: STextStyles.desktopTextExtraSmall(context)
                            .copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textFieldActiveSearchIconLeft,
                            ),
                      ),
                      CustomTextButton(
                        text: "See all",
                        onTap: () {
                          // TODO: Navigate to all transactions for this token
                          // Navigator.of(context).pushNamed(
                          //   AllTransactionsV2View.routeName,
                          //   arguments: (
                          //     walletId: widget.walletId,
                          //     tokenMint: "TODO_TOKEN_MINT",
                          //   ),
                          // );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: sendReceiveColumnWidth,
                    child: MyWallet(
                      walletId: widget.walletId,
                      contractAddress: widget.tokenMint,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SolanaTokenTransactionsList(
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
