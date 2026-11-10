import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/slatepack_models.dart';
import '../../providers/global/wallets_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/amount/amount_formatter.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../wallets/isar/providers/wallet_info_provider.dart';
import '../../wallets/wallet/wallet_mixin_interfaces/slatepack_interface.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/detail_item.dart';
import '../../widgets/rounded_container.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_dialog.dart';
import 'slatepack_auth.dart';
import 'slatepack_dialog.dart';
import 'slatepack_import_flow.dart';

/// Review of someone else's invoice (I1) before paying it. Modelled on the
/// send confirm screen. The invoice carries no fee, so the fee is the
/// wallet's estimate. Pops true once the payment slatepack (I2) was made.
class PayInvoiceConfirmView extends ConsumerStatefulWidget {
  const PayInvoiceConfirmView({
    super.key,
    required this.walletId,
    required this.invoice,
    required this.inspection,
  });

  static const String routeName = "/payInvoiceConfirm";

  final String walletId;

  /// The armored I1.
  final String invoice;

  /// The I1 as the wallet read it. Its amount is what the user confirms.
  final SlateInspection inspection;

  @override
  ConsumerState<PayInvoiceConfirmView> createState() =>
      _PayInvoiceConfirmViewState();
}

class _PayInvoiceConfirmViewState extends ConsumerState<PayInvoiceConfirmView> {
  late final SlatepackInterface _wallet;
  late final Future<Amount> _feeFuture;
  Amount? _estimatedFee;
  bool _busy = false;

  Amount get _amount => widget.inspection.amount!;

  @override
  void initState() {
    super.initState();
    _wallet =
        ref.read(pWallets).getWallet(widget.walletId) as SlatepackInterface;
    _feeFuture = _wallet.estimateFeeFor(_amount, BigInt.zero).then((fee) {
      _estimatedFee = fee;
      return fee;
    });
  }

  Future<void> _pay() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _payUnlocked();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _payUnlocked() async {
    final unlocked = await authenticateSlatepackSpend(
      context,
      coin: _wallet.cryptoCurrency,
      reason: "Authenticate to pay invoice",
    );
    if (!unlocked || !mounted) return;

    final terms = _wallet.slatepackTerms;
    final result = await SlatepackImportFlow.withLoading(
      context,
      "Paying invoice...",
      () async {
        final r = await _wallet.processInvoice(
          widget.invoice,
          confirmedAmount: _amount,
        );
        if (!r.success || r.slatepack == null) {
          throw Exception(r.error ?? "Failed to pay the invoice");
        }
        return r;
      },
      errorTitle: "Invoice payment failed",
    );
    if (result == null || !mounted) return;
    unawaited(_wallet.refresh());

    final estimate = _estimatedFee;
    final actual = result.fee;
    if (estimate != null && actual != null && actual > estimate) {
      final keep = await _confirmHigherFee(estimate, actual);
      if (!mounted) return;
      if (keep != true) {
        await _cancelPayment(result.slateId);
        return;
      }
    }

    await showSlatepackDialog(context: context, terms: terms, result: result);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<bool?> _confirmHigherFee(Amount estimate, Amount actual) {
    final formatter = ref.read(pAmountFormatter(_wallet.cryptoCurrency));
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StackDialog(
        width: Util.isDesktop ? 500 : null,
        title: "Higher fee",
        message:
            "The payment needs a fee of ${formatter.format(actual)}, more "
            "than the estimate of ${formatter.format(estimate)}. The funds "
            "are locked now. Cancel the payment to unlock them, or continue "
            "and hand out the payment ${_wallet.slatepackTerms.noun}.",
        leftButton: SecondaryButton(
          label: "Cancel payment",
          buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        rightButton: PrimaryButton(
          label: "Continue",
          buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ),
    );
  }

  Future<void> _cancelPayment(String? slateId) async {
    if (slateId == null) return;
    final message = await SlatepackImportFlow.withLoading(
      context,
      "Cancelling payment...",
      () => _wallet.cancelPendingTransactionAndPost(slateId),
      errorTitle: "Cancel failed",
    );
    if (!mounted || message == null) return;
    await SlatepackImportFlow.showMessage(
      context,
      message.isEmpty ? "Payment cancelled" : "Cancel failed",
      message.isEmpty
          ? "The funds are unlocked. Nothing was handed out."
          : "$message Cancel it from the transaction details.",
    );
    if (mounted && message.isEmpty) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final colors = Theme.of(context).extension<StackColors>()!;
    final coin = _wallet.cryptoCurrency;
    final formatter = ref.watch(pAmountFormatter(coin));
    final spendable = ref.watch(pWalletBalance(widget.walletId)).spendable;
    final inspection = widget.inspection;

    final amountStyle = isDesktop
        ? STextStyles.desktopH2(context)
        : STextStyles.pageTitleH1(context);

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RoundedWhiteContainer(
          borderColor: isDesktop ? colors.backgroundAppBar : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("You pay", style: STextStyles.label(context)),
              const SizedBox(height: 4),
              SelectableText(
                formatter.format(_amount),
                key: const Key("payInvoiceAmount"),
                style: amountStyle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<Amount>(
          future: _feeFuture,
          builder: (context, snapshot) {
            final fee = snapshot.data;
            final String feeText;
            final String totalText;
            final String remainingText;
            if (snapshot.hasError) {
              feeText = "Could not estimate";
              totalText = "-";
              remainingText = "-";
            } else if (fee == null) {
              feeText = "Estimating...";
              totalText = "...";
              remainingText = "...";
            } else {
              final total = _amount + fee;
              feeText = formatter.format(fee);
              totalText = formatter.format(total);
              remainingText = total > spendable
                  ? "Not enough funds"
                  : formatter.format(spendable - total);
            }
            final rows = <(String, String)>[
              ("Pay to", inspection.senderAddress ?? "Not given"),
              ("Encrypted", inspection.isEncrypted ? "Yes" : "No"),
              (
                "Expires",
                inspection.ttlCutoffHeight != null
                    ? "At block ${inspection.ttlCutoffHeight}"
                    : "If not finalized within about a day",
              ),
              ("Fee (estimated)", feeText),
              ("Total", totalText),
              ("Remaining balance", remainingText),
              ("Slate ID", inspection.slateId),
            ];
            return RoundedWhiteContainer(
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
            );
          },
        ),
        const SizedBox(height: 16),
        RoundedContainer(
          color: colors.warningBackground,
          child: Text(
            "Paying locks the funds until the payee finalizes the "
            "transaction, or until you cancel it. Only pay invoices you "
            "expect.",
            style: STextStyles.label(context)
                .copyWith(color: colors.warningForeground),
          ),
        ),
        const SizedBox(height: 24),
        FutureBuilder<Amount>(
          future: _feeFuture,
          builder: (context, snapshot) {
            final fee = snapshot.data;
            final canPay = !_busy && fee != null && _amount + fee <= spendable;
            return PrimaryButton(
              key: const Key("payInvoiceButton"),
              label: "Pay invoice",
              buttonHeight: isDesktop ? ButtonHeight.l : null,
              enabled: canPay,
              onPressed: canPay ? _pay : null,
            );
          },
        ),
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
              onPressed: () => Navigator.of(context).pop(false),
            ),
            title: Text("Pay invoice", style: STextStyles.navBarTitle(context)),
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
                    "Pay invoice",
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
