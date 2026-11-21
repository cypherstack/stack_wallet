import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/slatepack_models.dart';
import '../../providers/global/wallets_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/amount/amount_formatter.dart';
import '../../utilities/logger.dart';
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
/// wallet's estimate. Pops true once a payment was made and still stands:
/// the payment slatepack (I2) was shown, the payment failed after the wallet
/// recorded it, or the payment could not be cancelled again.
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
  Amount? _estimatedFee;
  bool _estimateFailed = false;
  bool _busy = false;
  String? _pendingAbandonedPayment;

  Amount get _amount => widget.inspection.amount!;

  @override
  void dispose() {
    final slateId = _pendingAbandonedPayment;
    _pendingAbandonedPayment = null;
    if (slateId != null) {
      unawaited(_cancelAbandonedPayment(slateId));
    }
    super.dispose();
  }

  Future<void> _cancelAbandonedPayment(String slateId) async {
    try {
      final message = await _wallet.cancelPendingTransactionAndPost(slateId);
      if (message.isNotEmpty) {
        Logging.instance.w(
          "Could not cancel an abandoned invoice payment: $message",
        );
      }
    } catch (e, s) {
      Logging.instance.w(
        "Could not cancel an abandoned invoice payment",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _wallet =
        ref.read(pWallets).getWallet(widget.walletId) as SlatepackInterface;
    unawaited(_estimateFee());
  }

  Future<void> _estimateFee() async {
    try {
      final fee = await _wallet.estimateFeeFor(_amount, BigInt.zero);
      if (mounted) setState(() => _estimatedFee = fee);
    } catch (e, s) {
      Logging.instance.w(
        "Could not estimate the fee of an invoice payment",
        error: e,
        stackTrace: s,
      );
      if (mounted) setState(() => _estimateFailed = true);
    }
  }

  void _retryEstimate() {
    setState(() => _estimateFailed = false);
    unawaited(_estimateFee());
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
        if ((!r.success || r.slatepack == null) && r.slateId == null) {
          throw Exception(r.error ?? "Failed to pay the invoice");
        }
        return r;
      },
      errorTitle: "Invoice payment failed",
    );
    if (result == null || !mounted) return;

    if (!result.success || result.slatepack == null) {
      // The payment failed but stays in the wallet, where it can be
      // cancelled. Paying this invoice again from here cannot work.
      await SlatepackImportFlow.showMessage(
        context,
        "Invoice payment failed",
        result.error ?? "Failed to pay the invoice",
      );
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    final estimate = _estimatedFee;
    final actual = result.fee;
    if (estimate != null && actual != null && actual > estimate) {
      _pendingAbandonedPayment = result.slateId;
      final keep = await _confirmHigherFee(estimate, actual);
      if (keep != true) {
        if (!mounted) return;
        final slateId = _pendingAbandonedPayment;
        _pendingAbandonedPayment = null;
        await _cancelPayment(slateId);
        return;
      }
      _pendingAbandonedPayment = null;
      if (!mounted) return;
    }

    await showSlatepackDialog(
      context: context,
      terms: terms,
      result: result,
      supportsEncryption: _wallet.supportsSlatepackEncryption,
    );
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
          label: Util.isDesktop ? "Cancel payment" : "Cancel",
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

  /// Cancels the payment just made. The screen closes either way: when the
  /// cancel fails the payment still exists with its funds locked, and paying
  /// from here again would be a second one.
  Future<void> _cancelPayment(String? slateId) async {
    String? failure;
    if (slateId == null) {
      failure = "Could not cancel automatically.";
    } else {
      final message = await SlatepackImportFlow.withLoading(
        context,
        "Cancelling payment...",
        () async {
          try {
            return await _wallet.cancelPendingTransactionAndPost(slateId);
          } catch (e) {
            return e.toString().replaceFirst("Exception: ", "");
          }
        },
        errorTitle: "Cancel failed",
      );
      if (!mounted) return;
      if (message == null || message.isNotEmpty) {
        failure = message ?? "Could not cancel automatically.";
      }
    }
    await SlatepackImportFlow.showMessage(
      context,
      failure == null ? "Payment cancelled" : "Cancel failed",
      failure == null
          ? "The funds are unlocked. Nothing was handed out."
          : "$failure The funds are still locked. Cancel the payment from "
                "the transaction details.",
    );
    if (mounted) Navigator.of(context).pop(failure != null);
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
        Builder(
          builder: (context) {
            final fee = _estimatedFee;
            final String feeText;
            final String totalText;
            final String remainingText;
            if (_estimateFailed) {
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
            "transaction. Cancelling unlocks them in this wallet, but a "
            "payee who already has your payment "
            "${_wallet.slatepackTerms.noun} can still complete the payment "
            "until the funds are spent in another transaction. Only pay "
            "invoices you expect.",
            style: STextStyles.label(context)
                .copyWith(color: colors.warningForeground),
          ),
        ),
        const SizedBox(height: 24),
        Builder(
          builder: (context) {
            if (_estimateFailed) {
              return SecondaryButton(
                key: const Key("payInvoiceRetryEstimate"),
                label: "Estimate the fee again",
                buttonHeight: isDesktop ? ButtonHeight.l : null,
                onPressed: _retryEstimate,
              );
            }
            final fee = _estimatedFee;
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
