import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/add_wallet_views/new_wallet_recovery_phrase_view/new_wallet_recovery_phrase_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:tuple/tuple.dart';

class NewWalletRecoveryPhraseWarningView extends StatefulWidget {
  const NewWalletRecoveryPhraseWarningView({
    Key? key,
    required this.coin,
    required this.walletName,
  }) : super(key: key);

  static const routeName = "/newWalletRecoveryPhraseWarning";

  final Coin coin;
  final String walletName;

  @override
  State<NewWalletRecoveryPhraseWarningView> createState() =>
      _NewWalletRecoveryPhraseWarningViewState();
}

class _NewWalletRecoveryPhraseWarningViewState
    extends State<NewWalletRecoveryPhraseWarningView> {
  late final Coin coin;
  late final String walletName;

  @override
  void initState() {
    coin = widget.coin;
    walletName = widget.walletName;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final _numberOfPhraseWords = coin == Coin.monero
        ? Constants.seedPhraseWordCountMonero
        : Constants.seedPhraseWordCountBip39;

    return Scaffold(
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Container(
        color: CFColors.almostWhite,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: 4,
              ),
              Text(
                walletName,
                textAlign: TextAlign.center,
                style: STextStyles.label.copyWith(
                  fontSize: 12,
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                "Recovery Phrase",
                textAlign: TextAlign.center,
                style: STextStyles.pageTitleH1,
              ),
              const SizedBox(
                height: 16,
              ),
              Container(
                decoration: BoxDecoration(
                  color: CFColors.white,
                  borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    "On the next screen you will see $_numberOfPhraseWords words that make up your recovery phrase.\n\nPlease write it down. Keep it safe and never share it with anyone. Your recovery phrase is the only way you can access your funds if you forget your PIN, lose your phone, etc.\n\nStack Wallet does not keep nor is able to restore your recover phrase. Only you have access to your wallet.",
                    style: STextStyles.subtitle.copyWith(
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Consumer(
                builder: (_, ref, __) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GestureDetector(
                        onTap: () {
                          final value =
                              ref.read(checkBoxStateProvider.state).state;
                          ref.read(checkBoxStateProvider.state).state = !value;
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Row(
                            children: [
                              Checkbox(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                value: ref
                                    .watch(checkBoxStateProvider.state)
                                    .state,
                                onChanged: (newValue) {
                                  ref.read(checkBoxStateProvider.state).state =
                                      newValue!;
                                },
                              ),
                              const SizedBox(
                                width: 4,
                              ),
                              Flexible(
                                child: Text(
                                  "I understand that if I lose my recovery phrase, I will not be able to access my funds.",
                                  style: STextStyles.baseXS,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      TextButton(
                        onPressed: ref.read(checkBoxStateProvider.state).state
                            ? () async {
                                try {
                                  showDialog<dynamic>(
                                    context: context,
                                    barrierDismissible: false,
                                    useSafeArea: true,
                                    builder: (ctx) {
                                      return const Center(
                                        child: LoadingIndicator(
                                          width: 50,
                                          height: 50,
                                        ),
                                      );
                                    },
                                  );

                                  final walletsService = ref.read(
                                      walletsServiceChangeNotifierProvider);

                                  final walletId =
                                      await walletsService.addNewWallet(
                                    name: walletName,
                                    coin: coin,
                                    shouldNotifyListeners: false,
                                  );

                                  var node = ref
                                      .read(nodeServiceChangeNotifierProvider)
                                      .getPrimaryNodeFor(coin: coin);

                                  if (node == null) {
                                    node = DefaultNodes.getNodeFor(coin);
                                    ref
                                        .read(nodeServiceChangeNotifierProvider)
                                        .setPrimaryNodeFor(
                                          coin: coin,
                                          node: node,
                                        );
                                  }

                                  final txTracker =
                                      TransactionNotificationTracker(
                                          walletId: walletId!);

                                  final failovers = ref
                                      .read(nodeServiceChangeNotifierProvider)
                                      .failoverNodesFor(coin: widget.coin);

                                  final wallet = CoinServiceAPI.from(
                                    coin,
                                    walletId,
                                    walletName,
                                    node,
                                    txTracker,
                                    ref.read(prefsChangeNotifierProvider),
                                    failovers,
                                  );

                                  final manager = Manager(wallet);

                                  await manager.initializeNew();

                                  // pop progress dialog
                                  if (mounted) {
                                    Navigator.pop(context);
                                  }
                                  // set checkbox back to unchecked to annoy users to agree again :P
                                  ref.read(checkBoxStateProvider.state).state =
                                      false;

                                  if (mounted) {
                                    Navigator.of(context).pushNamed(
                                      NewWalletRecoveryPhraseView.routeName,
                                      arguments: Tuple2(
                                        manager,
                                        await manager.mnemonic,
                                      ),
                                    );
                                  }
                                } catch (e, s) {
                                  Logging.instance
                                      .log("$e\n$s", level: LogLevel.Fatal);
                                  // TODO: handle gracefully
                                  // any network/socket exception here will break new wallet creation
                                  rethrow;
                                }
                              }
                            : null,
                        style: ref.read(checkBoxStateProvider.state).state
                            ? Theme.of(context).textButtonTheme.style?.copyWith(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                    CFColors.stackAccent,
                                  ),
                                )
                            : Theme.of(context).textButtonTheme.style?.copyWith(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                    CFColors.stackAccent.withOpacity(
                                      0.25,
                                    ),
                                  ),
                                ),
                        child: Text(
                          "View recovery phrase",
                          style: STextStyles.button,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
