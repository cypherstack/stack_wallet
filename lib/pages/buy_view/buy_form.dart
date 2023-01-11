import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/buy/response_objects/crypto.dart';
import 'package:stackwallet/models/buy/response_objects/fiat.dart';
import 'package:stackwallet/models/buy/response_objects/pair.dart';
import 'package:stackwallet/pages/buy_view/sub_widgets/crypto_selection_view.dart';
import 'package:stackwallet/pages/buy_view/sub_widgets/fiat_crypto_toggle.dart';
import 'package:stackwallet/pages/buy_view/sub_widgets/fiat_selection_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/textfields/buy_textfield.dart';

class BuyForm extends ConsumerStatefulWidget {
  const BuyForm({
    Key? key,
    this.walletId,
    this.coin,
  }) : super(key: key);

  final String? walletId;
  final Coin? coin;

  @override
  ConsumerState<BuyForm> createState() => _BuyFormState();
}

class _BuyFormState extends ConsumerState<BuyForm> {
  late final String? walletId;
  late final Coin? coin;

  late final TextEditingController _fiatController;
  late final TextEditingController _cryptoController;
  final isDesktop = Util.isDesktop;
  final FocusNode _fiatFocusNode = FocusNode();
  final FocusNode _cryptoFocusNode = FocusNode();

  void fiatFieldOnChanged(String value) async {
    if (_fiatFocusNode.hasFocus) {
      final newFromAmount = Decimal.tryParse(value);

      await ref.read(buyFormStateProvider).setFromAmountAndCalculateToAmount(
          newFromAmount ?? Decimal.zero, true);

      if (newFromAmount == null) {
        // _cryptoController.text =
        //     ref.read(prefsChangeNotifierProvider).exchangeRateType ==
        //             ExchangeRateType.estimated
        //         ? "-"
        //         : "";
      }
    }
  }

  void cryptoFieldOnChanged(String value) async {
    if (_cryptoFocusNode.hasFocus) {
      final newCryptoAmount = Decimal.tryParse(value);

      await ref.read(buyFormStateProvider).setFromAmountAndCalculateToAmount(
          newCryptoAmount ?? Decimal.zero, true);

      if (newCryptoAmount == null) {
        _cryptoController.text = "XXX";
        // ref.read(prefsChangeNotifierProvider).exchangeRateType ==
        //     ExchangeRateType.estimated
        //     ? "-"
        //     : "";
      }
    }
  }

  void selectCrypto() async {
    final fromTicker = ref.read(buyFormStateProvider).fromTicker ?? "-";
    // ref.read(estimatedRateExchangeFormProvider).from?.ticker ?? "-";

    // if (walletInitiated &&
    //     fromTicker.toLowerCase() == coin!.ticker.toLowerCase()) {
    //   // do not allow changing away from wallet coin
    //   return;
    // }

    List<Crypto> coins;
    // switch (ref.read(currentExchangeNameStateProvider.state).state) {
    //   // case ChangeNowExchange.exchangeName:
    //   //   coins = ref.read(availableChangeNowCurrenciesProvider).coins;
    //   //   break;
    //   // case SimpleSwapExchange.exchangeName:
    //   //   coins = ref
    //   //       .read(availableSimpleswapCurrenciesProvider)
    //   //       .floatingRateCurrencies;
    //   //   break;
    //   default:
    coins = [];
    // }

    await _showFloatingCryptoSelectionSheet(
        coins: coins,
        excludedTicker: ref.read(buyFormStateProvider).toTicker ?? "-",
        fromTicker: fromTicker,
        onSelected: (from) =>
            ref.read(buyFormStateProvider).updateFrom(from, true));

    // unawaited(
    //   showDialog<void>(
    //     context: context,
    //     barrierDismissible: false,
    //     builder: (_) => WillPopScope(
    //       onWillPop: () async => false,
    //       child: Container(
    //         color: Theme.of(context)
    //             .extension<StackColors>()!
    //             .overlay
    //             .withOpacity(0.6),
    //         child: const CustomLoadingOverlay(
    //           message: "Updating exchange rate",
    //           eventBus: null,
    //         ),
    //       ),
    //     ),
    //   ),
    // );

    await Future<void>.delayed(const Duration(milliseconds: 300));

    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _showFloatingCryptoSelectionSheet({
    required List<Crypto> coins,
    required String excludedTicker,
    required String fromTicker,
    required void Function(Crypto) onSelected,
  }) async {
    _fiatFocusNode.unfocus();
    _cryptoFocusNode.unfocus();

    List<Pair> allPairs;

    switch (ref.read(currentExchangeNameStateProvider.state).state) {
      // case ChangeNowExchange.exchangeName:
      //   allPairs = ref.read(availableChangeNowCurrenciesProvider).pairs;
      //   break;
      // case SimpleSwapExchange.exchangeName:
      //   allPairs = ref.read(exchangeFormStateProvider).exchangeType ==
      //           ExchangeRateType.fixed
      //       ? ref.read(availableSimpleswapCurrenciesProvider).fixedRatePairs
      //       : ref.read(availableSimpleswapCurrenciesProvider).floatingRatePairs;
      //   break;
      default:
        allPairs = [];
    }

    List<Pair> availablePairs;
    if (fromTicker.isEmpty ||
        fromTicker == "-" ||
        excludedTicker.isEmpty ||
        excludedTicker == "-") {
      availablePairs = allPairs;
    } else if (excludedTicker == fromTicker) {
      availablePairs = allPairs
          .where((e) => e.from == excludedTicker)
          .toList(growable: false);
    } else {
      availablePairs =
          allPairs.where((e) => e.to == excludedTicker).toList(growable: false);
    }

    final List<Crypto> tickers = coins.where((e) {
      if (excludedTicker == fromTicker) {
        return e.ticker != excludedTicker &&
            availablePairs.where((e2) => e2.to == e.ticker).isNotEmpty;
      } else {
        return e.ticker != excludedTicker &&
            availablePairs.where((e2) => e2.from == e.ticker).isNotEmpty;
      }
    }).toList(growable: false);

    final result = isDesktop
        ? await showDialog<Crypto?>(
            context: context,
            builder: (context) {
              return DesktopDialog(
                maxHeight: 700,
                maxWidth: 580,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 32,
                          ),
                          child: Text(
                            "Choose a crypto to buy",
                            style: STextStyles.desktopH3(context),
                          ),
                        ),
                        const DesktopDialogCloseButton(),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 32,
                          right: 32,
                          bottom: 32,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: RoundedWhiteContainer(
                                padding: const EdgeInsets.all(16),
                                borderColor: Theme.of(context)
                                    .extension<StackColors>()!
                                    .background,
                                child: CryptoSelectionView(
                                  coins: tickers,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })
        : await Navigator.of(context).push(
            MaterialPageRoute<dynamic>(
              builder: (_) => CryptoSelectionView(
                coins: tickers,
              ),
            ),
          );

    if (mounted && result is Crypto) {
      onSelected(result);
    }
  }

  void selectFiat() async {
    final fromTicker = ref.read(buyFormStateProvider).fromTicker ?? "-";
    // ref.read(estimatedRateExchangeFormProvider).from?.ticker ?? "-";

    // if (walletInitiated &&
    //     fromTicker.toLowerCase() == coin!.ticker.toLowerCase()) {
    //   // do not allow changing away from wallet coin
    //   return;
    // }

    List<Crypto> coins;
    // switch (ref.read(currentExchangeNameStateProvider.state).state) {
    // // case ChangeNowExchange.exchangeName:
    // //   coins = ref.read(availableChangeNowCurrenciesProvider).coins;
    // //   break;
    // // case SimpleSwapExchange.exchangeName:
    // //   coins = ref
    // //       .read(availableSimpleswapCurrenciesProvider)
    // //       .floatingRateCurrencies;
    // //   break;
    //   default:
    coins = [];
    // }
  }

  Future<void> _showFloatingFiatSelectionSheet({
    required List<Fiat> fiats,
    required String excludedTicker,
    required String fromTicker,
    required void Function(Fiat) onSelected,
  }) async {
    _fiatFocusNode.unfocus();
    _cryptoFocusNode.unfocus();

    List<Pair> allPairs;

    // switch (ref.read(currentExchangeNameStateProvider.state).state) {
    // // case ChangeNowExchange.exchangeName:
    // //   allPairs = ref.read(availableChangeNowCurrenciesProvider).pairs;
    // //   break;
    // // case SimpleSwapExchange.exchangeName:
    // //   allPairs = ref.read(exchangeFormStateProvider).exchangeType ==
    // //           ExchangeRateType.fixed
    // //       ? ref.read(availableSimpleswapCurrenciesProvider).fixedRatePairs
    // //       : ref.read(availableSimpleswapCurrenciesProvider).floatingRatePairs;
    // //   break;
    //   default:
    allPairs = [];
    // }

    List<Pair> availablePairs;
    if (fromTicker.isEmpty ||
        fromTicker == "-" ||
        excludedTicker.isEmpty ||
        excludedTicker == "-") {
      availablePairs = allPairs;
    } else if (excludedTicker == fromTicker) {
      availablePairs = allPairs
          .where((e) => e.from == excludedTicker)
          .toList(growable: false);
    } else {
      availablePairs =
          allPairs.where((e) => e.to == excludedTicker).toList(growable: false);
    }

    final List<Fiat> tickers = fiats.where((e) {
      if (excludedTicker == fromTicker) {
        return e.ticker != excludedTicker &&
            availablePairs.where((e2) => e2.to == e.ticker).isNotEmpty;
      } else {
        return e.ticker != excludedTicker &&
            availablePairs.where((e2) => e2.from == e.ticker).isNotEmpty;
      }
    }).toList(growable: false);

    final result = isDesktop
        ? await showDialog<Crypto?>(
            context: context,
            builder: (context) {
              return DesktopDialog(
                maxHeight: 700,
                maxWidth: 580,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 32,
                          ),
                          child: Text(
                            "Choose a fiat with which to pay",
                            style: STextStyles.desktopH3(context),
                          ),
                        ),
                        const DesktopDialogCloseButton(),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 32,
                          right: 32,
                          bottom: 32,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: RoundedWhiteContainer(
                                padding: const EdgeInsets.all(16),
                                borderColor: Theme.of(context)
                                    .extension<StackColors>()!
                                    .background,
                                child: FiatSelectionView(
                                  fiats: tickers,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })
        : await Navigator.of(context).push(
            MaterialPageRoute<dynamic>(
              builder: (_) => FiatSelectionView(
                fiats: tickers,
              ),
            ),
          );

    if (mounted && result is Fiat) {
      onSelected(result);
    }
  }

  String? _fetchIconUrlFromTicker(String? ticker) {
    if (ticker == null) return null;

    // Iterable<Crypto> possibleCurrencies;
    //
    // switch (ref.read(currentExchangeNameStateProvider.state).state) {
    //   case ChangeNowExchange.exchangeName:
    //     possibleCurrencies = ref
    //         .read(availableChangeNowCurrenciesProvider)
    //         .coins
    //         .where((e) => e.ticker.toUpperCase() == ticker.toUpperCase());
    //     break;
    //   default:
    //     possibleCurrencies = [];
    // }
    //
    // for (final Crypto in possibleCurrencies) {
    //   if (Crypto.image.isNotEmpty) {
    //     return Crypto.image;
    //   }
    // }

    return null;
  }

  bool isWalletCoin(Coin? coin, bool isSend) {
    if (coin == null) {
      return false;
    }

    String? ticker;

    if (isSend) {
      ticker = ref.read(buyFormStateProvider).fromTicker;
    } else {
      ticker = ref.read(buyFormStateProvider).toTicker;
    }

    if (ticker == null) {
      return false;
    }

    return coin.ticker.toUpperCase() == ticker.toUpperCase();
  }

  @override
  void initState() {
    _fiatController = TextEditingController();
    _cryptoController = TextEditingController();

    walletId = widget.walletId;
    coin = widget.coin;
    // walletInitiated = walletId != null && coin != null;
    //
    // if (walletInitiated) {
    //   WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    //     ref.read(buyFormStateProvider).clearAmounts(true);
    //     // ref.read(fixedRateExchangeFormProvider);
    //   });
    // } else {
    // final isEstimated =
    //     ref.read(prefsChangeNotifierProvider).exchangeRateType ==
    //         ExchangeRateType.estimated;
    _fiatController.text = ref.read(buyFormStateProvider).fromAmountString;
    _cryptoController
            .text = /*isEstimated
          ? "-" //ref.read(estimatedRateExchangeFormProvider).toAmountString
          :*/
        ref.read(buyFormStateProvider).toAmountString;
    // }

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "I want to buy",
          style: STextStyles.itemSubtitle(context).copyWith(
            color: Theme.of(context).extension<StackColors>()!.textDark3,
          ),
        ),
        SizedBox(
          height: isDesktop ? 10 : 4,
        ),
        BuyTextField(
          controller: _cryptoController,
          focusNode: _cryptoFocusNode,
          textStyle: STextStyles.smallMed14(context).copyWith(
            color: Theme.of(context).extension<StackColors>()!.textDark,
          ),
          buttonColor:
              Theme.of(context).extension<StackColors>()!.buttonBackSecondary,
          borderRadius: Constants.size.circularBorderRadius,
          background:
              Theme.of(context).extension<StackColors>()!.textFieldDefaultBG,
          onTap: () {
            if (_cryptoController.text == "-") {
              _cryptoController.text = "";
            }
          },
          onChanged: cryptoFieldOnChanged,
          onButtonTap: selectCrypto,
          isWalletCoin: isWalletCoin(coin, true),
          image: _fetchIconUrlFromTicker(ref
              .watch(buyFormStateProvider.select((value) => value.fromTicker))),
          ticker: ref
              .watch(buyFormStateProvider.select((value) => value.fromTicker)),
        ),
        SizedBox(
          height: isDesktop ? 20 : 12,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "I want to pay with",
              style: STextStyles.itemSubtitle(context).copyWith(
                color: Theme.of(context).extension<StackColors>()!.textDark3,
              ),
            ),
          ],
        ),
        SizedBox(
          height: isDesktop ? 10 : 4,
        ),
        BuyTextField(
          controller: _fiatController,
          focusNode: _fiatFocusNode,
          textStyle: STextStyles.smallMed14(context).copyWith(
            color: Theme.of(context).extension<StackColors>()!.textDark,
          ),
          buttonColor:
              Theme.of(context).extension<StackColors>()!.buttonBackSecondary,
          borderRadius: Constants.size.circularBorderRadius,
          background:
              Theme.of(context).extension<StackColors>()!.textFieldDefaultBG,
          onTap: () {
            if (_fiatController.text == "-") {
              _fiatController.text = "";
            }
          },
          onChanged: fiatFieldOnChanged,
          onButtonTap: selectFiat,
          isWalletCoin: isWalletCoin(coin, true),
          image: _fetchIconUrlFromTicker(ref
              .watch(buyFormStateProvider.select((value) => value.fromTicker))),
          ticker: ref
              .watch(buyFormStateProvider.select((value) => value.fromTicker)),
        ),
        SizedBox(
          height: isDesktop ? 20 : 12,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Enter amount",
              style: STextStyles.itemSubtitle(context).copyWith(
                color: Theme.of(context).extension<StackColors>()!.textDark3,
              ),
            ),
            const FiatCryptoToggle(),
          ],
        ),
        // // these reads should be watch
        // if (ref.watch(buyFormStateProvider).fromAmount != null &&
        //     ref.watch(buyFormStateProvider).fromAmount != Decimal.zero)
        SizedBox(
          height: isDesktop ? 10 : 4,
        ),
        BuyTextField(
          controller: _fiatController,
          focusNode: _fiatFocusNode,
          textStyle: STextStyles.smallMed14(context).copyWith(
            color: Theme.of(context).extension<StackColors>()!.textDark,
          ),
          buttonColor:
              Theme.of(context).extension<StackColors>()!.buttonBackSecondary,
          borderRadius: Constants.size.circularBorderRadius,
          background:
              Theme.of(context).extension<StackColors>()!.textFieldDefaultBG,
          onTap: () {
            if (_fiatController.text == "-") {
              _fiatController.text = "";
            }
          },
          onChanged: fiatFieldOnChanged,
          onButtonTap: selectFiat,
          // isWalletCoin: isWalletCoin(coin, true),
          isWalletCoin: false,
          // image: _fetchIconUrlFromTicker(ref
          //     .watch(buyFormStateProvider.select((value) => value.fromTicker))),
          // ticker: ref
          //     .watch(buyFormStateProvider.select((value) => value.fromTicker)),
        ),
        SizedBox(
          height: isDesktop ? 20 : 12,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Enter receiving address",
              style: STextStyles.itemSubtitle(context).copyWith(
                color: Theme.of(context).extension<StackColors>()!.textDark3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
