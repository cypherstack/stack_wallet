import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/pages/add_wallet_views/new_wallet_recovery_phrase_view/new_wallet_recovery_phrase_view.dart';
import 'package:stackwallet/pages/add_wallet_views/new_wallet_recovery_phrase_warning_view/recovery_phrase_explanation_dialog.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/exit_to_my_stack_button.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
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

    final _numberOfPhraseWords = coin == Coin.monero
        ? Constants.seedPhraseWordCountMonero
        : coin == Coin.wownero
            ? 14
            : Constants.seedPhraseWordCountBip39;

    return MasterScaffold(
      isDesktop: isDesktop,
      appBar: isDesktop
          ? const DesktopAppBar(
              isCompactHeight: false,
              leading: AppBarBackButton(),
              trailing: ExitToMyStackButton(),
            )
          : AppBar(
              leading: const AppBarBackButton(),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 10,
                    bottom: 10,
                    right: 10,
                  ),
                  child: AppBarIconButton(
                    semanticsLabel:
                        "Question Button. Opens A Dialog For Recovery Phrase Explanation.",
                    icon: SvgPicture.asset(
                      Assets.svg.circleQuestion,
                      width: 20,
                      height: 20,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorDark,
                    ),
                    onPressed: () async {
                      await showDialog<void>(
                        context: context,
                        builder: (context) =>
                            const RecoveryPhraseExplanationDialog(),
                      );
                    },
                  ),
                )
              ],
            ),
      body: ConditionalParent(
        condition: !isDesktop,
        builder: (child) => LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: child,
                  ),
                ),
              ),
            );
          },
        ),
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
              padding: const EdgeInsets.all(32),
              width: isDesktop ? 480 : null,
              child: isDesktop
                  ? Text(
                      "On the next screen you will see $_numberOfPhraseWords words that make up your recovery phrase.\n\nPlease write it down. Keep it safe and never share it with anyone. Your recovery phrase is the only way you can access your funds if you forget your PIN, lose your phone, etc.\n\nStack Wallet does not keep nor is able to restore your recover phrase. Only you have access to your wallet.",
                      style: isDesktop
                          ? STextStyles.desktopTextMediumRegular(context)
                          : STextStyles.subtitle(context).copyWith(
                              fontSize: 12,
                            ),
                    )
                  : Column(
                      children: [
                        Text(
                          "Important",
                          style: STextStyles.desktopH3(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorBlue,
                          ),
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: STextStyles.desktopH3(context)
                                .copyWith(fontSize: 18),
                            children: [
                              TextSpan(
                                text: "On the next screen you will be given ",
                                style: STextStyles.desktopH3(context).copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textDark,
                                  fontSize: 18,
                                  height: 1.3,
                                ),
                              ),
                              TextSpan(
                                text: "$_numberOfPhraseWords words",
                                style: STextStyles.desktopH3(context).copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .accentColorBlue,
                                  fontSize: 18,
                                  height: 1.3,
                                ),
                              ),
                              TextSpan(
                                text: ". They are your ",
                                style: STextStyles.desktopH3(context).copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textDark,
                                  fontSize: 18,
                                  height: 1.3,
                                ),
                              ),
                              TextSpan(
                                text: "recovery phrase",
                                style: STextStyles.desktopH3(context).copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .accentColorBlue,
                                  fontSize: 18,
                                  height: 1.3,
                                ),
                              ),
                              TextSpan(
                                text: ".",
                                style: STextStyles.desktopH3(context).copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textDark,
                                  fontSize: 18,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 40,
                        ),
                        Column(
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: RoundedContainer(
                                    radiusMultiplier: 20,
                                    padding: const EdgeInsets.all(9),
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .buttonBackSecondary,
                                    child: SvgPicture.asset(
                                      Assets.svg.pencil,
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .accentColorDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Text(
                                  "Write them down.",
                                  style: STextStyles.navBarTitle(context),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 30,
                            ),
                            Row(
                              children: [
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: RoundedContainer(
                                    radiusMultiplier: 20,
                                    padding: const EdgeInsets.all(8),
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .buttonBackSecondary,
                                    child: SvgPicture.asset(
                                      Assets.svg.lock,
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .accentColorDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Text(
                                  "Keep them safe.",
                                  style: STextStyles.navBarTitle(context),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 30,
                            ),
                            Row(
                              children: [
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: RoundedContainer(
                                    radiusMultiplier: 20,
                                    padding: const EdgeInsets.all(8),
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .buttonBackSecondary,
                                    child: SvgPicture.asset(
                                      Assets.svg.eyeSlash,
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .accentColorDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Expanded(
                                  child: Text(
                                    "Do not show them to anyone.",
                                    style: STextStyles.navBarTitle(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
            ),
            if (!isDesktop) const Spacer(),
            if (!isDesktop)
              const SizedBox(
                height: 16,
              ),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  value: ref
                                      .watch(checkBoxStateProvider.state)
                                      .state,
                                  onChanged: (newValue) {
                                    ref
                                        .read(checkBoxStateProvider.state)
                                        .state = newValue!;
                                  },
                                ),
                              ),
                              SizedBox(
                                width: isDesktop ? 20 : 10,
                              ),
                              Flexible(
                                child: Text(
                                  "I understand that Stack Wallet does not keep and cannot restore my recovery phrase, and If I lose my recovery phrase, I will not be able to access my funds.",
                                  style: isDesktop
                                      ? STextStyles.desktopTextMedium(context)
                                      : STextStyles.baseXS(context).copyWith(
                                          height: 1.3,
                                        ),
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
                                      ref.read(secureStoreProvider),
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
                                  .getPrimaryEnabledButtonStyle(context)
                              : Theme.of(context)
                                  .extension<StackColors>()!
                                  .getPrimaryDisabledButtonStyle(context),
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
