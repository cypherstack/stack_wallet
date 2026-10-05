import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/providers.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/address_utils.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/amount/amount_field_relocalization.dart';
import '../../../utilities/amount/amount_formatter.dart';
import '../../../utilities/amount/amount_input_formatter.dart';
import '../../../utilities/amount/amount_unit.dart';
import '../../../utilities/barcode_scanner_interface.dart';
import '../../../utilities/constants.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/crypto_currency/crypto_currency.dart';
import '../../../widgets/custom_buttons/blue_text_button.dart';
import '../../../widgets/desktop/qr_code_scanner_dialog.dart';
import '../../../widgets/icon_widgets/clipboard_icon.dart';
import '../../../widgets/icon_widgets/qrcode_icon.dart';
import '../../../widgets/icon_widgets/x_icon.dart';
import '../../../widgets/rounded_container.dart';
import '../../../widgets/stack_text_field.dart';
import '../../../widgets/textfield_icon_button.dart';

// final _pPrice = Provider.family<Decimal, Coin>((ref, coin) {
//   return ref.watch(
//     priceAnd24hChangeNotifierProvider
//         .select((value) => value.getPrice(coin).item1),
//   );
// });

/// A recipient entered on a send screen. [label] is a payment request's
/// name for [address].
typedef RecipientData = ({String address, Amount? amount, String? label});

/// A recipient form: the sending wallet and the form's index on its screen.
typedef RecipientId = ({String walletId, int index});

final pRecipient = StateProvider.family<RecipientData?, RecipientId>(
  (ref, id) => null,
);

class Recipient extends ConsumerStatefulWidget {
  const Recipient({
    super.key,
    required this.walletId,
    required this.index,
    required this.displayNumber,
    required this.coin,
    this.remove,
    this.onChanged,
    required this.addAnotherRecipientTapped,
    required this.sendAllTapped,
    this.onMultiRecipientUri,
  });

  final String walletId;
  final int index;
  final int displayNumber;
  final CryptoCurrency coin;

  final VoidCallback? remove;
  final VoidCallback? onChanged;
  final VoidCallback addAnotherRecipientTapped;
  final String Function() sendAllTapped;

  /// Called with a scanned or pasted payment request for several recipients,
  /// which are rejected if this is null.
  final void Function(PaymentUriData paymentData)? onMultiRecipientUri;

  @override
  ConsumerState<Recipient> createState() => _RecipientState();
}

class _RecipientState extends ConsumerState<Recipient> {
  late final TextEditingController addressController, amountController;
  late final FocusNode addressFocusNode, amountFocusNode;

  bool _addressIsEmpty = true;
  final bool _cryptoAmountChangeLock = false;

  bool get isSingle => widget.remove == null;

  RecipientId get _id => (walletId: widget.walletId, index: widget.index);

  void _updateRecipientData({String? label}) {
    final address = addressController.text;
    final amount = ref
        .read(pAmountFormatter(widget.coin))
        .tryParseEditable(amountController.text);
    final previous = ref.read(pRecipient(_id));

    ref.read(pRecipient(_id).notifier).state = (
      address: address,
      amount: amount,
      // A payment request's name only applies to the address it gave.
      label: label ?? (previous?.address == address ? previous?.label : null),
    );
    widget.onChanged?.call();
  }

  /// Fills in the address, and any amount and name, from scanned, pasted, or
  /// typed [input], which may be a payment request.
  void _applyAddressInput(String input) {
    final paymentData = AddressUtils.parsePaymentUri(
      input,
      logging: Logging.instance,
      allowMultipleRecipients: widget.onMultiRecipientUri != null,
    );

    if (paymentData != null &&
        paymentData.coin?.uriScheme == widget.coin.uriScheme) {
      if (paymentData.isMultiRecipient) {
        // Keep this recipient as it was, and let the screen offer to replace
        // every recipient with the request's.
        addressController.text = ref.read(pRecipient(_id))?.address ?? "";
        setState(() {
          _addressIsEmpty = addressController.text.isEmpty;
        });
        widget.onMultiRecipientUri!(paymentData);
        return;
      }

      addressController.text = paymentData.address.trim();

      if (paymentData.amount != null) {
        final amount = Amount.tryParseCanonicalAmount(
          paymentData.amount!,
          fractionDigits: widget.coin.fractionDigits,
          truncateOverprecision: true,
        );
        if (amount != null) {
          amountController.text = ref
              .read(pAmountFormatter(widget.coin))
              .formatEditable(amount);
        } else {
          amountController.clear();
        }
      }

      setState(() {
        _addressIsEmpty = addressController.text.isEmpty;
      });
      _updateRecipientData(label: paymentData.label);
    } else {
      if (addressController.text != input) {
        addressController.text = input;
      }

      setState(() {
        _addressIsEmpty = addressController.text.isEmpty;
      });
      _updateRecipientData();
    }
  }

  void _cryptoAmountChanged() async {
    if (!_cryptoAmountChangeLock) {
      Amount? cryptoAmount = ref
          .read(pAmountFormatter(widget.coin))
          .tryParseEditable(amountController.text);
      if (cryptoAmount != null) {
        if (ref.read(pRecipient(_id))?.amount != null &&
            ref.read(pRecipient(_id))?.amount == cryptoAmount) {
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

  void _onQrTapped() async {
    try {
      if (FocusScope.of(context).hasFocus) {
        FocusScope.of(context).unfocus();
        await Future<void>.delayed(const Duration(milliseconds: 75));
      }

      if (Util.isDesktop) {
        if (!mounted) return;
        final qrCodeData = await showDialog<String>(
          context: context,
          builder: (context) => const QrCodeScannerDialog(),
        );
        if (qrCodeData == null || !mounted) return;

        _applyAddressInput(qrCodeData.trim());
        return;
      }

      final qrResult = await ref.read(pBarcodeScanner).scan(context: context);

      Logging.instance.d("qrResult content: ${qrResult.rawContent}");

      if (qrResult.rawContent == null || !mounted) return;

      _applyAddressInput(qrResult.rawContent!.trim());
    } on PlatformException catch (e, s) {
      if (mounted) {
        try {
          await checkCamPermDeniedMobileAndOpenAppSettings(
            context,
            logging: Logging.instance,
          );
        } catch (e, s) {
          Logging.instance.e(
            "Failed to check cam permissions",
            error: e,
            stackTrace: s,
          );
        }
      } else {
        Logging.instance.e(
          "Failed to get camera permissions while "
          "trying to scan qr code in SendView: $e\n$s",
          error: e,
          stackTrace: s,
        );
      }
    }
  }

  @override
  void initState() {
    addressController = TextEditingController();
    amountController = TextEditingController();
    // baseController = TextEditingController();

    final amount = ref.read(pRecipient(_id))?.amount;
    if (amount != null) {
      amountController.text = ref
          .read(pAmountFormatter(widget.coin))
          .formatEditable(amount);
    }
    addressController.text = ref.read(pRecipient(_id))?.address ?? "";

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
      localeServiceChangeNotifierProvider.select((value) => value.locale),
    );
    listenForAmountRelocalization(ref.listen, controllers: [amountController]);
    // Keep the amount, rather than the number typed, when the unit changes.
    ref.listen<AmountFormatter>(pAmountFormatter(widget.coin), (
      previous,
      next,
    ) {
      final amount = ref.read(pRecipient(_id))?.amount;
      if (previous?.unit != next.unit && amount != null) {
        amountController.text = next.formatEditable(amount);
      }
    });

    final label = ref.watch(pRecipient(_id).select((e) => e?.label));
    final address = addressController.text.trim();

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
              Flexible(
                child: Text(
                  isSingle
                      ? "Send to"
                      : label ?? "Recipient ${widget.displayNumber}",
                  style: STextStyles.smallMed12(context),
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CustomTextButton(
                text: isSingle ? "Add another recipient" : "Remove",
                onTap: isSingle
                    ? widget.addAnotherRecipientTapped
                    : widget.remove,
              ),
            ],
          ),
          const SizedBox(height: 8),
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
              onChanged: (newValue) {
                final previous = ref.read(pRecipient(_id))?.address ?? "";
                // More than one character at once was pasted, and may be a
                // payment request.
                if ((newValue.length - previous.length).abs() > 1) {
                  _applyAddressInput(newValue.trim());
                  return;
                }
                _updateRecipientData();
                setState(() {
                  _addressIsEmpty = addressController.text.isEmpty;
                });
              },
              decoration:
                  standardInputDecoration(
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
                                    semanticsLabel: "Clear Button. Clears The Address Field Input.",
                                    key: const Key(
                                      "sendViewClearAddressFieldButtonKey",
                                    ),
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
                                    semanticsLabel: "Paste Button. Pastes From Clipboard To Address Field Input.",
                                    key: const Key(
                                      "sendViewPasteAddressFieldButtonKey",
                                    ),
                                    onTap: () async {
                                      final ClipboardData? data = await ref
                                          .read(pClipboard)
                                          .getData(Clipboard.kTextPlain);
                                      if (data?.text != null &&
                                          data!.text!.isNotEmpty) {
                                        String content = data.text!.trim();
                                        if (content.contains("\n")) {
                                          content = content.substring(
                                            0,
                                            content.indexOf("\n"),
                                          );
                                        }

                                        _applyAddressInput(content.trim());
                                      }
                                    },
                                    child: _addressIsEmpty
                                        ? const ClipboardIcon()
                                        : const XIcon(),
                                  ),
                            if (_addressIsEmpty)
                              TextFieldIconButton(
                                semanticsLabel:
                                    "Scan QR Button. "
                                    "Opens Camera For Scanning QR Code.",
                                key: const Key("sendViewScanQrButtonKey"),
                                onTap: _onQrTapped,
                                child: const QrCodeIcon(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ),
          ),
          if (address.isNotEmpty && !widget.coin.validateAddress(address))
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Text(
                "Invalid address",
                style: STextStyles.label(context).copyWith(
                  color: Theme.of(context).extension<StackColors>()!.textError,
                ),
              ),
            ),
          SizedBox(height: isSingle ? 12 : 8),
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
          if (isSingle) const SizedBox(height: 8),
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
                controller: amountController,
                decimals: widget.coin.fractionDigits,
                unit: ref.watch(pAmountUnit(widget.coin)),
                locale: locale,
              ),
            ],
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.only(top: 12, right: 12),
              hintText: "0",
              hintStyle: STextStyles.fieldLabel(context).copyWith(fontSize: 14),
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
                          .accentColorDark,
                    ),
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
