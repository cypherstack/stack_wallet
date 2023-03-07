import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/pages/coin_control/utxo_card.dart';
import 'package:stackwallet/pages/coin_control/utxo_details_view.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/toggle.dart';
import 'package:tuple/tuple.dart';

class CoinControlView extends ConsumerStatefulWidget {
  const CoinControlView({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  static const routeName = "/coinControl";

  final String walletId;

  @override
  ConsumerState<CoinControlView> createState() => _CoinControlViewState();
}

class _CoinControlViewState extends ConsumerState<CoinControlView> {
  bool _showAvailable = false;

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final ids = MainDB.instance
        .getUTXOs(widget.walletId)
        .filter()
        .isBlockedEqualTo(_showAvailable)
        .idProperty()
        .findAllSync();

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
            "Coin control",
            style: STextStyles.navBarTitle(context),
          ),
          titleSpacing: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              RoundedWhiteContainer(
                child: Text(
                  "This option allows you to control, freeze, and utilize outputs at your discretion. Tap the output circle to select.",
                  style: STextStyles.subtitle(context),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                height: 48,
                child: Toggle(
                  key: UniqueKey(),
                  onColor: Theme.of(context).extension<StackColors>()!.popupBG,
                  onText: "Available outputs",
                  offColor: Theme.of(context)
                      .extension<StackColors>()!
                      .textFieldDefaultBG,
                  offText: "Frozen outputs",
                  isOn: _showAvailable,
                  onValueChanged: (value) {
                    setState(() {
                      _showAvailable = value;
                    });
                  },
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: ids.length,
                  separatorBuilder: (context, _) => const SizedBox(
                    height: 10,
                  ),
                  itemBuilder: (context, index) {
                    final utxo = MainDB.instance.isar.utxos
                        .where()
                        .idEqualTo(ids[index])
                        .findFirstSync()!;

                    return UtxoCard(
                      key: Key("${utxo.walletId}_${utxo.id}"),
                      walletId: widget.walletId,
                      utxo: utxo,
                      onPressed: () async {
                        final result = await Navigator.of(context).pushNamed(
                          UtxoDetailsView.routeName,
                          arguments: Tuple2(
                            utxo.id,
                            widget.walletId,
                          ),
                        );
                        if (mounted && result == "refresh") {
                          setState(() {});
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
