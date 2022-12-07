import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:epicmobile/models/send_view_auto_fill_data.dart';
import 'package:epicmobile/pages/address_book_views/address_book_view.dart';
import 'package:epicmobile/pages/send_view/send_amount_view.dart';
// import 'package:epicmobile/pages/send_view/sub_widgets/firo_balance_selection_sheet.dart';
import 'package:epicmobile/pages/send_view/sub_widgets/transaction_fee_selection_sheet.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/providers/ui/fee_rate_type_state_provider.dart';
import 'package:epicmobile/providers/ui/preview_tx_button_state_provider.dart';
import 'package:epicmobile/services/coins/manager.dart';
import 'package:epicmobile/utilities/address_utils.dart';
import 'package:epicmobile/utilities/barcode_scanner_interface.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/enums/fee_rate_type_enum.dart';
import 'package:epicmobile/utilities/format.dart';
import 'package:epicmobile/utilities/logger.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/icon_widgets/addressbook_icon.dart';
import 'package:epicmobile/widgets/icon_widgets/qrcode_icon.dart';
import 'package:epicmobile/widgets/stack_text_field.dart';
import 'package:epicmobile/widgets/textfield_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';

import '../../widgets/icon_widgets/x_icon.dart';

class SendView extends ConsumerStatefulWidget {
  const SendView({
    Key? key,
    required this.walletId,
    required this.coin,
    this.autoFillData,
    this.barcodeScanner = const BarcodeScannerWrapper(),
  }) : super(key: key);

  static const String routeName = "/sendView";

  final String walletId;
  final Coin coin;
  final SendViewAutoFillData? autoFillData;
  final BarcodeScannerInterface barcodeScanner;

  @override
  ConsumerState<SendView> createState() => _SendViewState();
}

class _SendViewState extends ConsumerState<SendView> {
  late final String walletId;
  late final Coin coin;
  late final BarcodeScannerInterface scanner;

  late TextEditingController sendToController;

  late final SendViewAutoFillData? _data;

  final _addressFocusNode = FocusNode();
  Decimal? _amountToSend;
  Decimal? _cachedAmountToSend;
  String? _address;

  String? _privateBalanceString;
  String? _publicBalanceString;

  bool _addressToggleFlag = false;

  bool _cryptoAmountChangeLock = false;
  late VoidCallback onCryptoAmountChanged;

  Decimal? _cachedBalance;

  // void _cryptoAmountChanged() async {
  //   if (!_cryptoAmountChangeLock) {
  //     final String cryptoAmount = cryptoAmountController.text;
  //     if (cryptoAmount.isNotEmpty &&
  //         cryptoAmount != "." &&
  //         cryptoAmount != ",") {
  //       _amountToSend = cryptoAmount.contains(",")
  //           ? Decimal.parse(cryptoAmount.replaceFirst(",", "."))
  //           : Decimal.parse(cryptoAmount);
  //       if (_cachedAmountToSend != null &&
  //           _cachedAmountToSend == _amountToSend) {
  //         return;
  //       }
  //       _cachedAmountToSend = _amountToSend;
  //       Logging.instance.log("it changed $_amountToSend $_cachedAmountToSend",
  //           level: LogLevel.Info);
  //
  //       final price =
  //           ref.read(priceAnd24hChangeNotifierProvider).getPrice(coin).item1;
  //
  //       if (price > Decimal.zero) {
  //         final String fiatAmountString = Format.localizedStringAsFixed(
  //           value: _amountToSend! * price,
  //           locale: ref.read(localeServiceChangeNotifierProvider).locale,
  //           decimalPlaces: 2,
  //         );
  //
  //         baseAmountController.text = fiatAmountString;
  //       }
  //     } else {
  //       _amountToSend = null;
  //       baseAmountController.text = "";
  //     }

  // _updatePreviewButtonState(_address, _amountToSend);

  // if (_amountToSend == null) {
  //   setState(() {
  //     _calculateFeesFuture = calculateFees(0);
  //   });
  // } else {
  //   setState(() {
  //     _calculateFeesFuture =
  //         calculateFees(Format.decimalAmountToSatoshis(_amountToSend!));
  //   });
  // }
  //   }
  // }

  String? _updateInvalidAddressText(String address, Manager manager) {
    if (_data != null && _data!.contactLabel == address) {
      return null;
    }
    if (address.isNotEmpty && !manager.validateAddress(address)) {
      return "Invalid address";
    }
    return null;
  }

  void _updatePreviewButtonState(String? address, Decimal? amount) {
    final isValidAddress =
        ref.read(walletProvider)!.validateAddress(address ?? "");
    ref.read(previewTxButtonStateProvider.state).state = isValidAddress;
  }

  late Future<String> _calculateFeesFuture;

  Map<int, String> cachedFees = {};
  Map<int, String> cachedFiroPrivateFees = {};
  Map<int, String> cachedFiroPublicFees = {};

  Future<String> calculateFees(int amount) async {
    if (amount <= 0) {
      return "0";
    }

    if (cachedFees[amount] != null) {
      return cachedFees[amount]!;
    }

    final manager = ref.read(walletProvider)!;
    final feeObject = await manager.fees;

    late final int feeRate;

    switch (ref.read(feeRateTypeStateProvider.state).state) {
      case FeeRateType.fast:
        feeRate = feeObject.fast;
        break;
      case FeeRateType.average:
        feeRate = feeObject.medium;
        break;
      case FeeRateType.slow:
        feeRate = feeObject.slow;
        break;
    }

    int fee;
    fee = await manager.estimateFeeFor(amount, feeRate);
    cachedFees[amount] =
        Format.satoshisToAmount(fee).toStringAsFixed(Constants.decimalPlaces);

    return cachedFees[amount]!;
  }

  @override
  void initState() {
    ref.refresh(feeSheetSessionCacheProvider);

    _calculateFeesFuture = calculateFees(0);
    _data = widget.autoFillData;
    walletId = widget.walletId;
    coin = widget.coin;
    scanner = widget.barcodeScanner;

    sendToController = TextEditingController();

    if (_data != null) {
      sendToController.text = _data!.contactLabel;
      _address = _data!.address;
      _addressToggleFlag = true;
    }

    super.initState();
  }

  @override
  void dispose() {
    sendToController.dispose();
    _addressFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    final String locale = ref.watch(
        localeServiceChangeNotifierProvider.select((value) => value.locale));

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        body: LayoutBuilder(
          builder: (builderContext, constraints) {
            return Padding(
              padding: const EdgeInsets.only(
                left: 12,
                top: 12,
                right: 12,
              ),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // subtract top and bottom padding set in parent
                    minHeight: constraints.maxHeight - 24,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(
                            flex: 2,
                          ),
                          Text(
                            "Send EPIC",
                            style: STextStyles.titleH3(context).copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .buttonBackPrimary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          Text(
                            "Enter your recipient's address:",
                            style: STextStyles.smallMed14(context),
                            textAlign: TextAlign.center,
                          ),
                          // Container(
                          //   decoration: BoxDecoration(
                          //     color: Theme.of(context)
                          //         .extension<StackColors>()!
                          //         .popupBG,
                          //     borderRadius: BorderRadius.circular(
                          //       Constants.size.circularBorderRadius,
                          //     ),
                          //   ),
                          //   child: Padding(
                          //     padding: const EdgeInsets.all(12.0),
                          //     child: Row(
                          //       children: [
                          //         SvgPicture.asset(
                          //           Assets.svg.iconFor(coin: coin),
                          //           width: 22,
                          //           height: 22,
                          //         ),
                          //         const SizedBox(
                          //           width: 6,
                          //         ),
                          //         Expanded(
                          //           child: Text(
                          //             ref.watch(walletProvider.select(
                          //                 (value) => value!.walletName)),
                          //             style: STextStyles.bodyBold(context),
                          //             overflow: TextOverflow.ellipsis,
                          //             maxLines: 1,
                          //           ),
                          //         ),
                          //         const SizedBox(
                          //           width: 10,
                          //         ),
                          //       ],
                          //     ),
                          //   ),
                          // ),
                          const SizedBox(
                            height: 16,
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              Constants.size.circularBorderRadius,
                            ),
                            child: TextField(
                              key: const Key("sendViewAddressFieldKey"),
                              controller: sendToController,
                              readOnly: false,
                              autocorrect: false,
                              enableSuggestions: false,
                              toolbarOptions: const ToolbarOptions(
                                copy: false,
                                cut: false,
                                paste: true,
                                selectAll: false,
                              ),
                              onChanged: (newValue) {
                                _address = newValue;
                                _updatePreviewButtonState(
                                    _address, _amountToSend);

                                setState(() {
                                  _addressToggleFlag = newValue.isNotEmpty;
                                });
                              },
                              focusNode: _addressFocusNode,
                              style: STextStyles.field(context),
                              decoration: standardInputDecoration(
                                "Paste address...",
                                _addressFocusNode,
                                context,
                              ).copyWith(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 20),
                                suffixIcon: Padding(
                                  padding: sendToController.text.isEmpty
                                      ? const EdgeInsets.only(right: 8)
                                      : const EdgeInsets.only(right: 0),
                                  child: UnconstrainedBox(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        if (_addressToggleFlag == true)
                                          TextFieldIconButton(
                                            key: const Key(
                                                "sendViewClearAddressFieldButtonKey"),
                                            onTap: () {
                                              sendToController.text = "";
                                              _address = "";
                                              _updatePreviewButtonState(
                                                  _address, _amountToSend);
                                              setState(() {
                                                _addressToggleFlag = false;
                                              });
                                            },
                                            child: const XIcon(),
                                          ),
                                        TextFieldIconButton(
                                          key: const Key(
                                              "sendViewScanQrButtonKey"),
                                          onTap: () async {
                                            try {
                                              // ref
                                              //     .read(
                                              //         shouldShowLockscreenOnResumeStateProvider
                                              //             .state)
                                              //     .state = false;
                                              if (FocusScope.of(context)
                                                  .hasFocus) {
                                                FocusScope.of(context)
                                                    .unfocus();
                                                await Future<void>.delayed(
                                                    const Duration(
                                                        milliseconds: 75));
                                              }

                                              final qrResult =
                                                  await scanner.scan();

                                              // Future<void>.delayed(
                                              //   const Duration(seconds: 2),
                                              //   () => ref
                                              //       .read(
                                              //           shouldShowLockscreenOnResumeStateProvider
                                              //               .state)
                                              //       .state = true,
                                              // );

                                              Logging.instance.log(
                                                  "qrResult content: ${qrResult.rawContent}",
                                                  level: LogLevel.Info);

                                              final results =
                                                  AddressUtils.parseUri(
                                                      qrResult.rawContent);

                                              Logging.instance.log(
                                                  "qrResult parsed: $results",
                                                  level: LogLevel.Info);

                                              if (results.isNotEmpty &&
                                                  results["scheme"] ==
                                                      coin.uriScheme) {
                                                // auto fill address
                                                _address =
                                                    results["address"] ?? "";
                                                sendToController.text =
                                                    _address!;

                                                _updatePreviewButtonState(
                                                    _address, _amountToSend);
                                                setState(() {
                                                  _addressToggleFlag =
                                                      sendToController
                                                          .text.isNotEmpty;
                                                });

                                                // now check for non standard encoded basic address
                                              } else if (ref
                                                  .read(walletProvider)!
                                                  .validateAddress(
                                                      qrResult.rawContent)) {
                                                _address = qrResult.rawContent;
                                                sendToController.text =
                                                    _address ?? "";

                                                _updatePreviewButtonState(
                                                    _address, _amountToSend);
                                                setState(() {
                                                  _addressToggleFlag =
                                                      sendToController
                                                          .text.isNotEmpty;
                                                });
                                              }
                                            } on PlatformException catch (e, s) {
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
                                        ),
                                        TextFieldIconButton(
                                          key: const Key(
                                              "sendViewAddressBookButtonKey"),
                                          onTap: () {
                                            Navigator.of(context).pushNamed(
                                              AddressBookView.routeName,
                                              arguments: widget.coin,
                                            );
                                          },
                                          child: AddressBookIcon(
                                            width: 24,
                                            height: 24,
                                            color: Theme.of(context)
                                                .extension<StackColors>()!
                                                .textFieldActiveSearchIconRight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Builder(
                            builder: (_) {
                              final error = _updateInvalidAddressText(
                                _address ?? "",
                                ref.read(walletProvider)!,
                              );

                              if (error == null || error.isEmpty) {
                                return Container();
                              } else {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 12.0,
                                      top: 4.0,
                                    ),
                                    child: Text(
                                      error,
                                      textAlign: TextAlign.left,
                                      style:
                                          STextStyles.label(context).copyWith(
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .textError,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          // const SizedBox(
                          //   height: 12,
                          // ),
                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //   children: [
                          //     Text(
                          //       "Amount",
                          //       style: STextStyles.smallMed12(context),
                          //       textAlign: TextAlign.left,
                          //     ),
                          //     BlueTextButton(
                          //       text: "Send all ${coin.ticker}",
                          //       onTap: () async {
                          //         cryptoAmountController.text = (await ref
                          //                 .read(walletProvider)!
                          //                 .availableBalance)
                          //             .toStringAsFixed(Constants.decimalPlaces);
                          //       },
                          //     ),
                          //   ],
                          // ),
                          // const SizedBox(
                          //   height: 8,
                          // ),
                          // TextField(
                          //   autocorrect: Util.isDesktop ? false : true,
                          //   enableSuggestions: Util.isDesktop ? false : true,
                          //   style: STextStyles.smallMed14(context).copyWith(
                          //     color: Theme.of(context)
                          //         .extension<StackColors>()!
                          //         .textLight,
                          //   ),
                          //   key:
                          //       const Key("amountInputFieldCryptoTextFieldKey"),
                          //   controller: cryptoAmountController,
                          //   focusNode: _cryptoFocus,
                          //   keyboardType: const TextInputType.numberWithOptions(
                          //     signed: false,
                          //     decimal: true,
                          //   ),
                          //   textAlign: TextAlign.right,
                          //   inputFormatters: [
                          //     // regex to validate a crypto amount with 8 decimal places
                          //     TextInputFormatter.withFunction((oldValue,
                          //             newValue) =>
                          //         RegExp(r'^([0-9]*[,.]?[0-9]{0,8}|[,.][0-9]{0,8})$')
                          //                 .hasMatch(newValue.text)
                          //             ? newValue
                          //             : oldValue),
                          //   ],
                          //   decoration: InputDecoration(
                          //     contentPadding: const EdgeInsets.only(
                          //       top: 12,
                          //       right: 12,
                          //     ),
                          //     hintText: "0",
                          //     hintStyle:
                          //         STextStyles.fieldLabel(context).copyWith(
                          //       fontSize: 14,
                          //     ),
                          //     prefixIcon: FittedBox(
                          //       fit: BoxFit.scaleDown,
                          //       child: Padding(
                          //         padding: const EdgeInsets.all(12),
                          //         child: Text(
                          //           coin.ticker,
                          //           style: STextStyles.smallMed14(context)
                          //               .copyWith(
                          //                   color: Theme.of(context)
                          //                       .extension<StackColors>()!
                          //                       .accentColorDark),
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          // const SizedBox(
                          //   height: 8,
                          // ),
                          // TextField(
                          //   autocorrect: Util.isDesktop ? false : true,
                          //   enableSuggestions: Util.isDesktop ? false : true,
                          //   style: STextStyles.smallMed14(context).copyWith(
                          //     color: Theme.of(context)
                          //         .extension<StackColors>()!
                          //         .textLight,
                          //   ),
                          //   key: const Key("amountInputFieldFiatTextFieldKey"),
                          //   controller: baseAmountController,
                          //   focusNode: _baseFocus,
                          //   keyboardType: const TextInputType.numberWithOptions(
                          //     signed: false,
                          //     decimal: true,
                          //   ),
                          //   textAlign: TextAlign.right,
                          //   inputFormatters: [
                          //     // regex to validate a fiat amount with 2 decimal places
                          //     TextInputFormatter.withFunction((oldValue,
                          //             newValue) =>
                          //         RegExp(r'^([0-9]*[,.]?[0-9]{0,2}|[,.][0-9]{0,2})$')
                          //                 .hasMatch(newValue.text)
                          //             ? newValue
                          //             : oldValue),
                          //   ],
                          //   onChanged: (baseAmountString) {
                          //     if (baseAmountString.isNotEmpty &&
                          //         baseAmountString != "." &&
                          //         baseAmountString != ",") {
                          //       final baseAmount = baseAmountString
                          //               .contains(",")
                          //           ? Decimal.parse(
                          //               baseAmountString.replaceFirst(",", "."))
                          //           : Decimal.parse(baseAmountString);
                          //
                          //       var _price = ref
                          //           .read(priceAnd24hChangeNotifierProvider)
                          //           .getPrice(coin)
                          //           .item1;
                          //
                          //       if (_price == Decimal.zero) {
                          //         _amountToSend = Decimal.zero;
                          //       } else {
                          //         _amountToSend = baseAmount <= Decimal.zero
                          //             ? Decimal.zero
                          //             : (baseAmount / _price).toDecimal(
                          //                 scaleOnInfinitePrecision:
                          //                     Constants.decimalPlaces);
                          //       }
                          //       if (_cachedAmountToSend != null &&
                          //           _cachedAmountToSend == _amountToSend) {
                          //         return;
                          //       }
                          //       _cachedAmountToSend = _amountToSend;
                          //       Logging.instance.log(
                          //           "it changed $_amountToSend $_cachedAmountToSend",
                          //           level: LogLevel.Info);
                          //
                          //       final amountString =
                          //           Format.localizedStringAsFixed(
                          //         value: _amountToSend!,
                          //         locale: ref
                          //             .read(localeServiceChangeNotifierProvider)
                          //             .locale,
                          //         decimalPlaces: Constants.decimalPlaces,
                          //       );
                          //
                          //       _cryptoAmountChangeLock = true;
                          //       cryptoAmountController.text = amountString;
                          //       _cryptoAmountChangeLock = false;
                          //     } else {
                          //       _amountToSend = Decimal.zero;
                          //       _cryptoAmountChangeLock = true;
                          //       cryptoAmountController.text = "";
                          //       _cryptoAmountChangeLock = false;
                          //     }
                          //     // setState(() {
                          //     //   _calculateFeesFuture = calculateFees(
                          //     //       Format.decimalAmountToSatoshis(
                          //     //           _amountToSend!));
                          //     // });
                          //     _updatePreviewButtonState(
                          //         _address, _amountToSend);
                          //   },
                          //   decoration: InputDecoration(
                          //     contentPadding: const EdgeInsets.only(
                          //       top: 12,
                          //       right: 12,
                          //     ),
                          //     hintText: "0",
                          //     hintStyle:
                          //         STextStyles.fieldLabel(context).copyWith(
                          //       fontSize: 14,
                          //     ),
                          //     prefixIcon: FittedBox(
                          //       fit: BoxFit.scaleDown,
                          //       child: Padding(
                          //         padding: const EdgeInsets.all(12),
                          //         child: Text(
                          //           ref.watch(prefsChangeNotifierProvider
                          //               .select((value) => value.currency)),
                          //           style: STextStyles.smallMed14(context)
                          //               .copyWith(
                          //                   color: Theme.of(context)
                          //                       .extension<StackColors>()!
                          //                       .accentColorDark),
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          // const SizedBox(
                          //   height: 12,
                          // ),
                          // Text(
                          //   "Note (optional)",
                          //   style: STextStyles.smallMed12(context),
                          //   textAlign: TextAlign.left,
                          // ),
                          // const SizedBox(
                          //   height: 8,
                          // ),
                          // ClipRRect(
                          //   borderRadius: BorderRadius.circular(
                          //     Constants.size.circularBorderRadius,
                          //   ),
                          //   child: TextField(
                          //     autocorrect: Util.isDesktop ? false : true,
                          //     enableSuggestions: Util.isDesktop ? false : true,
                          //     controller: noteController,
                          //     focusNode: _noteFocusNode,
                          //     style: STextStyles.field(context),
                          //     onChanged: (_) => setState(() {}),
                          //     decoration: standardInputDecoration(
                          //       "Type something...",
                          //       _noteFocusNode,
                          //       context,
                          //     ).copyWith(
                          //       suffixIcon: noteController.text.isNotEmpty
                          //           ? Padding(
                          //               padding:
                          //                   const EdgeInsets.only(right: 0),
                          //               child: UnconstrainedBox(
                          //                 child: Row(
                          //                   children: [
                          //                     TextFieldIconButton(
                          //                       child: const XIcon(),
                          //                       onTap: () async {
                          //                         setState(() {
                          //                           noteController.text = "";
                          //                         });
                          //                       },
                          //                     ),
                          //                   ],
                          //                 ),
                          //               ),
                          //             )
                          //           : null,
                          //     ),
                          //   ),
                          // ),
                          // const SizedBox(
                          //   height: 12,
                          // ),
                          // Text(
                          //   "Transaction fee (estimated)",
                          //   style: STextStyles.smallMed12(context),
                          //   textAlign: TextAlign.left,
                          // ),
                          // const SizedBox(
                          //   height: 8,
                          // ),
                          // Stack(
                          //   children: [
                          //     TextField(
                          //       autocorrect: Util.isDesktop ? false : true,
                          //       enableSuggestions:
                          //           Util.isDesktop ? false : true,
                          //       controller: feeController,
                          //       readOnly: true,
                          //       textInputAction: TextInputAction.none,
                          //     ),
                          //     Padding(
                          //       padding: const EdgeInsets.symmetric(
                          //         horizontal: 12,
                          //       ),
                          //       child: RawMaterialButton(
                          //         splashColor: Theme.of(context)
                          //             .extension<StackColors>()!
                          //             .highlight,
                          //         shape: RoundedRectangleBorder(
                          //           borderRadius: BorderRadius.circular(
                          //             Constants.size.circularBorderRadius,
                          //           ),
                          //         ),
                          //         onPressed: () {
                          //           showModalBottomSheet<dynamic>(
                          //             backgroundColor: Colors.transparent,
                          //             context: context,
                          //             shape: const RoundedRectangleBorder(
                          //               borderRadius: BorderRadius.vertical(
                          //                 top: Radius.circular(20),
                          //               ),
                          //             ),
                          //             builder: (_) =>
                          //                 TransactionFeeSelectionSheet(
                          //               walletId: walletId,
                          //               amount: Decimal.tryParse(
                          //                       cryptoAmountController.text) ??
                          //                   Decimal.zero,
                          //               updateChosen: (String fee) {
                          //                 setState(() {
                          //                   _calculateFeesFuture =
                          //                       Future(() => fee);
                          //                 });
                          //               },
                          //             ),
                          //           );
                          //         },
                          //         child: Row(
                          //           mainAxisAlignment:
                          //               MainAxisAlignment.spaceBetween,
                          //           children: [
                          //             Row(
                          //               children: [
                          //                 Text(
                          //                   ref
                          //                       .watch(feeRateTypeStateProvider
                          //                           .state)
                          //                       .state
                          //                       .prettyName,
                          //                   style: STextStyles.itemSubtitle12(
                          //                       context),
                          //                 ),
                          //                 const SizedBox(
                          //                   width: 10,
                          //                 ),
                          //                 FutureBuilder(
                          //                   future: _calculateFeesFuture,
                          //                   builder: (context, snapshot) {
                          //                     if (snapshot.connectionState ==
                          //                             ConnectionState.done &&
                          //                         snapshot.hasData) {
                          //                       return Text(
                          //                         "~${snapshot.data! as String} ${coin.ticker}",
                          //                         style:
                          //                             STextStyles.itemSubtitle(
                          //                                 context),
                          //                       );
                          //                     } else {
                          //                       return AnimatedText(
                          //                         stringsToLoopThrough: const [
                          //                           "Calculating",
                          //                           "Calculating.",
                          //                           "Calculating..",
                          //                           "Calculating...",
                          //                         ],
                          //                         style:
                          //                             STextStyles.itemSubtitle(
                          //                                 context),
                          //                       );
                          //                     }
                          //                   },
                          //                 ),
                          //               ],
                          //             ),
                          //             SvgPicture.asset(
                          //               Assets.svg.chevronDown,
                          //               width: 8,
                          //               height: 4,
                          //               color: Theme.of(context)
                          //                   .extension<StackColors>()!
                          //                   .textSubtitle2,
                          //             ),
                          //           ],
                          //         ),
                          //       ),
                          //     )
                          //   ],
                          // ),
                          const SizedBox(
                            height: 24,
                          ),
                          TextButton(
                            onPressed: _addressToggleFlag
                                ? () {
                                    Navigator.of(context).pushNamed(
                                      SendAmountView.routeName,
                                      arguments: Tuple2(
                                        "$ref.read(walletProvider)!.walletId",
                                        Coin.epicCash,
                                      ),
                                    );
                                    debugPrint("$_address");
                                    //     // wait for keyboard to disappear
                                    //     FocusScope.of(context).unfocus();
                                    //     await Future<void>.delayed(
                                    //       const Duration(milliseconds: 100),
                                    //     );
                                    //
                                    //     // TODO: remove the need for this!!
                                    //     final bool isOwnAddress = await ref
                                    //         .read(walletProvider)!
                                    //         .isOwnAddress(_address!);
                                    //     if (isOwnAddress) {
                                    //       await showDialog<dynamic>(
                                    //         context: context,
                                    //         useSafeArea: false,
                                    //         barrierDismissible: true,
                                    //         builder: (context) {
                                    //           return StackDialog(
                                    //             title: "Transaction failed",
                                    //             message:
                                    //                 "Sending to self is currently disabled",
                                    //             rightButton: TextButton(
                                    //               style: Theme.of(context)
                                    //                   .extension<StackColors>()!
                                    //                   .getSecondaryEnabledButtonColor(
                                    //                       context),
                                    //               child: Text(
                                    //                 "Ok",
                                    //                 style: STextStyles.buttonText(
                                    //                         context)
                                    //                     .copyWith(
                                    //                         color: Theme.of(context)
                                    //                             .extension<
                                    //                                 StackColors>()!
                                    //                             .accentColorDark),
                                    //               ),
                                    //               onPressed: () {
                                    //                 Navigator.of(context).pop();
                                    //               },
                                    //             ),
                                    //           );
                                    //         },
                                    //       );
                                    //       return;
                                    //     }
                                    //
                                    //     final amount =
                                    //         Format.decimalAmountToSatoshis(
                                    //             _amountToSend!);
                                    //     int availableBalance;
                                    //     availableBalance =
                                    //         Format.decimalAmountToSatoshis(await ref
                                    //             .read(walletProvider)!
                                    //             .availableBalance);
                                    //
                                    //     // confirm send all
                                    //     if (amount == availableBalance) {
                                    //       final bool? shouldSendAll =
                                    //           await showDialog<bool>(
                                    //         context: context,
                                    //         useSafeArea: false,
                                    //         barrierDismissible: true,
                                    //         builder: (context) {
                                    //           return StackDialog(
                                    //             title: "Confirm send all",
                                    //             message:
                                    //                 "You are about to send your entire balance. Would you like to continue?",
                                    //             leftButton: TextButton(
                                    //               style: Theme.of(context)
                                    //                   .extension<StackColors>()!
                                    //                   .getSecondaryEnabledButtonColor(
                                    //                       context),
                                    //               child: Text(
                                    //                 "Cancel",
                                    //                 style: STextStyles.buttonText(
                                    //                         context)
                                    //                     .copyWith(
                                    //                         color: Theme.of(context)
                                    //                             .extension<
                                    //                                 StackColors>()!
                                    //                             .accentColorDark),
                                    //               ),
                                    //               onPressed: () {
                                    //                 Navigator.of(context)
                                    //                     .pop(false);
                                    //               },
                                    //             ),
                                    //             rightButton: TextButton(
                                    //               style: Theme.of(context)
                                    //                   .extension<StackColors>()!
                                    //                   .getPrimaryEnabledButtonColor(
                                    //                       context),
                                    //               child: Text(
                                    //                 "Yes",
                                    //                 style: STextStyles.buttonText(
                                    //                     context),
                                    //               ),
                                    //               onPressed: () {
                                    //                 Navigator.of(context).pop(true);
                                    //               },
                                    //             ),
                                    //           );
                                    //         },
                                    //       );
                                    //
                                    //       if (shouldSendAll == null ||
                                    //           shouldSendAll == false) {
                                    //         // cancel preview
                                    //         return;
                                    //       }
                                    //     }
                                    //
                                    //     try {
                                    //       bool wasCancelled = false;
                                    //
                                    //       unawaited(showDialog<dynamic>(
                                    //         context: context,
                                    //         useSafeArea: false,
                                    //         barrierDismissible: false,
                                    //         builder: (context) {
                                    //           return BuildingTransactionDialog(
                                    //             onCancel: () {
                                    //               wasCancelled = true;
                                    //
                                    //               Navigator.of(context).pop();
                                    //             },
                                    //           );
                                    //         },
                                    //       ));
                                    //
                                    //       Map<String, dynamic> txData = await ref
                                    //           .read(walletProvider)!
                                    //           .prepareSend(
                                    //         address: _address!,
                                    //         satoshiAmount: amount,
                                    //         args: {
                                    //           "feeRate":
                                    //               ref.read(feeRateTypeStateProvider)
                                    //         },
                                    //       );
                                    //
                                    //       if (!wasCancelled && mounted) {
                                    //         // pop building dialog
                                    //         Navigator.of(context).pop();
                                    //         txData["note"] = noteController.text;
                                    //         txData["address"] = _address;
                                    //
                                    //         unawaited(Navigator.of(context).push(
                                    //           RouteGenerator.getRoute(
                                    //             shouldUseMaterialRoute:
                                    //                 RouteGenerator
                                    //                     .useMaterialPageRoute,
                                    //             builder: (_) =>
                                    //                 ConfirmTransactionView(
                                    //               transactionInfo: txData,
                                    //               walletId: walletId,
                                    //             ),
                                    //             settings: const RouteSettings(
                                    //               name: ConfirmTransactionView
                                    //                   .routeName,
                                    //             ),
                                    //           ),
                                    //         ));
                                    //       }
                                    //     } catch (e) {
                                    //       if (mounted) {
                                    //         // pop building dialog
                                    //         Navigator.of(context).pop();
                                    //
                                    //         unawaited(showDialog<dynamic>(
                                    //           context: context,
                                    //           useSafeArea: false,
                                    //           barrierDismissible: true,
                                    //           builder: (context) {
                                    //             return StackDialog(
                                    //               title: "Transaction failed",
                                    //               message: e.toString(),
                                    //               rightButton: TextButton(
                                    //                 style: Theme.of(context)
                                    //                     .extension<StackColors>()!
                                    //                     .getSecondaryEnabledButtonColor(
                                    //                         context),
                                    //                 child: Text(
                                    //                   "Ok",
                                    //                   style: STextStyles.buttonText(
                                    //                           context)
                                    //                       .copyWith(
                                    //                           color: Theme.of(
                                    //                                   context)
                                    //                               .extension<
                                    //                                   StackColors>()!
                                    //                               .accentColorDark),
                                    //                 ),
                                    //                 onPressed: () {
                                    //                   Navigator.of(context).pop();
                                    //                 },
                                    //               ),
                                    //             );
                                    //           },
                                    //         ));
                                    //       }
                                    //     }
                                  }
                                : null,
                            style: _addressToggleFlag
                                ? Theme.of(context)
                                    .extension<StackColors>()!
                                    .getPrimaryEnabledButtonColor(context)
                                : Theme.of(context)
                                    .extension<StackColors>()!
                                    .getPrimaryDisabledButtonColor(context),
                            child: Text(
                              "Next",
                              style: STextStyles.buttonText(context).copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .coal),
                            ),
                          ),
                          const Spacer(
                            flex: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
