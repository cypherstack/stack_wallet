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
import 'package:isar_community/isar.dart';

import '../../db/isar/main_db.dart';
import '../../models/isar/models/isar_models.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/custom_buttons/simple_copy_button.dart';
import '../../widgets/rounded_white_container.dart';

class SolanaTokenContractDetailsView extends ConsumerStatefulWidget {
  const SolanaTokenContractDetailsView({
    super.key,
    required this.tokenMint,
    required this.walletId,
  });

  static const String routeName = "/solanaTokenContractDetailsView";

  final String tokenMint;
  final String walletId;

  @override
  ConsumerState<SolanaTokenContractDetailsView> createState() =>
      _SolanaTokenContractDetailsViewState();
}

class _SolanaTokenContractDetailsViewState
    extends ConsumerState<SolanaTokenContractDetailsView> {
  final isDesktop = Util.isDesktop;

  late SolContract token;

  @override
  void initState() {
    token = MainDB.instance.isar.solContracts
        .where()
        .addressEqualTo(widget.tokenMint)
        .findFirstSync()!;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) => Background(
        child: Scaffold(
          backgroundColor: Theme.of(
            context,
          ).extension<StackColors>()!.background,
          appBar: AppBar(
            backgroundColor: Theme.of(
              context,
            ).extension<StackColors>()!.backgroundAppBar,
            leading: AppBarBackButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            titleSpacing: 0,
            title: Text(
              "Token details",
              style: STextStyles.navBarTitle(context),
            ),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (builderContext, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: child,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Item(
            title: "Mint address",
            data: token.address,
            button: SimpleCopyButton(data: token.address),
          ),
          const SizedBox(height: 12),
          _Item(
            title: "Name",
            data: token.name,
            button: SimpleCopyButton(data: token.name),
          ),
          const SizedBox(height: 12),
          _Item(
            title: "Symbol",
            data: token.symbol,
            button: SimpleCopyButton(data: token.symbol),
          ),
          const SizedBox(height: 12),
          _Item(
            title: "Decimals",
            data: token.decimals.toString(),
            button: SimpleCopyButton(data: token.decimals.toString()),
          ),
          if (token.metadataAddress != null) ...[
            const SizedBox(height: 12),
            _Item(
              title: "Metadata address",
              data: token.metadataAddress ?? "",
              button: SimpleCopyButton(data: token.metadataAddress ?? ""),
            ),
          ],
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    super.key,
    required this.title,
    required this.data,
    required this.button,
  });

  final String title;
  final String data;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: STextStyles.itemSubtitle(context)),
              button,
            ],
          ),
          const SizedBox(height: 5),
          data.isNotEmpty
              ? SelectableText(data, style: STextStyles.w500_14(context))
              : Text(
                  "$title will appear here",
                  style: STextStyles.w500_14(context).copyWith(
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.textSubtitle3,
                  ),
                ),
        ],
      ),
    );
  }
}
