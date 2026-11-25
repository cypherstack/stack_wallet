/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2025 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../../providers/global/locale_provider.dart';
import '../../../providers/global/price_provider.dart';
import '../../../providers/global/prefs_provider.dart';
import '../../../services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/constants.dart';
import '../../../utilities/text_styles.dart';
import '../../../wallets/crypto_currency/crypto_currency.dart';
import '../../../wallets/isar/providers/solana/current_sol_token_wallet_provider.dart';
import '../../../wallets/isar/providers/solana/sol_token_balance_provider.dart';
import '../../../wallets/isar/providers/wallet_info_provider.dart';
import '../../../widgets/coin_ticker_tag.dart';
import '../../../widgets/conditional_parent.dart';
import '../../../widgets/rounded_container.dart';
import '../../receive_view/sol_token_receive_view.dart';
import '../../send_view/sol_token_send_view.dart';
import '../../wallet_view/sub_widgets/wallet_refresh_button.dart';

/// Solana-specific token summary widget.
///
/// Displays token balance, wallet name, and available actions for Solana tokens.
class SolanaTokenSummary extends ConsumerWidget {
  const SolanaTokenSummary({
    super.key,
    required this.walletId,
    required this.tokenMint,
    required this.initialSyncStatus,
  });

  final String walletId;
  final String tokenMint;
  final WalletSyncStatus initialSyncStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the Solana token wallet.
    final tokenWallet = ref.watch(pCurrentSolanaTokenWallet);

    // If wallet is not initialized, show a placeholder.
    if (tokenWallet == null) {
      return RoundedContainer(
        color: Theme.of(context).extension<StackColors>()!.tokenSummaryBG,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            "Loading token data...",
            style: STextStyles.subtitle500(context).copyWith(
              color:
                  Theme.of(context).extension<StackColors>()!.tokenSummaryTextPrimary,
            ),
          ),
        ),
      );
    }

    // Watch the balance from the database provider.
    final balance = ref.watch(
      pSolanaTokenBalance(
        (
          walletId: walletId,
          tokenMint: tokenMint,
        ),
      ),
    );

    Decimal? price;
    if (ref.watch(prefsChangeNotifierProvider.select((s) => s.externalCalls))) {
      // Get the token price from the price service.
      price = ref.watch(
        priceAnd24hChangeNotifierProvider.select(
          (value) => value.getTokenPrice(tokenMint)?.value,
        ),
      );
    }

    return Stack(
      children: [
        RoundedContainer(
          color: Theme.of(context).extension<StackColors>()!.tokenSummaryBG,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    Assets.svg.walletDesktop,
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.tokenSummaryTextSecondary,
                    width: 12,
                    height: 12,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ref.watch(pWalletName(walletId)),
                    style: STextStyles.w500_12(context).copyWith(
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.tokenSummaryTextSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    balance.total.decimal.toStringAsFixed(tokenWallet.tokenDecimals),
                    style: STextStyles.pageTitleH1(context).copyWith(
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.tokenSummaryTextPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  CoinTickerTag(
                    ticker: tokenWallet.tokenSymbol,
                  ),
                ],
              ),
              if (price != null) const SizedBox(height: 6),
              if (price != null)
                Text(
                  "${(balance.total.decimal * price).toAmount(fractionDigits: 2).fiatString(locale: ref.watch(localeServiceChangeNotifierProvider.select((value) => value.locale)))} ${ref.watch(prefsChangeNotifierProvider.select((value) => value.currency))}",
                  style: STextStyles.subtitle500(context).copyWith(
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.tokenSummaryTextPrimary,
                  ),
                ),
              const SizedBox(height: 20),
              SolanaTokenWalletOptions(
                walletId: walletId,
                tokenMint: tokenMint,
              ),
            ],
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: WalletRefreshButton(
            walletId: walletId,
            initialSyncStatus: initialSyncStatus,
            tokenContractAddress: tokenMint,
            overrideIconColor:
                Theme.of(context).extension<StackColors>()!.topNavIconPrimary,
          ),
        ),
      ],
    );
  }
}

/// Solana token wallet action buttons (Send, Receive, etc.).
class SolanaTokenWalletOptions extends ConsumerWidget {
  const SolanaTokenWalletOptions({
    super.key,
    required this.walletId,
    required this.tokenMint,
  });

  final String walletId;
  final String tokenMint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Use prefs for enabling/disabling exchange features when implemented for Solana.
    // final prefs = ref.watch(prefsChangeNotifierProvider);
    // final showExchange = prefs.enableExchange;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TokenOptionsButton(
          onPressed: () {
            Navigator.of(context).pushNamed(
              SolTokenReceiveView.routeName,
              arguments: (walletId, tokenMint),
            );
          },
          subLabel: "Receive",
          iconAssetPathSVG: Assets.svg.arrowDownLeft,
        ),
        const SizedBox(width: 16),
        TokenOptionsButton(
          onPressed: () {
            Navigator.of(context).pushNamed(
              SolTokenSendView.routeName,
              arguments: (walletId, tokenMint),
            );
          },
          subLabel: "Send",
          iconAssetPathSVG: Assets.svg.arrowUpRight,
        ),
        // TODO: Add swap and buy buttons when Solana token swap/buy views are implemented.
        // if (AppConfig.hasFeature(AppFeature.swap) && showExchange)
        //   const SizedBox(width: 16),
        // if (AppConfig.hasFeature(AppFeature.swap) && showExchange)
        //   TokenOptionsButton(
        //     onPressed: () => _onExchangePressed(context),
        //     subLabel: "Swap",
        //     iconAssetPathSVG: ref.watch(
        //       themeProvider.select((value) => value.assets.exchange),
        //     ),
        //   ),
      ],
    );
  }
}

/// A button for token wallet options (Send, Receive, Swap, Buy).
class TokenOptionsButton extends StatelessWidget {
  const TokenOptionsButton({
    super.key,
    required this.onPressed,
    required this.subLabel,
    required this.iconAssetPathSVG,
  });

  final VoidCallback onPressed;
  final String subLabel;
  final String iconAssetPathSVG;

  @override
  Widget build(BuildContext context) {
    final iconSize = subLabel == "Send" || subLabel == "Receive" ? 12.0 : 24.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RawMaterialButton(
          fillColor:
              Theme.of(context).extension<StackColors>()!.tokenSummaryButtonBG,
          elevation: 0,
          focusElevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          constraints: const BoxConstraints(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
          ),
          onPressed: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: ConditionalParent(
              condition: iconSize < 24,
              builder:
                  (child) => RoundedContainer(
                    padding: const EdgeInsets.all(6),
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .tokenSummaryIcon
                        .withOpacity(0.4),
                    radiusMultiplier: 10,
                    child: Center(child: child),
                  ),
              child:
                  iconAssetPathSVG.startsWith("assets/")
                      ? SvgPicture.asset(
                        iconAssetPathSVG,
                        color:
                            Theme.of(
                              context,
                            ).extension<StackColors>()!.tokenSummaryIcon,
                        width: iconSize,
                        height: iconSize,
                      )
                      : SvgPicture.file(
                        File(iconAssetPathSVG),
                        color:
                            Theme.of(
                              context,
                            ).extension<StackColors>()!.tokenSummaryIcon,
                        width: iconSize,
                        height: iconSize,
                      ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subLabel,
          style: STextStyles.w500_12(context).copyWith(
            color:
                Theme.of(
                  context,
                ).extension<StackColors>()!.tokenSummaryTextPrimary,
          ),
        ),
      ],
    );
  }
}
