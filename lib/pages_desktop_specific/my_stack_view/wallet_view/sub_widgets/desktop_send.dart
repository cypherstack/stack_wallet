import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/models/contact_address_entry.dart';
import 'package:stackwallet/models/send_view_auto_fill_data.dart';
import 'package:stackwallet/pages/send_view/confirm_transaction_view.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/building_transaction_dialog.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/transaction_fee_selection_sheet.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_home_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/address_book_address_chooser/address_book_address_chooser.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_fee_dropdown.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/providers/ui/fee_rate_type_state_provider.dart';
import 'package:stackwallet/providers/ui/preview_tx_button_state_provider.dart';
import 'package:stackwallet/providers/wallet/public_private_balance_state_provider.dart';
import 'package:stackwallet/services/coins/firo/firo_wallet.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/barcode_scanner_interface.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/animated_text.dart';
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

class DesktopSend extends ConsumerStatefulWidget {
  const DesktopSend({
    Key? key,
    required this.walletId,
    this.autoFillData,
    this.clipboard = const ClipboardWrapper(),
    this.barcodeScanner = const BarcodeScannerWrapper(),
  }) : super(key: key);

  final String walletId;
  final SendViewAutoFillData? autoFillData;
  final ClipboardInterface clipboard;
  final BarcodeScannerInterface barcodeScanner;

  @override
  ConsumerState<DesktopSend> createState() => _DesktopSendState();
}

class _DesktopSendState extends ConsumerState<DesktopSend> {
  late final String walletId;
  late final Coin coin;
  late final ClipboardInterface clipboard;
  late final BarcodeScannerInterface scanner;

  late TextEditingController sendToController;
  late TextEditingController cryptoAmountController;
  late TextEditingController baseAmountController;
  // late TextEditingController feeController;

  late final SendViewAutoFillData? _data;

  final _addressFocusNode = FocusNode();
  final _cryptoFocus = FocusNode();
  final _baseFocus = FocusNode();

  String? _note;

  Decimal? _amountToSend;
  Decimal? _cachedAmountToSend;
  String? _address;

  String? _privateBalanceString;
  String? _publicBalanceString;

  bool _addressToggleFlag = false;

  bool _cryptoAmountChangeLock = false;
  late VoidCallback onCryptoAmountChanged;

  Future<void> previewSend() async {
    final manager =
        ref.read(walletsChangeNotifierProvider).getManager(walletId);

    // TODO: remove the need for this!!
    final bool isOwnAddress = await manager.isOwnAddress(_address!);
    if (isOwnAddress) {
      await showDialog<dynamic>(
        context: context,
        useSafeArea: false,
        barrierDismissible: true,
        builder: (context) {
          return DesktopDialog(
            maxWidth: 400,
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
                  Text(
                    "Sending to self is currently disabled",
                    textAlign: TextAlign.left,
                    style: STextStyles.desktopTextExtraExtraSmall(context)
                        .copyWith(
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 32,
                    ),
                    child: SecondaryButton(
                      buttonHeight: ButtonHeight.l,
                      label: "Ok",
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      return;
    }

    final amount = Format.decimalAmountToSatoshis(_amountToSend!, coin);
    int availableBalance;
    if ((coin == Coin.firo || coin == Coin.firoTestNet)) {
      if (ref.read(publicPrivateBalanceStateProvider.state).state ==
          "Private") {
        availableBalance = Format.decimalAmountToSatoshis(
            await (manager.wallet as FiroWallet).availablePrivateBalance(),
            coin);
      } else {
        availableBalance = Format.decimalAmountToSatoshis(
            await (manager.wallet as FiroWallet).availablePublicBalance(),
            coin);
      }
    } else {
      availableBalance =
          Format.decimalAmountToSatoshis(await manager.availableBalance, coin);
    }

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

                              setState(() {
                                sendToController.text = "";
                                cryptoAmountController.text = "";
                                baseAmountController.text = "";
                              });
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

      unawaited(showDialog<dynamic>(
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
                onCancel: () {
                  wasCancelled = true;

                  Navigator.of(context).pop();
                },
              ),
            ),
          );
        },
      ));

      Map<String, dynamic> txData;

      if ((coin == Coin.firo || coin == Coin.firoTestNet) &&
          ref.read(publicPrivateBalanceStateProvider.state).state !=
              "Private") {
        txData = await (manager.wallet as FiroWallet).prepareSendPublic(
          address: _address!,
          satoshiAmount: amount,
          args: {"feeRate": ref.read(feeRateTypeStateProvider)},
        );
      } else {
        txData = await manager.prepareSend(
          address: _address!,
          satoshiAmount: amount,
          args: {"feeRate": ref.read(feeRateTypeStateProvider)},
        );
      }

      if (!wasCancelled && mounted) {
        // pop building dialog
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop();
        txData["note"] = _note;
        txData["address"] = _address;

        unawaited(
          showDialog(
            context: context,
            builder: (context) => DesktopDialog(
              maxHeight: double.infinity,
              maxWidth: 580,
              child: ConfirmTransactionView(
                transactionInfo: txData,
                walletId: walletId,
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
                        child: Text(
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
                      Padding(
                        padding: const EdgeInsets.only(
                          right: 32,
                        ),
                        child: Expanded(
                          child: SecondaryButton(
                            buttonHeight: ButtonHeight.l,
                            label: "Yes",
                            onPressed: () {
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pop();
                            },
                          ),
                        ),
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
            ? Decimal.parse(cryptoAmount.replaceFirst(",", "."))
            : Decimal.parse(cryptoAmount);
        if (_cachedAmountToSend != null &&
            _cachedAmountToSend == _amountToSend) {
          return;
        }
        _cachedAmountToSend = _amountToSend;
        Logging.instance.log("it changed $_amountToSend $_cachedAmountToSend",
            level: LogLevel.Info);

        final price =
            ref.read(priceAnd24hChangeNotifierProvider).getPrice(coin).item1;

        if (price > Decimal.zero) {
          final String fiatAmountString = Format.localizedStringAsFixed(
            value: _amountToSend! * price,
            locale: ref.read(localeServiceChangeNotifierProvider).locale,
            decimalPlaces: 2,
          );

          baseAmountController.text = fiatAmountString;
        }
      } else {
        _amountToSend = null;
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

  void _updatePreviewButtonState(String? address, Decimal? amount) {
    final isValidAddress = ref
        .read(walletsChangeNotifierProvider)
        .getManager(walletId)
        .validateAddress(address ?? "");
    ref.read(previewTxButtonStateProvider.state).state =
        (isValidAddress && amount != null && amount > Decimal.zero);
  }

  // late Future<String> _calculateFeesFuture;

  // Map<int, String> cachedFees = {};
  // Map<int, String> cachedFiroPrivateFees = {};
  // Map<int, String> cachedFiroPublicFees = {};

  // Future<String> calculateFees(int amount) async {
  //   if (amount <= 0) {
  //     return "0";
  //   }
  //
  //   if (coin == Coin.firo || coin == Coin.firoTestNet) {
  //     if (ref.read(publicPrivateBalanceStateProvider.state).state ==
  //         "Private") {
  //       if (cachedFiroPrivateFees[amount] != null) {
  //         return cachedFiroPrivateFees[amount]!;
  //       }
  //     } else {
  //       if (cachedFiroPublicFees[amount] != null) {
  //         return cachedFiroPublicFees[amount]!;
  //       }
  //     }
  //   } else if (cachedFees[amount] != null) {
  //     return cachedFees[amount]!;
  //   }
  //
  //   final manager =
  //       ref.read(walletsChangeNotifierProvider).getManager(walletId);
  //   final feeObject = await manager.fees;
  //
  //   late final int feeRate;
  //
  //   switch (ref.read(feeRateTypeStateProvider.state).state) {
  //     case FeeRateType.fast:
  //       feeRate = feeObject.fast;
  //       break;
  //     case FeeRateType.average:
  //       feeRate = feeObject.medium;
  //       break;
  //     case FeeRateType.slow:
  //       feeRate = feeObject.slow;
  //       break;
  //   }
  //
  //   int fee;
  //
  //   if (coin == Coin.firo || coin == Coin.firoTestNet) {
  //     if (ref.read(publicPrivateBalanceStateProvider.state).state ==
  //         "Private") {
  //       fee = await manager.estimateFeeFor(amount, feeRate);
  //
  //       cachedFiroPrivateFees[amount] = Format.satoshisToAmount(fee)
  //           .toStringAsFixed(Constants.decimalPlaces);
  //
  //       return cachedFiroPrivateFees[amount]!;
  //     } else {
  //       fee = await (manager.wallet as FiroWallet)
  //           .estimateFeeForPublic(amount, feeRate);
  //
  //       cachedFiroPublicFees[amount] = Format.satoshisToAmount(fee)
  //           .toStringAsFixed(Constants.decimalPlaces);
  //
  //       return cachedFiroPublicFees[amount]!;
  //     }
  //   } else {
  //     fee = await manager.estimateFeeFor(amount, feeRate);
  //     cachedFees[amount] =
  //         Format.satoshisToAmount(fee).toStringAsFixed(Constants.decimalPlaces);
  //
  //     return cachedFees[amount]!;
  //   }
  // }

  Future<String?> _firoBalanceFuture(
    ChangeNotifierProvider<Manager> provider,
    String locale,
    bool private,
  ) async {
    final wallet = ref.read(provider).wallet as FiroWallet?;

    if (wallet != null) {
      Decimal? balance;
      if (private) {
        balance = await wallet.availablePrivateBalance();
      } else {
        balance = await wallet.availablePublicBalance();
      }

      return Format.localizedStringAsFixed(
          value: balance, locale: locale, decimalPlaces: 8);
    }

    return null;
  }

  Widget firoBalanceFutureBuilder(
    BuildContext context,
    AsyncSnapshot<String?> snapshot,
    bool private,
  ) {
    if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
      if (private) {
        _privateBalanceString = snapshot.data!;
      } else {
        _publicBalanceString = snapshot.data!;
      }
    }
    if (private && _privateBalanceString != null) {
      return Text(
        "$_privateBalanceString ${coin.ticker}",
        style: STextStyles.itemSubtitle(context),
      );
    } else if (!private && _publicBalanceString != null) {
      return Text(
        "$_publicBalanceString ${coin.ticker}",
        style: STextStyles.itemSubtitle(context),
      );
    } else {
      return AnimatedText(
        stringsToLoopThrough: const [
          "Loading balance",
          "Loading balance.",
          "Loading balance..",
          "Loading balance...",
        ],
        style: STextStyles.itemSubtitle(context),
      );
    }
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
          final amount = Decimal.parse(results["amount"]!);
          cryptoAmountController.text = Format.localizedStringAsFixed(
            value: amount,
            locale: ref.read(localeServiceChangeNotifierProvider).locale,
            decimalPlaces: Constants.decimalPlacesForCoin(coin),
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
    if (baseAmountString.isNotEmpty &&
        baseAmountString != "." &&
        baseAmountString != ",") {
      final baseAmount = baseAmountString.contains(",")
          ? Decimal.parse(baseAmountString.replaceFirst(",", "."))
          : Decimal.parse(baseAmountString);

      var _price =
          ref.read(priceAnd24hChangeNotifierProvider).getPrice(coin).item1;

      if (_price == Decimal.zero) {
        _amountToSend = Decimal.zero;
      } else {
        _amountToSend = baseAmount <= Decimal.zero
            ? Decimal.zero
            : (baseAmount / _price).toDecimal(
                scaleOnInfinitePrecision: Constants.decimalPlacesForCoin(coin));
      }
      if (_cachedAmountToSend != null && _cachedAmountToSend == _amountToSend) {
        return;
      }
      _cachedAmountToSend = _amountToSend;
      Logging.instance.log("it changed $_amountToSend $_cachedAmountToSend",
          level: LogLevel.Info);

      final amountString = Format.localizedStringAsFixed(
        value: _amountToSend!,
        locale: ref.read(localeServiceChangeNotifierProvider).locale,
        decimalPlaces: Constants.decimalPlacesForCoin(coin),
      );

      _cryptoAmountChangeLock = true;
      cryptoAmountController.text = amountString;
      _cryptoAmountChangeLock = false;
    } else {
      _amountToSend = Decimal.zero;
      _cryptoAmountChangeLock = true;
      cryptoAmountController.text = "";
      _cryptoAmountChangeLock = false;
    }
    // setState(() {
    //   _calculateFeesFuture = calculateFees(
    //       Format.decimalAmountToSatoshis(
    //           _amountToSend!));
    // });
    _updatePreviewButtonState(_address, _amountToSend);
  }

  Future<void> sendAllTapped() async {
    if (coin == Coin.firo || coin == Coin.firoTestNet) {
      final firoWallet = ref
          .read(walletsChangeNotifierProvider)
          .getManager(walletId)
          .wallet as FiroWallet;
      if (ref.read(publicPrivateBalanceStateProvider.state).state ==
          "Private") {
        cryptoAmountController.text =
            (await firoWallet.availablePrivateBalance())
                .toStringAsFixed(Constants.decimalPlacesForCoin(coin));
      } else {
        cryptoAmountController.text =
            (await firoWallet.availablePublicBalance())
                .toStringAsFixed(Constants.decimalPlacesForCoin(coin));
      }
    } else {
      cryptoAmountController.text = (await ref
              .read(walletsChangeNotifierProvider)
              .getManager(walletId)
              .availableBalance)
          .toStringAsFixed(Constants.decimalPlacesForCoin(coin));
    }
  }

  @override
  void initState() {
    ref.refresh(feeSheetSessionCacheProvider);

    // _calculateFeesFuture = calculateFees(0);
    _data = widget.autoFillData;
    walletId = widget.walletId;
    coin = ref.read(walletsChangeNotifierProvider).getManager(walletId).coin;
    clipboard = widget.clipboard;
    scanner = widget.barcodeScanner;

    sendToController = TextEditingController();
    cryptoAmountController = TextEditingController();
    baseAmountController = TextEditingController();
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
        if (_amountToSend == null) {
          ref.refresh(sendAmountProvider);
        } else {
          ref.read(sendAmountProvider.state).state = _amountToSend!;
        }
      }
    });

    _baseFocus.addListener(() {
      if (!_cryptoFocus.hasFocus && !_baseFocus.hasFocus) {
        if (_amountToSend == null) {
          ref.refresh(sendAmountProvider);
        } else {
          ref.read(sendAmountProvider.state).state = _amountToSend!;
        }
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
    // feeController.dispose();

    _addressFocusNode.dispose();
    _cryptoFocus.dispose();
    _baseFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    final provider = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManagerProvider(walletId)));
    final String locale = ref.watch(
        localeServiceChangeNotifierProvider.select((value) => value.locale));

    // if (coin == Coin.firo || coin == Coin.firoTestNet) {
    //   ref.listen(publicPrivateBalanceStateProvider, (previous, next) {
    //     if (_amountToSend == null) {
    //       setState(() {
    //         _calculateFeesFuture = calculateFees(0);
    //       });
    //     } else {
    //       setState(() {
    //         _calculateFeesFuture =
    //             calculateFees(Format.decimalAmountToSatoshis(_amountToSend!));
    //       });
    //     }
    //   });
    // }

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
        if (coin == Coin.firo)
          const SizedBox(
            height: 10,
          ),
        if (coin == Coin.firo)
          DropdownButtonHideUnderline(
            child: DropdownButton2(
              offset: const Offset(0, -10),
              isExpanded: true,
              dropdownElevation: 0,
              value: ref.watch(publicPrivateBalanceStateProvider.state).state,
              items: [
                DropdownMenuItem(
                  value: "Private",
                  child: Row(
                    children: [
                      Text(
                        "Private balance",
                        style: STextStyles.itemSubtitle12(context),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      FutureBuilder(
                        future: _firoBalanceFuture(provider, locale, true),
                        builder: (context, AsyncSnapshot<String?> snapshot) =>
                            firoBalanceFutureBuilder(
                          context,
                          snapshot,
                          true,
                        ),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: "Public",
                  child: Row(
                    children: [
                      Text(
                        "Public balance",
                        style: STextStyles.itemSubtitle12(context),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      FutureBuilder(
                        future: _firoBalanceFuture(provider, locale, false),
                        builder: (context, AsyncSnapshot<String?> snapshot) =>
                            firoBalanceFutureBuilder(
                          context,
                          snapshot,
                          false,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value is String) {
                  setState(() {
                    ref.watch(publicPrivateBalanceStateProvider.state).state =
                        value;
                  });
                }
              },
              icon: SvgPicture.asset(
                Assets.svg.chevronDown,
                width: 12,
                height: 6,
                color: Theme.of(context).extension<StackColors>()!.textDark3,
              ),
              buttonPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              buttonDecoration: BoxDecoration(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldDefaultBG,
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
              ),
              dropdownDecoration: BoxDecoration(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldDefaultBG,
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
              ),
            ),
          ),
        if (coin == Coin.firo)
          const SizedBox(
            height: 20,
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
            BlueTextButton(
              text: "Send all ${coin.ticker}",
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
          keyboardType: const TextInputType.numberWithOptions(
            signed: false,
            decimal: true,
          ),
          textAlign: TextAlign.right,
          inputFormatters: [
            // regex to validate a crypto amount with 8 decimal places
            TextInputFormatter.withFunction((oldValue, newValue) =>
                RegExp(r'^([0-9]*[,.]?[0-9]{0,8}|[,.][0-9]{0,8})$')
                        .hasMatch(newValue.text)
                    ? newValue
                    : oldValue),
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
                  coin.ticker,
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
            keyboardType: const TextInputType.numberWithOptions(
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
              "Enter ${coin.ticker} address",
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
                            )
                          : TextFieldIconButton(
                              key: const Key(
                                  "sendViewPasteAddressFieldButtonKey"),
                              onTap: pasteAddress,
                              child: sendToController.text.isEmpty
                                  ? const ClipboardIcon()
                                  : const XIcon(),
                            ),
                      if (sendToController.text.isEmpty)
                        TextFieldIconButton(
                          key: const Key("sendViewAddressBookButtonKey"),
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
                      // if (sendToController.text.isEmpty)
                      //   TextFieldIconButton(
                      //     key: const Key("sendViewScanQrButtonKey"),
                      //     onTap: scanQr,
                      //     child: const QrCodeIcon(),
                      //   )
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
        // const SizedBox(
        //   height: 20,
        // ),
        // Text(
        //   "Note (optional)",
        //   style: STextStyles.desktopTextExtraSmall(context).copyWith(
        //     color: Theme.of(context)
        //         .extension<StackColors>()!
        //         .textFieldActiveSearchIconRight,
        //   ),
        //   textAlign: TextAlign.left,
        // ),
        // const SizedBox(
        //   height: 10,
        // ),
        // ClipRRect(
        //   borderRadius: BorderRadius.circular(
        //     Constants.size.circularBorderRadius,
        //   ),
        //   child: TextField(
        //     minLines: 1,
        //     maxLines: 5,
        //     autocorrect: Util.isDesktop ? false : true,
        //     enableSuggestions: Util.isDesktop ? false : true,
        //     controller: noteController,
        //     focusNode: _noteFocusNode,
        //     style: STextStyles.desktopTextExtraSmall(context).copyWith(
        //       color: Theme.of(context)
        //           .extension<StackColors>()!
        //           .textFieldActiveText,
        //       height: 1.8,
        //     ),
        //     onChanged: (_) => setState(() {}),
        //     decoration: standardInputDecoration(
        //       "Type something...",
        //       _noteFocusNode,
        //       context,
        //       desktopMed: true,
        //     ).copyWith(
        //       contentPadding: const EdgeInsets.only(
        //         left: 16,
        //         top: 11,
        //         bottom: 12,
        //         right: 5,
        //       ),
        //       suffixIcon: noteController.text.isNotEmpty
        //           ? Padding(
        //               padding: const EdgeInsets.only(right: 0),
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
        const SizedBox(
          height: 20,
        ),
        Text(
          "Transaction fee (estimated)",
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
        ),
        const SizedBox(
          height: 36,
        ),
        PrimaryButton(
          buttonHeight: ButtonHeight.l,
          label: "Preview send",
          enabled: ref.watch(previewTxButtonStateProvider.state).state,
          onPressed: ref.watch(previewTxButtonStateProvider.state).state
              ? previewSend
              : null,
        )
      ],
    );
  }
}
