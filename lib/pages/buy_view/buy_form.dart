import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:stackwallet/models/buy/response_objects/crypto.dart';
import 'package:stackwallet/models/buy/response_objects/fiat.dart';
import 'package:stackwallet/models/buy/response_objects/quote.dart';
import 'package:stackwallet/models/contact_address_entry.dart';
import 'package:stackwallet/pages/address_book_views/address_book_view.dart';
import 'package:stackwallet/pages/buy_view/buy_quote_preview.dart';
import 'package:stackwallet/pages/buy_view/sub_widgets/crypto_selection_view.dart';
import 'package:stackwallet/pages/buy_view/sub_widgets/fiat_selection_view.dart';
import 'package:stackwallet/pages/exchange_view/choose_from_stack_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/address_book_address_chooser/address_book_address_chooser.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/buy/buy_response.dart';
import 'package:stackwallet/services/buy/simplex/simplex_api.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/barcode_scanner_interface.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/custom_loading_overlay.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/addressbook_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/clipboard_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/qrcode_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class BuyForm extends ConsumerStatefulWidget {
  const BuyForm({
    Key? key,
    this.coin,
    this.clipboard = const ClipboardWrapper(),
    this.scanner = const BarcodeScannerWrapper(),
  }) : super(key: key);

  final Coin? coin;

  final ClipboardInterface clipboard;
  final BarcodeScannerInterface scanner;

  @override
  ConsumerState<BuyForm> createState() => _BuyFormState();
}

class _BuyFormState extends ConsumerState<BuyForm> {
  late final Coin? coin;

  late final ClipboardInterface clipboard;
  late final BarcodeScannerInterface scanner;

  late final TextEditingController _receiveAddressController;
  late final TextEditingController _buyAmountController;
  final FocusNode _receiveAddressFocusNode = FocusNode();
  final FocusNode _fiatFocusNode = FocusNode();
  final FocusNode _cryptoFocusNode = FocusNode();
  final FocusNode _buyAmountFocusNode = FocusNode();

  final isDesktop = Util.isDesktop;

  List<Crypto>? coins;
  List<Fiat>? fiats;
  String? _address;

  static Fiat? selectedFiat;
  static Crypto? selectedCrypto;
  SimplexQuote quote = SimplexQuote(
    crypto: Crypto.fromJson({'ticker': 'BTC', 'name': 'Bitcoin'}),
    fiat: Fiat.fromJson({'ticker': 'USD', 'name': 'United States Dollar'}),
    youPayFiatPrice: Decimal.parse("100"),
    youReceiveCryptoAmount: Decimal.parse("1.0238917"),
    id: "someID",
    receivingAddress: '',
    buyWithFiat: true,
  ); // TODO enum this or something

  static bool buyWithFiat = true;
  bool _addressToggleFlag = false;
  bool _hovering1 = false;
  bool _hovering2 = false;

  // TODO actually check USD min and max, these could get updated by Simplex
  static Decimal minFiat = Decimal.fromInt(50);
  static Decimal maxFiat = Decimal.fromInt(20000);

  // We can't get crypto min and max without asking for a quote
  static Decimal minCrypto = Decimal.parse((0.00000001)
      .toString()); // lol how to go from double->Decimal more easily?
  static Decimal maxCrypto = Decimal.parse((10000.00000000).toString());
  static String boundedCryptoTicker = '';

  void selectCrypto() async {
    if (ref.read(simplexProvider).supportedCryptos.isEmpty) {
      bool shouldPop = false;
      unawaited(
        showDialog(
          context: context,
          builder: (context) => WillPopScope(
            child: const CustomLoadingOverlay(
              message: "Loading currency data",
              eventBus: null,
            ),
            onWillPop: () async => shouldPop,
          ),
        ),
      );
      await _loadSimplexCryptos();
      shouldPop = true;
      if (mounted) {
        Navigator.of(context, rootNavigator: isDesktop).pop();
      }
    }

    await _showFloatingCryptoSelectionSheet(
      coins: ref.read(simplexProvider).supportedCryptos,
      onSelected: (crypto) {
        setState(() {
          if (selectedCrypto?.ticker != _BuyFormState.boundedCryptoTicker) {
            // Reset crypto mins and maxes ... we don't know these bounds until we request a quote
            _BuyFormState.minCrypto = Decimal.parse((0.00000001)
                .toString()); // lol how to go from double->Decimal more easily?
            _BuyFormState.maxCrypto =
                Decimal.parse((10000.00000000).toString());
          }
          selectedCrypto = crypto;
        });
      },
    );
  }

  Future<void> _showFloatingCryptoSelectionSheet({
    required List<Crypto> coins,
    required void Function(Crypto) onSelected,
  }) async {
    _fiatFocusNode.unfocus();
    _cryptoFocusNode.unfocus();

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
                                  coins: coins,
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
                coins: coins,
              ),
            ),
          );

    if (mounted && result is Crypto) {
      onSelected(result);
    }
  }

  Future<void> selectFiat() async {
    if (ref.read(simplexProvider).supportedFiats.isEmpty) {
      bool shouldPop = false;
      unawaited(
        showDialog(
          context: context,
          builder: (context) => WillPopScope(
            child: const CustomLoadingOverlay(
              message: "Loading currency data",
              eventBus: null,
            ),
            onWillPop: () async => shouldPop,
          ),
        ),
      );
      await _loadSimplexFiats();
      shouldPop = true;
      if (mounted) {
        Navigator.of(context, rootNavigator: isDesktop).pop();
      }
    }

    await _showFloatingFiatSelectionSheet(
      fiats: ref.read(simplexProvider).supportedFiats,
      onSelected: (fiat) {
        setState(() {
          selectedFiat = fiat;
          minFiat = fiat.minAmount != minFiat ? fiat.minAmount : minFiat;
          maxFiat = fiat.maxAmount != maxFiat ? fiat.maxAmount : maxFiat;
        });
      },
    );
  }

  Future<void> _loadSimplexCryptos() async {
    final response = await SimplexAPI.instance.getSupportedCryptos();

    if (response.value != null) {
      ref
          .read(simplexProvider)
          .updateSupportedCryptos(response.value!); // TODO validate
    } else {
      Logging.instance.log(
        "_loadSimplexCurrencies: $response",
        level: LogLevel.Warning,
      );
    }
  }

  Future<void> _loadSimplexFiats() async {
    final response = await SimplexAPI.instance.getSupportedFiats();

    if (response.value != null) {
      ref
          .read(simplexProvider)
          .updateSupportedFiats(response.value!); // TODO validate
    } else {
      Logging.instance.log(
        "_loadSimplexCurrencies: $response",
        level: LogLevel.Warning,
      );
    }
  }

  Future<void> _showFloatingFiatSelectionSheet({
    required List<Fiat> fiats,
    required void Function(Fiat) onSelected,
  }) async {
    _fiatFocusNode.unfocus();
    _cryptoFocusNode.unfocus();

    final result = isDesktop
        ? await showDialog<Fiat?>(
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
                                  fiats: fiats,
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
                fiats: fiats,
              ),
            ),
          );

    if (mounted && result is Fiat) {
      onSelected(result);
    }
  }

  String? _fetchIconUrlFromTicker(String? ticker) {
    if (ticker == null) return null;

    return null;
  }

  bool isStackCoin(String? ticker) {
    if (ticker == null) return false;

    try {
      coinFromTickerCaseInsensitive(ticker);
      return true;
    } on ArgumentError catch (_) {
      return false;
    }
  }

  Widget? getIconForTicker(String ticker) {
    String? iconAsset = /*isStackCoin(ticker)
        ?*/
        Assets.svg.iconFor(coin: coinFromTickerCaseInsensitive(ticker));
    // : Assets.svg.buyIconFor(ticker);
    return (iconAsset != null)
        ? SvgPicture.asset(iconAsset, height: 20, width: 20)
        : null;
  }

  Future<void> previewQuote(SimplexQuote quote) async {
    bool shouldPop = false;
    unawaited(
      showDialog(
        context: context,
        builder: (context) => WillPopScope(
          child: const CustomLoadingOverlay(
            message: "Loading quote data",
            eventBus: null,
          ),
          onWillPop: () async => shouldPop,
        ),
      ),
    );

    quote = SimplexQuote(
      crypto: selectedCrypto!,
      fiat: selectedFiat!,
      youPayFiatPrice: buyWithFiat
          ? Decimal.parse(_buyAmountController.text)
          : Decimal.parse("100"), // dummy value
      youReceiveCryptoAmount: buyWithFiat
          ? Decimal.parse("0.000420282") // dummy value
          : Decimal.parse(_buyAmountController.text), // Ternary for this
      id: "id", // anything; we get an ID back
      receivingAddress: _receiveAddressController.text,
      buyWithFiat: buyWithFiat,
    );

    BuyResponse<SimplexQuote> quoteResponse = await _loadQuote(quote);
    shouldPop = true;
    if (mounted) {
      Navigator.of(context, rootNavigator: isDesktop).pop();
    }
    if (quoteResponse.exception == null) {
      quote = quoteResponse.value as SimplexQuote;

      if (quote.id != 'id' && quote.id != 'someID') {
        // TODO detect default quote better
        await _showFloatingBuyQuotePreviewSheet(
          quote: ref.read(simplexProvider).quote,
          onSelected: (quote) {
            // TODO launch URL
          },
        );
      } else {
        await showDialog<dynamic>(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            if (isDesktop) {
              return DesktopDialog(
                maxWidth: 450,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Simplex API unresponsive",
                        style: STextStyles.desktopH3(context),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      Text(
                        "Simplex API unresponsive, please try again later",
                        style: STextStyles.smallMed14(context),
                      ),
                      const SizedBox(
                        height: 56,
                      ),
                      Row(
                        children: [
                          const Spacer(),
                          Expanded(
                            child: PrimaryButton(
                              buttonHeight: ButtonHeight.l,
                              label: "Ok",
                              onPressed: Navigator.of(context).pop,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            } else {
              return StackDialog(
                title: "Simplex API error",
                message: "${quoteResponse.exception?.errorMessage}",
                rightButton: TextButton(
                  style: Theme.of(context)
                      .extension<StackColors>()!
                      .getSecondaryEnabledButtonStyle(context),
                  child: Text(
                    "Ok",
                    style: STextStyles.button(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorDark),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              );
            }
          },
        );
      }
    } else {
      // Error; probably amount out of bounds
      String errorMessage = "${quoteResponse.exception?.errorMessage}";
      if (errorMessage.contains('must be between')) {
        errorMessage = errorMessage.substring(
            (errorMessage.indexOf('getQuote exception: ') ?? 19) + 20,
            errorMessage.indexOf(", value: null"));
        _BuyFormState.boundedCryptoTicker = errorMessage.substring(
            errorMessage.indexOf('The ') + 4,
            errorMessage.indexOf(' amount must be between'));
        _BuyFormState.minCrypto = Decimal.parse(errorMessage.substring(
            errorMessage.indexOf('must be between ') + 16,
            errorMessage.indexOf(' and ')));
        _BuyFormState.maxCrypto = Decimal.parse(errorMessage.substring(
            errorMessage.indexOf("$minCrypto and ") + "$minCrypto and ".length,
            errorMessage.length));
        if (Decimal.parse(_buyAmountController.text) >
            _BuyFormState.maxCrypto) {
          _buyAmountController.text = _BuyFormState.maxCrypto.toString();
        }
      }
      await showDialog<dynamic>(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          if (isDesktop) {
            return DesktopDialog(
              maxWidth: 450,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Simplex API error",
                      style: STextStyles.desktopH3(context),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    Text(
                      errorMessage,
                      style: STextStyles.smallMed14(context),
                    ),
                    const SizedBox(
                      height: 56,
                    ),
                    Row(
                      children: [
                        const Spacer(),
                        Expanded(
                          child: PrimaryButton(
                            buttonHeight: ButtonHeight.l,
                            label: "Ok",
                            onPressed: Navigator.of(context).pop,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          } else {
            return StackDialog(
              title: "Simplex API error",
              message: "${quoteResponse.exception?.errorMessage}",
              // "${quoteResponse.exception?.errorMessage.substring(8, (quoteResponse.exception?.errorMessage?.length ?? 109) - (8 + 6))}",
              rightButton: TextButton(
                style: Theme.of(context)
                    .extension<StackColors>()!
                    .getSecondaryEnabledButtonStyle(context),
                child: Text(
                  "Ok",
                  style: STextStyles.button(context).copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorDark),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            );
          }
        },
      );
    }
  }

  Future<BuyResponse<SimplexQuote>> _loadQuote(SimplexQuote quote) async {
    final response = await SimplexAPI.instance.getQuote(quote);

    if (response.value != null) {
      // TODO check for error key
      ref.read(simplexProvider).updateQuote(response.value!);
      return BuyResponse(value: response.value!);
    } else {
      Logging.instance.log(
        "_loadQuote: $response",
        level: LogLevel.Warning,
      );
      return BuyResponse(
        exception: BuyException(
          response.toString(),
          BuyExceptionType.generic,
        ),
      );
    }
  }

  Future<void> _showFloatingBuyQuotePreviewSheet({
    required SimplexQuote quote,
    required void Function(SimplexQuote) onSelected,
  }) async {
    _fiatFocusNode.unfocus();
    _cryptoFocusNode.unfocus();

    final result = isDesktop
        ? await showDialog<Fiat?>(
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
                            "Preview quote",
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
                                child: BuyQuotePreviewView(
                                  quote: quote,
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
              builder: (_) => BuyQuotePreviewView(
                quote: quote,
              ),
            ),
          );

    if (mounted && result is SimplexQuote) {
      onSelected(result);
    }
  }

  @override
  void initState() {
    _receiveAddressController = TextEditingController();
    _buyAmountController = TextEditingController();

    clipboard = widget.clipboard;
    scanner = widget.scanner;

    coins = ref.read(simplexProvider).supportedCryptos;
    fiats = ref.read(simplexProvider).supportedFiats;
    // quote = ref.read(simplexProvider).quote;

    quote = SimplexQuote(
      crypto: Crypto.fromJson({'ticker': 'BTC', 'name': 'Bitcoin'}),
      fiat: Fiat.fromJson({'ticker': 'USD', 'name': 'United States Dollar'}),
      youPayFiatPrice: Decimal.parse("100"),
      youReceiveCryptoAmount: Decimal.parse("1.0238917"),
      id: "someID",
      receivingAddress: '',
      buyWithFiat: true,
    ); // TODO enum this or something

    // TODO set defaults better; should probably explicitly enumerate the coins & fiats used and pull the specific ones we need rather than generating them as defaults here
    selectedFiat =
        Fiat.fromJson({'ticker': 'USD', 'name': 'United States Dollar'});
    selectedCrypto = Crypto.fromJson({
      'ticker': widget.coin?.ticker ?? 'BTC',
      'name': widget.coin?.prettyName ?? 'Bitcoin'
    });

    // TODO set initial crypto to open wallet if a wallet is open

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    Locale locale = Localizations.localeOf(context);
    var format = NumberFormat.simpleCurrency(locale: locale.toString());
    // See https://stackoverflow.com/a/67055685

    return ConditionalParent(
      condition: isDesktop,
      builder: (child) => SizedBox(
        width: 458,
        child: child,
      ),
      child: ConditionalParent(
        condition: !isDesktop,
        builder: (child) => LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: child,
              ),
            ),
          ),
        ),
        child: Column(
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
            MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hovering1 = true),
              onExit: (_) => setState(() => _hovering1 = false),
              child: GestureDetector(
                onTap: () {
                  selectCrypto();
                },
                child: RoundedContainer(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                  color: _hovering1
                      ? Theme.of(context)
                          .extension<StackColors>()!
                          .currencyListItemBG
                          .withOpacity(_hovering1 ? 0.3 : 0)
                      : Theme.of(context)
                          .extension<StackColors>()!
                          .textFieldDefaultBG,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: <Widget>[
                        getIconForTicker(selectedCrypto?.ticker ?? "BTC")
                            as Widget,
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Text(
                            selectedCrypto?.ticker ?? "ERR",
                            style: STextStyles.largeMedium14(context),
                          ),
                        ),
                        SvgPicture.asset(
                          Assets.svg.chevronDown,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .buttonTextSecondaryDisabled,
                          width: 10,
                          height: 5,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
                    color:
                        Theme.of(context).extension<StackColors>()!.textDark3,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: isDesktop ? 10 : 4,
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hovering2 = true),
              onExit: (_) => setState(() => _hovering2 = false),
              child: GestureDetector(
                onTap: () {
                  selectFiat();
                },
                child: RoundedContainer(
                  padding:
                      const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                  color: _hovering2
                      ? Theme.of(context)
                          .extension<StackColors>()!
                          .currencyListItemBG
                          .withOpacity(_hovering2 ? 0.3 : 0)
                      : Theme.of(context)
                          .extension<StackColors>()!
                          .textFieldDefaultBG,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 12.0, top: 12.0, right: 12.0, bottom: 12.0),
                    child: Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 3, horizontal: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .currencyListItemBG,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            format.simpleCurrencySymbol(
                                selectedFiat?.ticker ?? "ERR".toUpperCase()),
                            textAlign: TextAlign.center,
                            style: STextStyles.smallMed12(context).copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .accentColorDark),
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Text(
                          "${selectedFiat?.ticker ?? 'ERR'}",
                          style: STextStyles.largeMedium14(context),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Text(
                            "${selectedFiat?.name ?? 'Error'}",
                            style: STextStyles.largeMedium14(context),
                          ),
                        ),
                        SvgPicture.asset(
                          Assets.svg.chevronDown,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .buttonTextSecondaryDisabled,
                          width: 10,
                          height: 5,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: isDesktop ? 10 : 4,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  buyWithFiat ? "Enter amount" : "Enter crypto amount",
                  style: STextStyles.itemSubtitle(context).copyWith(
                    color:
                        Theme.of(context).extension<StackColors>()!.textDark3,
                  ),
                ),
                BlueTextButton(
                  text: buyWithFiat ? "Use crypto amount" : "Use fiat amount",
                  onTap: () {
                    setState(() {
                      buyWithFiat = !buyWithFiat;
                    });
                  },
                )
              ],
            ),
            SizedBox(
              height: isDesktop ? 10 : 4,
            ),
            TextField(
              autocorrect: Util.isDesktop ? false : true,
              enableSuggestions: Util.isDesktop ? false : true,
              style: STextStyles.smallMed14(context).copyWith(
                color: Theme.of(context).extension<StackColors>()!.textDark,
              ),
              key: const Key("buyAmountInputFieldTextFieldKey"),
              controller: _buyAmountController
                ..text = _BuyFormState.buyWithFiat
                    ? _BuyFormState.minFiat.toStringAsFixed(2) ?? '50.00'
                    : _BuyFormState.minCrypto.toStringAsFixed(8),
              focusNode: _buyAmountFocusNode,
              keyboardType: Util.isDesktop
                  ? null
                  : const TextInputType.numberWithOptions(
                      signed: false,
                      decimal: true,
                    ),
              textAlign: TextAlign.left,
              inputFormatters: [NumericalRangeFormatter()],
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.only(
                  // top: 22,
                  // right: 12,
                  // bottom: 22,
                  left: 0,
                  top: 8,
                  bottom: 10,
                  right: 5,
                ),
                hintText: "0",
                hintStyle: STextStyles.desktopTextExtraSmall(context).copyWith(
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .textFieldDefaultText,
                ),
                prefixIcon: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      const SizedBox(width: 2),
                      buyWithFiat
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 3, horizontal: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .currencyListItemBG,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                format.simpleCurrencySymbol(
                                    selectedFiat?.ticker ??
                                        "ERR".toUpperCase()),
                                textAlign: TextAlign.center,
                                style: STextStyles.smallMed12(context).copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .accentColorDark),
                              ),
                            )
                          : getIconForTicker(selectedCrypto?.ticker ?? "BTC")
                              as Widget,
                      SizedBox(
                          width: buyWithFiat
                              ? 8
                              : 10), // maybe make isDesktop-aware?
                      Text(
                        buyWithFiat
                            ? selectedFiat?.ticker ?? "ERR"
                            : selectedCrypto?.ticker ?? "ERR",
                        style: STextStyles.smallMed14(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorDark),
                      ),
                    ]),
                  ),
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(0),
                  child: UnconstrainedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buyAmountController.text.isNotEmpty
                            ? TextFieldIconButton(
                                key: const Key(
                                    "buyViewClearAmountFieldButtonKey"),
                                onTap: () {
                                  if (_BuyFormState.buyWithFiat) {
                                    _buyAmountController.text = _BuyFormState
                                        .minFiat
                                        .toStringAsFixed(2);
                                  } else {
                                    if (selectedCrypto?.ticker ==
                                        _BuyFormState.boundedCryptoTicker) {
                                      _buyAmountController.text = _BuyFormState
                                          .minCrypto
                                          .toStringAsFixed(8);
                                    }
                                  }
                                },
                                child: const XIcon(),
                              )
                            : TextFieldIconButton(
                                key: const Key(
                                    "buyViewPasteAddressFieldButtonKey"),
                                onTap: () async {
                                  final ClipboardData? data = await clipboard
                                      .getData(Clipboard.kTextPlain);

                                  final amountString =
                                      Decimal.tryParse(data?.text ?? "");
                                  if (amountString != null) {
                                    _buyAmountController.text =
                                        amountString.toString();

                                    setState(() {});
                                  }
                                },
                                child: _buyAmountController.text.isEmpty
                                    ? const ClipboardIcon()
                                    : const XIcon(),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
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
                    color:
                        Theme.of(context).extension<StackColors>()!.textDark3,
                  ),
                ),
                if (isStackCoin(selectedCrypto?.ticker))
                  BlueTextButton(
                    text: "Choose from stack",
                    onTap: () {
                      try {
                        final coin = coinFromTickerCaseInsensitive(
                          selectedCrypto!.ticker,
                        );
                        Navigator.of(context)
                            .pushNamed(
                          ChooseFromStackView.routeName,
                          arguments: coin,
                        )
                            .then((value) async {
                          if (value is String) {
                            final manager = ref
                                .read(walletsChangeNotifierProvider)
                                .getManager(value);

                            // _toController.text = manager.walletName;
                            // model.recipientAddress =
                            //     await manager.currentReceivingAddress;
                            _receiveAddressController.text =
                                await manager.currentReceivingAddress;

                            setState(() {});
                          }
                        });
                      } catch (e, s) {
                        Logging.instance.log("$e\n$s", level: LogLevel.Info);
                      }
                    },
                  ),
              ],
            ),
            SizedBox(
              height: isDesktop ? 10 : 4,
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius,
              ),
              child: TextField(
                key: const Key("buyViewReceiveAddressFieldKey"),
                controller: _receiveAddressController,
                readOnly: false,
                autocorrect: false,
                enableSuggestions: false,
                // inputFormatters: <TextInputFormatter>[
                //   FilteringTextInputFormatter.allow(
                //       RegExp("[a-zA-Z0-9]{34}")),
                // ],
                toolbarOptions: const ToolbarOptions(
                  copy: false,
                  cut: false,
                  paste: true,
                  selectAll: false,
                ),
                onChanged: (newValue) {
                  _address = newValue;
                  setState(() {
                    _addressToggleFlag = newValue.isNotEmpty;
                  });
                },
                focusNode: _receiveAddressFocusNode,
                style: STextStyles.field(context),
                decoration: standardInputDecoration(
                  "Enter ${selectedCrypto?.ticker} address",
                  _receiveAddressFocusNode,
                  context,
                ).copyWith(
                  contentPadding: const EdgeInsets.only(
                    left: 13,
                    top: 6,
                    bottom: 8,
                    right: 5,
                  ),
                  suffixIcon: Padding(
                    padding: _receiveAddressController.text.isEmpty
                        ? const EdgeInsets.only(right: 8)
                        : const EdgeInsets.only(right: 0),
                    child: UnconstrainedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _addressToggleFlag
                              ? TextFieldIconButton(
                                  key: const Key(
                                      "buyViewClearAddressFieldButtonKey"),
                                  onTap: () {
                                    _receiveAddressController.text = "";
                                    _address = "";
                                    setState(() {
                                      _addressToggleFlag = true;
                                    });
                                  },
                                  child: const XIcon(),
                                )
                              : TextFieldIconButton(
                                  key: const Key(
                                      "buyViewPasteAddressFieldButtonKey"),
                                  onTap: () async {
                                    final ClipboardData? data = await clipboard
                                        .getData(Clipboard.kTextPlain);
                                    if (data?.text != null &&
                                        data!.text!.isNotEmpty) {
                                      String content = data.text!.trim();
                                      if (content.contains("\n")) {
                                        content = content.substring(
                                            0, content.indexOf("\n"));
                                      }

                                      _receiveAddressController.text = content;
                                      _address = content;

                                      setState(() {
                                        _addressToggleFlag =
                                            _receiveAddressController
                                                .text.isNotEmpty;
                                      });
                                    }
                                  },
                                  child: _receiveAddressController.text.isEmpty
                                      ? const ClipboardIcon()
                                      : const XIcon(),
                                ),
                          if (_receiveAddressController.text.isEmpty &&
                              isStackCoin(selectedCrypto?.ticker) &&
                              isDesktop)
                            TextFieldIconButton(
                              key: const Key("buyViewAddressBookButtonKey"),
                              onTap: () async {
                                final entry =
                                    await showDialog<ContactAddressEntry?>(
                                  context: context,
                                  builder: (context) => DesktopDialog(
                                    maxWidth: 696,
                                    maxHeight: 600,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 32,
                                              ),
                                              child: Text(
                                                "Address book",
                                                style: STextStyles.desktopH3(
                                                    context),
                                              ),
                                            ),
                                            const DesktopDialogCloseButton(),
                                          ],
                                        ),
                                        Expanded(
                                          child: AddressBookAddressChooser(
                                            coin: coinFromTickerCaseInsensitive(
                                                selectedCrypto!.ticker
                                                    .toString()),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );

                                if (entry != null) {
                                  _receiveAddressController.text =
                                      entry.address;
                                  _address = entry.address;

                                  setState(() {
                                    _addressToggleFlag = true;
                                  });
                                }
                              },
                              child: const AddressBookIcon(),
                            ),
                          if (_receiveAddressController.text.isEmpty &&
                              isStackCoin(selectedCrypto?.ticker) &&
                              !isDesktop)
                            TextFieldIconButton(
                              key: const Key("buyViewAddressBookButtonKey"),
                              onTap: () {
                                Navigator.of(context, rootNavigator: isDesktop)
                                    .pushNamed(
                                  AddressBookView.routeName,
                                );
                              },
                              child: const AddressBookIcon(),
                            ),
                          if (_receiveAddressController.text.isEmpty &&
                              !isDesktop)
                            TextFieldIconButton(
                              key: const Key("buyViewScanQrButtonKey"),
                              onTap: () async {
                                try {
                                  if (FocusScope.of(context).hasFocus) {
                                    FocusScope.of(context).unfocus();
                                    await Future<void>.delayed(
                                        const Duration(milliseconds: 75));
                                  }

                                  final qrResult = await scanner.scan();

                                  Logging.instance.log(
                                      "qrResult content: ${qrResult.rawContent}",
                                      level: LogLevel.Info);

                                  final results = AddressUtils.parseUri(
                                      qrResult.rawContent);

                                  Logging.instance.log(
                                      "qrResult parsed: $results",
                                      level: LogLevel.Info);

                                  if (results.isNotEmpty) {
                                    // auto fill address
                                    _address = results["address"] ?? "";
                                    _receiveAddressController.text = _address!;

                                    setState(() {
                                      _addressToggleFlag =
                                          _receiveAddressController
                                              .text.isNotEmpty;
                                    });

                                    // now check for non standard encoded basic address
                                  } else {
                                    _address = qrResult.rawContent;
                                    _receiveAddressController.text =
                                        _address ?? "";

                                    setState(() {
                                      _addressToggleFlag =
                                          _receiveAddressController
                                              .text.isNotEmpty;
                                    });
                                  }
                                } on PlatformException catch (e, s) {
                                  // here we ignore the exception caused by not giving permission
                                  // to use the camera to scan a qr code
                                  Logging.instance.log(
                                    "Failed to get camera permissions while trying to scan qr code in SendView: $e\n$s",
                                    level: LogLevel.Warning,
                                  );
                                }
                              },
                              child: const QrCodeIcon(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: isDesktop ? 20 : 12,
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                  onTap: () {
                    if (_receiveAddressController.text.isNotEmpty &&
                        _buyAmountController.text.isNotEmpty) {
                      previewQuote(quote);
                    }
                  },
                  child: PrimaryButton(
                    buttonHeight: isDesktop ? ButtonHeight.l : null,
                    enabled: _receiveAddressController.text.isNotEmpty &&
                        _buyAmountController.text.isNotEmpty,
                    onPressed: () {
                      if (_receiveAddressController.text.isNotEmpty &&
                          _buyAmountController.text.isNotEmpty) {
                        previewQuote(quote);
                      }
                    },
                    label: "Preview quote",
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

// See https://stackoverflow.com/a/68072967
class NumericalRangeFormatter extends TextInputFormatter {
  NumericalRangeFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    TextSelection newSelection = newValue.selection;
    String newVal = _BuyFormState.buyWithFiat
        ? Decimal.parse(newValue.text).toStringAsFixed(2)
        : Decimal.parse(newValue.text).toStringAsFixed(8);
    if (newValue.text == '') {
      return newValue;
    } else {
      if (_BuyFormState.buyWithFiat) {
        if (Decimal.parse(newValue.text) < _BuyFormState.minFiat) {
          newVal = _BuyFormState.minFiat.toStringAsFixed(2);
          // _BuyFormState._buyAmountController.selection =
          //     TextSelection.collapsed(
          //         offset: _BuyFormState.buyWithFiat
          //             ? _BuyFormState._buyAmountController.text.length - 2
          //             : _BuyFormState._buyAmountController.text.length - 8);
        } else if (Decimal.parse(newValue.text) > _BuyFormState.maxFiat) {
          newVal = _BuyFormState.maxFiat.toStringAsFixed(2);
        }
      } else if (!_BuyFormState.buyWithFiat &&
          _BuyFormState.selectedCrypto?.ticker ==
              _BuyFormState.boundedCryptoTicker) {
        if (Decimal.parse(newValue.text) < _BuyFormState.minCrypto) {
          newVal = _BuyFormState.minCrypto.toStringAsFixed(8);
        } else if (Decimal.parse(newValue.text) > _BuyFormState.maxCrypto) {
          newVal = _BuyFormState.maxCrypto.toStringAsFixed(8);
        }
      }
    }

    final regexString = _BuyFormState.buyWithFiat
        ? r'^([0-9]*[,.]?[0-9]{0,2}|[,.][0-9]{0,2})$'
        : r'^([0-9]*[,.]?[0-9]{0,8}|[,.][0-9]{0,8})$';

    // return RegExp(r'^([0-9]*[,.]?[0-9]{0,8}|[,.][0-9]{0,8})$')
    return RegExp(regexString).hasMatch(newVal)
        ? TextEditingValue(text: newVal, selection: newSelection)
        : oldValue;
  }
}
