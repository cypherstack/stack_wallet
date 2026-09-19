/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/add_wallet_list_entity/sub_classes/coin_entity.dart';
import '../../models/add_wallet_list_entity/sub_classes/sol_token_entity.dart';
import 'add_token_view/edit_wallet_tokens_view.dart';
import 'create_or_restore_wallet_view/create_or_restore_wallet_view.dart';
import 'verify_recovery_phrase_view/verify_recovery_phrase_view.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../wallets/isar/providers/all_wallets_info_provider.dart';
import '../../wallets/isar/providers/wallet_info_provider.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_app_bar.dart';
import '../../widgets/desktop/desktop_scaffold.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/eth_wallet_radio.dart';
import '../../widgets/rounded_container.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/wallet_info_row/wallet_info_row.dart';
import 'package:tuple/tuple.dart';

final newSolWalletTriggerTempUntilHiveCompletelyDeleted =
    StateProvider((ref) => false);

class SelectWalletForSolTokenView extends ConsumerStatefulWidget {
  const SelectWalletForSolTokenView({
    super.key,
    required this.entity,
  });

  static const String routeName = "/selectWalletForSolTokenView";

  final SolTokenEntity entity;

  @override
  ConsumerState<SelectWalletForSolTokenView> createState() =>
      _SelectWalletForSolTokenViewState();
}

class _SelectWalletForSolTokenViewState
    extends ConsumerState<SelectWalletForSolTokenView> {
  final isDesktop = Util.isDesktop;

  String? _selectedWalletId;

  void _onContinue() {
    Navigator.of(context).pushNamed(
      EditWalletTokensView.routeName,
      arguments: Tuple2(
        _selectedWalletId!,
        [widget.entity.token.address],
      ),
    );
  }

  void _onAddNewSolWallet() {
    ref.read(newSolWalletTriggerTempUntilHiveCompletelyDeleted.notifier).state = true;
    Navigator.of(context).pushNamed(
      CreateOrRestoreWalletView.routeName,
      arguments: CoinEntity(widget.entity.cryptoCurrency),
    );
  }

  @override
  Widget build(BuildContext context) {
    final solWalletInfos = ref
        .watch(pAllWalletsInfo)
        .where((e) => e.coin == widget.entity.cryptoCurrency)
        .toList();

    final _hasSolWallets = solWalletInfos.isNotEmpty;

    final List<String> solWalletIds = [];

    for (final walletId in solWalletInfos.map((e) => e.walletId).toList()) {
      final walletTokens = ref.read(pWalletTokenAddresses(walletId));
      if (!walletTokens.contains(widget.entity.token.address)) {
        solWalletIds.add(walletId);
      }
    }

    return WillPopScope(
      onWillPop: () async {
        ref.read(newSolWalletTriggerTempUntilHiveCompletelyDeleted.notifier).state = false;
        return true;
      },
      child: ConditionalParent(
        condition: !isDesktop,
        builder: (child) => Background(
          child: Scaffold(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.background,
            appBar: AppBar(
              leading: AppBarBackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
        ),
        child: ConditionalParent(
          condition: isDesktop,
          builder: (child) => DesktopScaffold(
            appBar: const DesktopAppBar(
              isCompactHeight: false,
              leading: AppBarBackButton(),
            ),
            body: SizedBox(
              width: 500,
              child: child,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isDesktop)
                const SizedBox(
                  height: 24,
                ),
              Text(
                "Select Solana wallet",
                textAlign: TextAlign.center,
                style: isDesktop
                    ? STextStyles.desktopH2(context)
                    : STextStyles.pageTitleH1(context),
              ),
              SizedBox(
                height: isDesktop ? 16 : 8,
              ),
              Text(
                "You are adding a Solana token.",
                textAlign: TextAlign.center,
                style: isDesktop
                    ? STextStyles.desktopSubtitleH2(context)
                    : STextStyles.subtitle(context),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                "You must choose a Solana wallet in order to use ${widget.entity.name}",
                textAlign: TextAlign.center,
                style: isDesktop
                    ? STextStyles.desktopSubtitleH2(context)
                    : STextStyles.subtitle(context),
              ),
              SizedBox(
                height: isDesktop ? 60 : 16,
              ),
              solWalletIds.isEmpty
                  ? RoundedWhiteContainer(
                      padding: EdgeInsets.all(isDesktop ? 16 : 12),
                      child: Text(
                        _hasSolWallets
                            ? "All current Solana wallets already have ${widget.entity.name}"
                            : "You do not have any Solana wallets",
                        style: isDesktop
                            ? STextStyles.desktopSubtitleH2(context)
                            : STextStyles.label(context),
                      ),
                    )
                  : ConditionalParent(
                      condition: !isDesktop,
                      builder: (child) => Expanded(
                        child: Column(
                          children: [
                            RoundedWhiteContainer(
                              padding: const EdgeInsets.all(8),
                              child: child,
                            ),
                          ],
                        ),
                      ),
                      child: ListView.separated(
                        itemCount: solWalletIds.length,
                        shrinkWrap: true,
                        separatorBuilder: (_, __) => SizedBox(
                          height: isDesktop ? 12 : 6,
                        ),
                        itemBuilder: (_, index) {
                          return RoundedContainer(
                            padding: EdgeInsets.all(isDesktop ? 16 : 8),
                            onPressed: () {
                              setState(() {
                                _selectedWalletId = solWalletIds[index];
                              });
                            },
                            color: isDesktop
                                ? Theme.of(context)
                                    .extension<StackColors>()!
                                    .popupBG
                                : _selectedWalletId == solWalletIds[index]
                                    ? Theme.of(context)
                                        .extension<StackColors>()!
                                        .highlight
                                    : Colors.transparent,
                            child: isDesktop
                                ? EthWalletRadio(
                                    walletId: solWalletIds[index],
                                    selectedWalletId: _selectedWalletId,
                                  )
                                : WalletInfoRow(
                                    walletId: solWalletIds[index],
                                  ),
                          );
                        },
                      ),
                    ),
              if (solWalletIds.isEmpty || isDesktop)
                const SizedBox(
                  height: 16,
                ),
              if (isDesktop)
                const SizedBox(
                  height: 16,
                ),
              solWalletIds.isEmpty
                  ? PrimaryButton(
                      label: "Add new Solana wallet",
                      onPressed: _onAddNewSolWallet,
                    )
                  : PrimaryButton(
                      label: "Continue",
                      enabled: _selectedWalletId != null,
                      onPressed: _onContinue,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
