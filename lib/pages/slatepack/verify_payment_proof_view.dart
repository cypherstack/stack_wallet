import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/slatepack_models.dart';
import '../../providers/global/wallets_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/amount/amount_formatter.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../wallets/wallet/wallet_mixin_interfaces/slatepack_interface.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/detail_item.dart';
import '../../widgets/rounded_container.dart';
import '../../widgets/rounded_white_container.dart';
import 'slatepack_import_flow.dart';
import 'slatepack_input_field.dart';

/// Opens the payment proof check: a page on mobile, a dialog on desktop.
Future<void> showVerifyPaymentProof(BuildContext context, String walletId) {
  final view = VerifyPaymentProofView(walletId: walletId);
  if (Util.isDesktop) {
    return showDialog<void>(
      context: context,
      builder: (_) =>
          DesktopDialog(maxWidth: 700, maxHeight: double.infinity, child: view),
    );
  }
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => view,
      settings: const RouteSettings(name: VerifyPaymentProofView.routeName),
    ),
  );
}

/// Checks a payment proof through the wallet's node.
class VerifyPaymentProofView extends ConsumerStatefulWidget {
  const VerifyPaymentProofView({super.key, required this.walletId});

  static const String routeName = "/verifyPaymentProof";

  final String walletId;

  @override
  ConsumerState<VerifyPaymentProofView> createState() =>
      _VerifyPaymentProofViewState();
}

class _VerifyPaymentProofViewState
    extends ConsumerState<VerifyPaymentProofView> {
  late final SlatepackInterface _wallet;
  final _controller = TextEditingController();
  PaymentProofCheck? _check;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _wallet =
        ref.read(pWallets).getWallet(widget.walletId) as SlatepackInterface;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _check = null;
    });
    try {
      final check = await SlatepackImportFlow.withLoading(
        context,
        "Checking payment proof...",
        () => _wallet.verifyPaymentProof(_controller.text),
        errorTitle: "Payment proof not verified",
      );
      if (mounted) setState(() => _check = check);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _result(BuildContext context, PaymentProofCheck check) {
    final isDesktop = Util.isDesktop;
    final colors = Theme.of(context).extension<StackColors>()!;
    final formatter = ref.watch(pAmountFormatter(_wallet.cryptoCurrency));
    final rows = <(String, String)>[
      ("Amount", formatter.format(check.amount)),
      ("Kernel excess", check.kernelExcess),
      ("Sender address", check.senderAddress),
      ("Recipient address", check.recipientAddress),
      ("This wallet sent it", check.isSender ? "Yes" : "No"),
      ("This wallet received it", check.isRecipient ? "Yes" : "No"),
    ];
    return Column(
      key: const Key("paymentProofResult"),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RoundedContainer(
          color: colors.snackBarBackSuccess,
          child: Text(
            "Signatures valid. Kernel presence as reported by your node.",
            style: STextStyles.label(context)
                .copyWith(color: colors.snackBarTextSuccess),
          ),
        ),
        const SizedBox(height: 12),
        RoundedWhiteContainer(
          padding: EdgeInsets.zero,
          borderColor: isDesktop ? colors.backgroundAppBar : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < rows.length; i++) ...[
                if (i > 0) const DetailDivider(),
                DetailItem(title: rows[i].$1, detail: rows[i].$2),
              ],
            ],
          ),
        ),
        if (!check.isSender && !check.isRecipient) ...[
          const SizedBox(height: 12),
          Text(
            "The proof is valid but neither address belongs to this wallet.",
            style: STextStyles.label(context),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final colors = Theme.of(context).extension<StackColors>()!;
    final canVerify = !_busy && _controller.text.trim().isNotEmpty;

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "A payment proof shows that a recipient's address signed for an "
          "amount. The check looks up the transaction kernel through your "
          "node.",
          style: STextStyles.label(context),
        ),
        const SizedBox(height: 16),
        SlatepackInputField(
          controller: _controller,
          hint: "Payment proof (JSON)",
          onChanged: (_) => setState(() => _check = null),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          key: const Key("verifyPaymentProofButton"),
          label: "Verify",
          buttonHeight: isDesktop ? ButtonHeight.l : null,
          enabled: canVerify,
          onPressed: canVerify ? _verify : null,
        ),
        if (_check != null) ...[
          const SizedBox(height: 24),
          _result(context, _check!),
        ],
      ],
    );

    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) => Background(
        child: Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            backgroundColor: colors.background,
            leading: AppBarBackButton(
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              "Verify payment proof",
              style: STextStyles.navBarTitle(context),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
      child: ConditionalParent(
        condition: isDesktop,
        builder: (child) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    "Verify payment proof",
                    style: STextStyles.desktopH3(context),
                  ),
                ),
                const DesktopDialogCloseButton(),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 32, right: 32, bottom: 32),
                child: child,
              ),
            ),
          ],
        ),
        child: body,
      ),
    );
  }
}
