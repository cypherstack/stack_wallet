import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/exceptions/exchange/pair_unavailable_exception.dart';
import 'package:stackwallet/models/exchange/response_objects/estimate.dart';
import 'package:stackwallet/providers/exchange/exchange_form_state_provider.dart';
import 'package:stackwallet/providers/global/locale_provider.dart';
import 'package:stackwallet/services/exchange/exchange.dart';
import 'package:stackwallet/services/exchange/exchange_response.dart';
import 'package:stackwallet/services/exchange/trocador/trocador_exchange.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/animated_text.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/exchange/trocador/trocador_kyc_info_button.dart';
import 'package:stackwallet/widgets/exchange/trocador/trocador_rating_type_enum.dart';

class ExchangeProviderOption extends ConsumerStatefulWidget {
  const ExchangeProviderOption({
    Key? key,
    required this.exchange,
    required this.exchangeProvider,
    required this.fixedRate,
    required this.reversed,
  }) : super(key: key);

  final Exchange exchange;
  final String exchangeProvider;
  final bool fixedRate;
  final bool reversed;

  @override
  ConsumerState<ExchangeProviderOption> createState() =>
      _ExchangeProviderOptionState();
}

class _ExchangeProviderOptionState
    extends ConsumerState<ExchangeProviderOption> {
  final isDesktop = Util.isDesktop;
  late final String _id;

  @override
  void initState() {
    _id = "${widget.exchange.name} (${widget.exchangeProvider})";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final sendCurrency = ref
        .watch(exchangeFormStateProvider.select((value) => value.sendCurrency));
    final receivingCurrency = ref.watch(
        exchangeFormStateProvider.select((value) => value.receiveCurrency));
    final fromAmount = ref
        .watch(exchangeFormStateProvider.select((value) => value.sendAmount));
    final toAmount = ref.watch(
        exchangeFormStateProvider.select((value) => value.receiveAmount));

    final selected = ref.watch(exchangeFormStateProvider
            .select((value) => value.combinedExchangeId)) ==
        _id;

    return ConditionalParent(
      condition: isDesktop,
      builder: (child) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: child,
      ),
      child: GestureDetector(
        onTap: () {
          if (!selected) {
            // showLoading(
            //   whileFuture:
            ref.read(exchangeFormStateProvider).updateExchange(
                  exchange: widget.exchange,
                  shouldUpdateData: true,
                  shouldNotifyListeners: true,
                  providerName: widget.exchangeProvider,
                  //     ),
                  // context: context,
                  // message: "Updating rates",
                  // isDesktop: isDesktop,
                );
          }
        },
        child: Container(
          color: Colors.transparent,
          child: Padding(
            padding:
                isDesktop ? const EdgeInsets.all(16) : const EdgeInsets.all(0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Padding(
                    padding: EdgeInsets.only(top: isDesktop ? 20.0 : 15.0),
                    child: Radio(
                      activeColor: Theme.of(context)
                          .extension<StackColors>()!
                          .radioButtonIconEnabled,
                      value: _id,
                      groupValue: ref.watch(exchangeFormStateProvider
                          .select((value) => value.combinedExchangeId)),
                      onChanged: (_) {
                        if (!selected) {
                          ref.read(exchangeFormStateProvider).updateExchange(
                                exchange: widget.exchange,
                                shouldUpdateData: false,
                                shouldNotifyListeners: true,
                                providerName: widget.exchangeProvider,
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
                      Assets.exchange.getIconFor(
                        exchangeName: widget.exchange.name,
                      ),
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
                        widget.exchangeProvider,
                        style: STextStyles.titleBold12(context).copyWith(
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
                          future: widget.exchange.getEstimates(
                            sendCurrency.ticker,
                            receivingCurrency.ticker,
                            widget.reversed ? toAmount : fromAmount,
                            widget.fixedRate,
                            widget.reversed,
                          ),
                          builder: (context,
                              AsyncSnapshot<ExchangeResponse<List<Estimate>>>
                                  snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.hasData) {
                              final estimates = snapshot.data?.value;
                              if (estimates != null &&
                                  estimates
                                      .where((e) =>
                                          e.exchangeProvider ==
                                          widget.exchangeProvider)
                                      .isNotEmpty) {
                                final estimate = estimates.firstWhere((e) =>
                                    e.exchangeProvider ==
                                    widget.exchangeProvider);
                                int decimals;
                                try {
                                  decimals = coinFromTickerCaseInsensitive(
                                          receivingCurrency.ticker)
                                      .decimals;
                                } catch (_) {
                                  decimals = 8; // some reasonable alternative
                                }
                                Amount rate;
                                if (estimate.reversed) {
                                  rate = (toAmount / estimate.estimatedAmount)
                                      .toDecimal(scaleOnInfinitePrecision: 18)
                                      .toAmount(fractionDigits: decimals);
                                } else {
                                  rate = (estimate.estimatedAmount / fromAmount)
                                      .toDecimal(scaleOnInfinitePrecision: 18)
                                      .toAmount(fractionDigits: decimals);
                                }

                                return ConditionalParent(
                                  condition: widget.exchange.name ==
                                      TrocadorExchange.exchangeName,
                                  builder: (child) {
                                    return Row(
                                      children: [
                                        child,
                                        TrocadorKYCInfoButton(
                                          kycType: TrocadorKYCType.fromString(
                                            estimate.kycRating!,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                  child: Text(
                                    "1 ${sendCurrency.ticker.toUpperCase()} ~ ${rate.localizedStringAsFixed(
                                      locale: ref.watch(
                                        localeServiceChangeNotifierProvider
                                            .select((value) => value.locale),
                                      ),
                                    )} ${receivingCurrency.ticker.toUpperCase()}",
                                    style: STextStyles.itemSubtitle12(context)
                                        .copyWith(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .textSubtitle1,
                                    ),
                                  ),
                                );
                              } else if (snapshot.data?.exception
                                  is PairUnavailableException) {
                                return Text(
                                  "Unsupported pair",
                                  style: STextStyles.itemSubtitle12(context)
                                      .copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textSubtitle1,
                                  ),
                                );
                              } else {
                                Logging.instance.log(
                                  "$runtimeType failed to fetch rate for $_id}: ${snapshot.data}",
                                  level: LogLevel.Warning,
                                );
                                return Text(
                                  "Failed to fetch rate",
                                  style: STextStyles.itemSubtitle12(context)
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
                                style: STextStyles.itemSubtitle12(context)
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
                          style: STextStyles.itemSubtitle12(context).copyWith(
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
    );
  }
}
