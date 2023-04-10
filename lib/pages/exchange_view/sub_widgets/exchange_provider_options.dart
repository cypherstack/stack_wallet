import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/exceptions/exchange/pair_unavailable_exception.dart';
import 'package:stackwallet/models/exchange/aggregate_currency.dart';
import 'package:stackwallet/models/exchange/response_objects/estimate.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/exchange/change_now/change_now_exchange.dart';
import 'package:stackwallet/services/exchange/exchange_response.dart';
import 'package:stackwallet/services/exchange/majestic_bank/majestic_bank_exchange.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/animated_text.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class ExchangeProviderOptions extends ConsumerStatefulWidget {
  const ExchangeProviderOptions({
    Key? key,
    required this.fixedRate,
    required this.reversed,
  }) : super(key: key);

  final bool fixedRate;
  final bool reversed;

  @override
  ConsumerState<ExchangeProviderOptions> createState() =>
      _ExchangeProviderOptionsState();
}

class _ExchangeProviderOptionsState
    extends ConsumerState<ExchangeProviderOptions> {
  final isDesktop = Util.isDesktop;

  bool exchangeSupported({
    required String exchangeName,
    required AggregateCurrency? sendCurrency,
    required AggregateCurrency? receiveCurrency,
  }) {
    final send = sendCurrency?.forExchange(exchangeName);
    if (send == null) return false;

    final rcv = receiveCurrency?.forExchange(exchangeName);
    if (rcv == null) return false;

    if (widget.fixedRate) {
      return send.supportsFixedRate && rcv.supportsFixedRate;
    } else {
      return send.supportsEstimatedRate && rcv.supportsEstimatedRate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sendCurrency = ref.watch(exchangeFormStateProvider).sendCurrency;
    final receivingCurrency =
        ref.watch(exchangeFormStateProvider).receiveCurrency;
    final fromAmount = ref.watch(exchangeFormStateProvider).sendAmount;
    final toAmount = ref.watch(exchangeFormStateProvider).receiveAmount;

    final showChangeNow = exchangeSupported(
      exchangeName: ChangeNowExchange.exchangeName,
      sendCurrency: sendCurrency,
      receiveCurrency: receivingCurrency,
    );
    final showMajesticBank = exchangeSupported(
      exchangeName: MajesticBankExchange.exchangeName,
      sendCurrency: sendCurrency,
      receiveCurrency: receivingCurrency,
    );

    return RoundedWhiteContainer(
      padding: isDesktop ? const EdgeInsets.all(0) : const EdgeInsets.all(12),
      borderColor: isDesktop
          ? Theme.of(context).extension<StackColors>()!.background
          : null,
      child: Column(
        children: [
          if (showChangeNow)
            ConditionalParent(
              condition: isDesktop,
              builder: (child) => MouseRegion(
                cursor: SystemMouseCursors.click,
                child: child,
              ),
              child: GestureDetector(
                onTap: () {
                  if (ref.read(exchangeFormStateProvider).exchange.name !=
                      ChangeNowExchange.exchangeName) {
                    ref.read(exchangeFormStateProvider).updateExchange(
                          exchange: ChangeNowExchange.instance,
                          shouldUpdateData: true,
                          shouldNotifyListeners: true,
                        );
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  child: Padding(
                    padding: isDesktop
                        ? const EdgeInsets.all(16)
                        : const EdgeInsets.all(0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding:
                                EdgeInsets.only(top: isDesktop ? 20.0 : 15.0),
                            child: Radio(
                              activeColor: Theme.of(context)
                                  .extension<StackColors>()!
                                  .radioButtonIconEnabled,
                              value: ChangeNowExchange.exchangeName,
                              groupValue: ref.watch(exchangeFormStateProvider
                                  .select((value) => value.exchange.name)),
                              onChanged: (_) {
                                if (ref
                                        .read(exchangeFormStateProvider)
                                        .exchange
                                        .name !=
                                    ChangeNowExchange.exchangeName) {
                                  ref
                                      .read(exchangeFormStateProvider)
                                      .updateExchange(
                                        exchange: ChangeNowExchange.instance,
                                        shouldUpdateData: true,
                                        shouldNotifyListeners: true,
                                      );
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 14,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: SizedBox(
                            width: isDesktop ? 32 : 24,
                            height: isDesktop ? 32 : 24,
                            child: SvgPicture.asset(
                              Assets.exchange.changeNow,
                              width: isDesktop ? 32 : 24,
                              height: isDesktop ? 32 : 24,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ChangeNowExchange.exchangeName,
                                style:
                                    STextStyles.titleBold12(context).copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textDark2,
                                ),
                              ),
                              if (sendCurrency != null &&
                                  receivingCurrency != null &&
                                  toAmount != null &&
                                  toAmount > Decimal.zero &&
                                  fromAmount != null &&
                                  fromAmount > Decimal.zero)
                                FutureBuilder(
                                  future:
                                      ChangeNowExchange.instance.getEstimate(
                                    sendCurrency.ticker,
                                    receivingCurrency.ticker,
                                    widget.reversed ? toAmount : fromAmount,
                                    widget.fixedRate,
                                    widget.reversed,
                                  ),
                                  builder: (context,
                                      AsyncSnapshot<ExchangeResponse<Estimate>>
                                          snapshot) {
                                    if (snapshot.connectionState ==
                                            ConnectionState.done &&
                                        snapshot.hasData) {
                                      final estimate = snapshot.data?.value;
                                      if (estimate != null) {
                                        Coin coin;
                                        try {
                                          coin = coinFromTickerCaseInsensitive(
                                              receivingCurrency.ticker);
                                        } catch (_) {
                                          coin = Coin.bitcoin;
                                        }
                                        Amount rate;
                                        if (estimate.reversed) {
                                          rate = (toAmount /
                                                  estimate.estimatedAmount)
                                              .toDecimal(
                                                  scaleOnInfinitePrecision: 18)
                                              .toAmount(
                                                  fractionDigits:
                                                      coin.decimals);
                                        } else {
                                          rate = (estimate.estimatedAmount /
                                                  fromAmount)
                                              .toDecimal(
                                                  scaleOnInfinitePrecision: 18)
                                              .toAmount(
                                                  fractionDigits:
                                                      coin.decimals);
                                        }

                                        return Text(
                                          "1 ${sendCurrency.ticker.toUpperCase()} ~ ${rate.localizedStringAsFixed(
                                            locale: ref.watch(
                                              localeServiceChangeNotifierProvider
                                                  .select(
                                                      (value) => value.locale),
                                            ),
                                          )} ${receivingCurrency.ticker.toUpperCase()}",
                                          style: STextStyles.itemSubtitle12(
                                                  context)
                                              .copyWith(
                                            color: Theme.of(context)
                                                .extension<StackColors>()!
                                                .textSubtitle1,
                                          ),
                                        );
                                      } else if (snapshot.data?.exception
                                          is PairUnavailableException) {
                                        return Text(
                                          "Unsupported pair",
                                          style: STextStyles.itemSubtitle12(
                                                  context)
                                              .copyWith(
                                            color: Theme.of(context)
                                                .extension<StackColors>()!
                                                .textSubtitle1,
                                          ),
                                        );
                                      } else {
                                        Logging.instance.log(
                                          "$runtimeType failed to fetch rate for ChangeNOW: ${snapshot.data}",
                                          level: LogLevel.Warning,
                                        );
                                        return Text(
                                          "Failed to fetch rate",
                                          style: STextStyles.itemSubtitle12(
                                                  context)
                                              .copyWith(
                                            color: Theme.of(context)
                                                .extension<StackColors>()!
                                                .textSubtitle1,
                                          ),
                                        );
                                      }
                                    } else {
                                      return AnimatedText(
                                        stringsToLoopThrough: const [
                                          "Loading",
                                          "Loading.",
                                          "Loading..",
                                          "Loading...",
                                        ],
                                        style:
                                            STextStyles.itemSubtitle12(context)
                                                .copyWith(
                                          color: Theme.of(context)
                                              .extension<StackColors>()!
                                              .textSubtitle1,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              if (!(sendCurrency != null &&
                                  receivingCurrency != null &&
                                  toAmount != null &&
                                  toAmount > Decimal.zero &&
                                  fromAmount != null &&
                                  fromAmount > Decimal.zero))
                                Text(
                                  "n/a",
                                  style: STextStyles.itemSubtitle12(context)
                                      .copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textSubtitle1,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (showChangeNow && showMajesticBank)
            isDesktop
                ? Container(
                    height: 1,
                    color:
                        Theme.of(context).extension<StackColors>()!.background,
                  )
                : const SizedBox(
                    height: 16,
                  ),

          if (showMajesticBank)
            ConditionalParent(
              condition: isDesktop,
              builder: (child) => MouseRegion(
                cursor: SystemMouseCursors.click,
                child: child,
              ),
              child: GestureDetector(
                onTap: () {
                  if (ref.read(exchangeFormStateProvider).exchange.name !=
                      MajesticBankExchange.exchangeName) {
                    ref.read(exchangeFormStateProvider).updateExchange(
                          exchange: MajesticBankExchange.instance,
                          shouldUpdateData: true,
                          shouldNotifyListeners: true,
                        );
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  child: Padding(
                    padding: isDesktop
                        ? const EdgeInsets.all(16)
                        : const EdgeInsets.all(0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding:
                                EdgeInsets.only(top: isDesktop ? 20.0 : 15.0),
                            child: Radio(
                              activeColor: Theme.of(context)
                                  .extension<StackColors>()!
                                  .radioButtonIconEnabled,
                              value: MajesticBankExchange.exchangeName,
                              groupValue: ref.watch(exchangeFormStateProvider
                                  .select((value) => value.exchange.name)),
                              onChanged: (_) {
                                if (ref
                                        .read(exchangeFormStateProvider)
                                        .exchange
                                        .name !=
                                    MajesticBankExchange.exchangeName) {
                                  ref
                                      .read(exchangeFormStateProvider)
                                      .updateExchange(
                                        exchange: MajesticBankExchange.instance,
                                        shouldUpdateData: true,
                                        shouldNotifyListeners: true,
                                      );
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 14,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: SizedBox(
                            width: isDesktop ? 32 : 24,
                            height: isDesktop ? 32 : 24,
                            child: SvgPicture.asset(
                              Assets.exchange.majesticBankBlue,
                              width: isDesktop ? 32 : 24,
                              height: isDesktop ? 32 : 24,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                MajesticBankExchange.exchangeName,
                                style:
                                    STextStyles.titleBold12(context).copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textDark2,
                                ),
                              ),
                              if (sendCurrency != null &&
                                  receivingCurrency != null &&
                                  toAmount != null &&
                                  toAmount > Decimal.zero &&
                                  fromAmount != null &&
                                  fromAmount > Decimal.zero)
                                FutureBuilder(
                                  future:
                                      MajesticBankExchange.instance.getEstimate(
                                    sendCurrency.ticker,
                                    receivingCurrency.ticker,
                                    widget.reversed ? toAmount : fromAmount,
                                    widget.fixedRate,
                                    widget.reversed,
                                  ),
                                  builder: (context,
                                      AsyncSnapshot<ExchangeResponse<Estimate>>
                                          snapshot) {
                                    if (snapshot.connectionState ==
                                            ConnectionState.done &&
                                        snapshot.hasData) {
                                      final estimate = snapshot.data?.value;
                                      if (estimate != null) {
                                        Coin coin;
                                        try {
                                          coin = coinFromTickerCaseInsensitive(
                                              receivingCurrency.ticker);
                                        } catch (_) {
                                          coin = Coin.bitcoin;
                                        }
                                        Amount rate;
                                        if (estimate.reversed) {
                                          rate = (toAmount /
                                                  estimate.estimatedAmount)
                                              .toDecimal(
                                                  scaleOnInfinitePrecision: 18)
                                              .toAmount(
                                                fractionDigits: coin.decimals,
                                              );
                                        } else {
                                          rate = (estimate.estimatedAmount /
                                                  fromAmount)
                                              .toDecimal(
                                                  scaleOnInfinitePrecision: 18)
                                              .toAmount(
                                                fractionDigits: coin.decimals,
                                              );
                                        }

                                        return Text(
                                          "1 ${sendCurrency.ticker.toUpperCase()} ~ ${rate.localizedStringAsFixed(
                                            locale: ref.watch(
                                              localeServiceChangeNotifierProvider
                                                  .select(
                                                      (value) => value.locale),
                                            ),
                                          )} ${receivingCurrency.ticker.toUpperCase()}",
                                          style: STextStyles.itemSubtitle12(
                                                  context)
                                              .copyWith(
                                            color: Theme.of(context)
                                                .extension<StackColors>()!
                                                .textSubtitle1,
                                          ),
                                        );
                                      } else if (snapshot.data?.exception
                                          is PairUnavailableException) {
                                        return Text(
                                          "Unsupported pair",
                                          style: STextStyles.itemSubtitle12(
                                                  context)
                                              .copyWith(
                                            color: Theme.of(context)
                                                .extension<StackColors>()!
                                                .textSubtitle1,
                                          ),
                                        );
                                      } else {
                                        Logging.instance.log(
                                          "$runtimeType failed to fetch rate for ChangeNOW: ${snapshot.data}",
                                          level: LogLevel.Warning,
                                        );
                                        return Text(
                                          "Failed to fetch rate",
                                          style: STextStyles.itemSubtitle12(
                                                  context)
                                              .copyWith(
                                            color: Theme.of(context)
                                                .extension<StackColors>()!
                                                .textSubtitle1,
                                          ),
                                        );
                                      }
                                    } else {
                                      return AnimatedText(
                                        stringsToLoopThrough: const [
                                          "Loading",
                                          "Loading.",
                                          "Loading..",
                                          "Loading...",
                                        ],
                                        style:
                                            STextStyles.itemSubtitle12(context)
                                                .copyWith(
                                          color: Theme.of(context)
                                              .extension<StackColors>()!
                                              .textSubtitle1,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              if (!(sendCurrency != null &&
                                  receivingCurrency != null &&
                                  toAmount != null &&
                                  toAmount > Decimal.zero &&
                                  fromAmount != null &&
                                  fromAmount > Decimal.zero))
                                Text(
                                  "n/a",
                                  style: STextStyles.itemSubtitle12(context)
                                      .copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textSubtitle1,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // if (isDesktop)
          //   Container(
          //     height: 1,
          //     color: Theme.of(context).extension<StackColors>()!.background,
          //   ),
          // if (!isDesktop)
          //   const SizedBox(
          //     height: 16,
          //   ),
          // ConditionalParent(
          //   condition: isDesktop,
          //   builder: (child) => MouseRegion(
          //     cursor: SystemMouseCursors.click,
          //     child: child,
          //   ),
          //   child: GestureDetector(
          //     onTap: () {
          //       if (ref.read(currentExchangeNameStateProvider.state).state !=
          //           SimpleSwapExchange.exchangeName) {
          //         // ref.read(currentExchangeNameStateProvider.state).state =
          //         //     SimpleSwapExchange.exchangeName;
          //         ref.read(exchangeFormStateProvider).exchange =
          //             Exchange.fromName(ref
          //                 .read(currentExchangeNameStateProvider.state)
          //                 .state);
          //       }
          //     },
          //     child: Container(
          //       color: Colors.transparent,
          //       child: Padding(
          //         padding: isDesktop
          //             ? const EdgeInsets.all(16)
          //             : const EdgeInsets.all(0),
          //         child: Row(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             SizedBox(
          //               width: 20,
          //               height: 20,
          //               child: Radio(
          //                 activeColor: Theme.of(context)
          //                     .extension<StackColors>()!
          //                     .radioButtonIconEnabled,
          //                 value: SimpleSwapExchange.exchangeName,
          //                 groupValue: ref
          //                     .watch(currentExchangeNameStateProvider.state)
          //                     .state,
          //                 onChanged: (value) {
          //                   if (value is String) {
          //                     ref
          //                         .read(currentExchangeNameStateProvider.state)
          //                         .state = value;
          //                     ref.read(exchangeFormStateProvider).exchange =
          //                         Exchange.fromName(ref
          //                             .read(currentExchangeNameStateProvider
          //                                 .state)
          //                             .state);
          //                   }
          //                 },
          //               ),
          //             ),
          //             const SizedBox(
          //               width: 14,
          //             ),
          //             // SvgPicture.asset(
          //             //   Assets.exchange.simpleSwap,
          //             //   width: isDesktop ? 32 : 24,
          //             //   height: isDesktop ? 32 : 24,
          //             // ),
          //             // const SizedBox(
          //             //   width: 10,
          //             // ),
          //             // Expanded(
          //             //   child: Column(
          //             //     mainAxisAlignment: MainAxisAlignment.start,
          //             //     mainAxisSize: MainAxisSize.min,
          //             //     crossAxisAlignment: CrossAxisAlignment.start,
          //             //     children: [
          //             //       Text(
          //             //         SimpleSwapExchange.exchangeName,
          //             //         style: STextStyles.titleBold12(context).copyWith(
          //             //           color: Theme.of(context)
          //             //               .extension<StackColors>()!
          //             //               .textDark2,
          //             //         ),
          //             //       ),
          //             //       if (from != null &&
          //             //           to != null &&
          //             //           toAmount != null &&
          //             //           toAmount! > Decimal.zero &&
          //             //           fromAmount != null &&
          //             //           fromAmount! > Decimal.zero)
          //             //         FutureBuilder(
          //             //           future: SimpleSwapExchange().getEstimate(
          //             //             from!,
          //             //             to!,
          //             //             // reversed ? toAmount! : fromAmount!,
          //             //             fromAmount!,
          //             //             fixedRate,
          //             //             // reversed,
          //             //             false,
          //             //           ),
          //             //           builder: (context,
          //             //               AsyncSnapshot<ExchangeResponse<Estimate>>
          //             //                   snapshot) {
          //             //             if (snapshot.connectionState ==
          //             //                     ConnectionState.done &&
          //             //                 snapshot.hasData) {
          //             //               final estimate = snapshot.data?.value;
          //             //               if (estimate != null) {
          //             //                 Decimal rate = (estimate.estimatedAmount /
          //             //                         fromAmount!)
          //             //                     .toDecimal(
          //             //                         scaleOnInfinitePrecision: 12);
          //             //
          //             //                 Coin coin;
          //             //                 try {
          //             //                   coin =
          //             //                       coinFromTickerCaseInsensitive(to!);
          //             //                 } catch (_) {
          //             //                   coin = Coin.bitcoin;
          //             //                 }
          //             //                 return Text(
          //             //                   "1 ${from!.toUpperCase()} ~ ${Format.localizedStringAsFixed(
          //             //                     value: rate,
          //             //                     locale: ref.watch(
          //             //                       localeServiceChangeNotifierProvider
          //             //                           .select(
          //             //                               (value) => value.locale),
          //             //                     ),
          //             //                     decimalPlaces:
          //             //                         Constants.decimalPlacesForCoin(
          //             //                             coin),
          //             //                   )} ${to!.toUpperCase()}",
          //             //                   style:
          //             //                       STextStyles.itemSubtitle12(context)
          //             //                           .copyWith(
          //             //                     color: Theme.of(context)
          //             //                         .extension<StackColors>()!
          //             //                         .textSubtitle1,
          //             //                   ),
          //             //                 );
          //             //               } else {
          //             //                 Logging.instance.log(
          //             //                   "$runtimeType failed to fetch rate for SimpleSwap: ${snapshot.data}",
          //             //                   level: LogLevel.Warning,
          //             //                 );
          //             //                 return Text(
          //             //                   "Failed to fetch rate",
          //             //                   style:
          //             //                       STextStyles.itemSubtitle12(context)
          //             //                           .copyWith(
          //             //                     color: Theme.of(context)
          //             //                         .extension<StackColors>()!
          //             //                         .textSubtitle1,
          //             //                   ),
          //             //                 );
          //             //               }
          //             //             } else {
          //             //               return AnimatedText(
          //             //                 stringsToLoopThrough: const [
          //             //                   "Loading",
          //             //                   "Loading.",
          //             //                   "Loading..",
          //             //                   "Loading...",
          //             //                 ],
          //             //                 style: STextStyles.itemSubtitle12(context)
          //             //                     .copyWith(
          //             //                   color: Theme.of(context)
          //             //                       .extension<StackColors>()!
          //             //                       .textSubtitle1,
          //             //                 ),
          //             //               );
          //             //             }
          //             //           },
          //             //         ),
          //             //       // if (!(from != null &&
          //             //       //     to != null &&
          //             //       //     (reversed
          //             //       //         ? toAmount != null && toAmount! > Decimal.zero
          //             //       //         : fromAmount != null &&
          //             //       //             fromAmount! > Decimal.zero)))
          //             //       if (!(from != null &&
          //             //           to != null &&
          //             //           toAmount != null &&
          //             //           toAmount! > Decimal.zero &&
          //             //           fromAmount != null &&
          //             //           fromAmount! > Decimal.zero))
          //             //         Text(
          //             //           "n/a",
          //             //           style: STextStyles.itemSubtitle12(context)
          //             //               .copyWith(
          //             //             color: Theme.of(context)
          //             //                 .extension<StackColors>()!
          //             //                 .textSubtitle1,
          //             //           ),
          //             //         ),
          //             //     ],
          //             //   ),
          //             // ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
