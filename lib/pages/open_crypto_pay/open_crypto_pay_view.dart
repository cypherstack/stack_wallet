import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications/show_flush_bar.dart';
import '../../services/open_crypto_pay/method_support.dart';
import '../../services/open_crypto_pay/models.dart';
import '../../services/open_crypto_pay/open_crypto_pay_api.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/logger.dart';
import '../../utilities/text_styles.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/rounded_white_container.dart';
import 'open_crypto_pay_confirm_view.dart';

/// Shows the payment details from an Open CryptoPay QR code and lets the user
/// choose a payment method/asset that is supported by this wallet.
class OpenCryptoPayView extends ConsumerStatefulWidget {
  const OpenCryptoPayView({
    super.key,
    required this.qrUrl,
    required this.walletId,
    required this.coin,
  });

  static const String routeName = "/openCryptoPayView";

  final String qrUrl;

  /// Only methods/assets this wallet can safely settle are offered.
  final String walletId;
  final CryptoCurrency coin;

  @override
  ConsumerState<OpenCryptoPayView> createState() => _OpenCryptoPayViewState();
}

class _OpenCryptoPayViewState extends ConsumerState<OpenCryptoPayView> {
  OpenCryptoPayPaymentDetails? _details;
  bool _isLoading = true;
  String? _errorMessage;

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
      final details = await OpenCryptoPayApi.instance.getPaymentDetails(
        widget.qrUrl,
      );
      if (mounted) setState(() => _details = details);
    } on OpenCryptoPayNoPendingPaymentException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e, s) {
      Logging.instance.e("OpenCryptoPay fetch failed", error: e, stackTrace: s);
      if (mounted) setState(() => _errorMessage = 'Failed to fetch: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isSupportedOption(
    OpenCryptoPayTransferMethod method,
    OpenCryptoPayAsset asset,
  ) => OpenCryptoPayMethodSupport.isSupportedWalletOption(
    coin: widget.coin,
    method: method,
    asset: asset,
  );

  Future<void> _onSelected(
    OpenCryptoPayTransferMethod method,
    OpenCryptoPayAsset asset,
  ) async {
    final quote = _details?.quote;
    if (quote == null) return;

    if (quote.isExpired) {
      unawaited(
        showFloatingFlushBar(
          type: FlushBarType.warning,
          message: "Quote expired, refreshing...",
          context: context,
        ),
      );
      await _fetch();
      return;
    }

    final result = await Navigator.of(context).push<OpenCryptoPayConfirmResult>(
      MaterialPageRoute<OpenCryptoPayConfirmResult>(
        builder: (_) => OpenCryptoPayConfirmView(
          paymentDetails: _details!,
          selectedMethod: method,
          selectedAsset: asset,
          walletId: widget.walletId,
          coin: widget.coin,
        ),
      ),
    );

    if (result == OpenCryptoPayConfirmResult.quoteExpired && mounted) {
      await _fetch();
    }
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
            "Open CryptoPay",
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

    final details = _details;
    if (details == null) {
      return const Center(child: Text("No payment data"));
    }

    // Flatten into (method, asset) pairs that this wallet can safely settle.
    final options = [
      for (final m in details.availableMethods)
        for (final a in m.assets)
          if (_isSupportedOption(m, a)) (method: m, asset: a),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (details.recipient != null) ...[
            _recipientCard(details.recipient!),
            const SizedBox(height: 16),
          ],
          if (details.requestedAmount != null) ...[
            _amountCard(details),
            const SizedBox(height: 16),
          ],
          Text(
            "Select Payment Method",
            style: STextStyles.pageTitleH2(context),
          ),
          const SizedBox(height: 8),
          if (options.isEmpty)
            RoundedWhiteContainer(
              child: Text(
                "No supported Open CryptoPay option available for "
                "${widget.coin.prettyName}.",
                style: STextStyles.itemSubtitle(context),
              ),
            )
          else
            ...options.map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _methodCard(o.method, o.asset),
              ),
            ),
          if (details.quote != null) ...[
            const SizedBox(height: 8),
            Text(
              "Quote expires: ${details.quote!.expiration.toLocal()}",
              style: STextStyles.label(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _recipientCard(OpenCryptoPayRecipient recipient) {
    return RoundedWhiteContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Recipient", style: STextStyles.itemSubtitle12(context)),
          if (recipient.name != null) ...[
            const SizedBox(height: 4),
            Text(recipient.name!, style: STextStyles.titleBold12(context)),
          ],
          if (recipient.formattedAddress.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              recipient.formattedAddress,
              style: STextStyles.itemSubtitle(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _amountCard(OpenCryptoPayPaymentDetails details) {
    return RoundedWhiteContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Amount Due", style: STextStyles.itemSubtitle12(context)),
          const SizedBox(height: 4),
          Text(
            "${details.requestedAmount!.amount} ${details.requestedAmount!.asset}",
            style: STextStyles.pageTitleH2(context),
          ),
          if (details.displayName != null) ...[
            const SizedBox(height: 4),
            Text(
              details.displayName!,
              style: STextStyles.itemSubtitle(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _methodCard(
    OpenCryptoPayTransferMethod method,
    OpenCryptoPayAsset asset,
  ) {
    return GestureDetector(
      onTap: () => _onSelected(method, asset),
      child: RoundedWhiteContainer(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${asset.amount} ${asset.asset}",
                    style: STextStyles.titleBold12(context),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "via ${method.method}",
                    style: STextStyles.itemSubtitle(context),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(
                context,
              ).extension<StackColors>()!.textFieldDefaultSearchIconLeft,
            ),
          ],
        ),
      ),
    );
  }
}
