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
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/isar/models/isar_models.dart';
import '../../notifications/show_flush_bar.dart';
import '../../providers/providers.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/clipboard_interface.dart';
import '../../utilities/constants.dart';
import '../../utilities/text_styles.dart';
import '../../wallets/isar/providers/solana/current_sol_token_wallet_provider.dart';
import '../../wallets/isar/providers/wallet_info_provider.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/icon_widgets/sol_token_icon.dart';
import '../../widgets/qr.dart';
import '../../widgets/rounded_white_container.dart';

class SolTokenReceiveView extends ConsumerStatefulWidget {
  const SolTokenReceiveView({
    super.key,
    required this.walletId,
    required this.tokenMint,
    this.clipboard = const ClipboardWrapper(),
  });

  static const String routeName = "/solTokenReceiveView";

  final String walletId;
  final String tokenMint;
  final ClipboardInterface clipboard;

  @override
  ConsumerState<SolTokenReceiveView> createState() =>
      _SolTokenReceiveViewState();
}

class _SolTokenReceiveViewState extends ConsumerState<SolTokenReceiveView> {
  late final String walletId;
  late final String tokenMint;
  late final ClipboardInterface clipboard;

  @override
  void initState() {
    walletId = widget.walletId;
    tokenMint = widget.tokenMint;
    clipboard = widget.clipboard;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final tokenWallet = ref.watch(pCurrentSolanaTokenWallet);
    final walletName = ref.watch(pWalletName(walletId));
    final receivingAddress = ref.watch(pWalletReceivingAddress(walletId));

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            tokenWallet != null
                ? "Receive ${tokenWallet.tokenSymbol}"
                : "Receive Token",
            style: STextStyles.navBarTitle(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    "Your Solana address",
                    style: STextStyles.itemSubtitle(context),
                  ),
                  const SizedBox(height: 12),
                  RoundedWhiteContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: SizedBox(
                            width: 200,
                            height: 200,
                            child: QR(
                              data: receivingAddress,
                              size: 200,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).extension<StackColors>()!.popupBG,
                            borderRadius: BorderRadius.circular(
                              Constants.size.circularBorderRadius,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                if (tokenWallet != null)
                                  SolTokenIcon(
                                    mintAddress: tokenMint,
                                  )
                                else
                                  SizedBox.square(dimension: 32),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        walletName,
                                        style: STextStyles.titleBold12(
                                          context,
                                        ).copyWith(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      Text(
                                        "Solana wallet",
                                        style: STextStyles.label(
                                          context,
                                        ).copyWith(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  await clipboard.setData(
                                    ClipboardData(text: receivingAddress),
                                  );
                                  if (mounted) {
                                    showFloatingFlushBar(
                                      type: FlushBarType.info,
                                      message: "Address copied",
                                      context: context,
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).extension<StackColors>()!.highlight,
                                    borderRadius: BorderRadius.circular(
                                      Constants.size.circularBorderRadius,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        Assets.svg.copy,
                                        width: 16,
                                        height: 16,
                                        colorFilter: ColorFilter.mode(
                                          Theme.of(
                                            context,
                                          ).extension<StackColors>()!.textDark,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Copy",
                                        style:
                                            STextStyles.smallMed12(context)
                                                .copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).extension<StackColors>()!
                                                      .textDark,
                                                ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Address",
                    style: STextStyles.itemSubtitle(context),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.popupBG,
                      borderRadius: BorderRadius.circular(
                        Constants.size.circularBorderRadius,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        receivingAddress,
                        style: STextStyles.label(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}