import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_copy_button.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_edit_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class UtxoDetailsView extends ConsumerStatefulWidget {
  const UtxoDetailsView({
    Key? key,
    required this.utxoId,
    required this.walletId,
  }) : super(key: key);

  static const routeName = "/utxoDetails";

  final Id utxoId;
  final String walletId;

  @override
  ConsumerState<UtxoDetailsView> createState() => _UtxoDetailsViewState();
}

class _UtxoDetailsViewState extends ConsumerState<UtxoDetailsView> {
  static const double _spacing = 12;

  late Stream<UTXO?> stream;
  UTXO? utxo;

  bool _popWithRefresh = false;

  Future<void> _toggleFreeze() async {
    _popWithRefresh = true;
    await MainDB.instance.putUTXO(utxo!.copyWith(isBlocked: !utxo!.isBlocked));
  }

  @override
  void initState() {
    utxo = MainDB.instance.isar.utxos
        .where()
        .idEqualTo(widget.utxoId)
        .findFirstSync()!;

    stream = MainDB.instance.watchUTXO(id: widget.utxoId);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final coin = ref.watch(
      walletsChangeNotifierProvider.select(
        (value) => value.getManager(widget.walletId).coin,
      ),
    );

    final currentHeight = ref.watch(
      walletsChangeNotifierProvider.select(
        (value) => value.getManager(widget.walletId).currentHeight,
      ),
    );

    final confirmed = utxo!.isConfirmed(
      currentHeight,
      coin.requiredConfirmations,
    );

    return ConditionalParent(
      condition: !Util.isDesktop,
      builder: (child) => Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.background,
            leading: AppBarBackButton(
              onPressed: () {
                Navigator.of(context).pop(_popWithRefresh ? "refresh" : null);
              },
            ),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: child,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      child: StreamBuilder<UTXO?>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            utxo = snapshot.data!;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: 10,
              ),
              RoundedWhiteContainer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${Format.satoshisToAmount(
                        utxo!.value,
                        coin: coin,
                      ).toStringAsFixed(
                        coin.decimals,
                      )} ${coin.ticker}",
                      style: STextStyles.pageTitleH2(context),
                    ),
                    Text(
                      utxo!.isBlocked
                          ? "Frozen"
                          : confirmed
                              ? "Available"
                              : "Unconfirmed",
                      style: STextStyles.w500_14(context).copyWith(
                        color: utxo!.isBlocked
                            ? Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorBlue
                            : confirmed
                                ? Theme.of(context)
                                    .extension<StackColors>()!
                                    .accentColorGreen
                                : Theme.of(context)
                                    .extension<StackColors>()!
                                    .accentColorYellow,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: _spacing,
              ),
              RoundedWhiteContainer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Address",
                          style: STextStyles.w500_14(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textSubtitle1,
                          ),
                        ),
                        SimpleCopyButton(
                          data: utxo!.address!,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      utxo!.address!,
                      style: STextStyles.w500_14(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: _spacing,
              ),
              RoundedWhiteContainer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Transaction ID",
                          style: STextStyles.w500_14(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textSubtitle1,
                          ),
                        ),
                        SimpleCopyButton(
                          data: utxo!.txid,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      utxo!.txid,
                      style: STextStyles.w500_14(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: _spacing,
              ),
              RoundedWhiteContainer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Confirmations",
                      style: STextStyles.w500_14(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textSubtitle1,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      "${utxo!.getConfirmations(currentHeight)}",
                      style: STextStyles.w500_14(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: _spacing,
              ),
              RoundedWhiteContainer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Note",
                          style: STextStyles.w500_14(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textSubtitle1,
                          ),
                        ),
                        SimpleEditButton(
                          editValue: utxo!.name,
                          editLabel: "note",
                          onValueChanged: (newName) {
                            MainDB.instance.putUTXO(
                              utxo!.copyWith(
                                name: newName,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      utxo!.name,
                      style: STextStyles.w500_14(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: _spacing,
              ),
              if (utxo!.isBlocked)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RoundedWhiteContainer(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Freeze reason",
                                style: STextStyles.w500_14(context).copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textSubtitle1,
                                ),
                              ),
                              SimpleEditButton(
                                editValue: utxo!.blockedReason ?? "",
                                editLabel: "freeze reason",
                                onValueChanged: (newReason) {
                                  MainDB.instance.putUTXO(
                                    utxo!.copyWith(
                                      blockedReason: newReason,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            utxo!.blockedReason ?? "",
                            style: STextStyles.w500_14(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: _spacing,
                    ),
                  ],
                ),
              const Spacer(),
              SecondaryButton(
                label: utxo!.isBlocked ? "Unfreeze" : "Freeze",
                onPressed: _toggleFreeze,
              ),
              const SizedBox(
                height: 16,
              ),
            ],
          );
        },
      ),
    );
  }
}
