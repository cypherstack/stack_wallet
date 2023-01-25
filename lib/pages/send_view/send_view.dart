import 'dart:async';

import 'package:cw_core/monero_transaction_priority.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/models/send_view_auto_fill_data.dart';
import 'package:stackwallet/pages/address_book_views/address_book_view.dart';
import 'package:stackwallet/pages/send_view/confirm_transaction_view.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/building_transaction_dialog.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/firo_balance_selection_sheet.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/transaction_fee_selection_sheet.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/providers/ui/fee_rate_type_state_provider.dart';
import 'package:stackwallet/providers/ui/preview_tx_button_state_provider.dart';
import 'package:stackwallet/providers/wallet/public_private_balance_state_provider.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/services/coins/firo/firo_wallet.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/barcode_scanner_interface.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/animated_text.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/icon_widgets/addressbook_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/clipboard_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/qrcode_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class SendView extends ConsumerStatefulWidget {
  const SendView({
    Key? key,
    required this.walletId,
    required this.coin,
    this.autoFillData,
    this.clipboard = const ClipboardWrapper(),
    this.barcodeScanner = const BarcodeScannerWrapper(),
  }) : super(key: key);

  static const String routeName = "/sendView";

  final String walletId;
  final Coin coin;
  final SendViewAutoFillData? autoFillData;
  final ClipboardInterface clipboard;
  final BarcodeScannerInterface barcodeScanner;

  @override
  ConsumerState<SendView> createState() => _SendViewState();
}

class _SendViewState extends ConsumerState<SendView> {
  late final String walletId;
  late final Coin coin;
  late final ClipboardInterface clipboard;
  late final BarcodeScannerInterface scanner;

  late TextEditingController sendToController;
  late TextEditingController cryptoAmountController;
  late TextEditingController baseAmountController;
  late TextEditingController noteController;
  late TextEditingController feeController;

  late final SendViewAutoFillData? _data;

  final _addressFocusNode = FocusNode();
  final _noteFocusNode = FocusNode();
  final _cryptoFocus = FocusNode();
  final _baseFocus = FocusNode();

  Decimal? _amountToSend;
  Decimal? _cachedAmountToSend;
  String? _address;

  String? _privateBalanceString;
  String? _publicBalanceString;

  bool _addressToggleFlag = false;

  bool _cryptoAmountChangeLock = false;
  late VoidCallback onCryptoAmountChanged;

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

      _updatePreviewButtonState(_address, _amountToSend);

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

  late Future<String> _calculateFeesFuture;

  Map<int, String> cachedFees = {};
  Map<int, String> cachedFiroPrivateFees = {};
  Map<int, String> cachedFiroPublicFees = {};

  Future<String> calculateFees(int amount) async {
    if (amount <= 0) {
      return "0";
    }

    if (coin == Coin.firo || coin == Coin.firoTestNet) {
      if (ref.read(publicPrivateBalanceStateProvider.state).state ==
          "Private") {
        if (cachedFiroPrivateFees[amount] != null) {
          return cachedFiroPrivateFees[amount]!;
        }
      } else {
        if (cachedFiroPublicFees[amount] != null) {
          return cachedFiroPublicFees[amount]!;
        }
      }
    } else if (cachedFees[amount] != null) {
      return cachedFees[amount]!;
    }

    final manager =
        ref.read(walletsChangeNotifierProvider).getManager(walletId);
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
    if (coin == Coin.monero) {
      MoneroTransactionPriority specialMoneroId;
      switch (ref.read(feeRateTypeStateProvider.state).state) {
        case FeeRateType.fast:
          specialMoneroId = MoneroTransactionPriority.fast;
          break;
        case FeeRateType.average:
          specialMoneroId = MoneroTransactionPriority.regular;
          break;
        case FeeRateType.slow:
          specialMoneroId = MoneroTransactionPriority.slow;
          break;
      }

      fee = await manager.estimateFeeFor(amount, specialMoneroId.raw!);
      cachedFees[amount] = Format.satoshisToAmount(fee, coin: coin)
          .toStringAsFixed(Constants.decimalPlacesForCoin(coin));

      return cachedFees[amount]!;
    } else if (coin == Coin.firo || coin == Coin.firoTestNet) {
      if (ref.read(publicPrivateBalanceStateProvider.state).state ==
          "Private") {
        fee = await manager.estimateFeeFor(amount, feeRate);

        cachedFiroPrivateFees[amount] = Format.satoshisToAmount(fee, coin: coin)
            .toStringAsFixed(Constants.decimalPlacesForCoin(coin));

        return cachedFiroPrivateFees[amount]!;
      } else {
        fee = await (manager.wallet as FiroWallet)
            .estimateFeeForPublic(amount, feeRate);

        cachedFiroPublicFees[amount] = Format.satoshisToAmount(fee, coin: coin)
            .toStringAsFixed(Constants.decimalPlacesForCoin(coin));

        return cachedFiroPublicFees[amount]!;
      }
    } else {
      fee = await manager.estimateFeeFor(amount, feeRate);
      cachedFees[amount] = Format.satoshisToAmount(fee, coin: coin)
          .toStringAsFixed(Constants.decimalPlacesForCoin(coin));

      return cachedFees[amount]!;
    }
  }

  Future<String?> _firoBalanceFuture(
      ChangeNotifierProvider<Manager> provider, String locale) async {
    final wallet = ref.read(provider).wallet as FiroWallet?;

    if (wallet != null) {
      Decimal? balance;
      if (ref.read(publicPrivateBalanceStateProvider.state).state ==
          "Private") {
        balance = await wallet.availablePrivateBalance();
      } else {
        balance = await wallet.availablePublicBalance();
      }

      return Format.localizedStringAsFixed(
          value: balance, locale: locale, decimalPlaces: 8);
    }

    return null;
  }

  @override
  void initState() {
    ref.refresh(feeSheetSessionCacheProvider);

    _calculateFeesFuture = calculateFees(0);
    _data = widget.autoFillData;
    walletId = widget.walletId;
    coin = widget.coin;
    clipboard = widget.clipboard;
    scanner = widget.barcodeScanner;

    sendToController = TextEditingController();
    cryptoAmountController = TextEditingController();
    baseAmountController = TextEditingController();
    noteController = TextEditingController();
    feeController = TextEditingController();

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

    if (coin != Coin.epicCash) {
      _cryptoFocus.addListener(() {
        if (!_cryptoFocus.hasFocus && !_baseFocus.hasFocus) {
          if (_amountToSend == null) {
            setState(() {
              _calculateFeesFuture = calculateFees(0);
            });
          } else {
            setState(() {
              _calculateFeesFuture = calculateFees(
                  Format.decimalAmountToSatoshis(_amountToSend!, coin));
            });
          }
        }
      });

      _baseFocus.addListener(() {
        if (!_cryptoFocus.hasFocus && !_baseFocus.hasFocus) {
          if (_amountToSend == null) {
            setState(() {
              _calculateFeesFuture = calculateFees(0);
            });
          } else {
            setState(() {
              _calculateFeesFuture = calculateFees(
                  Format.decimalAmountToSatoshis(_amountToSend!, coin));
            });
          }
        }
      });
    }
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
    final provider = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManagerProvider(walletId)));
    final String locale = ref.watch(
        localeServiceChangeNotifierProvider.select((value) => value.locale));

    if (coin == Coin.firo || coin == Coin.firoTestNet) {
      ref.listen(publicPrivateBalanceStateProvider, (previous, next) {
        if (_amountToSend == null) {
          setState(() {
            _calculateFeesFuture = calculateFees(0);
          });
        } else {
          setState(() {
            _calculateFeesFuture = calculateFees(
                Format.decimalAmountToSatoshis(_amountToSend!, coin));
          });
        }
      });
    }

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () async {
              if (FocusScope.of(context).hasFocus) {
                FocusScope.of(context).unfocus();
                await Future<void>.delayed(const Duration(milliseconds: 50));
              }
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            "Send ${coin.ticker}",
            style: STextStyles.navBarTitle(context),
          ),
        ),
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
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .popupBG,
                              borderRadius: BorderRadius.circular(
                                Constants.size.circularBorderRadius,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    Assets.svg.iconFor(coin: coin),
                                    width: 22,
                                    height: 22,
                                  ),
                                  const SizedBox(
                                    width: 6,
                                  ),
                                  if (coin != Coin.firo &&
                                      coin != Coin.firoTestNet)
                                    Expanded(
                                      child: Text(
                                        ref.watch(provider.select(
                                            (value) => value.walletName)),
                                        style: STextStyles.titleBold12(context),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  if (coin == Coin.firo ||
                                      coin == Coin.firoTestNet)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ref.watch(provider.select(
                                              (value) => value.walletName)),
                                          style:
                                              STextStyles.titleBold12(context)
                                                  .copyWith(fontSize: 14),
                                        ),
                                        // const SizedBox(
                                        //   height: 2,
                                        // ),
                                        Text(
                                          "${ref.watch(publicPrivateBalanceStateProvider.state).state} balance",
                                          style: STextStyles.label(context)
                                              .copyWith(fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  if (coin != Coin.firo &&
                                      coin != Coin.firoTestNet)
                                    const SizedBox(
                                      width: 10,
                                    ),
                                  if (coin == Coin.firo ||
                                      coin == Coin.firoTestNet)
                                    const Spacer(),
                                  FutureBuilder(
                                    // TODO redo this widget now that its not actually a future
                                    future: (coin != Coin.firo &&
                                            coin != Coin.firoTestNet)
                                        ? Future(() => ref.watch(
                                            provider.select((value) =>
                                                value.balance.getSpendable())))
                                        : ref.watch(publicPrivateBalanceStateProvider.state).state ==
                                                "Private"
                                            ? Future(() => (ref
                                                    .watch(provider)
                                                    .wallet as FiroWallet)
                                                .availablePrivateBalance())
                                            : Future(() => (ref
                                                    .watch(provider)
                                                    .wallet as FiroWallet)
                                                .availablePublicBalance()),
                                    builder:
                                        (_, AsyncSnapshot<Decimal> snapshot) {
                                      if (snapshot.connectionState ==
                                              ConnectionState.done &&
                                          snapshot.hasData) {
                                        _cachedBalance = snapshot.data!;
                                      }

                                      if (_cachedBalance != null) {
                                        return GestureDetector(
                                          onTap: () {
                                            cryptoAmountController.text =
                                                _cachedBalance!.toStringAsFixed(
                                                    Constants
                                                        .decimalPlacesForCoin(
                                                            coin));
                                          },
                                          child: Container(
                                            color: Colors.transparent,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  "${Format.localizedStringAsFixed(
                                                    value: _cachedBalance!,
                                                    locale: locale,
                                                    decimalPlaces: 8,
                                                  )} ${coin.ticker}",
                                                  style:
                                                      STextStyles.titleBold12(
                                                              context)
                                                          .copyWith(
                                                    fontSize: 10,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                ),
                                                Text(
                                                  "${Format.localizedStringAsFixed(
                                                    value: _cachedBalance! *
                                                        ref.watch(priceAnd24hChangeNotifierProvider
                                                            .select((value) =>
                                                                value
                                                                    .getPrice(
                                                                        coin)
                                                                    .item1)),
                                                    locale: locale,
                                                    decimalPlaces: 2,
                                                  )} ${ref.watch(prefsChangeNotifierProvider.select((value) => value.currency))}",
                                                  style: STextStyles
                                                          .titleBold12_400(
                                                              context)
                                                      .copyWith(
                                                    fontSize: 8,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                )
                                              ],
                                            ),
                                          ),
                                        );
                                      } else {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            AnimatedText(
                                              stringsToLoopThrough: const [
                                                "Loading balance   ",
                                                "Loading balance.  ",
                                                "Loading balance.. ",
                                                "Loading balance...",
                                              ],
                                              style: STextStyles.itemSubtitle(
                                                      context)
                                                  .copyWith(
                                                fontSize: 10,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 2,
                                            ),
                                            AnimatedText(
                                              stringsToLoopThrough: const [
                                                "Loading balance   ",
                                                "Loading balance.  ",
                                                "Loading balance.. ",
                                                "Loading balance...",
                                              ],
                                              style: STextStyles.itemSubtitle(
                                                      context)
                                                  .copyWith(
                                                fontSize: 8,
                                              ),
                                            )
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Text(
                            "Send to",
                            style: STextStyles.smallMed12(context),
                            textAlign: TextAlign.left,
                          ),
                          const SizedBox(
                            height: 8,
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
                                _updatePreviewButtonState(
                                    _address, _amountToSend);

                                setState(() {
                                  _addressToggleFlag = newValue.isNotEmpty;
                                });
                              },
                              focusNode: _addressFocusNode,
                              style: STextStyles.field(context),
                              decoration: standardInputDecoration(
                                "Enter ${coin.ticker} address",
                                _addressFocusNode,
                                context,
                              ).copyWith(
                                contentPadding: const EdgeInsets.only(
                                  left: 16,
                                  top: 6,
                                  bottom: 8,
                                  right: 5,
                                ),
                                suffixIcon: Padding(
                                  padding: sendToController.text.isEmpty
                                      ? const EdgeInsets.only(right: 8)
                                      : const EdgeInsets.only(right: 0),
                                  child: UnconstrainedBox(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
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
                                                onTap: () async {
                                                  final ClipboardData? data =
                                                      await clipboard.getData(
                                                          Clipboard.kTextPlain);
                                                  if (data?.text != null &&
                                                      data!.text!.isNotEmpty) {
                                                    String content =
                                                        data.text!.trim();
                                                    if (content
                                                        .contains("\n")) {
                                                      content =
                                                          content.substring(
                                                              0,
                                                              content.indexOf(
                                                                  "\n"));
                                                    }

                                                    sendToController.text =
                                                        content;
                                                    _address = content;

                                                    _updatePreviewButtonState(
                                                        _address,
                                                        _amountToSend);
                                                    setState(() {
                                                      _addressToggleFlag =
                                                          sendToController
                                                              .text.isNotEmpty;
                                                    });
                                                  }
                                                },
                                                child: sendToController
                                                        .text.isEmpty
                                                    ? const ClipboardIcon()
                                                    : const XIcon(),
                                              ),
                                        if (sendToController.text.isEmpty)
                                          TextFieldIconButton(
                                            key: const Key(
                                                "sendViewAddressBookButtonKey"),
                                            onTap: () {
                                              Navigator.of(context).pushNamed(
                                                AddressBookView.routeName,
                                                arguments: widget.coin,
                                              );
                                            },
                                            child: const AddressBookIcon(),
                                          ),
                                        if (sendToController.text.isEmpty)
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

                                                  // autofill notes field
                                                  if (results["message"] !=
                                                      null) {
                                                    noteController.text =
                                                        results["message"]!;
                                                  } else if (results["label"] !=
                                                      null) {
                                                    noteController.text =
                                                        results["label"]!;
                                                  }

                                                  // autofill amount field
                                                  if (results["amount"] !=
                                                      null) {
                                                    final amount =
                                                        Decimal.parse(
                                                            results["amount"]!);
                                                    cryptoAmountController
                                                            .text =
                                                        Format
                                                            .localizedStringAsFixed(
                                                      value: amount,
                                                      locale: ref
                                                          .read(
                                                              localeServiceChangeNotifierProvider)
                                                          .locale,
                                                      decimalPlaces: Constants
                                                          .decimalPlacesForCoin(
                                                              coin),
                                                    );
                                                    amount.toString();
                                                    _amountToSend = amount;
                                                  }

                                                  _updatePreviewButtonState(
                                                      _address, _amountToSend);
                                                  setState(() {
                                                    _addressToggleFlag =
                                                        sendToController
                                                            .text.isNotEmpty;
                                                  });

                                                  // now check for non standard encoded basic address
                                                } else if (ref
                                                    .read(
                                                        walletsChangeNotifierProvider)
                                                    .getManager(walletId)
                                                    .validateAddress(
                                                        qrResult.rawContent)) {
                                                  _address =
                                                      qrResult.rawContent;
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
                                          )
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
                                ref
                                    .read(walletsChangeNotifierProvider)
                                    .getManager(walletId),
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
                          if (coin == Coin.firo)
                            const SizedBox(
                              height: 12,
                            ),
                          if (coin == Coin.firo)
                            Text(
                              "Send from",
                              style: STextStyles.smallMed12(context),
                              textAlign: TextAlign.left,
                            ),
                          if (coin == Coin.firo)
                            const SizedBox(
                              height: 8,
                            ),
                          if (coin == Coin.firo)
                            Stack(
                              children: [
                                TextField(
                                  autocorrect: Util.isDesktop ? false : true,
                                  enableSuggestions:
                                      Util.isDesktop ? false : true,
                                  readOnly: true,
                                  textInputAction: TextInputAction.none,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: RawMaterialButton(
                                    splashColor: Theme.of(context)
                                        .extension<StackColors>()!
                                        .highlight,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        Constants.size.circularBorderRadius,
                                      ),
                                    ),
                                    onPressed: () {
                                      showModalBottomSheet<dynamic>(
                                        backgroundColor: Colors.transparent,
                                        context: context,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(20),
                                          ),
                                        ),
                                        builder: (_) =>
                                            FiroBalanceSelectionSheet(
                                          walletId: walletId,
                                        ),
                                      );
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              "${ref.watch(publicPrivateBalanceStateProvider.state).state} balance",
                                              style: STextStyles.itemSubtitle12(
                                                  context),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            FutureBuilder(
                                              future: _firoBalanceFuture(
                                                  provider, locale),
                                              builder: (context,
                                                  AsyncSnapshot<String?>
                                                      snapshot) {
                                                if (snapshot.connectionState ==
                                                        ConnectionState.done &&
                                                    snapshot.hasData) {
                                                  if (ref
                                                          .read(
                                                              publicPrivateBalanceStateProvider
                                                                  .state)
                                                          .state ==
                                                      "Private") {
                                                    _privateBalanceString =
                                                        snapshot.data!;
                                                  } else {
                                                    _publicBalanceString =
                                                        snapshot.data!;
                                                  }
                                                }
                                                if (ref
                                                            .read(
                                                                publicPrivateBalanceStateProvider
                                                                    .state)
                                                            .state ==
                                                        "Private" &&
                                                    _privateBalanceString !=
                                                        null) {
                                                  return Text(
                                                    "$_privateBalanceString ${coin.ticker}",
                                                    style: STextStyles
                                                        .itemSubtitle(context),
                                                  );
                                                } else if (ref
                                                            .read(
                                                                publicPrivateBalanceStateProvider
                                                                    .state)
                                                            .state ==
                                                        "Public" &&
                                                    _publicBalanceString !=
                                                        null) {
                                                  return Text(
                                                    "$_publicBalanceString ${coin.ticker}",
                                                    style: STextStyles
                                                        .itemSubtitle(context),
                                                  );
                                                } else {
                                                  return AnimatedText(
                                                    stringsToLoopThrough: const [
                                                      "Loading balance",
                                                      "Loading balance.",
                                                      "Loading balance..",
                                                      "Loading balance...",
                                                    ],
                                                    style: STextStyles
                                                        .itemSubtitle(context),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                        SvgPicture.asset(
                                          Assets.svg.chevronDown,
                                          width: 8,
                                          height: 4,
                                          color: Theme.of(context)
                                              .extension<StackColors>()!
                                              .textSubtitle2,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          const SizedBox(
                            height: 12,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Amount",
                                style: STextStyles.smallMed12(context),
                                textAlign: TextAlign.left,
                              ),
                              BlueTextButton(
                                text: "Send all ${coin.ticker}",
                                onTap: () async {
                                  if (coin == Coin.firo ||
                                      coin == Coin.firoTestNet) {
                                    final firoWallet =
                                        ref.read(provider).wallet as FiroWallet;
                                    if (ref
                                            .read(
                                                publicPrivateBalanceStateProvider
                                                    .state)
                                            .state ==
                                        "Private") {
                                      cryptoAmountController.text =
                                          (await firoWallet
                                                  .availablePrivateBalance())
                                              .toStringAsFixed(Constants
                                                  .decimalPlacesForCoin(coin));
                                    } else {
                                      cryptoAmountController.text =
                                          (await firoWallet
                                                  .availablePublicBalance())
                                              .toStringAsFixed(Constants
                                                  .decimalPlacesForCoin(coin));
                                    }
                                  } else {
                                    cryptoAmountController.text = (ref
                                            .read(provider)
                                            .balance
                                            .getSpendable())
                                        .toStringAsFixed(
                                            Constants.decimalPlacesForCoin(
                                                coin));
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          TextField(
                            autocorrect: Util.isDesktop ? false : true,
                            enableSuggestions: Util.isDesktop ? false : true,
                            style: STextStyles.smallMed14(context).copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textDark,
                            ),
                            key:
                                const Key("amountInputFieldCryptoTextFieldKey"),
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
                              TextInputFormatter.withFunction((oldValue,
                                      newValue) =>
                                  RegExp(r'^([0-9]*[,.]?[0-9]{0,8}|[,.][0-9]{0,8})$')
                                          .hasMatch(newValue.text)
                                      ? newValue
                                      : oldValue),
                            ],
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.only(
                                top: 12,
                                right: 12,
                              ),
                              hintText: "0",
                              hintStyle:
                                  STextStyles.fieldLabel(context).copyWith(
                                fontSize: 14,
                              ),
                              prefixIcon: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    coin.ticker,
                                    style: STextStyles.smallMed14(context)
                                        .copyWith(
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
                              height: 8,
                            ),
                          if (Prefs.instance.externalCalls)
                            TextField(
                              autocorrect: Util.isDesktop ? false : true,
                              enableSuggestions: Util.isDesktop ? false : true,
                              style: STextStyles.smallMed14(context).copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textDark,
                              ),
                              key:
                                  const Key("amountInputFieldFiatTextFieldKey"),
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
                                  final baseAmount =
                                      baseAmountString.contains(",")
                                          ? Decimal.parse(baseAmountString
                                              .replaceFirst(",", "."))
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
                                                Constants.decimalPlacesForCoin(
                                                    coin));
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
                                        .read(
                                            localeServiceChangeNotifierProvider)
                                        .locale,
                                    decimalPlaces:
                                        Constants.decimalPlacesForCoin(coin),
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
                                    _address, _amountToSend);
                              },
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.only(
                                  top: 12,
                                  right: 12,
                                ),
                                hintText: "0",
                                hintStyle:
                                    STextStyles.fieldLabel(context).copyWith(
                                  fontSize: 14,
                                ),
                                prefixIcon: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      ref.watch(prefsChangeNotifierProvider
                                          .select((value) => value.currency)),
                                      style: STextStyles.smallMed14(context)
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .accentColorDark),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(
                            height: 12,
                          ),
                          Text(
                            "Note (optional)",
                            style: STextStyles.smallMed12(context),
                            textAlign: TextAlign.left,
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              Constants.size.circularBorderRadius,
                            ),
                            child: TextField(
                              autocorrect: Util.isDesktop ? false : true,
                              enableSuggestions: Util.isDesktop ? false : true,
                              controller: noteController,
                              focusNode: _noteFocusNode,
                              style: STextStyles.field(context),
                              onChanged: (_) => setState(() {}),
                              decoration: standardInputDecoration(
                                "Type something...",
                                _noteFocusNode,
                                context,
                              ).copyWith(
                                suffixIcon: noteController.text.isNotEmpty
                                    ? Padding(
                                        padding:
                                            const EdgeInsets.only(right: 0),
                                        child: UnconstrainedBox(
                                          child: Row(
                                            children: [
                                              TextFieldIconButton(
                                                child: const XIcon(),
                                                onTap: () async {
                                                  setState(() {
                                                    noteController.text = "";
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          if (coin != Coin.epicCash)
                            Text(
                              "Transaction fee (estimated)",
                              style: STextStyles.smallMed12(context),
                              textAlign: TextAlign.left,
                            ),
                          if (coin != Coin.epicCash)
                            const SizedBox(
                              height: 8,
                            ),
                          if (coin != Coin.epicCash)
                            Stack(
                              children: [
                                TextField(
                                  autocorrect: Util.isDesktop ? false : true,
                                  enableSuggestions:
                                      Util.isDesktop ? false : true,
                                  controller: feeController,
                                  readOnly: true,
                                  textInputAction: TextInputAction.none,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: RawMaterialButton(
                                    splashColor: Theme.of(context)
                                        .extension<StackColors>()!
                                        .highlight,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        Constants.size.circularBorderRadius,
                                      ),
                                    ),
                                    onPressed: (coin == Coin.firo ||
                                                coin == Coin.firoTestNet) &&
                                            ref
                                                    .watch(
                                                        publicPrivateBalanceStateProvider
                                                            .state)
                                                    .state ==
                                                "Private"
                                        ? null
                                        : () {
                                            showModalBottomSheet<dynamic>(
                                              backgroundColor:
                                                  Colors.transparent,
                                              context: context,
                                              shape:
                                                  const RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                  top: Radius.circular(20),
                                                ),
                                              ),
                                              builder: (_) =>
                                                  TransactionFeeSelectionSheet(
                                                walletId: walletId,
                                                amount: Decimal.tryParse(
                                                        cryptoAmountController
                                                            .text) ??
                                                    Decimal.zero,
                                                updateChosen: (String fee) {
                                                  setState(() {
                                                    _calculateFeesFuture =
                                                        Future(() => fee);
                                                  });
                                                },
                                              ),
                                            );
                                          },
                                    child: ((coin == Coin.firo ||
                                                coin == Coin.firoTestNet) &&
                                            ref
                                                    .watch(
                                                        publicPrivateBalanceStateProvider
                                                            .state)
                                                    .state ==
                                                "Private")
                                        ? Row(
                                            children: [
                                              FutureBuilder(
                                                future: _calculateFeesFuture,
                                                builder: (context, snapshot) {
                                                  if (snapshot.connectionState ==
                                                          ConnectionState
                                                              .done &&
                                                      snapshot.hasData) {
                                                    return Text(
                                                      "~${snapshot.data! as String} ${coin.ticker}",
                                                      style: STextStyles
                                                          .itemSubtitle(
                                                              context),
                                                    );
                                                  } else {
                                                    return AnimatedText(
                                                      stringsToLoopThrough: const [
                                                        "Calculating",
                                                        "Calculating.",
                                                        "Calculating..",
                                                        "Calculating...",
                                                      ],
                                                      style: STextStyles
                                                          .itemSubtitle(
                                                              context),
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    ref
                                                        .watch(
                                                            feeRateTypeStateProvider
                                                                .state)
                                                        .state
                                                        .prettyName,
                                                    style: STextStyles
                                                        .itemSubtitle12(
                                                            context),
                                                  ),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  FutureBuilder(
                                                    future:
                                                        _calculateFeesFuture,
                                                    builder:
                                                        (context, snapshot) {
                                                      if (snapshot.connectionState ==
                                                              ConnectionState
                                                                  .done &&
                                                          snapshot.hasData) {
                                                        return Text(
                                                          "~${snapshot.data! as String} ${coin.ticker}",
                                                          style: STextStyles
                                                              .itemSubtitle(
                                                                  context),
                                                        );
                                                      } else {
                                                        return AnimatedText(
                                                          stringsToLoopThrough: const [
                                                            "Calculating",
                                                            "Calculating.",
                                                            "Calculating..",
                                                            "Calculating...",
                                                          ],
                                                          style: STextStyles
                                                              .itemSubtitle(
                                                                  context),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                              SvgPicture.asset(
                                                Assets.svg.chevronDown,
                                                width: 8,
                                                height: 4,
                                                color: Theme.of(context)
                                                    .extension<StackColors>()!
                                                    .textSubtitle2,
                                              ),
                                            ],
                                          ),
                                  ),
                                )
                              ],
                            ),
                          const Spacer(),
                          const SizedBox(
                            height: 12,
                          ),
                          TextButton(
                            onPressed: ref
                                    .watch(previewTxButtonStateProvider.state)
                                    .state
                                ? () async {
                                    // wait for keyboard to disappear
                                    FocusScope.of(context).unfocus();
                                    await Future<void>.delayed(
                                      const Duration(milliseconds: 100),
                                    );
                                    final manager = ref
                                        .read(walletsChangeNotifierProvider)
                                        .getManager(walletId);

                                    // // TODO: remove the need for this!!
                                    // final bool isOwnAddress =
                                    //     await manager.isOwnAddress(_address!);
                                    // if (isOwnAddress && coin != Coin.dogecoinTestNet) {
                                    //   await showDialog<dynamic>(
                                    //     context: context,
                                    //     useSafeArea: false,
                                    //     barrierDismissible: true,
                                    //     builder: (context) {
                                    //       return StackDialog(
                                    //         title: "Transaction failed",
                                    //         message:
                                    //             "Sending to self is currently disabled",
                                    //         rightButton: TextButton(
                                    //           style: Theme.of(context)
                                    //               .extension<StackColors>()!
                                    //               .getSecondaryEnabledButtonColor(
                                    //                   context),
                                    //           child: Text(
                                    //             "Ok",
                                    //             style: STextStyles.button(
                                    //                     context)
                                    //                 .copyWith(
                                    //                     color: Theme.of(context)
                                    //                         .extension<
                                    //                             StackColors>()!
                                    //                         .accentColorDark),
                                    //           ),
                                    //           onPressed: () {
                                    //             Navigator.of(context).pop();
                                    //           },
                                    //         ),
                                    //       );
                                    //     },
                                    //   );
                                    //   return;
                                    // }

                                    final amount =
                                        Format.decimalAmountToSatoshis(
                                            _amountToSend!, coin);
                                    int availableBalance;
                                    if ((coin == Coin.firo ||
                                        coin == Coin.firoTestNet)) {
                                      if (ref
                                              .read(
                                                  publicPrivateBalanceStateProvider
                                                      .state)
                                              .state ==
                                          "Private") {
                                        availableBalance =
                                            Format.decimalAmountToSatoshis(
                                                (manager.wallet as FiroWallet)
                                                    .availablePrivateBalance(),
                                                coin);
                                      } else {
                                        availableBalance =
                                            Format.decimalAmountToSatoshis(
                                                (manager.wallet as FiroWallet)
                                                    .availablePublicBalance(),
                                                coin);
                                      }
                                    } else {
                                      availableBalance =
                                          Format.decimalAmountToSatoshis(
                                              manager.balance.getSpendable(),
                                              coin);
                                    }

                                    // confirm send all
                                    if (amount == availableBalance) {
                                      final bool? shouldSendAll =
                                          await showDialog<bool>(
                                        context: context,
                                        useSafeArea: false,
                                        barrierDismissible: true,
                                        builder: (context) {
                                          return StackDialog(
                                            title: "Confirm send all",
                                            message:
                                                "You are about to send your entire balance. Would you like to continue?",
                                            leftButton: TextButton(
                                              style: Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .getSecondaryEnabledButtonStyle(
                                                      context),
                                              child: Text(
                                                "Cancel",
                                                style: STextStyles.button(
                                                        context)
                                                    .copyWith(
                                                        color: Theme.of(context)
                                                            .extension<
                                                                StackColors>()!
                                                            .accentColorDark),
                                              ),
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop(false);
                                              },
                                            ),
                                            rightButton: TextButton(
                                              style: Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .getPrimaryEnabledButtonStyle(
                                                      context),
                                              child: Text(
                                                "Yes",
                                                style:
                                                    STextStyles.button(context),
                                              ),
                                              onPressed: () {
                                                Navigator.of(context).pop(true);
                                              },
                                            ),
                                          );
                                        },
                                      );

                                      if (shouldSendAll == null ||
                                          shouldSendAll == false) {
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
                                          return BuildingTransactionDialog(
                                            onCancel: () {
                                              wasCancelled = true;

                                              Navigator.of(context).pop();
                                            },
                                          );
                                        },
                                      ));

                                      Map<String, dynamic> txData;

                                      if ((coin == Coin.firo ||
                                              coin == Coin.firoTestNet) &&
                                          ref
                                                  .read(
                                                      publicPrivateBalanceStateProvider
                                                          .state)
                                                  .state !=
                                              "Private") {
                                        txData =
                                            await (manager.wallet as FiroWallet)
                                                .prepareSendPublic(
                                          address: _address!,
                                          satoshiAmount: amount,
                                          args: {
                                            "feeRate": ref
                                                .read(feeRateTypeStateProvider)
                                          },
                                        );
                                      } else {
                                        txData = await manager.prepareSend(
                                          address: _address!,
                                          satoshiAmount: amount,
                                          args: {
                                            "feeRate": ref
                                                .read(feeRateTypeStateProvider)
                                          },
                                        );
                                      }

                                      if (!wasCancelled && mounted) {
                                        // pop building dialog
                                        Navigator.of(context).pop();
                                        txData["note"] = noteController.text;
                                        txData["address"] = _address;

                                        unawaited(Navigator.of(context).push(
                                          RouteGenerator.getRoute(
                                            shouldUseMaterialRoute:
                                                RouteGenerator
                                                    .useMaterialPageRoute,
                                            builder: (_) =>
                                                ConfirmTransactionView(
                                              transactionInfo: txData,
                                              walletId: walletId,
                                            ),
                                            settings: const RouteSettings(
                                              name: ConfirmTransactionView
                                                  .routeName,
                                            ),
                                          ),
                                        ));
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        // pop building dialog
                                        Navigator.of(context).pop();

                                        unawaited(showDialog<dynamic>(
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
                                                    .getSecondaryEnabledButtonStyle(
                                                        context),
                                                child: Text(
                                                  "Ok",
                                                  style: STextStyles.button(
                                                          context)
                                                      .copyWith(
                                                          color: Theme.of(
                                                                  context)
                                                              .extension<
                                                                  StackColors>()!
                                                              .accentColorDark),
                                                ),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            );
                                          },
                                        ));
                                      }
                                    }
                                  }
                                : null,
                            style: ref
                                    .watch(previewTxButtonStateProvider.state)
                                    .state
                                ? Theme.of(context)
                                    .extension<StackColors>()!
                                    .getPrimaryEnabledButtonStyle(context)
                                : Theme.of(context)
                                    .extension<StackColors>()!
                                    .getPrimaryDisabledButtonStyle(context),
                            child: Text(
                              "Preview",
                              style: STextStyles.button(context),
                            ),
                          ),
                          const SizedBox(
                            height: 4,
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
