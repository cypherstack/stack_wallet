import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction.dart';
import 'package:stackwallet/pages/exchange_view/confirm_change_now_send.dart';
import 'package:stackwallet/pages/home_view/home_view.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/building_transaction_dialog.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/animated_text.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class SendFromView extends ConsumerStatefulWidget {
  const SendFromView({
    Key? key,
    required this.coin,
    required this.trade,
    required this.amount,
    required this.address,
  }) : super(key: key);

  static const String routeName = "/sendFrom";

  final Coin coin;
  final Decimal amount;
  final String address;
  final ExchangeTransaction trade;

  @override
  ConsumerState<SendFromView> createState() => _SendFromViewState();
}

class _SendFromViewState extends ConsumerState<SendFromView> {
  late final Coin coin;
  late final Decimal amount;
  late final String address;
  late final ExchangeTransaction trade;

  @override
  void initState() {
    coin = widget.coin;
    address = widget.address;
    amount = widget.amount;
    trade = widget.trade;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).extension<StackColors>()!.background,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "Send ",
          style: STextStyles.navBarTitle(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          // crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Choose your ${coin.ticker} wallet",
              style: STextStyles.pageTitleH1(context),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              "You need to send ${amount.toStringAsFixed(coin == Coin.monero ? Constants.satsPerCoinMonero : coin == Coin.wownero ? Constants.satsPerCoinWownero : Constants.satsPerCoin)} ${coin.ticker}",
              style: STextStyles.itemSubtitle(context),
            ),
            const SizedBox(
              height: 16,
            ),
            ListView(
              shrinkWrap: true,
              children: [
                ...ref
                    .watch(walletsChangeNotifierProvider
                        .select((value) => value.managers))
                    .where((element) => element.coin == coin)
                    .map((e) => SendFromCard(
                          walletId: e.walletId,
                          amount: amount,
                          address: address,
                          trade: trade,
                        ))
                    .toList(growable: false)
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SendFromCard extends ConsumerStatefulWidget {
  const SendFromCard({
    Key? key,
    required this.walletId,
    required this.amount,
    required this.address,
    required this.trade,
  }) : super(key: key);

  final String walletId;
  final Decimal amount;
  final String address;
  final ExchangeTransaction trade;

  @override
  ConsumerState<SendFromCard> createState() => _SendFromCardState();
}

class _SendFromCardState extends ConsumerState<SendFromCard> {
  late final String walletId;
  late final Decimal amount;
  late final String address;
  late final ExchangeTransaction trade;

  @override
  void initState() {
    walletId = widget.walletId;
    amount = widget.amount;
    address = widget.address;
    trade = widget.trade;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final manager = ref.watch(ref
        .watch(walletsChangeNotifierProvider.notifier)
        .getManagerProvider(walletId));

    final locale = ref.watch(
        localeServiceChangeNotifierProvider.select((value) => value.locale));

    final coin = manager.coin;

    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(0),
      child: MaterialButton(
        splashColor: Theme.of(context).extension<StackColors>()!.highlight,
        key: Key("walletsSheetItemButtonKey_$walletId"),
        padding: const EdgeInsets.all(5),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
        ),
        onPressed: () async {
          final _amount = Format.decimalAmountToSatoshis(amount);

          try {
            bool wasCancelled = false;

            unawaited(showDialog<dynamic>(
              context: context,
              useSafeArea: false,
              barrierDismissible: false,
              builder: (context) {
                return BuildingTransactionDialog(
                  onCancel: () {
                    wasCancelled = true;

                    Navigator.of(context).pop();
                  },
                );
              },
            ));

            final txData = await manager.prepareSend(
              address: address,
              satoshiAmount: _amount,
              args: {
                "feeRate": FeeRateType.average,
                // ref.read(feeRateTypeStateProvider)
              },
            );

            if (!wasCancelled) {
              // pop building dialog

              if (mounted) {
                Navigator.of(context).pop();
              }

              txData["note"] =
                  "${trade.fromCurrency.toUpperCase()}/${trade.toCurrency.toUpperCase()} exchange";
              txData["address"] = address;

              if (mounted) {
                await Navigator.of(context).push(
                  RouteGenerator.getRoute(
                    shouldUseMaterialRoute: RouteGenerator.useMaterialPageRoute,
                    builder: (_) => ConfirmChangeNowSendView(
                      transactionInfo: txData,
                      walletId: walletId,
                      routeOnSuccessName: HomeView.routeName,
                      trade: trade,
                    ),
                    settings: const RouteSettings(
                      name: ConfirmChangeNowSendView.routeName,
                    ),
                  ),
                );
              }
            }
          } catch (e) {
            // if (mounted) {
            // pop building dialog
            Navigator.of(context).pop();

            await showDialog<dynamic>(
              context: context,
              useSafeArea: false,
              barrierDismissible: true,
              builder: (context) {
                return StackDialog(
                  title: "Transaction failed",
                  message: e.toString(),
                  rightButton: TextButton(
                    style: Theme.of(context)
                        .extension<StackColors>()!
                        .getSecondaryEnabledButtonColor(context),
                    child: Text(
                      "Ok",
                      style: STextStyles.button(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .buttonTextSecondary,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
            );
            // }
          }
        },
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .colorForCoin(manager.coin)
                    .withOpacity(0.5),
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SvgPicture.asset(
                  Assets.svg.iconFor(coin: coin),
                  width: 20,
                  height: 20,
                ),
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  manager.walletName,
                  style: STextStyles.titleBold12(context),
                ),
                const SizedBox(
                  height: 2,
                ),
                FutureBuilder(
                  future: manager.totalBalance,
                  builder: (builderContext, AsyncSnapshot<Decimal> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      return Text(
                        "${Format.localizedStringAsFixed(
                          value: snapshot.data!,
                          locale: locale,
                          decimalPlaces: coin == Coin.monero
                              ? Constants.satsPerCoinMonero
                              : coin == Coin.wownero
                                  ? Constants.satsPerCoinWownero
                                  : Constants.satsPerCoin,
                        )} ${coin.ticker}",
                        style: STextStyles.itemSubtitle(context),
                      );
                    } else {
                      return AnimatedText(
                        stringsToLoopThrough: const [
                          "Loading balance",
                          "Loading balance.",
                          "Loading balance..",
                          "Loading balance..."
                        ],
                        style: STextStyles.itemSubtitle(context),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
