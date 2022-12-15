import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:epicpay/pages/home_view/home_view.dart';
import 'package:epicpay/pages/pinpad_views/lock_screen_view.dart';
import 'package:epicpay/pages/wallet_view/sub_widgets/wallet_summary_info.dart';
import 'package:epicpay/providers/providers.dart';
import 'package:epicpay/providers/ui/preview_tx_button_state_provider.dart';
import 'package:epicpay/route_generator.dart';
import 'package:epicpay/utilities/barcode_scanner_interface.dart';
import 'package:epicpay/utilities/constants.dart';
import 'package:epicpay/utilities/enums/coin_enum.dart';
import 'package:epicpay/utilities/format.dart';
import 'package:epicpay/utilities/logger.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/widgets/animated_text.dart';
import 'package:epicpay/widgets/background.dart';
import 'package:epicpay/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicpay/widgets/desktop/custom_text_button.dart';
import 'package:epicpay/widgets/icon_widgets/x_icon.dart';
import 'package:epicpay/widgets/stack_dialog.dart';
import 'package:epicpay/widgets/textfield_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SendAmountView extends ConsumerStatefulWidget {
  const SendAmountView({
    Key? key,
    required this.walletId,
    required this.address,
    required this.coin,
    this.barcodeScanner = const BarcodeScannerWrapper(),
  }) : super(key: key);

  static const String routeName = "/sendAmountView";

  final String walletId;
  final String address;
  final Coin coin;
  final BarcodeScannerInterface barcodeScanner;

  @override
  ConsumerState<SendAmountView> createState() => _SendAmountViewState();
}

enum SendingState { waiting, generating, sending, sent }

class _SendAmountViewState extends ConsumerState<SendAmountView> {
  late final String walletId;
  late final String address;
  late final Coin coin;
  late final BarcodeScannerInterface scanner;

  late TextEditingController sendToController;
  late TextEditingController cryptoAmountController;
  late TextEditingController baseAmountController;
  late TextEditingController noteController;
  late TextEditingController feeController;

  final _addressFocusNode = FocusNode();
  final _noteFocusNode = FocusNode();
  final _cryptoFocus = FocusNode();
  final _baseFocus = FocusNode();

  Decimal? _amountToSend;
  Decimal? _cachedAmountToSend;
  String? feeErr;

  bool _cryptoAmountChangeLock = false;
  late VoidCallback onCryptoAmountChanged;

  SendingState sendingState = SendingState.waiting;

  Widget getButtonChild(
    BuildContext context,
    bool enabled,
    SendingState state,
  ) {
    final style = STextStyles.buttonText(context).copyWith(
      color: enabled
          ? Theme.of(context).extension<StackColors>()!.buttonTextPrimary
          : Theme.of(context)
              .extension<StackColors>()!
              .buttonTextPrimaryDisabled,
    );

    switch (state) {
      case SendingState.waiting:
        return Text(
          "SEND",
          style: style,
        );
      case SendingState.generating:
        return AnimatedText(
          stringsToLoopThrough: const [
            "GENERATING",
            "GENERATING.",
            "GENERATING..",
            "GENERATING...",
          ],
          style: style,
        );
      case SendingState.sending:
        return AnimatedText(
          stringsToLoopThrough: const [
            "SENDING",
            "SENDING.",
            "SENDING..",
            "SENDING...",
          ],
          style: style,
        );
      case SendingState.sent:
        return Text(
          "SENT",
          style: style,
        );
    }
  }

  Decimal? _cachedBalance;

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

      _updatePreviewButtonState(address, _amountToSend, feeErr);

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
    }
  }

  void _updatePreviewButtonState(
      String? address, Decimal? amount, String? feeErr) {
    final isValidAddress =
        ref.read(walletProvider)!.validateAddress(address ?? "");
    ref.read(previewTxButtonStateProvider.state).state = (isValidAddress &&
            amount != null &&
            amount > Decimal.zero &&
            amount <= ref.read(walletProvider)!.cachedAvailableBalance) &&
        feeErr == null;
  }

  late Future<Decimal> _calculateFeesFuture;
  // late Future<Decimal> _displayFees;
  Map<int, Decimal> cachedFees = {};

  Future<Decimal> calculateFees(int amount) async {
    if (amount <= 0) {
      return Decimal.zero;
    }

    if (cachedFees[amount] != null) {
      return cachedFees[amount]!;
    }

    final manager = ref.read(walletProvider)!;

    final fee = await manager.estimateFeeFor(amount, 1);
    cachedFees[amount] = Format.satoshisToAmount(fee);

    return cachedFees[amount]!;
  }

  Future<void> availableBalance() async {
    unawaited(
      showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius * 2),
              ),
              backgroundColor:
                  Theme.of(context).extension<StackColors>()!.popupBG,
              child: Container(
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius * 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: const [
                          AppBarBackButton(),
                        ],
                      ),
                      Text(
                        "Available Balance",
                        style: STextStyles.titleH3(context).copyWith(
                          fontSize: 18,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textMedium,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        "YOU CAN SPEND",
                        style: STextStyles.overLineBold(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textDark,
                        ),
                      ),
                      const SizedBox(
                        height: 6,
                      ),
                      WalletSummaryInfo(
                        walletId: walletId,
                        isSendView: true,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
    );
  }

  void send() async {
    // ignore if currently sending
    if (sendingState != SendingState.waiting) {
      return;
    }

    // // wait for keyboard to disappear
    // FocusScope.of(context).unfocus();
    // await Future<void>.delayed(
    //   const Duration(milliseconds: 75),
    // );
    //

    // unlock
    final unlocked = await Navigator.push(
      context,
      RouteGenerator.getRoute(
        shouldUseMaterialRoute: RouteGenerator.useMaterialPageRoute,
        builder: (_) => const LockscreenView(
          showBackButton: true,
          popOnSuccess: true,
          routeOnSuccessArguments: true,
          routeOnSuccess: "",
          biometricsCancelButtonString: "CANCEL",
          biometricsLocalizedReason: "Authenticate to send transaction",
          biometricsAuthenticationTitle: "Confirm Transaction",
        ),
        settings: const RouteSettings(name: "/confirmsendlockscreen"),
      ),
    );

    // failed to authenticate
    if (!(unlocked is bool && unlocked && mounted)) {
      return;
    }

    setState(() {
      sendingState = SendingState.generating;
    });

    final amount = Format.decimalAmountToSatoshis(_amountToSend!);

    try {
      Map<String, dynamic> txData = await ref.read(walletProvider)!.prepareSend(
        address: address,
        satoshiAmount: amount,
        args: {"feeRate": 1},
      );

      setState(() {
        sendingState = SendingState.sending;
      });

      txData["note"] = noteController.text;
      txData["address"] = address;

      final txid = await ref.read(walletProvider)!.confirmSend(txData: txData);

      unawaited(
        ref.read(walletProvider)!.refresh(),
      );

      // save note
      await ref
          .read(notesServiceChangeNotifierProvider(walletId))
          .editOrAddNote(txid: txid, note: noteController.text);

      setState(() {
        sendingState = SendingState.sent;
      });

      await Future<void>.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).popUntil(
          ModalRoute.withName(
            HomeView.routeName,
          ),
        );
        // ensure return to wallet view
        ref.read(homeViewPageIndexStateProvider.state).state = 1;
      }
      sendingState = SendingState.waiting;
    } catch (e) {
      if (mounted) {
        setState(() {
          sendingState = SendingState.waiting;
        });
        unawaited(
          showDialog<dynamic>(
            context: context,
            useSafeArea: false,
            barrierDismissible: true,
            builder: (context) {
              return StackDialog(
                title: "Transaction failed",
                message: e.toString(),
                rightButton: TextButton(
                  style: Theme.of(context)
                      .extension<StackColors>()!
                      .getSecondaryEnabledButtonColor(context),
                  child: Text(
                    "Ok",
                    style: STextStyles.buttonText(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorDark),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              );
            },
          ),
        );
      }
    }
  }

  @override
  void initState() {
    _calculateFeesFuture = calculateFees(0);
    // _displayFees = calculateFees(0);
    walletId = widget.walletId;
    address = widget.address;
    coin = widget.coin;
    scanner = widget.barcodeScanner;

    sendToController = TextEditingController();
    cryptoAmountController = TextEditingController();
    baseAmountController = TextEditingController();
    noteController = TextEditingController();
    feeController = TextEditingController();

    onCryptoAmountChanged = _cryptoAmountChanged;
    cryptoAmountController.addListener(onCryptoAmountChanged);

    _cryptoFocus.addListener(() {
      if (!_cryptoFocus.hasFocus && !_baseFocus.hasFocus) {
        if (_amountToSend == null) {
          setState(() {
            _calculateFeesFuture = calculateFees(0);
            // _displayFees = calculateFees(0);
          });
        } else {
          setState(() {
            _calculateFeesFuture =
                calculateFees(Format.decimalAmountToSatoshis(_amountToSend!));
            // _displayFees = calculateNetworkFees(
            //     Format.decimalAmountToSatoshis(_amountToSend!));
          });
        }
      }
    });

    _baseFocus.addListener(() {
      if (!_cryptoFocus.hasFocus && !_baseFocus.hasFocus) {
        if (_amountToSend == null) {
          setState(() {
            _calculateFeesFuture = calculateFees(0);
            // _displayFees = calculateFees(0);
          });
        } else {
          setState(() {
            _calculateFeesFuture =
                calculateFees(Format.decimalAmountToSatoshis(_amountToSend!));
            // _displayFees = calculateNetworkFees(
            //     Format.decimalAmountToSatoshis(_amountToSend!));
          });
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
    noteController.dispose();
    feeController.dispose();

    _noteFocusNode.dispose();
    _addressFocusNode.dispose();
    _cryptoFocus.dispose();
    _baseFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return Background(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leading: AppBarBackButton(
            onPressed: () async {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            "Send",
            style: STextStyles.titleH3(context).copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (builderContext, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "SEND TO",
                          style: STextStyles.overLineBold(context),
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Text(
                          address,
                          style: STextStyles.body(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textLight,
                          ),
                        ),
                        const _Divider(),
                        Text(
                          "NOTE (OPTIONAL)",
                          style: STextStyles.overLineBold(context),
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                autocorrect: true,
                                enableSuggestions: true,
                                controller: noteController,
                                focusNode: _noteFocusNode,
                                style: STextStyles.body(context),
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.all(0),
                                  hintText: "Type something...",
                                  hintStyle: STextStyles.body(context).copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textDark,
                                  ),
                                  fillColor: Theme.of(context)
                                      .extension<StackColors>()!
                                      .background,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isCollapsed: true,
                                ),
                              ),
                            ),
                            if (noteController.text.isNotEmpty)
                              TextFieldIconButton(
                                height: 20,
                                width: 20,
                                child: const XIcon(
                                  width: 16,
                                  height: 16,
                                ),
                                onTap: () async {
                                  setState(() {
                                    noteController.text = "";
                                  });
                                },
                              ),
                          ],
                        ),
                        const _Divider(),
                        Text(
                          "ENTER AMOUNT TO SEND",
                          style: STextStyles.overLineBold(context),
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        TextField(
                          autocorrect: true,
                          enableSuggestions: true,
                          style: STextStyles.body(context),
                          key: const Key("amountInputFieldCryptoTextFieldKey"),
                          controller: cryptoAmountController,
                          focusNode: _cryptoFocus,
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: false,
                            decimal: true,
                          ),
                          textAlign: TextAlign.left,
                          inputFormatters: [
                            // regex to validate a crypto amount with 8 decimal places
                            TextInputFormatter.withFunction((oldValue,
                                    newValue) =>
                                RegExp(r'^([0-9]*[,.]?[0-9]{0,8}|[,.][0-9]{0,8})$')
                                        .hasMatch(newValue.text)
                                    ? newValue
                                    : oldValue),
                          ],
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context)
                                .extension<StackColors>()!
                                .coal,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            hintText: "0.00",
                            hintStyle: STextStyles.body(context).copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textMedium,
                            ),
                            isCollapsed: true,
                            suffixIcon: SizedBox(
                              width: 79,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(
                                      Constants.size.circularBorderRadius,
                                    ),
                                    bottomRight: Radius.circular(
                                      Constants.size.circularBorderRadius,
                                    ),
                                  ),
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .buttonBackPrimaryDisabled
                                      .withOpacity(0.7),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    coin.ticker,
                                    textAlign: TextAlign.center,
                                    style: STextStyles.body(context).copyWith(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .textMedium,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        TextField(
                          autocorrect: true,
                          enableSuggestions: true,
                          style: STextStyles.body(context),
                          key: const Key("amountInputFieldFiatTextFieldKey"),
                          controller: baseAmountController,
                          focusNode: _baseFocus,
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: false,
                            decimal: true,
                          ),
                          textAlign: TextAlign.left,
                          inputFormatters: [
                            // regex to validate a fiat amount with 2 decimal places
                            TextInputFormatter.withFunction((oldValue,
                                    newValue) =>
                                RegExp(r'^([0-9]*[,.]?[0-9]{0,2}|[,.][0-9]{0,2})$')
                                        .hasMatch(newValue.text)
                                    ? newValue
                                    : oldValue),
                          ],
                          onChanged: (baseAmountString) {
                            if (baseAmountString.isNotEmpty &&
                                baseAmountString != "." &&
                                baseAmountString != ",") {
                              final baseAmount = baseAmountString.contains(",")
                                  ? Decimal.parse(
                                      baseAmountString.replaceFirst(",", "."))
                                  : Decimal.parse(baseAmountString);

                              var _price = ref
                                  .read(priceAnd24hChangeNotifierProvider)
                                  .getPrice(coin)
                                  .item1;

                              if (_price == Decimal.zero) {
                                _amountToSend = Decimal.zero;
                              } else {
                                _amountToSend = baseAmount <= Decimal.zero
                                    ? Decimal.zero
                                    : (baseAmount / _price).toDecimal(
                                        scaleOnInfinitePrecision:
                                            Constants.decimalPlaces);
                              }
                              if (_cachedAmountToSend != null &&
                                  _cachedAmountToSend == _amountToSend) {
                                return;
                              }
                              _cachedAmountToSend = _amountToSend;
                              Logging.instance.log(
                                  "it changed $_amountToSend $_cachedAmountToSend",
                                  level: LogLevel.Info);

                              final amountString =
                                  Format.localizedStringAsFixed(
                                value: _amountToSend!,
                                locale: ref
                                    .read(localeServiceChangeNotifierProvider)
                                    .locale,
                                decimalPlaces: Constants.decimalPlaces,
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
                            _updatePreviewButtonState(
                                address, _amountToSend, feeErr);
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context)
                                .extension<StackColors>()!
                                .coal,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            hintText: "0.00",
                            hintStyle: STextStyles.body(context).copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textMedium,
                            ),
                            isCollapsed: true,
                            suffixIcon: SizedBox(
                              width: 79,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(
                                      Constants.size.circularBorderRadius,
                                    ),
                                    bottomRight: Radius.circular(
                                      Constants.size.circularBorderRadius,
                                    ),
                                  ),
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .buttonBackPrimaryDisabled
                                      .withOpacity(0.7),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    ref.watch(prefsChangeNotifierProvider
                                        .select((value) => value.currency)),
                                    textAlign: TextAlign.center,
                                    style: STextStyles.body(context).copyWith(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .textMedium,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: availableBalance,
                              style: Theme.of(context)
                                  .extension<StackColors>()!
                                  .getPrimaryDisabledButtonColor(context),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  "VIEW AVAILABLE BALANCE",
                                  textAlign: TextAlign.center,
                                  style: STextStyles.overLineBold(context)
                                      .copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .buttonBackPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 32,
                        ),
                        Center(
                          child: Text(
                            "NETWORK FEE",
                            style: STextStyles.overLineBold(context).copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textMedium,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        FutureBuilder(
                          future: _calculateFeesFuture,
                          builder: (context, AsyncSnapshot<Decimal> snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.hasData) {
                              final feeAmount = snapshot.data!;

                              final total =
                                  feeAmount + (_amountToSend ?? Decimal.zero);

                              if (total >
                                  ref
                                      .read(walletProvider)!
                                      .cachedAvailableBalance) {
                                feeErr = "Not enough balance";
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  _updatePreviewButtonState(
                                      address, _amountToSend, feeErr);
                                });
                              } else {
                                feeErr = null;
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  _updatePreviewButtonState(
                                      address, _amountToSend, feeErr);
                                });
                              }

                              return Column(
                                children: [
                                  Text(
                                    feeErr ?? "~$feeAmount ${coin.ticker}",
                                    textAlign: TextAlign.center,
                                    style: STextStyles.body(context),
                                  ),
                                  const SizedBox(
                                    height: 36,
                                  ),
                                  Center(
                                    child: Text(
                                      "TOTAL AMOUNT TO SEND (INCLUDING FEE)",
                                      style: STextStyles.overLineBold(context)
                                          .copyWith(
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .textMedium,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 6,
                                  ),
                                  Text(
                                    feeErr ?? "~$total ${coin.ticker}",
                                    textAlign: TextAlign.center,
                                    style:
                                        STextStyles.titleH2(context).copyWith(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .buttonBackPrimary,
                                    ),
                                  )
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  Center(
                                    child: AnimatedText(
                                      stringsToLoopThrough: const [
                                        "Calculating",
                                        "Calculating.",
                                        "Calculating..",
                                        "Calculating...",
                                      ],
                                      style: STextStyles.body(context),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 36,
                                  ),
                                  Center(
                                    child: Text(
                                      "TOTAL AMOUNT TO SEND (INCLUDING FEE)",
                                      style: STextStyles.overLineBold(context)
                                          .copyWith(
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .textMedium,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 6,
                                  ),
                                  Center(
                                    child: AnimatedText(
                                      stringsToLoopThrough: const [
                                        "Calculating",
                                        "Calculating.",
                                        "Calculating..",
                                        "Calculating...",
                                      ],
                                      style:
                                          STextStyles.titleH2(context).copyWith(
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .buttonBackPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                        const Spacer(),
                        const SizedBox(
                          height: 24,
                        ),
                        CustomTextButtonBase(
                          height: 56,
                          textButton: TextButton(
                            onPressed: ref
                                    .watch(previewTxButtonStateProvider.state)
                                    .state
                                ? send
                                : null,
                            style: ref
                                    .watch(previewTxButtonStateProvider.state)
                                    .state
                                ? Theme.of(context)
                                    .extension<StackColors>()!
                                    .getPrimaryEnabledButtonColor(context)
                                : Theme.of(context)
                                    .extension<StackColors>()!
                                    .getPrimaryDisabledButtonColor(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                getButtonChild(
                                  context,
                                  ref
                                      .watch(previewTxButtonStateProvider.state)
                                      .state,
                                  sendingState,
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Container(
        height: 2,
        color: Theme.of(context)
            .extension<StackColors>()!
            .buttonBackPrimaryDisabled,
      ),
    );
  }
}
