import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/contact_address_entry.dart';
import 'package:stackwallet/models/paynym/paynym_account_lite.dart';
import 'package:stackwallet/models/send_view_auto_fill_data.dart';
import 'package:stackwallet/pages/send_view/confirm_transaction_view.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/building_transaction_dialog.dart';
import 'package:stackwallet/pages/token_view/token_view.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_home_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/address_book_address_chooser/address_book_address_chooser.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_fee_dropdown.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/providers/ui/fee_rate_type_state_provider.dart';
import 'package:stackwallet/providers/ui/preview_tx_button_state_provider.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/barcode_scanner_interface.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/addressbook_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/clipboard_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

const _kCryptoAmountRegex = r'^([0-9]*[,.]?[0-9]{0,8}|[,.][0-9]{0,8})$';

class DesktopTokenSend extends ConsumerStatefulWidget {
  const DesktopTokenSend({
    Key? key,
    required this.walletId,
    this.autoFillData,
    this.clipboard = const ClipboardWrapper(),
    this.barcodeScanner = const BarcodeScannerWrapper(),
    this.accountLite,
  }) : super(key: key);

  final String walletId;
  final SendViewAutoFillData? autoFillData;
  final ClipboardInterface clipboard;
  final BarcodeScannerInterface barcodeScanner;
  final PaynymAccountLite? accountLite;

  @override
  ConsumerState<DesktopTokenSend> createState() => _DesktopTokenSendState();
}

class _DesktopTokenSendState extends ConsumerState<DesktopTokenSend> {
  late final String walletId;
  late final Coin coin;
  late final ClipboardInterface clipboard;
  late final BarcodeScannerInterface scanner;

  late TextEditingController sendToController;
  late TextEditingController cryptoAmountController;
  late TextEditingController baseAmountController;
  late TextEditingController nonceController;

  late final SendViewAutoFillData? _data;

  final _addressFocusNode = FocusNode();
  final _cryptoFocus = FocusNode();
  final _baseFocus = FocusNode();
  final _nonceFocusNode = FocusNode();

  String? _note;

  Amount? _amountToSend;
  Amount? _cachedAmountToSend;
  String? _address;

  bool _addressToggleFlag = false;

  bool _cryptoAmountChangeLock = false;
  late VoidCallback onCryptoAmountChanged;

  Future<void> previewSend() async {
    final tokenWallet = ref.read(tokenServiceProvider)!;

    final Amount amount = _amountToSend!;
    final Amount availableBalance = tokenWallet.balance.spendable;

    // confirm send all
    if (amount == availableBalance) {
      final bool? shouldSendAll = await showDialog<bool>(
        context: context,
        useSafeArea: false,
        barrierDismissible: true,
        builder: (context) {
          return DesktopDialog(
            maxWidth: 450,
            maxHeight: double.infinity,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 32,
                bottom: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Confirm send all",
                        style: STextStyles.desktopH3(context),
                      ),
                      const DesktopDialogCloseButton(),
                    ],
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 32,
                    ),
                    child: Text(
                      "You are about to send your entire balance. Would you like to continue?",
                      textAlign: TextAlign.left,
                      style: STextStyles.desktopTextExtraExtraSmall(context)
                          .copyWith(
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 32,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            buttonHeight: ButtonHeight.l,
                            label: "Cancel",
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        Expanded(
                          child: PrimaryButton(
                            buttonHeight: ButtonHeight.l,
                            label: "Yes",
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (shouldSendAll == null || shouldSendAll == false) {
        // cancel preview
        return;
      }
    }

    try {
      bool wasCancelled = false;

      if (mounted) {
        unawaited(
          showDialog<dynamic>(
            context: context,
            useSafeArea: false,
            barrierDismissible: false,
            builder: (context) {
              return DesktopDialog(
                maxWidth: 400,
                maxHeight: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: BuildingTransactionDialog(
                    coin: tokenWallet.coin,
                    onCancel: () {
                      wasCancelled = true;

                      Navigator.of(context).pop();
                    },
                  ),
                ),
              );
            },
          ),
        );
      }

      final time = Future<dynamic>.delayed(
        const Duration(
          milliseconds: 2500,
        ),
      );

      Map<String, dynamic> txData;
      Future<Map<String, dynamic>> txDataFuture;

      txDataFuture = tokenWallet.prepareSend(
        address: _address!,
        amount: amount,
        args: {
          "feeRate": ref.read(feeRateTypeStateProvider),
          "nonce": int.tryParse(nonceController.text),
        },
      );

      final results = await Future.wait([
        txDataFuture,
        time,
      ]);

      txData = results.first as Map<String, dynamic>;

      if (!wasCancelled && mounted) {
        txData["address"] = _address;
        txData["note"] = _note ?? "";

        // pop building dialog
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop();

        unawaited(
          showDialog(
            context: context,
            builder: (context) => DesktopDialog(
              maxHeight: double.infinity,
              maxWidth: 580,
              child: ConfirmTransactionView(
                transactionInfo: txData,
                walletId: walletId,
                isTokenTx: true,
                routeOnSuccessName: DesktopHomeView.routeName,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // pop building dialog
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop();

        unawaited(
          showDialog<void>(
            context: context,
            builder: (context) {
              return DesktopDialog(
                maxWidth: 450,
                maxHeight: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 32,
                    bottom: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Transaction failed",
                            style: STextStyles.desktopH3(context),
                          ),
                          const DesktopDialogCloseButton(),
                        ],
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          right: 32,
                        ),
                        child: SelectableText(
                          e.toString(),
                          textAlign: TextAlign.left,
                          style: STextStyles.desktopTextExtraExtraSmall(context)
                              .copyWith(
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 40,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              buttonHeight: ButtonHeight.l,
                              label: "Ok",
                              onPressed: () {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();
                              },
                            ),
                          ),
                          const SizedBox(
                            width: 32,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }
    }
  }

  void _cryptoAmountChanged() async {
    if (!_cryptoAmountChangeLock) {
      final String cryptoAmount = cryptoAmountController.text;
      if (cryptoAmount.isNotEmpty &&
          cryptoAmount != "." &&
          cryptoAmount != ",") {
        _amountToSend = cryptoAmount.contains(",")
            ? Decimal.parse(cryptoAmount.replaceFirst(",", ".")).toAmount(
                fractionDigits:
                    ref.read(tokenServiceProvider)!.tokenContract.decimals,
              )
            : Decimal.parse(cryptoAmount).toAmount(
                fractionDigits:
                    ref.read(tokenServiceProvider)!.tokenContract.decimals,
              );
        if (_cachedAmountToSend != null &&
            _cachedAmountToSend == _amountToSend) {
          return;
        }
        Logging.instance.log("it changed $_amountToSend $_cachedAmountToSend",
            level: LogLevel.Info);
        _cachedAmountToSend = _amountToSend;

        final price = ref
            .read(priceAnd24hChangeNotifierProvider)
            .getTokenPrice(
              ref.read(tokenServiceProvider)!.tokenContract.address,
            )
            .item1;

        if (price > Decimal.zero) {
          final String fiatAmountString = Amount.fromDecimal(
            _amountToSend!.decimal * price,
            fractionDigits: 2,
          ).localizedStringAsFixed(
            locale: ref.read(localeServiceChangeNotifierProvider).locale,
            decimalPlaces: 2,
          );

          baseAmountController.text = fiatAmountString;
        }
      } else {
        _amountToSend = null;
        _cachedAmountToSend = null;
        baseAmountController.text = "";
      }

      _updatePreviewButtonState(_address, _amountToSend);
    }
  }

  String? _updateInvalidAddressText(String address, Manager manager) {
    if (_data != null && _data!.contactLabel == address) {
      return null;
    }
    if (address.isNotEmpty && !manager.validateAddress(address)) {
      return "Invalid address";
    }
    return null;
  }

  void _updatePreviewButtonState(String? address, Amount? amount) {
    final isValidAddress = ref
        .read(walletsChangeNotifierProvider)
        .getManager(walletId)
        .validateAddress(address ?? "");
    ref.read(previewTokenTxButtonStateProvider.state).state =
        (isValidAddress && amount != null && amount > Amount.zero);
  }

  Future<void> scanQr() async {
    try {
      if (FocusScope.of(context).hasFocus) {
        FocusScope.of(context).unfocus();
        await Future<void>.delayed(const Duration(milliseconds: 75));
      }

      final qrResult = await scanner.scan();

      Logging.instance.log("qrResult content: ${qrResult.rawContent}",
          level: LogLevel.Info);

      final results = AddressUtils.parseUri(qrResult.rawContent);

      Logging.instance.log("qrResult parsed: $results", level: LogLevel.Info);

      if (results.isNotEmpty && results["scheme"] == coin.uriScheme) {
        // auto fill address
        _address = results["address"] ?? "";
        sendToController.text = _address!;

        // autofill notes field
        if (results["message"] != null) {
          _note = results["message"]!;
        } else if (results["label"] != null) {
          _note = results["label"]!;
        }

        // autofill amount field
        if (results["amount"] != null) {
          final amount = Decimal.parse(results["amount"]!).toAmount(
            fractionDigits:
                ref.read(tokenServiceProvider)!.tokenContract.decimals,
          );
          cryptoAmountController.text = amount.localizedStringAsFixed(
            locale: ref.read(localeServiceChangeNotifierProvider).locale,
          );

          amount.toString();
          _amountToSend = amount;
        }

        _updatePreviewButtonState(_address, _amountToSend);
        setState(() {
          _addressToggleFlag = sendToController.text.isNotEmpty;
        });

        // now check for non standard encoded basic address
      } else if (ref
          .read(walletsChangeNotifierProvider)
          .getManager(walletId)
          .validateAddress(qrResult.rawContent)) {
        _address = qrResult.rawContent;
        sendToController.text = _address ?? "";

        _updatePreviewButtonState(_address, _amountToSend);
        setState(() {
          _addressToggleFlag = sendToController.text.isNotEmpty;
        });
      }
    } on PlatformException catch (e, s) {
      // here we ignore the exception caused by not giving permission
      // to use the camera to scan a qr code
      Logging.instance.log(
          "Failed to get camera permissions while trying to scan qr code in SendView: $e\n$s",
          level: LogLevel.Warning);
    }
  }

  Future<void> pasteAddress() async {
    final ClipboardData? data = await clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      String content = data.text!.trim();
      if (content.contains("\n")) {
        content = content.substring(0, content.indexOf("\n"));
      }

      sendToController.text = content;
      _address = content;

      _updatePreviewButtonState(_address, _amountToSend);
      setState(() {
        _addressToggleFlag = sendToController.text.isNotEmpty;
      });
    }
  }

  void fiatTextFieldOnChanged(String baseAmountString) {
    final int tokenDecimals =
        ref.read(tokenServiceProvider)!.tokenContract.decimals;

    if (baseAmountString.isNotEmpty &&
        baseAmountString != "." &&
        baseAmountString != ",") {
      final baseAmount = baseAmountString.contains(",")
          ? Decimal.parse(baseAmountString.replaceFirst(",", "."))
              .toAmount(fractionDigits: 2)
          : Decimal.parse(baseAmountString).toAmount(fractionDigits: 2);

      final Decimal _price = ref
          .read(priceAnd24hChangeNotifierProvider)
          .getTokenPrice(
            ref.read(tokenServiceProvider)!.tokenContract.address,
          )
          .item1;

      if (_price == Decimal.zero) {
        _amountToSend = Decimal.zero.toAmount(fractionDigits: tokenDecimals);
      } else {
        _amountToSend = baseAmount <= Amount.zero
            ? Decimal.zero.toAmount(fractionDigits: tokenDecimals)
            : (baseAmount.decimal / _price)
                .toDecimal(scaleOnInfinitePrecision: tokenDecimals)
                .toAmount(fractionDigits: tokenDecimals);
      }
      if (_cachedAmountToSend != null && _cachedAmountToSend == _amountToSend) {
        return;
      }
      _cachedAmountToSend = _amountToSend;
      Logging.instance.log("it changed $_amountToSend $_cachedAmountToSend",
          level: LogLevel.Info);

      final amountString = _amountToSend!.localizedStringAsFixed(
        locale: ref.read(localeServiceChangeNotifierProvider).locale,
        decimalPlaces: tokenDecimals,
      );

      _cryptoAmountChangeLock = true;
      cryptoAmountController.text = amountString;
      _cryptoAmountChangeLock = false;
    } else {
      _amountToSend = Decimal.zero.toAmount(fractionDigits: tokenDecimals);
      _cryptoAmountChangeLock = true;
      cryptoAmountController.text = "";
      _cryptoAmountChangeLock = false;
    }

    _updatePreviewButtonState(_address, _amountToSend);
  }

  Future<void> sendAllTapped() async {
    cryptoAmountController.text = ref
        .read(tokenServiceProvider)!
        .balance
        .spendable
        .decimal
        .toStringAsFixed(
          ref.read(tokenServiceProvider)!.tokenContract.decimals,
        );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.refresh(tokenFeeSessionCacheProvider);
      ref.read(previewTokenTxButtonStateProvider.state).state = false;
    });

    // _calculateFeesFuture = calculateFees(0);
    _data = widget.autoFillData;
    walletId = widget.walletId;
    coin = ref.read(walletsChangeNotifierProvider).getManager(walletId).coin;
    clipboard = widget.clipboard;
    scanner = widget.barcodeScanner;

    sendToController = TextEditingController();
    cryptoAmountController = TextEditingController();
    baseAmountController = TextEditingController();
    nonceController = TextEditingController();
    // feeController = TextEditingController();

    onCryptoAmountChanged = _cryptoAmountChanged;
    cryptoAmountController.addListener(onCryptoAmountChanged);

    if (_data != null) {
      if (_data!.amount != null) {
        cryptoAmountController.text = _data!.amount!.toString();
      }
      sendToController.text = _data!.contactLabel;
      _address = _data!.address;
      _addressToggleFlag = true;
    }

    _cryptoFocus.addListener(() {
      if (!_cryptoFocus.hasFocus && !_baseFocus.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_amountToSend == null) {
            ref.refresh(sendAmountProvider);
          } else {
            ref.read(sendAmountProvider.state).state = _amountToSend!;
          }
        });
      }
    });

    _baseFocus.addListener(() {
      if (!_cryptoFocus.hasFocus && !_baseFocus.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_amountToSend == null) {
            ref.refresh(sendAmountProvider);
          } else {
            ref.read(sendAmountProvider.state).state = _amountToSend!;
          }
        });
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    cryptoAmountController.removeListener(onCryptoAmountChanged);

    sendToController.dispose();
    cryptoAmountController.dispose();
    baseAmountController.dispose();
    nonceController.dispose();
    // feeController.dispose();

    _addressFocusNode.dispose();
    _cryptoFocus.dispose();
    _baseFocus.dispose();
    _nonceFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final tokenContract = ref.watch(tokenServiceProvider)!.tokenContract;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 4,
        ),
        if (coin == Coin.firo)
          Text(
            "Send from",
            style: STextStyles.desktopTextExtraSmall(context).copyWith(
              color: Theme.of(context)
                  .extension<StackColors>()!
                  .textFieldActiveSearchIconRight,
            ),
            textAlign: TextAlign.left,
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Amount",
              style: STextStyles.desktopTextExtraSmall(context).copyWith(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldActiveSearchIconRight,
              ),
              textAlign: TextAlign.left,
            ),
            CustomTextButton(
              text: "Send all ${tokenContract.symbol}",
              onTap: sendAllTapped,
            ),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        TextField(
          autocorrect: Util.isDesktop ? false : true,
          enableSuggestions: Util.isDesktop ? false : true,
          style: STextStyles.smallMed14(context).copyWith(
            color: Theme.of(context).extension<StackColors>()!.textDark,
          ),
          key: const Key("amountInputFieldCryptoTextFieldKey"),
          controller: cryptoAmountController,
          focusNode: _cryptoFocus,
          keyboardType: Util.isDesktop
              ? null
              : const TextInputType.numberWithOptions(
                  signed: false,
                  decimal: true,
                ),
          textAlign: TextAlign.right,
          inputFormatters: [
            // regex to validate a crypto amount with 8 decimal places
            TextInputFormatter.withFunction((oldValue, newValue) => RegExp(
                  _kCryptoAmountRegex.replaceAll(
                    "0,8",
                    "0,${tokenContract.decimals}",
                  ),
                ).hasMatch(newValue.text)
                    ? newValue
                    : oldValue),
          ],
          onChanged: (newValue) {},
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
                  tokenContract.symbol,
                  style: STextStyles.smallMed14(context).copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorDark),
                ),
              ),
            ),
          ),
        ),
        if (Prefs.instance.externalCalls)
          const SizedBox(
            height: 10,
          ),
        if (Prefs.instance.externalCalls)
          TextField(
            autocorrect: Util.isDesktop ? false : true,
            enableSuggestions: Util.isDesktop ? false : true,
            style: STextStyles.smallMed14(context).copyWith(
              color: Theme.of(context).extension<StackColors>()!.textDark,
            ),
            key: const Key("amountInputFieldFiatTextFieldKey"),
            controller: baseAmountController,
            focusNode: _baseFocus,
            keyboardType: Util.isDesktop
                ? null
                : const TextInputType.numberWithOptions(
                    signed: false,
                    decimal: true,
                  ),
            textAlign: TextAlign.right,
            inputFormatters: [
              // regex to validate a fiat amount with 2 decimal places
              TextInputFormatter.withFunction((oldValue, newValue) =>
                  RegExp(r'^([0-9]*[,.]?[0-9]{0,2}|[,.][0-9]{0,2})$')
                          .hasMatch(newValue.text)
                      ? newValue
                      : oldValue),
            ],
            onChanged: fiatTextFieldOnChanged,
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
                    ref.watch(prefsChangeNotifierProvider
                        .select((value) => value.currency)),
                    style: STextStyles.smallMed14(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorDark),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(
          height: 20,
        ),
        Text(
          "Send to",
          style: STextStyles.desktopTextExtraSmall(context).copyWith(
            color: Theme.of(context)
                .extension<StackColors>()!
                .textFieldActiveSearchIconRight,
          ),
          textAlign: TextAlign.left,
        ),
        const SizedBox(
          height: 10,
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
          child: TextField(
            minLines: 1,
            maxLines: 5,
            key: const Key("sendViewAddressFieldKey"),
            controller: sendToController,
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
              _updatePreviewButtonState(_address, _amountToSend);

              setState(() {
                _addressToggleFlag = newValue.isNotEmpty;
              });
            },
            focusNode: _addressFocusNode,
            style: STextStyles.desktopTextExtraSmall(context).copyWith(
              color: Theme.of(context)
                  .extension<StackColors>()!
                  .textFieldActiveText,
              height: 1.8,
            ),
            decoration: standardInputDecoration(
              "Enter ${tokenContract.symbol} address",
              _addressFocusNode,
              context,
              desktopMed: true,
            ).copyWith(
              contentPadding: const EdgeInsets.only(
                left: 16,
                top: 11,
                bottom: 12,
                right: 5,
              ),
              suffixIcon: Padding(
                padding: sendToController.text.isEmpty
                    ? const EdgeInsets.only(right: 8)
                    : const EdgeInsets.only(right: 0),
                child: UnconstrainedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _addressToggleFlag
                          ? TextFieldIconButton(
                              key: const Key(
                                  "sendTokenViewClearAddressFieldButtonKey"),
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
                            )
                          : TextFieldIconButton(
                              key: const Key(
                                  "sendTokenViewPasteAddressFieldButtonKey"),
                              onTap: pasteAddress,
                              child: sendToController.text.isEmpty
                                  ? const ClipboardIcon()
                                  : const XIcon(),
                            ),
                      if (sendToController.text.isEmpty)
                        TextFieldIconButton(
                          key: const Key("sendTokenViewAddressBookButtonKey"),
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
                                            style:
                                                STextStyles.desktopH3(context),
                                          ),
                                        ),
                                        const DesktopDialogCloseButton(),
                                      ],
                                    ),
                                    Expanded(
                                      child: AddressBookAddressChooser(
                                        coin: coin,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            if (entry != null) {
                              sendToController.text =
                                  entry.other ?? entry.label;

                              _address = entry.address;

                              _updatePreviewButtonState(
                                _address,
                                _amountToSend,
                              );

                              setState(() {
                                _addressToggleFlag = true;
                              });
                            }
                          },
                          child: const AddressBookIcon(),
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
              ref.read(walletsChangeNotifierProvider).getManager(walletId),
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
                    style: STextStyles.label(context).copyWith(
                      color:
                          Theme.of(context).extension<StackColors>()!.textError,
                    ),
                  ),
                ),
              );
            }
          },
        ),
        const SizedBox(
          height: 20,
        ),
        Text(
          "Transaction fee (max)",
          style: STextStyles.desktopTextExtraSmall(context).copyWith(
            color: Theme.of(context)
                .extension<StackColors>()!
                .textFieldActiveSearchIconRight,
          ),
          textAlign: TextAlign.left,
        ),
        const SizedBox(
          height: 10,
        ),
        DesktopFeeDropDown(
          walletId: walletId,
          isToken: true,
        ),
        const SizedBox(
          height: 20,
        ),
        Text(
          "Nonce",
          style: STextStyles.desktopTextExtraSmall(context).copyWith(
            color: Theme.of(context)
                .extension<StackColors>()!
                .textFieldActiveSearchIconRight,
          ),
          textAlign: TextAlign.left,
        ),
        const SizedBox(
          height: 10,
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
          child: TextField(
            minLines: 1,
            maxLines: 1,
            key: const Key("sendViewNonceFieldKey"),
            controller: nonceController,
            readOnly: false,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: const TextInputType.numberWithOptions(),
            focusNode: _nonceFocusNode,
            style: STextStyles.desktopTextExtraSmall(context).copyWith(
              color: Theme.of(context)
                  .extension<StackColors>()!
                  .textFieldActiveText,
              height: 1.8,
            ),
            decoration: standardInputDecoration(
              "Leave empty to auto select nonce",
              _nonceFocusNode,
              context,
              desktopMed: true,
            ).copyWith(
              contentPadding: const EdgeInsets.only(
                left: 16,
                top: 11,
                bottom: 12,
                right: 5,
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 36,
        ),
        PrimaryButton(
          buttonHeight: ButtonHeight.l,
          label: "Preview send",
          enabled: ref.watch(previewTokenTxButtonStateProvider.state).state,
          onPressed: ref.watch(previewTokenTxButtonStateProvider.state).state
              ? previewSend
              : null,
        )
      ],
    );
  }
}
