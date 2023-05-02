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

class ExchangeOption extends ConsumerStatefulWidget {
  const ExchangeOption({
    Key? key,
    required this.exchange,
    required this.fixedRate,
    required this.reversed,
  }) : super(key: key);

  final Exchange exchange;
  final bool fixedRate;
  final bool reversed;

  @override
  ConsumerState<ExchangeOption> createState() =>
      _ExchangeMultiProviderOptionState();
}

class _ExchangeMultiProviderOptionState extends ConsumerState<ExchangeOption> {
  final isDesktop = Util.isDesktop;

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

    return AnimatedSize(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubicEmphasized,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                  AsyncSnapshot<ExchangeResponse<List<Estimate>>> snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  final estimates = snapshot.data?.value;

                  if (estimates != null && estimates.isNotEmpty) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < estimates.length; i++)
                          Builder(
                            builder: (context) {
                              final e = estimates[i];
                              int decimals;
                              try {
                                decimals = coinFromTickerCaseInsensitive(
                                        receivingCurrency.ticker)
                                    .decimals;
                              } catch (_) {
                                decimals = 8; // some reasonable alternative
                              }
                              Amount rate;
                              if (e.reversed) {
                                rate = (toAmount / e.estimatedAmount)
                                    .toDecimal(scaleOnInfinitePrecision: 18)
                                    .toAmount(fractionDigits: decimals);
                              } else {
                                rate = (e.estimatedAmount / fromAmount)
                                    .toDecimal(scaleOnInfinitePrecision: 18)
                                    .toAmount(fractionDigits: decimals);
                              }

                              final rateString =
                                  "1 ${sendCurrency.ticker.toUpperCase()} ~ ${rate.localizedStringAsFixed(
                                locale: ref.watch(
                                  localeServiceChangeNotifierProvider
                                      .select((value) => value.locale),
                                ),
                              )} ${receivingCurrency.ticker.toUpperCase()}";

                              return ConditionalParent(
                                condition: i > 0,
                                builder: (child) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    isDesktop
                                        ? Container(
                                            height: 1,
                                            color: Theme.of(context)
                                                .extension<StackColors>()!
                                                .background,
                                          )
                                        : const SizedBox(
                                            height: 16,
                                          ),
                                    child,
                                  ],
                                ),
                                child: _ProviderOption(
                                  key: Key(widget.exchange.name +
                                      e.exchangeProvider),
                                  exchange: widget.exchange,
                                  providerName: e.exchangeProvider,
                                  rateString: rateString,
                                  kycRating: e.kycRating,
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  } else if (snapshot.data?.exception
                      is PairUnavailableException) {
                    return _ProviderOption(
                      exchange: widget.exchange,
                      providerName: widget.exchange.name,
                      rateString: "Unsupported pair",
                    );
                  } else {
                    Logging.instance.log(
                      "$runtimeType failed to fetch rate for ${widget.exchange.name}: ${snapshot.data}",
                      level: LogLevel.Warning,
                    );

                    return _ProviderOption(
                      exchange: widget.exchange,
                      providerName: widget.exchange.name,
                      rateString: "Failed to fetch rate",
                    );
                  }
                } else {
                  // show loading
                  return _ProviderOption(
                    exchange: widget.exchange,
                    providerName: widget.exchange.name,
                    rateString: "",
                    loadingString: true,
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}

class _ProviderOption extends ConsumerStatefulWidget {
  const _ProviderOption({
    Key? key,
    required this.exchange,
    required this.providerName,
    required this.rateString,
    this.kycRating,
    this.loadingString = false,
  }) : super(key: key);

  final Exchange exchange;
  final String providerName;
  final String rateString;
  final String? kycRating;
  final bool loadingString;

  @override
  ConsumerState<_ProviderOption> createState() => _ProviderOptionState();
}

class _ProviderOptionState extends ConsumerState<_ProviderOption> {
  final isDesktop = Util.isDesktop;

  late final String _id;

  @override
  void initState() {
    _id = "${widget.exchange.name} (${widget.providerName})";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool selected = ref.watch(exchangeFormStateProvider
            .select((value) => value.combinedExchangeId)) ==
        _id;
    String groupValue = ref.watch(
        exchangeFormStateProvider.select((value) => value.combinedExchangeId));

    if (ref.watch(
            exchangeFormStateProvider.select((value) => value.exchange.name)) ==
        widget.providerName) {
      selected = true;
      groupValue = _id;
    }

    return ConditionalParent(
      condition: isDesktop,
      builder: (child) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: child,
      ),
      child: GestureDetector(
        onTap: () {
          if (!selected) {
            ref.read(exchangeFormStateProvider).updateExchange(
                  exchange: widget.exchange,
                  shouldUpdateData: true,
                  shouldNotifyListeners: true,
                  providerName: widget.providerName,
                  shouldAwait: false,
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
                      groupValue: groupValue,
                      onChanged: (_) {
                        if (!selected) {
                          ref.read(exchangeFormStateProvider).updateExchange(
                                exchange: widget.exchange,
                                shouldUpdateData: false,
                                shouldNotifyListeners: true,
                                providerName: widget.providerName,
                                shouldAwait: false,
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
                        widget.providerName,
                        style: STextStyles.titleBold12(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textDark2,
                        ),
                      ),
                      widget.loadingString
                          ? AnimatedText(
                              stringsToLoopThrough: const [
                                "Loading",
                                "Loading.",
                                "Loading..",
                                "Loading...",
                              ],
                              style:
                                  STextStyles.itemSubtitle12(context).copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textSubtitle1,
                              ),
                            )
                          : Text(
                              widget.rateString,
                              style:
                                  STextStyles.itemSubtitle12(context).copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textSubtitle1,
                              ),
                            ),
                    ],
                  ),
                ),
                if (widget.kycRating != null)
                  TrocadorKYCInfoButton(
                    kycType: TrocadorKYCType.fromString(
                      widget.kycRating!,
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
