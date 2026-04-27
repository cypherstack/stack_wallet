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
import '../../services/open_crypto_pay/evm_uri.dart';
import '../../services/open_crypto_pay/method_support.dart';
import '../../services/open_crypto_pay/models.dart';
import '../../services/open_crypto_pay/open_crypto_pay_api.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/address_utils.dart';
import '../../utilities/logger.dart';
import '../../utilities/text_styles.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../../wallets/isar/providers/eth/current_token_wallet_provider.dart';
import '../../wallets/isar/providers/wallet_info_provider.dart';
import '../../wallets/wallet/impl/ethereum_wallet.dart';
import '../../wallets/wallet/impl/sub_wallets/eth_token_wallet.dart';
import '../../wallets/wallet/wallet.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/rounded_white_container.dart';
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
    final evmUri = OpenCryptoPayEvmUri.tryParse(uri);
    if (evmUri != null && !evmUri.isTokenTransfer) {
      return (
        address: evmUri.targetAddress,
        amount: evmUri.isNativeTransfer
            ? evmUri.amount(fractionDigits: widget.coin.fractionDigits)
            : Decimal.tryParse(widget.selectedAsset.amount),
        chainId: evmUri.chainId,
        scheme: evmUri.scheme,
      );
    }

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

  EthContract? _enabledErc20Token(String contractAddress) {
    final normalized = contractAddress.toLowerCase();
    final mainDB = ref.read(mainDBProvider);
    for (final address in ref.read(pWalletTokenAddresses(widget.walletId))) {
      final contract = mainDB.getEthContractSync(address);
      if (contract == null || contract.type != EthContractType.erc20) {
        continue;
      }
      if (contract.address.toLowerCase() == normalized) {
        return contract;
      }
    }
    return null;
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
        if (evmUri.chainId != 1) {
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
    if (parsed.scheme != null &&
        parsed.scheme!.isNotEmpty &&
        parsed.scheme != widget.coin.uriScheme) {
      _warn("Payment URI does not match this wallet");
      return;
    }

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
            paymentId: widget.paymentDetails.quote!.paymentId,
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
    if (!mounted) return;
    await Navigator.of(context).pushNamed(
      TokenSendView.routeName,
      arguments: Tuple4(
        widget.walletId,
        widget.coin,
        contract,
        SendViewAutoFillData(
          address: evmUri.recipientAddress!,
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
            recipientAddress: evmUri.recipientAddress!,
            amount: amount,
            tokenContractAddress: contract.address,
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
