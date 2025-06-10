import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:namecoin/namecoin.dart';

import '../../../models/isar/models/blockchain_data/utxo.dart';
import '../../../providers/providers.dart';
import '../../../utilities/address_utils.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/barcode_scanner_interface.dart';
import '../../../utilities/clipboard_interface.dart';
import '../../../utilities/constants.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/isar/providers/wallet_info_provider.dart';
import '../../../wallets/models/name_op_state.dart';
import '../../../wallets/models/tx_data.dart';
import '../../../wallets/wallet/impl/namecoin_wallet.dart';
import '../../../widgets/conditional_parent.dart';
import '../../../widgets/desktop/desktop_dialog.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/dialogs/s_dialog.dart';
import '../../../widgets/icon_widgets/addressbook_icon.dart';
import '../../../widgets/icon_widgets/clipboard_icon.dart';
import '../../../widgets/icon_widgets/qrcode_icon.dart';
import '../../../widgets/icon_widgets/x_icon.dart';
import '../../../widgets/stack_dialog.dart';
import '../../../widgets/stack_text_field.dart';
import '../../../widgets/textfield_icon_button.dart';
import '../../address_book_views/address_book_view.dart';
import '../../send_view/sub_widgets/building_transaction_dialog.dart';
import '../confirm_name_transaction_view.dart';

class TransferOptionWidget extends ConsumerStatefulWidget {
  const TransferOptionWidget({
    super.key,
    required this.walletId,
    required this.utxo,
    this.clipboard = const ClipboardWrapper(),
  });

  final String walletId;
  final UTXO utxo;

  final ClipboardInterface clipboard;

  @override
  ConsumerState<TransferOptionWidget> createState() =>
      _TransferOptionWidgetState();
}

class _TransferOptionWidgetState extends ConsumerState<TransferOptionWidget> {
  late final String walletId;
  late final ClipboardInterface clipboard;

  late final TextEditingController _addressController;
  late final FocusNode _addressFocusNode;

  String? _address;

  bool _previewLock = false;
  Future<void> _preview() async {
    if (_previewLock) return;
    _previewLock = true;

    // wait for keyboard to disappear
    FocusScope.of(context).unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    try {
      final wallet = ref.read(pWallets).getWallet(walletId) as NamecoinWallet;

      bool wasCancelled = false;

      if (mounted) {
        if (Util.isDesktop) {
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
                      coin: wallet.info.coin,
                      isSpark: false,
                      onCancel: () {
                        wasCancelled = true;
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                    ),
                  ),
                );
              },
            ),
          );
        } else {
          unawaited(
            showDialog<void>(
              context: context,
              useSafeArea: false,
              barrierDismissible: false,
              builder: (context) {
                return BuildingTransactionDialog(
                  coin: wallet.info.coin,
                  isSpark: false,
                  onCancel: () {
                    wasCancelled = true;
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          );
        }
      }

      final opName = wallet.getOpNameDataFrom(widget.utxo)!;

      final time = Future<dynamic>.delayed(const Duration(milliseconds: 2500));

      final nameScriptHex = scriptNameUpdate(opName.fullname, opName.value);

      final txDataFuture = wallet.prepareNameSend(
        txData: TxData(
          feeRateType: kNameTxDefaultFeeRate, // TODO: make configurable?
          recipients: [
            (
              address: _address!,
              isChange: false,
              amount: Amount(
                rawValue: BigInt.from(kNameAmountSats),
                fractionDigits: wallet.cryptoCurrency.fractionDigits,
              ),
            ),
          ],
          note: "Transfer ${opName.constructedName}",
          opNameState: NameOpState(
            name: opName.fullname,
            saltHex: "",
            commitment: "",
            value: opName.value,
            nameScriptHex: nameScriptHex,
            type: OpName.nameUpdate,
            output: widget.utxo,
            outputPosition: -1, //currently unknown, updated later
          ),
        ),
      );

      final results = await Future.wait([txDataFuture, time]);

      final txData = results.first as TxData;

      if (!wasCancelled && mounted) {
        // pop building dialog
        Navigator.of(context).pop();

        if (mounted) {
          if (Util.isDesktop) {
            await showDialog<void>(
              context: context,
              builder:
                  (context) => SDialog(
                    child: SizedBox(
                      width: 580,
                      child: ConfirmNameTransactionView(
                        txData: txData,
                        walletId: widget.walletId,
                      ),
                    ),
                  ),
            );
          } else {
            await Navigator.of(context).pushNamed(
              ConfirmNameTransactionView.routeName,
              arguments: (txData, widget.walletId),
            );
          }
        }
      }
    } catch (e, s) {
      Logging.instance.e(
        "_preview transfer name failed",
        error: e,
        stackTrace: s,
      );

      if (mounted) {
        String err = e.toString();
        if (err.startsWith("Exception: ")) {
          err = err.replaceFirst("Exception: ", "");
        }

        await showDialog<void>(
          context: context,
          builder:
              (_) => StackOkDialog(
                title: "Error",
                message: err,
                desktopPopRootNavigator: Util.isDesktop,
                maxWidth: Util.isDesktop ? 600 : null,
              ),
        );
      }
    } finally {
      _previewLock = false;
    }
  }

  bool _enableButton = false;

  void _setValidAddressProviders(String? address) {
    _enableButton = ref
        .read(pWallets)
        .getWallet(walletId)
        .cryptoCurrency
        .validateAddress(address ?? "");
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _scanQr() async {
    try {
      if (FocusScope.of(context).hasFocus) {
        FocusScope.of(context).unfocus();
        await Future<void>.delayed(const Duration(milliseconds: 75));
      }

      final qrResult = await ref.read(pBarcodeScanner).scan(context: context);
      final coin = ref.read(pWalletCoin(walletId));

      Logging.instance.d("qrResult content: ${qrResult.rawContent}");

      final paymentData = AddressUtils.parsePaymentUri(
        qrResult.rawContent,
        logging: Logging.instance,
      );

      if (paymentData != null &&
          paymentData.coin?.uriScheme == coin.uriScheme) {
        // auto fill address
        _address = paymentData.address.trim();
        _addressController.text = _address!;

        _setValidAddressProviders(_address);

        // now check for non standard encoded basic address
      } else {
        _address = qrResult.rawContent.split("\n").first.trim();
        _addressController.text = _address ?? "";

        _setValidAddressProviders(_address);
      }
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
          "Failed to get camera permissions while trying to scan qr code in"
          " $runtimeType",
          error: e,
          stackTrace: s,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    walletId = widget.walletId;
    clipboard = widget.clipboard;

    _addressController = TextEditingController();
    _addressFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _addressFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          Util.isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
          child: TextField(
            key: const Key("nameTransferViewAddressFieldKey"),
            controller: _addressController,
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
              _address = newValue.trim();
              _setValidAddressProviders(_address);
            },
            focusNode: _addressFocusNode,
            style: STextStyles.field(context),
            decoration: standardInputDecoration(
              "Enter ${ref.watch(pWalletCoin(walletId)).ticker} address",
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
                padding:
                    _addressController.text.isEmpty
                        ? const EdgeInsets.only(right: 8)
                        : const EdgeInsets.only(right: 0),
                child: UnconstrainedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _addressController.text.isNotEmpty
                          ? TextFieldIconButton(
                            semanticsLabel:
                                "Clear Button. Clears The Address Field Input.",
                            key: const Key(
                              "nameTransferClearAddressFieldButtonKey",
                            ),
                            onTap: () {
                              _addressController.text = "";
                              _address = "";
                              _setValidAddressProviders(_address);
                              setState(() {});
                            },
                            child: const XIcon(),
                          )
                          : TextFieldIconButton(
                            semanticsLabel:
                                "Paste Button. Pastes From Clipboard To Address Field Input.",
                            key: const Key(
                              "nameTransferPasteAddressFieldButtonKey",
                            ),
                            onTap: () async {
                              final ClipboardData? data = await clipboard
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

                                _addressController.text = content.trim();
                                _address = content.trim();

                                _setValidAddressProviders(_address);
                              }
                            },
                            child:
                                _addressController.text.isEmpty
                                    ? const ClipboardIcon()
                                    : const XIcon(),
                          ),
                      if (_addressController.text.isEmpty)
                        TextFieldIconButton(
                          semanticsLabel:
                              "Address Book Button. Opens Address Book For Address Field.",
                          key: const Key("nameTransferAddressBookButtonKey"),
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              AddressBookView.routeName,
                              arguments: ref.read(pWalletCoin(walletId)),
                            );
                          },
                          child: const AddressBookIcon(),
                        ),
                      if (_addressController.text.isEmpty)
                        TextFieldIconButton(
                          semanticsLabel:
                              "Scan QR Button. Opens Camera For Scanning QR Code.",
                          key: const Key("nameTransferScanQrButtonKey"),
                          onTap: _scanQr,
                          child: const QrCodeIcon(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: Util.isDesktop ? 42 : 16),
        if (!Util.isDesktop) const Spacer(),
        ConditionalParent(
          condition: Util.isDesktop,
          builder:
              (child) => Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: "Cancel",
                      buttonHeight: ButtonHeight.l,
                      onPressed:
                          Navigator.of(
                            context,
                            rootNavigator: Util.isDesktop,
                          ).pop,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: child),
                ],
              ),
          child: PrimaryButton(
            label: "Transfer",
            enabled: _enableButton,
            // width: Util.isDesktop ? 160 : double.infinity,
            buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
            onPressed: _preview,
          ),
        ),
        if (!Util.isDesktop) const SizedBox(height: 16),
      ],
    );
  }
}
