import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';

import '../../models/isar/models/ethereum/eth_contract.dart';
import '../../models/send_view_auto_fill_data.dart';
import '../../notifications/show_flush_bar.dart';
import '../../providers/db/main_db_provider.dart';
import '../../providers/providers.dart';
import '../../pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_send.dart';
import '../../pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_token_send.dart';
import '../../services/open_crypto_pay/erc20_token_lookup.dart';
import '../../services/open_crypto_pay/evm_uri.dart';
import '../../services/open_crypto_pay/method_support.dart';
import '../../services/open_crypto_pay/models.dart';
import '../../services/open_crypto_pay/open_crypto_pay_api.dart';
import '../../utilities/address_utils.dart';
import '../../utilities/logger.dart';
import '../../utilities/text_styles.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../../wallets/isar/providers/eth/current_token_wallet_provider.dart';
import '../../wallets/isar/providers/wallet_info_provider.dart';
import '../../wallets/wallet/impl/ethereum_wallet.dart';
import '../../wallets/wallet/impl/sub_wallets/eth_token_wallet.dart';
import '../../wallets/wallet/wallet.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/rounded_white_container.dart';
import 'open_crypto_pay_widgets.dart';
import '../send_view/send_view.dart';
import '../send_view/token_send_view.dart';

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
    this.isDesktop = false,
  });

  final OpenCryptoPayPaymentDetails paymentDetails;
  final OpenCryptoPayTransferMethod selectedMethod;
  final OpenCryptoPayAsset selectedAsset;
  final String walletId;
  final CryptoCurrency coin;
  final bool isDesktop;

  @override
  ConsumerState<OpenCryptoPayConfirmView> createState() =>
      _OpenCryptoPayConfirmViewState();
}

class _OpenCryptoPayConfirmViewState
    extends ConsumerState<OpenCryptoPayConfirmView> {
  OpenCryptoPayTransactionDetails? _txDetails;
  bool _isLoading = true;
  String? _errorMessage;
  late final Decimal? _quotedAmount;

  DateTime? get _expiresAt =>
      _txDetails?.expiryDate ?? widget.paymentDetails.quote?.expiration;

  bool get _isExpired {
    final expiresAt = _expiresAt;
    return expiresAt != null && expiresAt.isBefore(DateTime.now());
  }

  @override
  void initState() {
    super.initState();
    _quotedAmount = Decimal.tryParse(widget.selectedAsset.amount);
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

  ({String? address, Decimal? amount, String? scheme}) _parseTransactionUri(
    String uri,
  ) {
    final evmUri = OpenCryptoPayEvmUri.tryParse(uri);
    if (evmUri != null && !evmUri.isTokenTransfer) {
      return (
        address: evmUri.targetAddress,
        amount: evmUri.isNativeTransfer
            ? evmUri.amount(fractionDigits: widget.coin.fractionDigits)
            : _quotedAmount,
        scheme: evmUri.scheme,
      );
    }

    final parsedUri = Uri.tryParse(uri);
    final data = AddressUtils.parsePaymentUri(uri, logging: Logging.instance);
    var address = data?.address ?? parsedUri?.path;
    if (address != null) {
      if (address.isEmpty) address = null;
    }
    final amount = data?.amount != null
        ? Decimal.tryParse(data!.amount!)
        : _quotedAmount;
    return (
      address: address,
      amount: amount,
      scheme: data?.scheme ?? parsedUri?.scheme,
    );
  }

  EthContract? _enabledErc20Token(String contractAddress) {
    return OpenCryptoPayErc20TokenLookup.enabledToken(
      ref.read(mainDBProvider),
      ref.read(pWalletTokenAddresses(widget.walletId)),
      contractAddress,
    );
  }

  bool _matchesQuotedAmount(Decimal amount) {
    final quotedAmount = _quotedAmount;
    return quotedAmount != null && amount.compareTo(quotedAmount) == 0;
  }

  SendViewAutoFillData _autoFillData({
    required String address,
    required Decimal amount,
    required DateTime expiresAt,
    required String recipient,
    required OpenCryptoPaySubmissionFlow submissionFlow,
    String? tokenContractAddress,
    int? tokenDecimals,
  }) {
    return SendViewAutoFillData(
      address: address,
      contactLabel: recipient,
      amount: amount,
      note: "OpenCryptoPay: $recipient",
      openCryptoPayCommit: OpenCryptoPayCommit(
        callbackUrl: widget.paymentDetails.callback,
        quoteId: widget.paymentDetails.quote!.id,
        paymentId: widget.paymentDetails.quote!.paymentId,
        method: widget.selectedMethod.method,
        asset: widget.selectedAsset.asset,
        expiresAt: expiresAt,
        submissionFlow: submissionFlow,
        minFee: widget.selectedMethod.minFee,
        recipientAddress: address,
        amount: amount,
        tokenContractAddress: tokenContractAddress,
        tokenDecimals: tokenDecimals,
      ),
    );
  }

  Future<EthTokenWallet> _loadTokenWallet(EthContract contract) async {
    final wallet = ref.read(pWallets).getWallet(widget.walletId);
    if (wallet is! EthereumWallet) {
      throw Exception("Ethereum wallet not loaded");
    }

    final old = ref.read(tokenServiceStateProvider);
    final tokenWallet =
        Wallet.loadTokenWallet(ethWallet: wallet, contract: contract)
            as EthTokenWallet;
    await tokenWallet.init();
    unawaited(old?.exit());
    ref.read(tokenServiceStateProvider.state).state = tokenWallet;
    return tokenWallet;
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

    if (_txDetails?.blockchain != null &&
        _txDetails!.blockchain != widget.selectedMethod.method) {
      _warn("Payment details do not match the selected method");
      return;
    }

    final submissionFlow = OpenCryptoPayMethodSupport.submissionFlowFor(
      widget.selectedMethod.method,
    );
    if (submissionFlow == null) {
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

    final evmUri = widget.selectedMethod.method == 'Ethereum'
        ? OpenCryptoPayEvmUri.tryParse(uri)
        : null;
    if (widget.selectedMethod.method == 'Ethereum') {
      if (evmUri == null) {
        _warn("Could not parse Ethereum payment details");
        return;
      }
      if (evmUri.chainId != null && evmUri.chainId != 1) {
        _warn("Payment URI is for a different Ethereum network");
        return;
      }
      if (evmUri.functionName != null && !evmUri.isTokenTransfer) {
        _warn("Unsupported Ethereum payment request");
        return;
      }
      if (evmUri.isTokenTransfer) {
        // Native ETH may omit chainId, but token calls must be explicit mainnet.
        if (evmUri.chainId == null) {
          _warn("Payment URI is for a different Ethereum network");
          return;
        }
        if (widget.selectedAsset.asset.toUpperCase() ==
            widget.coin.ticker.toUpperCase()) {
          _warn("Payment token details are invalid");
          return;
        }
        await _proceedToTokenSend(
          evmUri: evmUri,
          expiresAt: expiresAt,
          recipient: recipient,
          submissionFlow: submissionFlow,
        );
        return;
      }
      if (widget.selectedAsset.asset.toUpperCase() !=
          widget.coin.ticker.toUpperCase()) {
        _warn("Payment token details are invalid");
        return;
      }
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
    if (!_matchesQuotedAmount(parsed.amount!)) {
      _warn("Payment amount does not match the quoted amount");
      return;
    }
    if (parsed.scheme != null &&
        parsed.scheme!.isNotEmpty &&
        parsed.scheme != widget.coin.uriScheme) {
      _warn("Payment URI does not match this wallet");
      return;
    }

    final autoFillData = _autoFillData(
      address: parsed.address!,
      amount: parsed.amount!,
      expiresAt: expiresAt,
      recipient: recipient,
      submissionFlow: submissionFlow,
    );

    if (!mounted) return;
    if (widget.isDesktop) {
      await _showDesktopSendForm(
        DesktopSend(walletId: widget.walletId, autoFillData: autoFillData),
      );
      return;
    }

    await Navigator.of(context).pushNamed(
      SendView.routeName,
      arguments: Tuple3(widget.walletId, widget.coin, autoFillData),
    );
  }

  Future<void> _proceedToTokenSend({
    required OpenCryptoPayEvmUri evmUri,
    required DateTime expiresAt,
    required String recipient,
    required OpenCryptoPaySubmissionFlow submissionFlow,
  }) async {
    final contract = _enabledErc20Token(evmUri.targetAddress);
    if (contract == null) {
      _warn("This token is not enabled in this wallet");
      return;
    }
    if (contract.symbol.toUpperCase() !=
        widget.selectedAsset.asset.toUpperCase()) {
      _warn("Payment token does not match the selected asset");
      return;
    }

    try {
      await _loadTokenWallet(contract);
    } catch (e, s) {
      Logging.instance.e(
        "OpenCryptoPay token wallet load failed",
        error: e,
        stackTrace: s,
      );
      _warn("Could not load token wallet");
      return;
    }

    final amount = evmUri.amount(fractionDigits: contract.decimals);
    if (!_matchesQuotedAmount(amount)) {
      _warn("Payment amount does not match the quoted amount");
      return;
    }

    final recipientAddress = evmUri.recipientAddress;
    if (recipientAddress == null) {
      _warn("Could not parse token recipient address");
      return;
    }

    final autoFillData = _autoFillData(
      address: recipientAddress,
      amount: amount,
      expiresAt: expiresAt,
      recipient: recipient,
      submissionFlow: submissionFlow,
      tokenContractAddress: contract.address,
      tokenDecimals: contract.decimals,
    );

    if (!mounted) return;
    if (widget.isDesktop) {
      await _showDesktopSendForm(
        DesktopTokenSend(walletId: widget.walletId, autoFillData: autoFillData),
      );
      return;
    }

    await Navigator.of(context).pushNamed(
      TokenSendView.routeName,
      arguments: Tuple4(widget.walletId, widget.coin, contract, autoFillData),
    );
  }

  Future<void> _showDesktopSendForm(Widget child) {
    return showOpenCryptoPayDesktopDialog<void>(context: context, child: child);
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
    final body = Padding(
      padding: const EdgeInsets.all(16),
      child: _OpenCryptoPayConfirmBody(
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        paymentDetails: widget.paymentDetails,
        selectedMethod: widget.selectedMethod,
        selectedAsset: widget.selectedAsset,
        txDetails: _txDetails,
        onRetry: () => unawaited(_fetch()),
        onProceed: () => unawaited(_proceedToSend()),
      ),
    );

    return OpenCryptoPayScaffold(
      title: "Confirm Payment",
      isDesktop: widget.isDesktop,
      child: body,
    );
  }
}

class _OpenCryptoPayConfirmBody extends StatelessWidget {
  const _OpenCryptoPayConfirmBody({
    required this.isLoading,
    required this.errorMessage,
    required this.paymentDetails,
    required this.selectedMethod,
    required this.selectedAsset,
    required this.txDetails,
    required this.onRetry,
    required this.onProceed,
  });

  final bool isLoading;
  final String? errorMessage;
  final OpenCryptoPayPaymentDetails paymentDetails;
  final OpenCryptoPayTransferMethod selectedMethod;
  final OpenCryptoPayAsset selectedAsset;
  final OpenCryptoPayTransactionDetails? txDetails;
  final VoidCallback onRetry;
  final VoidCallback onProceed;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: LoadingIndicator());

    final error = errorMessage;
    if (error != null) {
      return OpenCryptoPayErrorView(message: error, onRetry: onRetry);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OpenCryptoPaySummaryCard(
            paymentDetails: paymentDetails,
            selectedMethod: selectedMethod,
            selectedAsset: selectedAsset,
          ),
          if (txDetails?.hint != null) ...[
            const SizedBox(height: 16),
            RoundedWhiteContainer(
              child: Text(txDetails!.hint!, style: STextStyles.label(context)),
            ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(label: "Proceed to Send", onPressed: onProceed),
        ],
      ),
    );
  }
}

class _OpenCryptoPaySummaryCard extends StatelessWidget {
  const _OpenCryptoPaySummaryCard({
    required this.paymentDetails,
    required this.selectedMethod,
    required this.selectedAsset,
  });

  final OpenCryptoPayPaymentDetails paymentDetails;
  final OpenCryptoPayTransferMethod selectedMethod;
  final OpenCryptoPayAsset selectedAsset;

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Payment Summary", style: STextStyles.itemSubtitle12(context)),
          const SizedBox(height: 8),
          if (paymentDetails.recipient?.name != null)
            _OpenCryptoPaySummaryRow(
              label: "To",
              value: paymentDetails.recipient!.name!,
            ),
          if (paymentDetails.requestedAmount != null)
            _OpenCryptoPaySummaryRow(
              label: "Fiat amount",
              value:
                  "${paymentDetails.requestedAmount!.amount} "
                  "${paymentDetails.requestedAmount!.asset}",
            ),
          _OpenCryptoPaySummaryRow(
            label: "Crypto amount",
            value: "${selectedAsset.amount} ${selectedAsset.asset}",
          ),
          _OpenCryptoPaySummaryRow(
            label: "Network",
            value: selectedMethod.method,
          ),
        ],
      ),
    );
  }
}

class _OpenCryptoPaySummaryRow extends StatelessWidget {
  const _OpenCryptoPaySummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: STextStyles.label(context)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: STextStyles.itemSubtitle(context),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
