import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/global/wallets_provider.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/if_not_already.dart';
import '../../../utilities/show_loading.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/wallet/impl/firo_wallet.dart';
import '../../../widgets/conditional_parent.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../widgets/stack_dialog.dart';
import '../../../widgets/textfields/adaptive_text_field.dart';

class UnbanMasternodeForm extends ConsumerStatefulWidget {
  const UnbanMasternodeForm({
    super.key,
    required this.walletId,
    this.node,
    required this.onSuccess,
  });

  final String walletId;
  final MasternodeInfo? node;
  final void Function(String txid) onSuccess;

  @override
  ConsumerState<UnbanMasternodeForm> createState() =>
      _UnbanMasternodeFormState();
}

class _UnbanMasternodeFormState extends ConsumerState<UnbanMasternodeForm> {
  late final TextEditingController _serviceController;
  late final TextEditingController _proTxHashController;
  final _operatorKeyController = TextEditingController();
  final _feeAddressController = TextEditingController();
  late final IfNotAlreadyAsync<void> _submit;
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _proTxHashController = TextEditingController(
      text: widget.node?.proTxHash ?? "",
    );
    _serviceController = TextEditingController(
      text: widget.node == null
          ? ""
          : widget.node!.serviceAddr.contains(":")
          ? "[${widget.node!.serviceAddr}]:${widget.node!.servicePort}"
          : "${widget.node!.serviceAddr}:${widget.node!.servicePort}",
    );
    _submit = IfNotAlreadyAsync<void>(_submitUnban);
    _validate();
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _proTxHashController.dispose();
    _operatorKeyController.dispose();
    _feeAddressController.dispose();
    super.dispose();
  }

  void _validate() {
    if (!mounted) return;
    setState(() {
      _canSubmit =
          RegExp(r'^[0-9a-fA-F]{64}$')
              .hasMatch(_proTxHashController.text.trim()) &&
          _serviceController.text.trim().isNotEmpty &&
          RegExp(r'^[0-9a-fA-F]{64}$')
              .hasMatch(_operatorKeyController.text.trim());
    });
  }

  Future<void> _submitUnban() async {
    final privateKey = _operatorKeyController.text.trim();
    final proTxHash = _proTxHashController.text.trim();
    final service = _serviceController.text.trim();
    final feeAddress = _feeAddressController.text.trim();
    FocusScope.of(context).unfocus();
    _operatorKeyController.clear();

    Exception? error;
    final txid = await showLoading<String>(
      whileFutureAlt: () async {
        final wallet =
            ref.read(pWallets).getWallet(widget.walletId) as FiroWallet;
        return wallet.unbanMasternode(
          proTxHash: proTxHash,
          ipAndPort: service,
          operatorPrivateKey: privateKey,
          feeSourceAddress: feeAddress.isEmpty ? null : feeAddress,
        );
      },
      context: context,
      rootNavigator: Util.isDesktop,
      message: "Signing and submitting the masternode unban transaction...",
      delay: const Duration(seconds: 1),
      onException: (e) => error = e,
    );

    if (!mounted) return;
    if (error != null || txid == null) {
      var message =
          error?.toString().trim() ?? "Could not submit the transaction.";
      const prefix = "Exception:";
      while (message.startsWith(prefix)) {
        message = message.substring(prefix.length).trim();
      }
      await showDialog<void>(
        context: context,
        builder: (context) => StackDialog(
          title: "Masternode unban failed",
          message: message,
          width: Util.isDesktop ? 520 : null,
          rightButton: PrimaryButton(
            label: "OK",
            onPressed: Navigator.of(context).pop,
          ),
        ),
      );
      return;
    }
    widget.onSuccess(txid);
  }

  TextStyle _labelStyle(BuildContext context) => Util.isDesktop
      ? STextStyles.desktopTextExtraExtraSmall(context).copyWith(
          color: Theme.of(context)
              .extension<StackColors>()!
              .textFieldActiveSearchIconRight,
        )
      : STextStyles.smallMed12(context);

  @override
  Widget build(BuildContext context) {
    final stack = Theme.of(context).extension<StackColors>()!;
    final spacing = Util.isDesktop ? 16.0 : 12.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Unban masternode",
                style: Util.isDesktop
                    ? STextStyles.desktopH3(context)
                    : STextStyles.pageTitleH2(context),
              ),
            ),
            if (Util.isDesktop) const DesktopDialogCloseButton(),
          ],
        ),
        SizedBox(height: spacing),
        SelectableText("ProTx hash", style: _labelStyle(context)),
        const SizedBox(height: 6),
        AdaptiveTextField(
          controller: _proTxHashController,
          showPasteClearButton: true,
          maxLines: 1,
          keyboardType: TextInputType.visiblePassword,
          readOnly: widget.node != null,
          onChangedComprehensive: (_) => _validate(),
        ),
        SizedBox(height: spacing),
        SelectableText("Masternode IP:Port", style: _labelStyle(context)),
        const SizedBox(height: 6),
        AdaptiveTextField(
          controller: _serviceController,
          showPasteClearButton: true,
          maxLines: 1,
          onChangedComprehensive: (_) => _validate(),
        ),
        SizedBox(height: spacing),
        SelectableText("Operator BLS private key", style: _labelStyle(context)),
        const SizedBox(height: 6),
        AdaptiveTextField(
          controller: _operatorKeyController,
          showPasteClearButton: true,
          maxLines: 1,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.visiblePassword,
          onChangedComprehensive: (_) => _validate(),
        ),
        const SizedBox(height: 4),
        Text(
          "The key is used on this device to sign the transaction.",
          style: STextStyles.baseXS(context)
              .copyWith(color: stack.textSubtitle1),
        ),
        SizedBox(height: spacing),
        SelectableText(
          "Fee source address (optional)",
          style: _labelStyle(context),
        ),
        const SizedBox(height: 6),
        AdaptiveTextField(
          controller: _feeAddressController,
          showPasteClearButton: true,
          maxLines: 1,
          labelText: "Use any confirmed transparent FIRO in this wallet",
        ),
        SizedBox(height: Util.isDesktop ? 18 : 16),
        Text(
          "This submits a network transaction and uses FIRO from your wallet "
          "for the fee. Make sure the masternode service is running at this "
          "address. You can enter a ProTx hash registered outside Stack.",
          style: STextStyles.baseXS(context)
              .copyWith(color: stack.textSubtitle1),
        ),
        SizedBox(height: Util.isDesktop ? 20 : 16),
        ConditionalParent(
          condition: Util.isDesktop,
          builder: (child) => Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: "Cancel",
                  onPressed: Navigator.of(context).pop,
                  buttonHeight: .l,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: child),
            ],
          ),
          child: PrimaryButton(
            label: "Unban masternode",
            enabled: _canSubmit,
            onPressed: _canSubmit ? () => _submit.execute() : null,
            buttonHeight: Util.isDesktop ? .l : null,
          ),
        ),
        if (!Util.isDesktop) ...[
          const SizedBox(height: 8),
          SecondaryButton(
            label: "Cancel",
            onPressed: Navigator.of(context).pop,
          ),
        ],
      ],
    );
  }
}
