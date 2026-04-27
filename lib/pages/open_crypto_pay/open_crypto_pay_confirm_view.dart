import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';

import '../../models/send_view_auto_fill_data.dart';
import '../../notifications/show_flush_bar.dart';
import '../../services/open_crypto_pay/method_support.dart';
import '../../services/open_crypto_pay/models.dart';
import '../../services/open_crypto_pay/open_crypto_pay_api.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/address_utils.dart';
import '../../utilities/logger.dart';
import '../../utilities/text_styles.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/rounded_white_container.dart';
import '../send_view/send_view.dart';

enum OpenCryptoPayConfirmResult { quoteExpired }

/// Fetches the transaction details for the selected method/asset, shows a
/// summary, then forwards to the standard [SendView] prefilled with the
/// payment address and amount.
class OpenCryptoPayConfirmView extends ConsumerStatefulWidget {
  const OpenCryptoPayConfirmView({
    super.key,
    required this.paymentDetails,
    required this.selectedMethod,
    required this.selectedAsset,
    required this.walletId,
    required this.coin,
  });

  final OpenCryptoPayPaymentDetails paymentDetails;
  final OpenCryptoPayTransferMethod selectedMethod;
  final OpenCryptoPayAsset selectedAsset;
  final String walletId;
  final CryptoCurrency coin;

  @override
  ConsumerState<OpenCryptoPayConfirmView> createState() =>
      _OpenCryptoPayConfirmViewState();
}

class _OpenCryptoPayConfirmViewState
    extends ConsumerState<OpenCryptoPayConfirmView> {
  OpenCryptoPayTransactionDetails? _txDetails;
  bool _isLoading = true;
  String? _errorMessage;

  DateTime? get _expiresAt =>
      _txDetails?.expiryDate ?? widget.paymentDetails.quote?.expiration;

  bool get _isExpired {
    final expiresAt = _expiresAt;
    return expiresAt != null && expiresAt.isBefore(DateTime.now());
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final quote = widget.paymentDetails.quote;
      if (quote == null) {
        throw Exception("No quote provided by the payment provider");
      }
      _txDetails = await OpenCryptoPayApi.instance.getTransactionDetails(
        callbackUrl: widget.paymentDetails.callback,
        quoteId: quote.id,
        method: widget.selectedMethod.method,
        asset: widget.selectedAsset.asset,
      );
    } catch (e, s) {
      Logging.instance.e(
        "OpenCryptoPay tx fetch failed",
        error: e,
        stackTrace: s,
      );
      _errorMessage = 'Failed to fetch transaction details: $e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Parses address and amount from the transaction URI. For EVM URIs this
  /// also extracts the EIP-681 `@chainId` suffix that [AddressUtils] leaves
  /// attached to the address.
  ({String? address, Decimal? amount, int? chainId, String? scheme})
  _parseTransactionUri(String uri) {
    final parsedUri = Uri.tryParse(uri);
    final data = AddressUtils.parsePaymentUri(uri, logging: Logging.instance);
    var address = data?.address ?? parsedUri?.path;
    int? chainId;
    if (address != null) {
      final at = address.indexOf('@');
      if (at != -1) {
        chainId = int.tryParse(address.substring(at + 1));
        address = address.substring(0, at);
      }
      if (address.isEmpty) address = null;
    }
    final amount = data?.amount != null
        ? Decimal.tryParse(data!.amount!)
        : Decimal.tryParse(widget.selectedAsset.amount);
    return (
      address: address,
      amount: amount,
      chainId: chainId,
      scheme: data?.scheme ?? parsedUri?.scheme,
    );
  }

  Future<void> _proceedToSend() async {
    if (_isExpired) {
      _warn("Quote expired, refreshing...");
      if (mounted) {
        Navigator.of(context).pop(OpenCryptoPayConfirmResult.quoteExpired);
      }
      return;
    }

    final uri = _txDetails?.uri;
    if (uri == null) {
      _warn("No transaction URI provided by the payment provider");
      return;
    }

    final parsed = _parseTransactionUri(uri);
    if (parsed.address == null) {
      _warn("Could not parse payment address");
      return;
    }
    if (parsed.amount == null) {
      _warn("Could not parse payment amount");
      return;
    }
    if (parsed.scheme != null &&
        parsed.scheme!.isNotEmpty &&
        parsed.scheme != widget.coin.uriScheme) {
      _warn("Payment URI does not match this wallet");
      return;
    }
    if (_txDetails?.blockchain != null &&
        _txDetails!.blockchain != widget.selectedMethod.method) {
      _warn("Payment details do not match the selected method");
      return;
    }
    if (widget.selectedMethod.method == 'Ethereum' &&
        parsed.chainId != null &&
        parsed.chainId != 1) {
      _warn("Payment URI is for a different Ethereum network");
      return;
    }

    final submissionFlow = OpenCryptoPayMethodSupport.submissionFlowFor(
      widget.selectedMethod.method,
    );
    if (submissionFlow == null ||
        submissionFlow == OpenCryptoPaySubmissionFlow.external) {
      _warn("This Open CryptoPay method is not supported yet");
      return;
    }

    final expiresAt = _expiresAt;
    if (expiresAt == null) {
      _warn("No quote expiration provided by the payment provider");
      return;
    }

    final recipient =
        widget.paymentDetails.recipient?.name ??
        widget.paymentDetails.displayName ??
        "OpenCryptoPay";

    if (!mounted) return;
    await Navigator.of(context).pushNamed(
      SendView.routeName,
      arguments: Tuple3(
        widget.walletId,
        widget.coin,
        SendViewAutoFillData(
          address: parsed.address!,
          contactLabel: recipient,
          amount: parsed.amount,
          note: "OpenCryptoPay: $recipient",
          openCryptoPayCommit: OpenCryptoPayCommit(
            callbackUrl: widget.paymentDetails.callback,
            quoteId: widget.paymentDetails.quote!.id,
            method: widget.selectedMethod.method,
            asset: widget.selectedAsset.asset,
            expiresAt: expiresAt,
            submissionFlow: submissionFlow,
            minFee: widget.selectedMethod.minFee,
            recipientAddress: parsed.address!,
            amount: parsed.amount!,
          ),
        ),
      ),
    );
  }

  void _warn(String message) {
    unawaited(
      showFloatingFlushBar(
        type: FlushBarType.warning,
        message: message,
        context: context,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          backgroundColor: Theme.of(
            context,
          ).extension<StackColors>()!.backgroundAppBar,
          leading: const AppBarBackButton(),
          title: Text(
            "Confirm Payment",
            style: STextStyles.navBarTitle(context),
          ),
        ),
        body: SafeArea(
          child: Padding(padding: const EdgeInsets.all(16), child: _body()),
        ),
      ),
    );
  }

  Widget _body() {
    if (_isLoading) return const Center(child: LoadingIndicator());

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: STextStyles.itemSubtitle(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: "Retry", onPressed: _fetch),
          ],
        ),
      );
    }

    final details = widget.paymentDetails;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RoundedWhiteContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Payment Summary",
                  style: STextStyles.itemSubtitle12(context),
                ),
                const SizedBox(height: 8),
                if (details.recipient?.name != null)
                  _row("To", details.recipient!.name!),
                if (details.requestedAmount != null)
                  _row(
                    "Fiat amount",
                    "${details.requestedAmount!.amount} "
                        "${details.requestedAmount!.asset}",
                  ),
                _row(
                  "Crypto amount",
                  "${widget.selectedAsset.amount} "
                      "${widget.selectedAsset.asset}",
                ),
                _row("Network", widget.selectedMethod.method),
              ],
            ),
          ),
          if (_txDetails?.hint != null) ...[
            const SizedBox(height: 16),
            RoundedWhiteContainer(
              child: Text(_txDetails!.hint!, style: STextStyles.label(context)),
            ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(label: "Proceed to Send", onPressed: _proceedToSend),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: STextStyles.label(context)),
          ),
          Expanded(
            child: Text(
              value,
              style: STextStyles.itemSubtitle(context),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
