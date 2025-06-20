import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:namecoin/namecoin.dart';

import '../../../models/isar/models/blockchain_data/utxo.dart';
import '../../../providers/global/wallets_provider.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/clipboard_interface.dart';
import '../../../utilities/extensions/extensions.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/text_formatters.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/models/name_op_state.dart';
import '../../../wallets/models/tx_data.dart';
import '../../../wallets/wallet/impl/namecoin_wallet.dart';
import '../../../widgets/desktop/desktop_dialog.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/dialogs/s_dialog.dart';
import '../../../widgets/stack_dialog.dart';
import '../../send_view/sub_widgets/building_transaction_dialog.dart';
import '../confirm_name_transaction_view.dart';

class UpdateOptionWidget extends ConsumerStatefulWidget {
  const UpdateOptionWidget({
    super.key,
    required this.walletId,
    required this.utxo,
    this.clipboard = const ClipboardWrapper(),
  });

  final String walletId;
  final UTXO utxo;

  final ClipboardInterface clipboard;

  @override
  ConsumerState<UpdateOptionWidget> createState() => _BuyDomainWidgetState();
}

class _BuyDomainWidgetState extends ConsumerState<UpdateOptionWidget> {
  final _controller = TextEditingController();

  late final bool wasJson;
  late final String _currentValue;

  String _getNewValue() {
    final value = _controller.text;
    try {
      final json = jsonDecode(value);
      final minified = jsonEncode(json);
      return minified;
    } catch (_) {}
    return value;
  }

  int _countLength() {
    try {
      final json = jsonDecode(_controller.text);
      final minified = jsonEncode(json);
      return minified.toUint8ListFromUtf8.lengthInBytes;
    } catch (_) {}

    return _controller.text.toUint8ListFromUtf8.lengthInBytes;
  }

  bool _previewLock = false;
  Future<void> _previewUpdate() async {
    if (_previewLock) return;
    _previewLock = true;
    try {
      final newValue = _getNewValue();
      if (newValue == _currentValue) {
        throw Exception("Value was not changed!");
      }

      // wait for keyboard to disappear
      FocusScope.of(context).unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final wallet =
          ref.read(pWallets).getWallet(widget.walletId) as NamecoinWallet;

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

      final _address = await wallet.getCurrentReceivingAddress();

      final opName = wallet.getOpNameDataFrom(widget.utxo)!;

      final time = Future<dynamic>.delayed(const Duration(milliseconds: 2500));

      final nameScriptHex = scriptNameUpdate(opName.fullname, newValue);

      final txDataFuture = wallet.prepareNameSend(
        txData: TxData(
          feeRateType: kNameTxDefaultFeeRate, // TODO: make configurable?
          recipients: [
            TxRecipient(
              address: _address!.value,
              isChange: false,
              amount: Amount(
                rawValue: BigInt.from(kNameAmountSats),
                fractionDigits: wallet.cryptoCurrency.fractionDigits,
              ),
            ),
          ],
          note: "Update ${opName.constructedName} (${opName.fullname})",
          opNameState: NameOpState(
            name: opName.fullname,
            saltHex: "",
            commitment: "",
            value: newValue,
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
        "_preview update name failed",
        error: e,
        stackTrace: s,
      );

      String? err;
      if (e.toString().contains("Contains invalid characters")) {
        err = "Contains invalid characters";
      }

      if (mounted) {
        await showDialog<void>(
          context: context,
          builder:
              (_) => StackOkDialog(
                title: "Update failed",
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

  @override
  void initState() {
    super.initState();
    final wallet =
        ref.read(pWallets).getWallet(widget.walletId) as NamecoinWallet;

    _currentValue = wallet.getOpNameDataFrom(widget.utxo)!.value;

    // see if json, if so format nicely
    try {
      final json = jsonDecode(_currentValue);
      _controller.text = const JsonEncoder.withIndent("  ").convert(json);
      wasJson = true;
    } catch (_) {
      _controller.text = _currentValue;
      wasJson = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          Util.isDesktop
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.stretch,
      children: [
        Text("Edit value", style: STextStyles.label(context)),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          maxLines: null,
          autocorrect: false,
          enableSuggestions: false,
          style: const TextStyle(fontFamily: "monospace"),
          onChanged: (_) {
            setState(() {});
          },
          inputFormatters: [
            Utf8ByteLengthLimitingTextInputFormatter(
              valueMaxLength,
              tryMinifyJson: true,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Builder(
              builder: (context) {
                final length = _countLength();
                return Text(
                  "$length/$valueMaxLength",
                  style: STextStyles.w500_10(context).copyWith(
                    color:
                        Theme.of(
                          context,
                        ).extension<StackColors>()!.textSubtitle2,
                  ),
                );
              },
            ),
          ],
        ),
        SizedBox(height: Util.isDesktop ? 32 : 16),
        if (!Util.isDesktop) const Spacer(),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: "Cancel",
                buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
                onPressed:
                    Navigator.of(context, rootNavigator: Util.isDesktop).pop,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                label: "Update",
                enabled: _controller.text.isNotEmpty,
                buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
                onPressed: _previewUpdate,
              ),
            ),
          ],
        ),
        if (!Util.isDesktop) const SizedBox(height: 16),
      ],
    );
  }
}
