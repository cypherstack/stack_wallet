import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/global/locale_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_input_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/barcode_scanner_interface.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/icon_widgets/clipboard_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/qrcode_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

//TODO: move the following two providers elsewhere
final pClipboard =
    Provider<ClipboardInterface>((ref) => const ClipboardWrapper());
final pBarcodeScanner =
    Provider<BarcodeScannerInterface>((ref) => const BarcodeScannerWrapper());

// final _pPrice = Provider.family<Decimal, Coin>((ref, coin) {
//   return ref.watch(
//     priceAnd24hChangeNotifierProvider
//         .select((value) => value.getPrice(coin).item1),
//   );
// });

final pRecipient =
    StateProvider.family<({String address, Amount? amount})?, int>(
        (ref, index) => null);

class Recipient extends ConsumerStatefulWidget {
  const Recipient({
    super.key,
    required this.index,
    required this.displayNumber,
    required this.coin,
    this.remove,
    this.onChanged,
    required this.addAnotherRecipientTapped,
    required this.sendAllTapped,
  });

  final int index;
  final int displayNumber;
  final Coin coin;

  final VoidCallback? remove;
  final VoidCallback? onChanged;
  final VoidCallback addAnotherRecipientTapped;
  final String Function() sendAllTapped;

  @override
  ConsumerState<Recipient> createState() => _RecipientState();
}

class _RecipientState extends ConsumerState<Recipient> {
  late final TextEditingController addressController, amountController;
  late final FocusNode addressFocusNode, amountFocusNode;

  bool _addressIsEmpty = true;
  final bool _cryptoAmountChangeLock = false;

  bool get isSingle => widget.remove == null;

  void _updateRecipientData() {
    final address = addressController.text;
    final amount =
        ref.read(pAmountFormatter(widget.coin)).tryParse(amountController.text);

    ref.read(pRecipient(widget.index).notifier).state = (
      address: address,
      amount: amount,
    );
    widget.onChanged?.call();
  }

  void _cryptoAmountChanged() async {
    if (!_cryptoAmountChangeLock) {
      Amount? cryptoAmount = ref.read(pAmountFormatter(widget.coin)).tryParse(
            amountController.text,
          );
      if (cryptoAmount != null) {
        if (ref.read(pRecipient(widget.index))?.amount != null &&
            ref.read(pRecipient(widget.index))?.amount == cryptoAmount) {
          return;
        }

        // final price = ref.read(_pPrice(widget.coin));
        //
        // if (price > Decimal.zero) {
        //   baseController.text = (cryptoAmount.decimal * price)
        //       .toAmount(
        //         fractionDigits: 2,
        //       )
        //       .fiatString(
        //         locale: ref.read(localeServiceChangeNotifierProvider).locale,
        //       );
        // }
      } else {
        cryptoAmount = null;
        // baseController.text = "";
      }

      _updateRecipientData();
    }
  }

  @override
  void initState() {
    addressController = TextEditingController();
    amountController = TextEditingController();
    // baseController = TextEditingController();

    final amount = ref.read(pRecipient(widget.index))?.amount;
    if (amount != null) {
      amountController.text = ref
          .read(pAmountFormatter(widget.coin))
          .format(amount, withUnitName: false);
    }
    addressController.text = ref.read(pRecipient(widget.index))?.address ?? "";

    _addressIsEmpty = addressController.text.isEmpty;

    addressFocusNode = FocusNode();
    amountFocusNode = FocusNode();
    // baseFocusNode = FocusNode();

    amountController.addListener(_cryptoAmountChanged);

    super.initState();
  }

  @override
  void dispose() {
    amountController.removeListener(_cryptoAmountChanged);

    addressController.dispose();
    amountController.dispose();
    // baseController.dispose();

    addressFocusNode.dispose();
    amountFocusNode.dispose();
    // baseFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String locale = ref.watch(
      localeServiceChangeNotifierProvider.select(
        (value) => value.locale,
      ),
    );

    return RoundedContainer(
      color: Colors.transparent,
      padding: const EdgeInsets.all(0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSingle ? "Send to" : "Recipient ${widget.displayNumber}",
                style: STextStyles.smallMed12(context),
                textAlign: TextAlign.left,
              ),
              CustomTextButton(
                text: isSingle ? "Add another recipient" : "Remove",
                onTap:
                    isSingle ? widget.addAnotherRecipientTapped : widget.remove,
              ),
            ],
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
              controller: addressController,
              readOnly: false,
              autocorrect: false,
              enableSuggestions: false,
              focusNode: addressFocusNode,
              style: STextStyles.field(context),
              onChanged: (_) {
                _updateRecipientData();
                setState(() {
                  _addressIsEmpty = addressController.text.isEmpty;
                });
              },
              decoration: standardInputDecoration(
                "Enter ${widget.coin.ticker} address",
                addressFocusNode,
                context,
              ).copyWith(
                contentPadding: const EdgeInsets.only(
                  left: 16,
                  top: 6,
                  bottom: 8,
                  right: 5,
                ),
                suffixIcon: Padding(
                  padding: _addressIsEmpty
                      ? const EdgeInsets.only(right: 8)
                      : const EdgeInsets.only(right: 0),
                  child: UnconstrainedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        !_addressIsEmpty
                            ? TextFieldIconButton(
                                semanticsLabel:
                                    "Clear Button. Clears The Address Field Input.",
                                key: const Key(
                                    "sendViewClearAddressFieldButtonKey"),
                                onTap: () {
                                  addressController.text = "";

                                  setState(() {
                                    _addressIsEmpty = true;
                                  });

                                  _updateRecipientData();
                                },
                                child: const XIcon(),
                              )
                            : TextFieldIconButton(
                                semanticsLabel:
                                    "Paste Button. Pastes From Clipboard To Address Field Input.",
                                key: const Key(
                                    "sendViewPasteAddressFieldButtonKey"),
                                onTap: () async {
                                  final ClipboardData? data = await ref
                                      .read(pClipboard)
                                      .getData(Clipboard.kTextPlain);
                                  if (data?.text != null &&
                                      data!.text!.isNotEmpty) {
                                    String content = data.text!.trim();
                                    if (content.contains("\n")) {
                                      content = content.substring(
                                          0, content.indexOf("\n"));
                                    }

                                    addressController.text = content.trim();

                                    setState(() {
                                      _addressIsEmpty =
                                          addressController.text.isEmpty;
                                    });

                                    _updateRecipientData();
                                  }
                                },
                                child: _addressIsEmpty
                                    ? const ClipboardIcon()
                                    : const XIcon(),
                              ),
                        if (_addressIsEmpty)
                          TextFieldIconButton(
                            semanticsLabel: "Scan QR Button. "
                                "Opens Camera For Scanning QR Code.",
                            key: const Key(
                              "sendViewScanQrButtonKey",
                            ),
                            onTap: () async {
                              try {
                                if (FocusScope.of(context).hasFocus) {
                                  FocusScope.of(context).unfocus();
                                  await Future<void>.delayed(
                                    const Duration(
                                      milliseconds: 75,
                                    ),
                                  );
                                }

                                final qrResult =
                                    await ref.read(pBarcodeScanner).scan();

                                Logging.instance.log(
                                  "qrResult content: ${qrResult.rawContent}",
                                  level: LogLevel.Info,
                                );

                                /// TODO: deal with address utils
                                final results =
                                    AddressUtils.parseUri(qrResult.rawContent);

                                Logging.instance.log(
                                  "qrResult parsed: $results",
                                  level: LogLevel.Info,
                                );

                                if (results.isNotEmpty &&
                                    results["scheme"] ==
                                        widget.coin.uriScheme) {
                                  // auto fill address

                                  addressController.text =
                                      (results["address"] ?? "").trim();

                                  // autofill amount field
                                  if (results["amount"] != null) {
                                    final Amount amount =
                                        Decimal.parse(results["amount"]!)
                                            .toAmount(
                                      fractionDigits: widget.coin.decimals,
                                    );
                                    amountController.text = ref
                                        .read(pAmountFormatter(widget.coin))
                                        .format(
                                          amount,
                                          withUnitName: false,
                                        );
                                  }
                                } else {
                                  addressController.text =
                                      qrResult.rawContent.trim();
                                }

                                setState(() {
                                  _addressIsEmpty =
                                      addressController.text.isEmpty;
                                });

                                _updateRecipientData();
                              } on PlatformException catch (e, s) {
                                Logging.instance.log(
                                  "Failed to get camera permissions while "
                                  "trying to scan qr code in SendView: $e\n$s",
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
            height: isSingle ? 12 : 8,
          ),
          if (isSingle)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Amount",
                  style: STextStyles.smallMed12(context),
                  textAlign: TextAlign.left,
                ),
                // disable send all since the frost tx creation logic isn't there (yet?)
                const Spacer(),
                // CustomTextButton(
                //   text: "Send all ${widget.coin.ticker}",
                //   onTap: () {
                //     amountController.text = widget.sendAllTapped();
                //     _cryptoAmountChanged();
                //   },
                // ),
              ],
            ),
          if (isSingle)
            const SizedBox(
              height: 8,
            ),
          TextField(
            autocorrect: false,
            enableSuggestions: false,
            style: STextStyles.smallMed14(context).copyWith(
              color: Theme.of(context).extension<StackColors>()!.textDark,
            ),
            key: const Key("amountInputFieldCryptoTextFieldKey"),
            controller: amountController,
            focusNode: amountFocusNode,
            onChanged: (_) {
              _updateRecipientData();
            },
            keyboardType: Util.isDesktop
                ? null
                : const TextInputType.numberWithOptions(
                    signed: false,
                    decimal: true,
                  ),
            textAlign: TextAlign.right,
            inputFormatters: [
              AmountInputFormatter(
                decimals: widget.coin.decimals,
                unit: ref.watch(pAmountUnit(widget.coin)),
                locale: locale,
              ),
            ],
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.only(
                top: 12,
                right: 12,
              ),
              hintText: "0",
              hintStyle: STextStyles.fieldLabel(context).copyWith(
                fontSize: 14,
              ),
              prefixIcon: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    ref
                        .watch(pAmountUnit(widget.coin))
                        .unitForCoin(widget.coin),
                    style: STextStyles.smallMed14(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorDark),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
