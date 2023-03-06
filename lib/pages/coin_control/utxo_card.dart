import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class UtxoCard extends ConsumerStatefulWidget {
  const UtxoCard({
    Key? key,
    required this.utxo,
    required this.walletId,
    this.selectable = false,
  }) : super(key: key);

  final String walletId;
  final UTXO utxo;
  final bool selectable;

  @override
  ConsumerState<UtxoCard> createState() => _UtxoCardState();
}

class _UtxoCardState extends ConsumerState<UtxoCard> {
  late final UTXO utxo;

  bool _selected = false;

  @override
  void initState() {
    utxo = widget.utxo;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final coin = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(widget.walletId).coin));

    String? label;
    if (utxo.address != null) {
      label = MainDB.instance.isar.addressLabels
          .where()
          .addressStringWalletIdEqualTo(utxo.address!, widget.walletId)
          .findFirstSync()
          ?.value;

      if (label != null && label.isEmpty) {
        label = null;
      }
    }

    return RoundedWhiteContainer(
      child: Row(
        children: [
          SvgPicture.asset(
            _selected
                ? Assets.svg.coinControl.selected
                : utxo.isBlocked
                    ? Assets.svg.coinControl.blocked
                    : Assets.svg.coinControl.unBlocked,
            width: 32,
            height: 32,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${Format.satoshisToAmount(
                    utxo.value,
                    coin: coin,
                  ).toStringAsFixed(coin.decimals)} ${coin.ticker}",
                  style: STextStyles.w600_14(context),
                ),
                const SizedBox(
                  height: 2,
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label ?? utxo.address ?? utxo.txid,
                        style: STextStyles.w500_12(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textSubtitle1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
