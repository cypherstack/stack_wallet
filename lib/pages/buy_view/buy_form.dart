import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/buy/response_objects/crypto.dart';
import 'package:stackwallet/models/buy/response_objects/fiat.dart';
import 'package:stackwallet/models/buy/response_objects/quote.dart';
import 'package:stackwallet/pages/address_book_views/address_book_view.dart';
import 'package:stackwallet/pages/buy_view/buy_quote_preview.dart';
import 'package:stackwallet/pages/buy_view/sub_widgets/crypto_selection_view.dart';
import 'package:stackwallet/pages/buy_view/sub_widgets/fiat_selection_view.dart';
import 'package:stackwallet/pages/exchange_view/choose_from_stack_view.dart';
import 'package:stackwallet/providers/providers.dart';
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
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class BuyForm extends ConsumerStatefulWidget {
  const BuyForm({
    Key? key,
    this.clipboard = const ClipboardWrapper(),
    this.scanner = const BarcodeScannerWrapper(),
  }) : super(key: key);

  final ClipboardInterface clipboard;
  final BarcodeScannerInterface scanner;

  @override
  ConsumerState<BuyForm> createState() => _BuyFormState();
}

class _BuyFormState extends ConsumerState<BuyForm> {
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

  Fiat? selectedFiat;
  Crypto? selectedCrypto;
  SimplexQuote quote = SimplexQuote(
    crypto: Crypto.fromJson({'ticker': 'BTC', 'name': 'Bitcoin', 'image': ''}),
    fiat: Fiat.fromJson(
        {'ticker': 'USD', 'name': 'United States Dollar', 'image': ''}),
    youPayFiatPrice: Decimal.parse("100"),
    youReceiveCryptoAmount: Decimal.parse("1.0238917"),
    id: "someID",
    receivingAddress: '',
    buyWithFiat: true,
  ); // TODO enum this or something

  bool buyWithFiat = true;
  bool _addressToggleFlag = false;
  bool _hovering1 = false;
  bool _hovering2 = false;

  void fiatFieldOnChanged(String value) async {}

  void cryptoFieldOnChanged(String value) async {}

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
      await _loadSimplexCurrencies();
      shouldPop = true;
      if (mounted) {
        Navigator.of(context, rootNavigator: isDesktop).pop();
      }
    }

    await _showFloatingCryptoSelectionSheet(
      coins: ref.read(simplexProvider).supportedCryptos,
      onSelected: (crypto) {
        setState(() {
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
      await _loadSimplexCurrencies();
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
        });
      },
    );
  }

  Future<void> _loadSimplexCurrencies() async {
    final response = await SimplexAPI.instance.getSupported();

    if (response.value != null) {
      ref.read(simplexProvider).updateSupportedCryptos(response.value!.item1);
      ref.read(simplexProvider).updateSupportedFiats(response.value!.item2);
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

  Future<void> previewQuote(SimplexQuote quote) async {
    // if (ref.read(simplexProvider).quote.id == "someID") {
    //   // TODO make a better way of detecting a default SimplexQuote
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

    await _loadQuote(quote);
    shouldPop = true;
    if (mounted) {
      Navigator.of(context, rootNavigator: isDesktop).pop();
    }
    // }

    await _showFloatingBuyQuotePreviewSheet(
      quote: ref.read(simplexProvider).quote,
      onSelected: (quote) {
        // setState(() {
        //   selectedFiat = fiat;
        // });
        // TODO launch URL
      },
    );
  }

  Future<void> _loadQuote(SimplexQuote quote) async {
    final response = await SimplexAPI.instance.getQuote(quote);

    if (response.value != null) {
      ref.read(simplexProvider).updateQuote(response.value!);
    } else {
      Logging.instance.log(
        "_loadQuote: $response",
        level: LogLevel.Warning,
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
      crypto:
          Crypto.fromJson({'ticker': 'BTC', 'name': 'Bitcoin', 'image': ''}),
      fiat: Fiat.fromJson(
          {'ticker': 'USD', 'name': 'United States Dollar', 'image': ''}),
      youPayFiatPrice: Decimal.parse("100"),
      youReceiveCryptoAmount: Decimal.parse("1.0238917"),
      id: "someID",
      receivingAddress: '',
      buyWithFiat: true,
    ); // TODO enum this or something

    // TODO set defaults better; should probably explicitly enumerate the coins & fiats used and pull the specific ones we need rather than generating them as defaults here
    selectedFiat = Fiat.fromJson({'ticker': 'USD', 'name': 'USD', 'image': ''});
    selectedCrypto =
        Crypto.fromJson({'ticker': 'BTC', 'name': 'Bitcoin', 'image': ''});

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
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                  color: _hovering1
                      ? Theme.of(context)
                          .extension<StackColors>()!
                          .highlight
                          .withOpacity(_hovering1 ? 0.3 : 0)
                      : Theme.of(context)
                          .extension<StackColors>()!
                          .textFieldDefaultBG,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: <Widget>[
                        SvgPicture.asset(
                          Assets.svg.iconFor(
                            coin: coinFromTickerCaseInsensitive("BTC"),
                          ),
                          height: 18,
                          width: 18,
                        ),
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
                      const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                  color: _hovering2
                      ? Theme.of(context)
                          .extension<StackColors>()!
                          .highlight
                          .withOpacity(_hovering2 ? 0.3 : 0)
                      : Theme.of(context)
                          .extension<StackColors>()!
                          .textFieldDefaultBG,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: <Widget>[
                        RoundedContainer(
                          radiusMultiplier: 0.5,
                          padding: const EdgeInsets.symmetric(
                              vertical: 2, horizontal: 4),
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .highlight,
                          child: Text(
                            "\$",
                            style: STextStyles.itemSubtitle12(context),
                          ),
                        ),
                        // SvgPicture.asset(
                        //   Assets.svg.iconFor(
                        //     coin: coinFromTickerCaseInsensitive("BTC"),
                        //   ),
                        //   height: 18,
                        //   width: 18,
                        // ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Text(
                            selectedFiat?.ticker ?? "ERR",
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
              key: const Key("amountInputFieldCryptoTextFieldKey"),
              controller: _buyAmountController,
              focusNode: _buyAmountFocusNode,
              keyboardType: Util.isDesktop
                  ? null
                  : const TextInputType.numberWithOptions(
                      signed: false,
                      decimal: true,
                    ),
              textAlign: TextAlign.left,
              inputFormatters: [
                // regex to validate a crypto amount with 8 decimal places or
                // 2 if fiat
                TextInputFormatter.withFunction(
                  (oldValue, newValue) {
                    final regexString = buyWithFiat
                        ? r'^([0-9]*[,.]?[0-9]{0,2}|[,.][0-9]{0,2})$'
                        : r'^([0-9]*[,.]?[0-9]{0,8}|[,.][0-9]{0,8})$';

                    // return RegExp(r'^([0-9]*[,.]?[0-9]{0,8}|[,.][0-9]{0,8})$')
                    return RegExp(regexString).hasMatch(newValue.text)
                        ? newValue
                        : oldValue;
                  },
                ),
              ],
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
                    child: Text(
                      buyWithFiat
                          ? selectedFiat?.ticker ?? "ERR"
                          : selectedCrypto?.ticker ?? "ERR",
                      style: STextStyles.smallMed14(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .accentColorDark),
                    ),
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
                                    "buyViewClearAddressFieldButtonKey"),
                                onTap: () {
                                  _buyAmountController.text = "";
                                  // _receiveAddress = "";
                                  setState(() {});
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
                    left: 16,
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
                                    // _receiveAddress = "";
                                    setState(() {
                                      _addressToggleFlag = false;
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
                          if (_receiveAddressController.text.isEmpty)
                            TextFieldIconButton(
                              key: const Key("buyViewAddressBookButtonKey"),
                              onTap: () {
                                Navigator.of(context).pushNamed(
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
              onEnter: (_) => setState(() => _hovering1 = true),
              onExit: (_) => setState(() => _hovering1 = false),
              child: GestureDetector(
                  onTap: () {
                    previewQuote(quote);
                  },
                  child: PrimaryButton(
                    buttonHeight: isDesktop ? ButtonHeight.l : null,
                    enabled: _receiveAddressController.text.isNotEmpty &&
                        _buyAmountController.text.isNotEmpty,
                    onPressed: () {
                      previewQuote(quote);
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
