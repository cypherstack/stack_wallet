/* 
 * This file is part of Stack Wallet.
 * 
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 * Generated by Cypher Stack on 2023-05-26
 *
 */

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tuple/tuple.dart';

import '../../../../themes/coin_icon_provider.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/assets.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../utilities/util.dart';
import '../../../../wallets/crypto_currency/crypto_currency.dart';
import '../../../../widgets/background.dart';
import '../../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../../widgets/custom_buttons/blue_text_button.dart';
import '../../../../widgets/desktop/desktop_dialog.dart';
import '../../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../sub_widgets/nodes_list.dart';
import 'add_edit_node_view.dart';

class CoinNodesView extends ConsumerStatefulWidget {
  const CoinNodesView({
    super.key,
    required this.coin,
    this.rootNavigator = false,
  });

  static const String routeName = "/coinNodes";

  final CryptoCurrency coin;
  final bool rootNavigator;

  @override
  ConsumerState<CoinNodesView> createState() => _CoinNodesViewState();
}

class _CoinNodesViewState extends ConsumerState<CoinNodesView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Util.isDesktop) {
      return DesktopDialog(
        maxHeight: null,
        maxWidth: 580,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 32,
                ),
                SvgPicture.file(
                  File(
                    ref.watch(
                      coinIconProvider(widget.coin),
                    ),
                  ),
                  width: 24,
                  height: 24,
                ),
                const SizedBox(
                  width: 12,
                ),
                Text(
                  "${widget.coin.prettyName} nodes",
                  style: STextStyles.desktopH3(context),
                  textAlign: TextAlign.center,
                ),
                Expanded(
                  child: DesktopDialogCloseButton(
                    onPressedOverride: Navigator.of(
                      context,
                      rootNavigator: widget.rootNavigator,
                    ).pop,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 32,
                right: 32,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${widget.coin.prettyName} nodes",
                    style: STextStyles.desktopTextExtraSmall(context).copyWith(
                      color:
                          Theme.of(context).extension<StackColors>()!.textDark3,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  CustomTextButton(
                    text: "Add new node",
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AddEditNodeView.routeName,
                        arguments: Tuple4(
                          AddEditNodeViewType.add,
                          widget.coin,
                          null,
                          CoinNodesView.routeName,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: NodesList(
                    coin: widget.coin,
                    popBackToRoute: CoinNodesView.routeName,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: AppBarBackButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            title: Text(
              "${widget.coin.prettyName} nodes",
              style: STextStyles.navBarTitle(context),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 10,
                  bottom: 10,
                  right: 10,
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AppBarIconButton(
                    key: const Key("manageNodesAddNewNodeButtonKey"),
                    size: 36,
                    shadows: const [],
                    color:
                        Theme.of(context).extension<StackColors>()!.background,
                    icon: SvgPicture.asset(
                      Assets.svg.plus,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorDark,
                      width: 20,
                      height: 20,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AddEditNodeView.routeName,
                        arguments: Tuple4(
                          AddEditNodeViewType.add,
                          widget.coin,
                          null,
                          CoinNodesView.routeName,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.only(
              top: 12,
              left: 12,
              right: 12,
            ),
            child: SingleChildScrollView(
              child: NodesList(
                coin: widget.coin,
                popBackToRoute: CoinNodesView.routeName,
              ),
            ),
          ),
        ),
      );
    }
  }
}
