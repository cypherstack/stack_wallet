import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
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
  late Stream<UTXO?> stream;

  UTXO? utxo;

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
    final coin = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(widget.walletId).coin));
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          child: StreamBuilder<UTXO?>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                utxo = snapshot.data!;
              }

              return Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  RoundedWhiteContainer(
                    child: Row(
                      children: [
                        Text(
                          "${Format.satoshisToAmount(
                            utxo!.value,
                            coin: coin,
                          ).toStringAsFixed(
                            coin.decimals,
                          )} ${coin.ticker}",
                        ),
                      ],
                    ),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
