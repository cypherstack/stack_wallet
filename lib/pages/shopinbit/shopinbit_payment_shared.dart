import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_config.dart';
import '../../models/isar/models/ethereum/eth_contract.dart';
import '../../providers/providers.dart';
import '../../route_generator.dart';
import '../../services/shopinbit/src/client.dart';
import '../../services/shopinbit/src/models/payment.dart';
import '../../services/wallets.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/address_utils.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/default_eth_tokens.dart';
import '../../utilities/logger.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import 'shopinbit_send_from_view.dart';

final String kShopInBitUsdtContractAddress = DefaultTokens.list
    .firstWhere((t) => t.symbol == "USDT")
    .address;

// Address + amount pulled out of one of the API's payment_links entries.
class ShopInBitPaymentTarget {
  const ShopInBitPaymentTarget({required this.address, required this.amount});

  final String address;
  final Amount? amount;
}

// Parses a BIP21-style payment URI (or a bare address) into a destination
// address and optional Amount.
ShopInBitPaymentTarget parseShopInBitPaymentTarget({
  required String paymentUri,
  required String ticker,
  CryptoCurrency? coin,
}) {
  String address = "";
  final parsed = AddressUtils.parsePaymentUri(paymentUri);

  if (parsed?.address != null && parsed!.address.isNotEmpty) {
    address = parsed.address;
  } else {
    final colonIdx = paymentUri.indexOf(':');
    if (colonIdx != -1) {
      final afterScheme = paymentUri.substring(colonIdx + 1);
      final qIdx = afterScheme.indexOf('?');
      address = qIdx != -1 ? afterScheme.substring(0, qIdx) : afterScheme;
    } else {
      address = paymentUri;
    }
  }

  String? amountStr = parsed?.amount;
  if (amountStr == null || amountStr.isEmpty) {
    final uri = Uri.tryParse(paymentUri);
    if (uri != null) {
      amountStr = uri.queryParameters['amount'];
    }
  }
  final int fractionDigits;
  if (coin != null) {
    fractionDigits = coin.fractionDigits;
  } else if (ticker == "USDT") {
    fractionDigits = 6;
  } else {
    fractionDigits = 8;
  }

  Amount? amount;
  if (amountStr != null && amountStr.isNotEmpty) {
    amount = Amount.tryParseCanonicalAmount(
      amountStr,
      fractionDigits: fractionDigits,
      truncateOverprecision: true,
    );
    if (amount == null) {
      Logging.instance.e(
        "Failed to parse ShopInBit payment amount '$amountStr'",
      );
    }
  }

  return ShopInBitPaymentTarget(address: address, amount: amount);
}

// USDT exists on multiple chains (ERC-20, TRC-20, BEP-20, ...) and the
// ShopInBit API just keys the payment link as "USDT". Only treat it as
// ETH-USDT when the URI scheme is `ethereum:` or the address looks like a
// bare Ethereum hex address. Anything else (Tron, etc.) we don't support
// in-app and the user has to pay externally.
final RegExp _kEthAddressRegExp = RegExp(r'^0x[0-9a-fA-F]{40}$');

bool isShopInBitEthereumUsdtUri(String paymentUri) {
  final trimmed = paymentUri.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.scheme.toLowerCase() == 'ethereum') {
    return _kEthAddressRegExp.hasMatch(uri.path);
  }
  return _kEthAddressRegExp.hasMatch(trimmed);
}

// True if any wallet in [wallets] can send the given upper-cased [ticker]
// for the given [paymentUri]. USDT is special-cased to look at Ethereum
// wallets' token contracts, gated on the URI actually being ETH-chain.
bool hasShopInBitWalletForTicker({
  required Wallets wallets,
  required String ticker,
  required String paymentUri,
}) {
  if (ticker == "USDT") {
    if (!isShopInBitEthereumUsdtUri(paymentUri)) return false;
    return wallets.wallets.any(
      (w) =>
          w.info.coin is Ethereum &&
          w.info.tokenContractAddresses.contains(kShopInBitUsdtContractAddress),
    );
  }
  final coin = AppConfig.getCryptoCurrencyForTicker(ticker);
  if (coin == null) return false;
  return wallets.wallets.any((e) => e.info.coin == coin);
}

// Pushes the send-from view and awaits it.
Future<void> _pushShopInBitSendFrom({
  required BuildContext context,
  required CryptoCurrency coin,
  required Amount? amount,
  required String address,
  required int apiTicketId,
  EthContract? tokenContract,
  String? routeOnSuccessName,
}) async {
  if (Util.isDesktop) {
    // Show the send-from dialog on top of the payment dialog. Do not pop the
    // payment flow first: doing so tears down the whole nested-navigator
    // dialog, so closing send-from would drop the user back to Services
    // instead of returning to the payment view.
    await showDialog<void>(
      context: context,
      routeSettings: const RouteSettings(name: ShopInBitSendFromView.routeName),
      builder: (_) => ShopInBitSendFromView(
        coin: coin,
        amount: amount,
        address: address,
        apiTicketId: apiTicketId,
        shouldPopRoot: true,
        tokenContract: tokenContract,
        routeOnSuccessName: routeOnSuccessName,
      ),
    );
  } else {
    await Navigator.of(context).push(
      RouteGenerator.getRoute<dynamic>(
        shouldUseMaterialRoute: RouteGenerator.useMaterialPageRoute,
        builder: (_) => ShopInBitSendFromView(
          coin: coin,
          amount: amount,
          address: address,
          apiTicketId: apiTicketId,
          tokenContract: tokenContract,
          routeOnSuccessName: routeOnSuccessName,
        ),
        settings: const RouteSettings(name: ShopInBitSendFromView.routeName),
      ),
    );
  }
}

// Tries to launch the in-wallet send flow for [ticker]/[address].
Future<bool> tryNavigateToShopInBitWalletSend({
  required WidgetRef ref,
  required BuildContext context,
  required String ticker,
  required String paymentUri,
  required String address,
  required Amount? amount,
  required int apiTicketId,
  String? routeOnSuccessName,
}) async {
  if (address.isEmpty) return false;

  final coin = AppConfig.getCryptoCurrencyForTicker(ticker);
  if (coin != null) {
    await _pushShopInBitSendFrom(
      context: context,
      coin: coin,
      amount: amount,
      address: address,
      apiTicketId: apiTicketId,
      routeOnSuccessName: routeOnSuccessName,
    );
    return true;
  }

  if (ticker == "USDT") {
    if (!isShopInBitEthereumUsdtUri(paymentUri)) return false;
    final tokenContract = ref
        .read(mainDBProvider)
        .getEthContractSync(kShopInBitUsdtContractAddress);
    if (tokenContract != null) {
      final ethCoin = AppConfig.getCryptoCurrencyForTicker("ETH");
      if (ethCoin != null) {
        await _pushShopInBitSendFrom(
          context: context,
          coin: ethCoin,
          amount: amount,
          address: address,
          apiTicketId: apiTicketId,
          tokenContract: tokenContract,
          routeOnSuccessName: routeOnSuccessName,
        );
        return true;
      }
    }
  }

  return false;
}

// Fetches the live payment info for a ticket so the caller can pass it into
// the payment view as an arg (rather than loading it after the view is up).
// GET first to reuse an existing invoice per the spec's "page reload
// recovery" guidance. Retry stale invoices and create only when not started.
// Returns null on any failure so the view can fall back to polling.
Future<PaymentInfo?> fetchShopInBitPaymentInfo(
  ShopInBitClient client,
  int apiTicketId,
  String customerKey,
) async {
  try {
    final getResp = await client.getPayment(
      apiTicketId,
      customerKey: customerKey,
    );
    if (getResp.hasError || getResp.value == null) {
      return null;
    }

    final paymentInfo = getResp.value!;
    final retry = const {
      'expired',
      'invalid',
      'underpaid_expired',
    }.contains(paymentInfo.status);
    if (!retry && paymentInfo.status != 'not_started') {
      return paymentInfo;
    }

    final putResp = await client.putPayment(
      apiTicketId,
      customerKey: customerKey,
      retry: retry,
    );
    if (!putResp.hasError && putResp.value != null) {
      return putResp.value;
    }
  } catch (e, s) {
    Logging.instance.w(
      "fetchShopInBitPaymentInfo failed, degrading to polling-only",
      error: e,
      stackTrace: s,
    );
  }
  return null;
}

// Shared mobile chrome for the two ShopInBit payment views: Background +
// PopScope (back goes through [onBack]) + AppBar + scrollable, intrinsic
// height body.
class ShopInBitPaymentMobileScaffold extends StatelessWidget {
  const ShopInBitPaymentMobileScaffold({
    super.key,
    required this.onBack,
    required this.child,
  });

  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Background(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (!didPop) {
            onBack();
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(
            context,
          ).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: AppBarBackButton(onPressed: onBack),
            title: Text("ShopinBit", style: STextStyles.navBarTitle(context)),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32,
                      ),
                      child: IntrinsicHeight(child: child),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
