import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/pages/coin_control/utxo_details_view.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/utxo_status_icon.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

class UtxoRowData {
  UtxoRowData(this.utxoId, this.selected);

  Id utxoId;
  bool selected;

  @override
  String toString() {
    return "selected=$selected: $utxoId";
  }

  @override
  bool operator ==(Object other) {
    return other is UtxoRowData && other.utxoId == utxoId;
  }

  @override
  int get hashCode => Object.hashAll([utxoId.hashCode]);
}

class UtxoRow extends ConsumerStatefulWidget {
  const UtxoRow({
    Key? key,
    required this.data,
    required this.walletId,
    this.onSelectionChanged,
    this.compact = false,
    this.compactWithBorder = true,
    this.raiseOnSelected = true,
  }) : super(key: key);

  final String walletId;
  final UtxoRowData data;
  final void Function(UtxoRowData)? onSelectionChanged;
  final bool compact;
  final bool compactWithBorder;
  final bool raiseOnSelected;

  @override
  ConsumerState<UtxoRow> createState() => _UtxoRowState();
}

class _UtxoRowState extends ConsumerState<UtxoRow> {
  late Stream<UTXO?> stream;
  late UTXO utxo;

  void _details() async {
    await showDialog<String?>(
      context: context,
      builder: (context) => UtxoDetailsView(
        utxoId: utxo.id,
        walletId: widget.walletId,
      ),
    );
  }

  @override
  void initState() {
    utxo = MainDB.instance.isar.utxos
        .where()
        .idEqualTo(widget.data.utxoId)
        .findFirstSync()!;

    stream = MainDB.instance.watchUTXO(id: utxo.id);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final coin = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(widget.walletId).coin));

    final currentChainHeight = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(widget.walletId).currentHeight));

    return StreamBuilder<UTXO?>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          utxo = snapshot.data!;
        }

        return RoundedContainer(
          borderColor: widget.compact && widget.compactWithBorder
              ? Theme.of(context).extension<StackColors>()!.textFieldDefaultBG
              : null,
          color: Theme.of(context).extension<StackColors>()!.popupBG,
          boxShadow: widget.data.selected && widget.raiseOnSelected
              ? [
                  Theme.of(context).extension<StackColors>()!.standardBoxShadow,
                ]
              : null,
          child: Row(
            children: [
              if (!(widget.compact && utxo.isBlocked))
                Checkbox(
                  value: widget.data.selected,
                  onChanged: (value) {
                    setState(() {
                      widget.data.selected = value!;
                    });
                    widget.onSelectionChanged?.call(widget.data);
                  },
                ),
              if (!(widget.compact && utxo.isBlocked))
                const SizedBox(
                  width: 10,
                ),
              UTXOStatusIcon(
                blocked: utxo.isBlocked,
                status: utxo.isConfirmed(
                  currentChainHeight,
                  coin.requiredConfirmations,
                )
                    ? UTXOStatusIconStatus.confirmed
                    : UTXOStatusIconStatus.unconfirmed,
                background: Theme.of(context).extension<StackColors>()!.popupBG,
                selected: false,
                width: 32,
                height: 32,
              ),
              const SizedBox(
                width: 10,
              ),
              if (!widget.compact)
                Text(
                  "${Format.satoshisToAmount(
                    utxo.value,
                    coin: coin,
                  ).toStringAsFixed(coin.decimals)} ${coin.ticker}",
                  textAlign: TextAlign.right,
                  style: STextStyles.w600_14(context),
                ),
              if (!widget.compact)
                const SizedBox(
                  width: 10,
                ),
              Expanded(
                child: ConditionalParent(
                  condition: widget.compact,
                  builder: (child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${Format.satoshisToAmount(
                            utxo.value,
                            coin: coin,
                          ).toStringAsFixed(coin.decimals)} ${coin.ticker}",
                          textAlign: TextAlign.right,
                          style: STextStyles.w600_14(context),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        child,
                      ],
                    );
                  },
                  child: Text(
                    utxo.name.isNotEmpty
                        ? utxo.name
                        : utxo.address ?? utxo.txid,
                    textAlign:
                        widget.compact ? TextAlign.left : TextAlign.center,
                    style: STextStyles.w500_12(context).copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textSubtitle1,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              widget.compact
                  ? CustomTextButton(
                      text: "Details",
                      onTap: _details,
                    )
                  : SecondaryButton(
                      width: 120,
                      buttonHeight: ButtonHeight.xs,
                      label: "Details",
                      onPressed: _details,
                    ),
            ],
          ),
        );
      },
    );
  }
}
