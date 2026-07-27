import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../models/isar/models/ethereum/eth_contract.dart';
import '../../notifications/show_flush_bar.dart';
import '../../providers/db/main_db_provider.dart';
import '../../services/open_crypto_pay/erc20_token_lookup.dart';
import '../../services/open_crypto_pay/method_support.dart';
import '../../services/open_crypto_pay/models.dart';
import '../../services/open_crypto_pay/open_crypto_pay_api.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/logger.dart';
import '../../utilities/text_styles.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../../wallets/isar/providers/wallet_info_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/rounded_white_container.dart';
import 'open_crypto_pay_confirm_view.dart';
import 'open_crypto_pay_widgets.dart';

typedef _OpenCryptoPayOptionSupported =
    bool Function(
      OpenCryptoPayTransferMethod method,
      OpenCryptoPayAsset asset,
      Iterable<EthContract> enabledErc20Tokens,
    );

typedef _OpenCryptoPayOptionSelected =
    void Function(OpenCryptoPayTransferMethod method, OpenCryptoPayAsset asset);

/// Shows the payment details from an Open CryptoPay QR code and lets the user
/// choose a payment method/asset that is supported by this wallet.
class OpenCryptoPayView extends ConsumerStatefulWidget {
  const OpenCryptoPayView({
    super.key,
    required this.qrUrl,
    required this.walletId,
    required this.coin,
    this.isDesktop = false,
  });

  static const String routeName = "/openCryptoPayView";

  final String qrUrl;

  /// Only methods/assets this wallet can safely settle are offered.
  final String walletId;
  final CryptoCurrency coin;
  final bool isDesktop;

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
    Iterable<EthContract> enabledErc20Tokens,
  ) {
    return OpenCryptoPayMethodSupport.isSupportedWalletOption(
      coin: widget.coin,
      method: method,
      asset: asset,
      enabledErc20Symbols: enabledErc20Tokens.map((e) => e.symbol),
    );
  }

  List<EthContract> _enabledErc20Tokens() {
    if (widget.coin is! Ethereum) return const [];
    return OpenCryptoPayErc20TokenLookup.enabledTokens(
      ref.watch(mainDBProvider),
      ref.watch(pWalletTokenAddresses(widget.walletId)),
    );
  }

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

    final confirmView = OpenCryptoPayConfirmView(
      paymentDetails: _details!,
      selectedMethod: method,
      selectedAsset: asset,
      walletId: widget.walletId,
      coin: widget.coin,
      isDesktop: widget.isDesktop,
    );
    final result = widget.isDesktop
        ? await showOpenCryptoPayDesktopDialog<OpenCryptoPayConfirmResult>(
            context: context,
            child: confirmView,
          )
        : await Navigator.of(context).push<OpenCryptoPayConfirmResult>(
            MaterialPageRoute<OpenCryptoPayConfirmResult>(
              builder: (_) => confirmView,
            ),
          );

    if (result == OpenCryptoPayConfirmResult.quoteExpired && mounted) {
      await _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.all(16),
      child: _OpenCryptoPayBody(
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        details: _details,
        coin: widget.coin,
        enabledErc20Tokens: _details == null ? const [] : _enabledErc20Tokens(),
        isSupportedOption: _isSupportedOption,
        onRetry: () => unawaited(_fetch()),
        onSelected: (method, asset) => unawaited(_onSelected(method, asset)),
      ),
    );

    return OpenCryptoPayScaffold(
      title: "Open CryptoPay",
      isDesktop: widget.isDesktop,
      child: body,
    );
  }
}

class _OpenCryptoPayBody extends StatelessWidget {
  const _OpenCryptoPayBody({
    required this.isLoading,
    required this.errorMessage,
    required this.details,
    required this.coin,
    required this.enabledErc20Tokens,
    required this.isSupportedOption,
    required this.onRetry,
    required this.onSelected,
  });

  final bool isLoading;
  final String? errorMessage;
  final OpenCryptoPayPaymentDetails? details;
  final CryptoCurrency coin;
  final List<EthContract> enabledErc20Tokens;
  final _OpenCryptoPayOptionSupported isSupportedOption;
  final VoidCallback onRetry;
  final _OpenCryptoPayOptionSelected onSelected;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: LoadingIndicator());

    final error = errorMessage;
    if (error != null) {
      return OpenCryptoPayErrorView(message: error, onRetry: onRetry);
    }

    final details = this.details;
    if (details == null) {
      return const Center(child: Text("No payment data"));
    }

    final options = [
      for (final m in details.availableMethods)
        for (final a in m.assets)
          if (isSupportedOption(m, a, enabledErc20Tokens))
            (method: m, asset: a),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (details.recipient != null) ...[
            _OpenCryptoPayRecipientCard(recipient: details.recipient!),
            const SizedBox(height: 16),
          ],
          if (details.requestedAmount != null) ...[
            _OpenCryptoPayAmountCard(details: details),
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
                "${coin.prettyName}.",
                style: STextStyles.itemSubtitle(context),
              ),
            )
          else
            ...options.map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _OpenCryptoPayMethodCard(
                  method: o.method,
                  asset: o.asset,
                  onTap: () => onSelected(o.method, o.asset),
                ),
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
}

class _OpenCryptoPayRecipientCard extends StatelessWidget {
  const _OpenCryptoPayRecipientCard({required this.recipient});

  final OpenCryptoPayRecipient recipient;

  @override
  Widget build(BuildContext context) {
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
}

class _OpenCryptoPayAmountCard extends StatelessWidget {
  const _OpenCryptoPayAmountCard({required this.details});

  final OpenCryptoPayPaymentDetails details;

  @override
  Widget build(BuildContext context) {
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
}

class _OpenCryptoPayMethodCard extends StatelessWidget {
  const _OpenCryptoPayMethodCard({
    required this.method,
    required this.asset,
    required this.onTap,
  });

  final OpenCryptoPayTransferMethod method;
  final OpenCryptoPayAsset asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      onPressed: onTap,
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
          SvgPicture.asset(
            Assets.svg.chevronRight,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              Theme.of(
                context,
              ).extension<StackColors>()!.textFieldDefaultSearchIconLeft,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}
