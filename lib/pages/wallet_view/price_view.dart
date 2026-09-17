/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../services/price.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/price_sparkline.dart';
import '../../widgets/rounded_white_container.dart';

/// What a coin costs, and what it has been doing.
///
/// Its own screen rather than a chart squeezed into the balance card. People
/// open a wallet to see their balance and they do it many times a day, so the
/// card belongs to the balance; a chart is read occasionally and needs room
/// to be read at all. Ledger moved their portfolio graph off the home tab in
/// 2026 for exactly this reason, calling the cramped version a compromise.
///
/// Every figure comes from one fetch, so the chart, the change beside it and
/// the high and low underneath cannot describe different windows.
class PriceView extends ConsumerStatefulWidget {
  const PriceView({super.key, required this.coin});

  static const String routeName = "/priceView";

  final CryptoCurrency coin;

  @override
  ConsumerState<PriceView> createState() => _PriceViewState();
}

/// The windows the server serves. Not a free choice: each is a resolution the
/// source actually returns, and anything else is rounded to one of them.
const _ranges = <int, String>{1: "24H", 7: "7D", 30: "30D"};

class _PriceViewState extends ConsumerState<PriceView> {
  int _days = 1;

  /// One entry per range, so returning to a range already looked at is
  /// instant and switching never blanks a chart that is already drawn.
  final Map<int, PriceHistory> _seen = {};
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load(_days);
  }

  Future<void> _load(int days) async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final history = await ref
        .read(priceAnd24hChangeNotifierProvider)
        .getHistory(widget.coin, days);
    if (!mounted) return;
    setState(() {
      if (history != null) _seen[days] = history;
      _failed = history == null && !_seen.containsKey(days);
      _loading = false;
    });
  }

  void _pick(int days) {
    if (days == _days) return;
    setState(() => _days = days);
    _load(days);
  }

  /// The move across the series drawn, as a percentage.
  ///
  /// Computed from the ends of the series on screen, never from the API's
  /// 24h figure: a percentage beside an active 30D control must be the 30 day
  /// move, or the screen contradicts its own chart.
  ({String text, bool down})? _change(PriceHistory h) {
    if (h.series.length < 2 || h.series.first <= 0) return null;
    final pct = (h.series.last / h.series.first - 1) * 100;
    final down = pct < 0;
    return (
      text: "${down ? "-" : "+"}${pct.abs().toStringAsFixed(2)}%",
      down: down,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<StackColors>()!;
    final locale = ref.watch(
      localeServiceChangeNotifierProvider.select((value) => value.locale),
    );
    final baseCurrency = ref.watch(
      prefsChangeNotifierProvider.select((value) => value.currency),
    );

    final shown = _seen[_days];
    final change = shown == null ? null : _change(shown);
    final tint = change == null || !change.down
        ? colors.accentColorGreen
        : colors.accentColorRed;

    String money(double v) => priceFigure(v, locale, baseCurrency);

    return Background(
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            "${widget.coin.prettyName} price",
            style: STextStyles.navBarTitle(context),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (_failed)
                RoundedWhiteContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "No price history came back for "
                        "${widget.coin.prettyName}. Check the connection and "
                        "try again.",
                        style: STextStyles.smallMed14(context),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _load(_days),
                        child: Text(
                          "Retry",
                          style: STextStyles.smallMed14(context).copyWith(
                            color: colors.infoItemIcons,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                _headline(context, shown, change, tint, money, baseCurrency),
                const SizedBox(height: 16),
                _chart(context, shown, tint, money),
                const SizedBox(height: 16),
                _rangePicker(context, colors),
                const SizedBox(height: 16),
                if (shown != null) _stats(context, shown, money),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _headline(
    BuildContext context,
    PriceHistory? shown,
    ({String text, bool down})? change,
    Color tint,
    String Function(double) money,
    String baseCurrency,
  ) {
    // The spot price, not the last close: it is the figure every other screen
    // in the app is showing right now, and two prices that disagree by a
    // minute read as one of them being wrong.
    final spot = ref
        .watch(priceAnd24hChangeNotifierProvider)
        .getPrice(widget.coin)
        ?.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            spot == null ? "" : money(spot.toDouble()),
            maxLines: 1,
            style: STextStyles.pageTitleH1(context).copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 4),
        // The change carries the window it belongs to. An unlabelled
        // percentage is how a market's month gets read as somebody's day.
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: change?.text ?? "",
                style: STextStyles.smallMed14(context).copyWith(
                  color: tint,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              TextSpan(
                text: shown == null
                    ? ""
                    : "  ·  ${windowLabel(shown.spanHours)}",
                style: STextStyles.smallMed14(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chart(
    BuildContext context,
    PriceHistory? shown,
    Color tint,
    String Function(double) money,
  ) {
    if (shown == null) {
      return SizedBox(
        height: 190,
        child: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : Text(
                  "No chart for this range",
                  style: STextStyles.smallMed14(context),
                ),
        ),
      );
    }
    // The interactive one: a touch reads out the value under the finger and
    // how long ago it was. A chart this size that could not be interrogated
    // would be a picture rather than a reading.
    return PriceSparkline(
      series: shown.series,
      color: tint,
      height: 160,
      spanHours: shown.spanHours,
      idleLabel: "Touch the chart to read a price",
      format: money,
    );
  }

  Widget _rangePicker(BuildContext context, StackColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.textFieldDefaultBG,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final entry in _ranges.entries)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _pick(entry.key),
                child: Container(
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _days == entry.key
                        ? colors.popupBG
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    entry.value,
                    style: STextStyles.smallMed14(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: _days == entry.key
                          ? colors.textDark
                          : colors.textSubtitle1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stats(
    BuildContext context,
    PriceHistory shown,
    String Function(double) money,
  ) {
    // Labelled with the window they actually cover, taken from the span the
    // server measured rather than the range that was asked for. A high over a
    // month and a high over a day are different facts, and on a market that
    // opened this September a 30 day request still returns about two days.
    final window = windowShort(shown.spanHours);
    final prefix = window.isEmpty ? "" : "$window ";
    final rows = <(String, String)>[
      if (shown.high != null) ("${prefix}high", money(shown.high!)),
      if (shown.low != null) ("${prefix}low", money(shown.low!)),
      if (shown.volume24h != null) ("24h volume", money(shown.volume24h!)),
      if (shown.source.isNotEmpty) ("Priced by", _venue(shown.source)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoundedWhiteContainer(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.backgroundAppBar,
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      Text(rows[i].$1, style: STextStyles.smallMed14(context)),
                      const Spacer(),
                      Flexible(
                        // Shrinks rather than wraps. A price broken across two
                        // lines reads as two numbers, and the second line was
                        // only ever the currency.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            rows[i].$2,
                            maxLines: 1,
                            textAlign: TextAlign.right,
                            style: STextStyles.smallMed14(context).copyWith(
                              color: Theme.of(
                                context,
                              ).extension<StackColors>()!.textDark,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "An estimate of what ${widget.coin.ticker} is worth, not an offer. "
          "This wallet cannot buy or sell.",
          style: STextStyles.smallMed12(context),
        ),
      ],
    );
  }

  /// A venue's own spelling. The server sends a key, and printing the key
  /// gives "coingecko" on a row that names a company.
  String _venue(String key) => switch (key) {
    "coingecko" => "CoinGecko",
    "nestex" => "NestEx",
    _ => key,
  };
}

/// Money, wide enough not to lie.
///
/// [Amount.fiatString] widens below a cent but keeps the familiar two places
/// from a cent up, which is right for an amount of money and wrong for the
/// price of a coin: a 24h high of 0.0249 printed as "0.02" understates it by
/// a fifth and contradicts the chart drawn above it. So under one unit of
/// the currency this shows four significant digits, and a unit or more is
/// left to the shared formatter. Only this screen behaves this way, because
/// balances elsewhere are amounts of money and two places is right for them.
String priceFigure(double value, String locale, String currency) {
  final d = Decimal.parse(value.toString());
  if (d > Decimal.zero && d < Decimal.one) {
    final digits = d.toStringAsFixed(8).substring(2);
    final firstSignificant = digits.indexOf(RegExp(r"[1-9]"));
    final places = firstSignificant < 0
        ? 2
        : (firstSignificant + 4).clamp(2, 8);
    var text = d.toStringAsFixed(places);
    // Widening introduces trailing zeros that say nothing.
    text = text.replaceAll(RegExp(r"0+$"), "");
    if (text.endsWith(".")) text = text.substring(0, text.length - 1);
    // The separator the reader's locale uses, the one fiatString would have
    // picked. A hardcoded dot prints a different number in half the world.
    final separator = Util.getSymbolsFor(locale: locale)?.DECIMAL_SEP ?? ".";
    return "${text.replaceFirst(".", separator)} $currency";
  }
  return "${d.toAmount(fractionDigits: 8).fiatString(locale: locale)} "
      "$currency";
}

/// What a price series really covers, in words.
///
/// From the span the server measured, never the range that was asked for. The
/// BFX market opened in September 2026, so a 30 day request currently returns
/// about two days, and a label taken from the range would be wrong by a month.
String windowLabel(double spanHours) {
  if (spanHours <= 0) return "so far";
  if (spanHours < 36) return "past ${spanHours.round()} hours";
  return "past ${(spanHours / 24).round()} days";
}

/// The same window, short enough to sit in front of "high" and "low".
///
/// Derived from the same measured span as [windowLabel] so the two cannot
/// disagree. They did: the change at the top of the screen read "past 2 days"
/// from the real span while the rows underneath said "30D high" from the range
/// that had been requested, which presented a two day extreme as a monthly one
/// on the same screen.
String windowShort(double spanHours) {
  if (spanHours <= 0) return "";
  if (spanHours < 36) return "${spanHours.round()}h";
  return "${(spanHours / 24).round()}d";
}
