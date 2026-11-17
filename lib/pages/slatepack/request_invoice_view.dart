import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/global/locale_provider.dart';
import '../../providers/global/prefs_provider.dart';
import '../../providers/global/price_provider.dart';
import '../../providers/global/wallets_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/amount/amount_input_formatter.dart';
import '../../utilities/constants.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../wallets/wallet/wallet_mixin_interfaces/slatepack_interface.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/rounded_container.dart';
import '../../widgets/stack_text_field.dart';
import 'slatepack_dialog.dart';
import 'slatepack_import_flow.dart';
import 'slatepack_recipient_field.dart';

/// Opens the invoice request form: a page on mobile, a dialog on desktop.
Future<void> showRequestInvoice(BuildContext context, String walletId) {
  final view = RequestInvoiceView(walletId: walletId);
  if (Util.isDesktop) {
    return showDialog<void>(
      context: context,
      builder: (_) =>
          DesktopDialog(maxWidth: 580, maxHeight: null, child: view),
    );
  }
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => view,
      settings: const RouteSettings(name: RequestInvoiceView.routeName),
    ),
  );
}

/// Asks someone for a payment: makes an invoice (I1) for an amount,
/// optionally encrypted to the payer.
class RequestInvoiceView extends ConsumerStatefulWidget {
  const RequestInvoiceView({super.key, required this.walletId});

  static const String routeName = "/requestInvoice";

  final String walletId;

  @override
  ConsumerState<RequestInvoiceView> createState() => _RequestInvoiceViewState();
}

class _RequestInvoiceViewState extends ConsumerState<RequestInvoiceView> {
  late final SlatepackInterface _wallet;
  final _amountController = TextEditingController();
  final _fiatController = TextEditingController();
  final _payerController = TextEditingController();
  final _amountFocus = FocusNode();
  final _fiatFocus = FocusNode();
  bool _lock = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _wallet =
        ref.read(pWallets).getWallet(widget.walletId) as SlatepackInterface;
    _payerController.addListener(_payerChanged);
  }

  void _payerChanged() => setState(() {});

  @override
  void dispose() {
    _amountController.dispose();
    _fiatController.dispose();
    _payerController.dispose();
    _amountFocus.dispose();
    _fiatFocus.dispose();
    super.dispose();
  }

  String get _locale => ref.read(localeServiceChangeNotifierProvider).locale;

  Decimal? get _price {
    final price = ref
        .read(priceAnd24hChangeNotifierProvider)
        .getPrice(_wallet.cryptoCurrency)
        ?.value;
    return price == null || price <= Decimal.zero ? null : price;
  }

  Amount? get _amount {
    final amount = Amount.tryParseEditableAmount(
      _amountController.text,
      locale: _locale,
      fractionDigits: _wallet.cryptoCurrency.fractionDigits,
    );
    return amount == null || amount.raw <= BigInt.zero ? null : amount;
  }

  void _amountChanged(String _) {
    if (_lock) return;
    final price = _price;
    final amount = _amount;
    _lock = true;
    _fiatController.text = price == null || amount == null
        ? ""
        : Amount.formatEditableDecimal(
            (amount.decimal * price).toAmount(fractionDigits: 2).decimal,
            locale: _locale,
          );
    _lock = false;
    setState(() {});
  }

  void _fiatChanged(String text) {
    if (_lock) return;
    final price = _price;
    final fiat = Amount.tryParseFiatString(text, locale: _locale);
    final digits = _wallet.cryptoCurrency.fractionDigits;
    _lock = true;
    _amountController.text = price == null || fiat == null
        ? ""
        : Amount.formatEditableDecimal(
            (fiat.decimal / price)
                .toDecimal(scaleOnInfinitePrecision: digits)
                .toAmount(fractionDigits: digits)
                .decimal,
            locale: _locale,
          );
    _lock = false;
    setState(() {});
  }

  bool get _canCreate =>
      !_busy &&
      _amount != null &&
      SlatepackRecipientField.isAcceptable(
        _wallet.cryptoCurrency,
        _payerController.text,
      );

  Future<void> _create() async {
    final amount = _amount;
    if (amount == null || !_canCreate) return;
    setState(() => _busy = true);
    try {
      final payer = _payerController.text.trim();
      final result = await SlatepackImportFlow.withLoading(
        context,
        "Creating invoice...",
        () async {
          final r = await _wallet.issueInvoice(
            amount: amount,
            payerAddress: payer.isEmpty ? null : payer,
          );
          if (!r.success || r.slatepack == null) {
            throw Exception(r.error ?? "Failed to create the invoice");
          }
          return r;
        },
        errorTitle: "Invoice error",
      );
      if (result == null || !mounted) return;
      await showSlatepackDialog(
        context: context,
        terms: _wallet.slatepackTerms,
        result: result,
        supportsEncryption: _wallet.supportsSlatepackEncryption,
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required int decimals,
    required void Function(String) onChanged,
    Key? key,
  }) {
    final isDesktop = Util.isDesktop;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Constants.size.circularBorderRadius),
      child: TextField(
        key: key,
        controller: controller,
        focusNode: focusNode,
        autocorrect: false,
        enableSuggestions: false,
        keyboardType: isDesktop
            ? null
            : const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          AmountInputFormatter(
            controller: controller,
            decimals: decimals,
            locale: ref.watch(
              localeServiceChangeNotifierProvider.select((e) => e.locale),
            ),
          ),
        ],
        onChanged: onChanged,
        style: isDesktop
            ? STextStyles.desktopTextExtraSmall(context).copyWith(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldActiveText,
                height: 1.8,
              )
            : STextStyles.field(context),
        decoration: standardInputDecoration(
          label,
          focusNode,
          context,
          desktopMed: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final colors = Theme.of(context).extension<StackColors>()!;
    final coin = _wallet.cryptoCurrency;
    final currency = ref.watch(
      prefsChangeNotifierProvider.select((p) => p.currency),
    );
    final price = ref
        .watch(priceAnd24hChangeNotifierProvider)
        .getPrice(coin)
        ?.value;
    final hasPrice = price != null && price > Decimal.zero;

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          key: const Key("requestInvoiceAmount"),
          controller: _amountController,
          focusNode: _amountFocus,
          label: "Amount (${coin.ticker})",
          decimals: coin.fractionDigits,
          onChanged: _amountChanged,
        ),
        if (hasPrice) ...[
          const SizedBox(height: 12),
          _field(
            controller: _fiatController,
            focusNode: _fiatFocus,
            label: "Amount ($currency)",
            decimals: 2,
            onChanged: _fiatChanged,
          ),
        ],
        const SizedBox(height: 16),
        SlatepackRecipientField(
          controller: _payerController,
          coin: coin,
          label: "Payer address (optional)",
          help:
              "The invoice is encrypted to this address so only the payer "
              "can read it.",
        ),
        const SizedBox(height: 16),
        RoundedContainer(
          color: colors.infoItemBG,
          child: Text(
            "The payer returns a payment ${_wallet.slatepackTerms.noun}. "
            "Import it on the Slatepack screen to finalize. An invoice locks "
            "none of your funds.",
            style: STextStyles.label(context),
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          key: const Key("requestInvoiceCreate"),
          label: "Create invoice",
          buttonHeight: isDesktop ? ButtonHeight.l : null,
          enabled: _canCreate,
          onPressed: _canCreate ? _create : null,
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
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              "Request payment",
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
                    "Request payment",
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
