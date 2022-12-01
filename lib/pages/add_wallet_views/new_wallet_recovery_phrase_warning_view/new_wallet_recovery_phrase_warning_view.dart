import 'dart:async';

import 'package:epicmobile/pages/add_wallet_views/new_wallet_recovery_phrase_view/new_wallet_recovery_phrase_view.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/services/coins/coin_service.dart';
import 'package:epicmobile/services/coins/manager.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/default_nodes.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/logger.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/utilities/util.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/desktop/desktop_scaffold.dart';
import 'package:epicmobile/widgets/loading_indicator.dart';
import 'package:epicmobile/widgets/rounded_white_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  late final bool isDesktop;

  @override
  void initState() {
    coin = widget.coin;
    walletName = widget.walletName;
    isDesktop = Util.isDesktop;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final _numberOfPhraseWords = Constants.seedPhraseWordCountBip39;

    return MasterScaffold(
      isDesktop: isDesktop,
      appBar: AppBar(
        leading: const AppBarBackButton(),
      ),
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 0 : 16),
        child: Column(
          crossAxisAlignment: isDesktop
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.stretch,
          children: [
            if (isDesktop)
              const Spacer(
                flex: 10,
              ),
            if (!isDesktop)
              const SizedBox(
                height: 4,
              ),
            if (!isDesktop)
              Text(
                walletName,
                textAlign: TextAlign.center,
                style: STextStyles.label(context).copyWith(
                  fontSize: 12,
                ),
              ),
            if (!isDesktop)
              const SizedBox(
                height: 4,
              ),
            Text(
              "Recovery Phrase",
              textAlign: TextAlign.center,
              style: isDesktop
                  ? STextStyles.desktopH2(context)
                  : STextStyles.pageTitleH1(context),
            ),
            SizedBox(
              height: isDesktop ? 32 : 16,
            ),
            RoundedWhiteContainer(
              padding: isDesktop
                  ? const EdgeInsets.all(32)
                  : const EdgeInsets.all(12),
              width: isDesktop ? 480 : null,
              child: Text(
                "On the next screen you will see $_numberOfPhraseWords words that make up your recovery phrase.\n\nPlease write it down. Keep it safe and never share it with anyone. Your recovery phrase is the only way you can access your funds if you forget your PIN, lose your phone, etc.\n\nEpic Mobile does not keep nor is able to restore your recover phrase. Only you have access to your wallet.",
                style: isDesktop
                    ? STextStyles.desktopTextMediumRegular(context)
                    : STextStyles.subtitle(context).copyWith(
                        fontSize: 12,
                      ),
              ),
            ),
            if (!isDesktop) const Spacer(),
            if (isDesktop)
              const SizedBox(
                height: 32,
              ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 480 : 0,
              ),
              child: Consumer(
                builder: (_, ref, __) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
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
                            crossAxisAlignment: isDesktop
                                ? CrossAxisAlignment.start
                                : CrossAxisAlignment.center,
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
                              SizedBox(
                                width: isDesktop ? 14 : 4,
                              ),
                              Flexible(
                                child: Text(
                                  "I understand that if I lose my recovery phrase, I will not be able to access my funds.",
                                  style: isDesktop
                                      ? STextStyles.desktopTextMedium(context)
                                      : STextStyles.baseXS(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: isDesktop ? 32 : 16,
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: isDesktop ? 70 : 0,
                        ),
                        child: TextButton(
                          onPressed: ref.read(checkBoxStateProvider.state).state
                              ? () async {
                                  try {
                                    unawaited(showDialog<dynamic>(
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
                                    ));

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
                                      await ref
                                          .read(
                                              nodeServiceChangeNotifierProvider)
                                          .setPrimaryNodeFor(
                                            coin: coin,
                                            node: node,
                                          );
                                    }

                                    final failovers = ref
                                        .read(nodeServiceChangeNotifierProvider)
                                        .failoverNodesFor(coin: widget.coin);

                                    final wallet = CoinServiceAPI.from(
                                      coin,
                                      walletId!,
                                      walletName,
                                      node,
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
                                    ref
                                        .read(checkBoxStateProvider.state)
                                        .state = false;

                                    if (mounted) {
                                      unawaited(Navigator.of(context).pushNamed(
                                        NewWalletRecoveryPhraseView.routeName,
                                        arguments: Tuple2(
                                          manager,
                                          await manager.mnemonic,
                                        ),
                                      ));
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
                              ? Theme.of(context)
                                  .extension<StackColors>()!
                                  .getPrimaryEnabledButtonColor(context)
                              : Theme.of(context)
                                  .extension<StackColors>()!
                                  .getPrimaryDisabledButtonColor(context),
                          child: Text(
                            "View recovery phrase",
                            style: isDesktop
                                ? ref.read(checkBoxStateProvider.state).state
                                    ? STextStyles.desktopButtonEnabled(context)
                                    : STextStyles.desktopButtonDisabled(context)
                                : STextStyles.button(context),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (isDesktop)
              const Spacer(
                flex: 15,
              ),
          ],
        ),
      ),
    );
  }
}
