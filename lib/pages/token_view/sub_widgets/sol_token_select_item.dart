/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2025 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/isar/models/solana/sol_contract.dart';
import '../../../pages_desktop_specific/my_stack_view/wallet_view/desktop_sol_token_view.dart';
import '../../../providers/providers.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/constants.dart';
import '../../../utilities/show_loading.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/isar/providers/solana/current_sol_token_wallet_provider.dart';
import '../../../wallets/isar/providers/solana/sol_token_balance_provider.dart';
import '../../../wallets/wallet/impl/solana_wallet.dart';
import '../../../wallets/wallet/impl/sub_wallets/solana_token_wallet.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/dialogs/basic_dialog.dart';
import '../../../widgets/icon_widgets/sol_token_icon.dart';
import '../../../widgets/rounded_white_container.dart';
import '../sol_token_view.dart';

class SolTokenSelectItem extends ConsumerStatefulWidget {
  const SolTokenSelectItem({
    super.key,
    required this.walletId,
    required this.token,
  });

  final String walletId;
  final SolContract token;

  @override
  ConsumerState<SolTokenSelectItem> createState() => _SolTokenSelectItemState();
}

class _SolTokenSelectItemState extends ConsumerState<SolTokenSelectItem> {
  final bool isDesktop = Util.isDesktop;

  Future<bool> _loadTokenWallet(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(pCurrentSolanaTokenWallet)!.init();
      return true;
    } catch (_) {
      await showDialog<void>(
        barrierDismissible: false,
        context: context,
        builder: (context) => BasicDialog(
          title: "Failed to load token data",
          desktopHeight: double.infinity,
          desktopWidth: 450,
          rightButton: PrimaryButton(
            label: "OK",
            onPressed: () {
              Navigator.of(context).pop();
              if (!isDesktop) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      );
      return false;
    }
  }

  void _onPressed() async {
    final old = ref.read(solanaTokenServiceStateProvider);
    // exit previous if there is one
    unawaited(old?.exit());

    // Get the parent Solana wallet.
    final solanaWallet =
        ref.read(pWallets).getWallet(widget.walletId) as SolanaWallet?;
    if (solanaWallet == null) {
      if (mounted) {
        await showDialog<void>(
          barrierDismissible: false,
          context: context,
          builder: (context) => BasicDialog(
            title: "Error: Parent Solana wallet not found",
            desktopHeight: double.infinity,
            desktopWidth: 450,
            rightButton: PrimaryButton(
              label: "OK",
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      }
      return;
    }

    ref.read(solanaTokenServiceStateProvider.state).state = SolanaTokenWallet(
      solanaWallet,
      widget.token,
    );

    final success = await showLoading<bool>(
      whileFuture: _loadTokenWallet(context, ref),
      context: context,
      rootNavigator: isDesktop,
      message: "Loading ${widget.token.name}",
    );

    if (!success!) {
      return;
    }

    if (mounted) {
      unawaited(ref.read(pCurrentSolanaTokenWallet)!.refresh());
      await Navigator.of(context).pushNamed(
        isDesktop ? DesktopSolTokenView.routeName : SolTokenView.routeName,
        arguments: (
          walletId: widget.walletId,
          tokenMint: widget.token.address,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String? priceString;
    if (ref.watch(prefsChangeNotifierProvider.select((s) => s.externalCalls))) {
      priceString = ref.watch(
        priceAnd24hChangeNotifierProvider.select(
          (s) =>
              s.getTokenPrice(widget.token.address)?.value.toStringAsFixed(2),
        ),
      );
    }

    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(0),
      child: MaterialButton(
        key: Key("walletListItemButtonKey_${widget.token.symbol}"),
        padding:
            isDesktop
                ? const EdgeInsets.symmetric(horizontal: 28, vertical: 24)
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
        ),
        onPressed: _onPressed,
        child: Row(
          children: [
            SolTokenIcon(
              mintAddress: widget.token.address,
              size: 32,
            ),
            SizedBox(width: isDesktop ? 12 : 10),
            Expanded(
              child: Consumer(
                builder: (_, ref, __) {
                  // Watch the balance from the database.
                  final balance = ref.watch(
                    pSolanaTokenBalance(
                      (
                        walletId: widget.walletId,
                        tokenMint: widget.token.address,
                      ),
                    ),
                  );

                  // Format the balance.
                  final decimalValue = balance.total.decimal.toStringAsFixed(widget.token.decimals);
                  final balanceString = "$decimalValue ${widget.token.symbol}";

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.token.name,
                            style:
                                isDesktop
                                    ? STextStyles.desktopTextExtraSmall(
                                      context,
                                    ).copyWith(
                                      color:
                                          Theme.of(
                                            context,
                                          ).extension<StackColors>()!.textDark,
                                    )
                                    : STextStyles.titleBold12(context),
                          ),
                          const Spacer(),
                          Text(
                            balanceString,
                            style:
                                isDesktop
                                    ? STextStyles.desktopTextExtraSmall(
                                      context,
                                    ).copyWith(
                                      color:
                                          Theme.of(
                                            context,
                                          ).extension<StackColors>()!.textDark,
                                    )
                                    : STextStyles.itemSubtitle(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            widget.token.symbol,
                            style:
                                isDesktop
                                    ? STextStyles.desktopTextExtraExtraSmall(
                                      context,
                                    )
                                    : STextStyles.itemSubtitle(context),
                          ),
                          const Spacer(),
                          if (priceString != null)
                            Text(
                              "$priceString "
                              "${ref.watch(prefsChangeNotifierProvider.select((value) => value.currency))}",
                              style:
                                  isDesktop
                                      ? STextStyles.desktopTextExtraExtraSmall(
                                        context,
                                      )
                                      : STextStyles.itemSubtitle(context),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
