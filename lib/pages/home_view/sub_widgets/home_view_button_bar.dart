import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/exchange_view/exchange_view.dart';
import 'package:stackwallet/providers/exchange/available_currencies_state_provider.dart';
import 'package:stackwallet/providers/exchange/available_floating_rate_pairs_state_provider.dart';
import 'package:stackwallet/providers/exchange/change_now_provider.dart';
import 'package:stackwallet/providers/exchange/estimate_rate_exchange_form_provider.dart';
import 'package:stackwallet/providers/exchange/fixed_rate_exchange_form_provider.dart';
import 'package:stackwallet/providers/exchange/fixed_rate_market_pairs_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class HomeViewButtonBar extends ConsumerStatefulWidget {
  const HomeViewButtonBar({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeViewButtonBar> createState() => _HomeViewButtonBarState();
}

class _HomeViewButtonBarState extends ConsumerState<HomeViewButtonBar> {
  final DateTime _lastRefreshed = DateTime.now();
  final Duration _refreshInterval = const Duration(hours: 1);

  Future<void> _loadChangeNowData(
    BuildContext context,
    WidgetRef ref,
  ) async {
    List<Future<void>> futures = [];
    if (kFixedRateEnabled) {
      futures.add(_loadFixedRateMarkets(context, ref));
    }
    futures.add(_loadStandardCurrencies(context, ref));

    await Future.wait(futures);
  }

  Future<void> _loadStandardCurrencies(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final response = await ref.read(changeNowProvider).getAvailableCurrencies();
    final response2 =
        await ref.read(changeNowProvider).getAvailableFloatingRatePairs();
    if (response.value != null && response2.value != null) {
      ref.read(availableChangeNowCurrenciesStateProvider.state).state =
          response.value!;
      ref.read(availableFloatingRatePairsStateProvider.state).state =
          response2.value!;

      if (response.value!.length > 1) {
        if (ref.read(estimatedRateExchangeFormProvider).from == null) {
          if (response.value!.where((e) => e.ticker == "btc").isNotEmpty) {
            await ref.read(estimatedRateExchangeFormProvider).updateFrom(
                response.value!.firstWhere((e) => e.ticker == "btc"), true);
          }
        }
        if (ref.read(estimatedRateExchangeFormProvider).to == null) {
          if (response.value!.where((e) => e.ticker == "doge").isNotEmpty) {
            await ref.read(estimatedRateExchangeFormProvider).updateTo(
                response.value!.firstWhere((e) => e.ticker == "doge"), true);
          }
        }
      }

      Logging.instance
          .log("loaded floating rate change now data", level: LogLevel.Info);
    } else {
      Logging.instance.log(
          "Failed to load changeNOW floating rate market data: \n${response.exception?.errorMessage}\n${response2.exception?.toString()}",
          level: LogLevel.Error);
      unawaited(showDialog<dynamic>(
        context: context,
        barrierDismissible: true,
        builder: (_) => StackDialog(
          title: "Failed to fetch available currencies",
          message:
              "${response.exception?.toString()}\n\n${response2.exception?.toString()}",
        ),
      ));
    }
  }

  Future<void> _loadFixedRateMarkets(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final response3 =
        await ref.read(changeNowProvider).getAvailableFixedRateMarkets();

    if (response3.value != null) {
      ref.read(fixedRateMarketPairsStateProvider.state).state =
          response3.value!;

      if (ref.read(fixedRateExchangeFormProvider).market == null) {
        final matchingMarkets =
            response3.value!.where((e) => e.to == "doge" && e.from == "btc");

        if (matchingMarkets.isNotEmpty) {
          await ref
              .read(fixedRateExchangeFormProvider)
              .updateMarket(matchingMarkets.first, true);
        }
      }
      Logging.instance
          .log("loaded fixed rate change now data", level: LogLevel.Info);
    } else {
      Logging.instance.log(
          "Failed to load changeNOW fixed rate markets: ${response3.exception?.errorMessage}",
          level: LogLevel.Error);
      unawaited(showDialog<dynamic>(
        context: context,
        barrierDismissible: true,
        builder: (_) => StackDialog(
          title: "ChangeNOW API call failed",
          message: "${response3.exception?.toString()}",
        ),
      ));
    }
  }

  @override
  void initState() {
    ref.read(estimatedRateExchangeFormProvider).setOnError(
          onError: (String message) => showDialog<dynamic>(
            context: context,
            barrierDismissible: true,
            builder: (_) => StackDialog(
              title: "ChangeNOW API Call Failed",
              message: message,
            ),
          ),
        );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: HomeViewButtonBar");
    final selectedIndex = ref.watch(homeViewPageIndexStateProvider.state).state;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: TextButton(
            style: selectedIndex == 0
                ? StackTheme.instance
                    .getPrimaryEnabledButtonColor(context)!
                    .copyWith(
                      minimumSize:
                          MaterialStateProperty.all<Size>(const Size(46, 36)),
                    )
                : StackTheme.instance
                    .getSecondaryEnabledButtonColor(context)!
                    .copyWith(
                      minimumSize:
                          MaterialStateProperty.all<Size>(const Size(46, 36)),
                    ),
            onPressed: () {
              FocusScope.of(context).unfocus();
              if (selectedIndex != 0) {
                ref.read(homeViewPageIndexStateProvider.state).state = 0;
              }
            },
            child: Text(
              "Wallets",
              style: STextStyles.button.copyWith(
                fontSize: 14,
                color: selectedIndex == 0
                    ? StackTheme.instance.color.buttonTextPrimary
                    : StackTheme.instance.color.textDark,
              ),
            ),
          ),
        ),
        const SizedBox(
          width: 8,
        ),
        Expanded(
          child: TextButton(
            style: selectedIndex == 1
                ? StackTheme.instance
                    .getPrimaryEnabledButtonColor(context)!
                    .copyWith(
                      minimumSize:
                          MaterialStateProperty.all<Size>(const Size(46, 36)),
                    )
                : StackTheme.instance
                    .getSecondaryEnabledButtonColor(context)!
                    .copyWith(
                      minimumSize:
                          MaterialStateProperty.all<Size>(const Size(46, 36)),
                    ),
            onPressed: () async {
              FocusScope.of(context).unfocus();
              if (selectedIndex != 1) {
                ref.read(homeViewPageIndexStateProvider.state).state = 1;
              }
              DateTime now = DateTime.now();

              if (now.difference(_lastRefreshed) > _refreshInterval) {
                // bool okPressed = false;
                // showDialog<dynamic>(
                //   context: context,
                //   barrierDismissible: false,
                //   builder: (_) => const StackDialog(
                //     // builder: (_) => StackOkDialog(
                //     title: "Refreshing ChangeNOW data",
                //     message: "This may take a while",
                //     // onOkPressed: (value) {
                //     //   if (value == "OK") {
                //     //     okPressed = true;
                //     //   }
                //     // },
                //   ),
                // );
                await _loadChangeNowData(context, ref);
                // if (!okPressed && mounted) {
                //   Navigator.of(context).pop();
                // }
              }
            },
            child: Text(
              "Exchange",
              style: STextStyles.button.copyWith(
                fontSize: 14,
                color: selectedIndex == 1
                    ? StackTheme.instance.color.buttonTextPrimary
                    : StackTheme.instance.color.textDark,
              ),
            ),
          ),
        ),
        // TODO: Do not delete this code.
        // only temporarily disabled
        // SizedBox(
        //   width: 8,
        // ),
        // Expanded(
        //   child: TextButton(
        //     style: ButtonStyle(
        //       minimumSize: MaterialStateProperty.all<Size>(Size(46, 36)),
        //       backgroundColor: MaterialStateProperty.all<Color>(
        //         selectedIndex == 2
        //             ? CFColors.stackAccent
        //             : CFColors.disabledButton,
        //       ),
        //     ),
        //     onPressed: () {
        //       FocusScope.of(context).unfocus();
        //       if (selectedIndex != 2) {
        //         ref.read(homeViewPageIndexStateProvider.state).state = 2;
        //       }
        //     },
        //     child: Text(
        //       "Buy",
        //       style: STextStyles.button.copyWith(
        //         fontSize: 14,
        //         color:
        //             selectedIndex == 2 ? CFColors.light1 : StackTheme.instance.color.accentColorDark
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
