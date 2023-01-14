import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/buy/response_objects/crypto.dart';
import 'package:stackwallet/models/buy/response_objects/fiat.dart';
import 'package:stackwallet/pages/buy_view/sub_widgets/crypto_selection_view.dart';
import 'package:stackwallet/pages/buy_view/sub_widgets/fiat_crypto_toggle.dart';
import 'package:stackwallet/pages/buy_view/sub_widgets/fiat_selection_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/buy/buy_data_loading_service.dart';
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

  bool buyWithFiat = true;
  bool _addressToggleFlag = false;
  bool _hovering1 = false;
  bool _hovering2 = false;

  void fiatFieldOnChanged(String value) async {}

  void cryptoFieldOnChanged(String value) async {}

  void selectCrypto() async {
    final supportedCoins =
        ref.read(supportedSimplexCurrenciesProvider).supportedCryptos;

    await _showFloatingCryptoSelectionSheet(
        coins: supportedCoins, onSelected: (_) {});
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

  void selectFiat() async {
    final supportedFiats =
        ref.read(supportedSimplexCurrenciesProvider).supportedFiats;

    await _showFloatingFiatSelectionSheet(
        fiats: supportedFiats, onSelected: (_) {});
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

  @override
  void initState() {
    _receiveAddressController = TextEditingController();
    _buyAmountController = TextEditingController();

    clipboard = widget.clipboard;
    scanner = widget.scanner;

    coins = ref.read(supportedSimplexCurrenciesProvider).supportedCryptos;
    fiats = ref.read(supportedSimplexCurrenciesProvider).supportedFiats;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      BuyDataLoadingService().loadAll(
          ref); // Why does this need to be called here?  Shouldn't it already be called by main.dart?
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

    buyWithFiat = ref.watch(
        prefsChangeNotifierProvider.select((value) => value.buyWithFiat));

    return SizedBox(
      width:
          458, // TODO test that this displays well on mobile or else put in a ternary or something else appropriate to switch here
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
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
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
                  child: Row(children: <Widget>[
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
                      "BTC",
                      style: STextStyles.largeMedium14(context),
                    )),
                    SvgPicture.asset(
                      Assets.svg.chevronDown,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .buttonTextSecondaryDisabled,
                      width: 10,
                      height: 5,
                    ),
                  ]),
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
                  color: Theme.of(context).extension<StackColors>()!.textDark3,
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
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
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
                  child: Row(children: <Widget>[
                    RoundedContainer(
                      radiusMultiplier: 0.5,
                      padding: const EdgeInsets.symmetric(
                          vertical: 2, horizontal: 4),
                      color:
                          Theme.of(context).extension<StackColors>()!.highlight,
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
                      "USD",
                      style: STextStyles.largeMedium14(context),
                    )),
                    SvgPicture.asset(
                      Assets.svg.chevronDown,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .buttonTextSecondaryDisabled,
                      width: 10,
                      height: 5,
                    ),
                  ]),
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
            textAlign: TextAlign.right,
            inputFormatters: [
              // TODO reactivate formatter
              // regex to validate a crypto amount with 8 decimal places
              // TextInputFormatter.withFunction((oldValue, newValue) =>
              //     RegExp(r'^([0-9]*[,.]?[0-9]{0,8}|[,.][0-9]{0,8})$')
              //             .hasMatch(newValue.text)
              //         ? newValue
              //         : oldValue),
            ],
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.only(
                top: 22,
                right: 12,
                bottom: 22,
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
                    "BTC",
                    style: STextStyles.smallMed14(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorDark),
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
                  color: Theme.of(context).extension<StackColors>()!.textDark3,
                ),
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
                /*"Enter ${coin.ticker} address",*/
                "Enter address",
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
                                  print(
                                      "TODO paste; Error: 'ClipboardData' isn't a type.");
                                  // final ClipboardData? data = await clipboard
                                  //     .getData(Clipboard.kTextPlain);
                                  // if (data?.text != null &&
                                  //     data!.text!.isNotEmpty) {
                                  //   String content = data.text!.trim();
                                  //   if (content.contains("\n")) {
                                  //     content = content.substring(
                                  //         0, content.indexOf("\n"));
                                  //   }
                                  //
                                  //   _receiveAddressController.text = content;
                                  //   _address = content;
                                  //
                                  //   setState(() {
                                  //     _addressToggleFlag =
                                  //         _receiveAddressController
                                  //             .text.isNotEmpty;
                                  //   });
                                  // }
                                },
                                child: _receiveAddressController.text.isEmpty
                                    ? const ClipboardIcon()
                                    : const XIcon(),
                              ),
                        if (_receiveAddressController.text.isEmpty)
                          TextFieldIconButton(
                            key: const Key("buyViewAddressBookButtonKey"),
                            onTap: () {
                              print('TODO tapped buyViewAddressBookButtonKey');
                              // Navigator.of(context).pushNamed(
                              //   AddressBookView.routeName,
                              //   arguments: widget.coin,
                              // );
                            },
                            child: const AddressBookIcon(),
                          ),
                        if (_receiveAddressController.text.isEmpty &&
                            !isDesktop)
                          TextFieldIconButton(
                            key: const Key("buyViewScanQrButtonKey"),
                            onTap: () async {
                              try {
                                // ref
                                //     .read(
                                //         shouldShowLockscreenOnResumeStateProvider
                                //             .state)
                                //     .state = false;
                                if (FocusScope.of(context).hasFocus) {
                                  FocusScope.of(context).unfocus();
                                  await Future<void>.delayed(
                                      const Duration(milliseconds: 75));
                                }

                                final qrResult = await scanner.scan();

                                Logging.instance.log(
                                    "qrResult content: ${qrResult.rawContent}",
                                    level: LogLevel.Info);

                                final results =
                                    AddressUtils.parseUri(qrResult.rawContent);

                                Logging.instance.log(
                                    "qrResult parsed: $results",
                                    level: LogLevel.Info);

                                print('TODO implement QR scanning');
                                // if (results.isNotEmpty &&
                                //     results["scheme"] == coin.uriScheme) {
                                //   // auto fill address
                                //   _address = results["address"] ?? "";
                                //   sendToController.text = _address!;
                                //
                                //   // autofill notes field
                                //   if (results["message"] != null) {
                                //     noteController.text = results["message"]!;
                                //   } else if (results["label"] != null) {
                                //     noteController.text = results["label"]!;
                                //   }
                                //
                                //   // autofill amount field
                                //   if (results["amount"] != null) {
                                //     final amount =
                                //         Decimal.parse(results["amount"]!);
                                //     cryptoAmountController.text =
                                //         Format.localizedStringAsFixed(
                                //       value: amount,
                                //       locale: ref
                                //           .read(
                                //               localeServiceChangeNotifierProvider)
                                //           .locale,
                                //       decimalPlaces:
                                //           Constants.decimalPlacesForCoin(
                                //               coin),
                                //     );
                                //     amount.toString();
                                //     _amountToSend = amount;
                                //   }
                                //
                                //   _updatePreviewButtonState(
                                //       _address, _amountToSend);
                                //   setState(() {
                                //     _addressToggleFlag =
                                //         sendToController.text.isNotEmpty;
                                //   });
                                //
                                //   // now check for non standard encoded basic address
                                // } else if (ref
                                //     .read(walletsChangeNotifierProvider)
                                //     .getManager(walletId)
                                //     .validateAddress(qrResult.rawContent)) {
                                //   _address = qrResult.rawContent;
                                //   sendToController.text = _address ?? "";
                                //
                                //   _updatePreviewButtonState(
                                //       _address, _amountToSend);
                                //   setState(() {
                                //     _addressToggleFlag =
                                //         sendToController.text.isNotEmpty;
                                //   });
                                // }
                              } /*on PlatformException*/ catch (e, s) {
                                // ref
                                //     .read(
                                //         shouldShowLockscreenOnResumeStateProvider
                                //             .state)
                                //     .state = true;
                                // here we ignore the exception caused by not giving permission
                                // to use the camera to scan a qr code
                                Logging.instance.log(
                                    "Failed to get camera permissions while trying to scan qr code in SendView: $e\n$s",
                                    level: LogLevel.Warning);
                              }
                            },
                            child: const QrCodeIcon(),
                          )
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
          PrimaryButton(
            buttonHeight: isDesktop ? ButtonHeight.l : null,
            enabled: ref.watch(
                exchangeFormStateProvider.select((value) => value.canExchange)),
            onPressed: () {
              // TODO implement buy confirmation dialog
            },
            label: "Exchange",
          )
        ],
      ),
    );
  }
}
