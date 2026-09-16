/*
 * A 7-day price sparkline, drawn from the series CoinGecko already returns
 * alongside the price. Hand-painted rather than pulling in a charting package:
 * one line and one fill needs no dependency, and a package would bring axes,
 * legends and tooltips this has no room for.
 *
 * Touch it and it reports: a crosshair, the point under your finger, and the
 * price and age of that point. A chart with no readout is a shape, not a
 * figure — you can see that it rose without ever learning what it rose to.
 *
 * Renders nothing when there is no series. BFX has no market, so it has no
 * series, and an empty chart frame would read as broken rather than as "not
 * applicable".
 */

import 'dart:math' as math;

import 'package:flutter/material.dart';

class PriceSparkline extends StatefulWidget {
  const PriceSparkline({
    super.key,
    required this.series,
    required this.color,
    required this.format,
    this.height = 38,
    this.strokeWidth = 2,
    this.spanHours = 7 * 24,
    this.idleLabel = "7 days",
  });

  /// Oldest point first. Fewer than two points cannot describe a change, so
  /// nothing is drawn.
  final List<double> series;
  final Color color;

  /// Renders one price the way the rest of the screen renders prices.
  ///
  /// Passed in rather than done here: the currency and locale already live in
  /// the hero, and a second formatter would be a second answer to the same
  /// question — the sub-cent widening that makes 0.0001443 legible included.
  final String Function(double) format;

  final double height;
  final double strokeWidth;

  /// How much time the whole series spans, for the "Nd ago" readout. The
  /// series carries no timestamps, so spacing derives from this. 168 matches
  /// the original 7-day sparkline; the hero's range selector passes 24/720.
  final double spanHours;

  /// Corner label when nothing is being read. The hero's chart card passes ""
  /// because its range pills already say what the chart spans.
  final String idleLabel;

  @override
  State<PriceSparkline> createState() => _PriceSparklineState();
}

class _PriceSparklineState extends State<PriceSparkline> {
  int? _active;

  /// The caption row's height, reserved whether or not anything is being read.
  ///
  /// Fixed rather than grown on touch: a row that appears under your finger
  /// would push the line you are pointing at somewhere else at the exact moment
  /// you are pointing at it.
  static const double _captionHeight = 15;

  void _setFromX(double dx, double width) {
    if (width <= 0) return;
    final n = widget.series.length;
    final i = ((dx / width) * (n - 1)).round().clamp(0, n - 1);
    if (i != _active) setState(() => _active = i);
  }

  void _clear() {
    if (_active != null) setState(() => _active = null);
  }

  /// How long ago point [i] is, as words.
  ///
  /// The series carries prices and no timestamps, so the spacing is derived
  /// from the endpoint's own definition: sparkline_in_7d covers seven days,
  /// evenly. That is exact enough for "2d ago" and would not be for a clock
  /// time, which is why this says the former and not the latter.
  String _ago(int i) {
    final n = widget.series.length;
    if (i >= n - 1) return "now";
    final hours = ((n - 1 - i) * (widget.spanHours / (n - 1))).round();
    if (hours < 1) return "now";
    if (hours < 24) return "${hours}h ago";
    return "${(hours / 24).round()}d ago";
  }

  @override
  Widget build(BuildContext context) {
    if (widget.series.length < 2) return const SizedBox.shrink();

    final i = _active;
    final caption = i == null
        ? widget.idleLabel
        : "${widget.format(widget.series[i])} · ${_ago(i)}";

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          // Opaque so the whole block answers to touch, caption row included.
          // The line itself is two pixels tall and would be a miserable target.
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _setFromX(d.localPosition.dx, width),
          onTapUp: (_) => _clear(),
          onTapCancel: _clear,
          onHorizontalDragStart: (d) => _setFromX(d.localPosition.dx, width),
          onHorizontalDragUpdate: (d) => _setFromX(d.localPosition.dx, width),
          onHorizontalDragEnd: (_) => _clear(),
          onHorizontalDragCancel: _clear,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: _captionHeight,
                child: Align(
                  // Idle it is a quiet range label in the corner; reading, it
                  // is the figure itself and moves to where reading starts.
                  alignment: i == null
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.1,
                      fontWeight: i == null ? FontWeight.w500 : FontWeight.w600,
                      letterSpacing: 0.2,
                      color: widget.color.withValues(
                        alpha: i == null ? 0.5 : 1,
                      ),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: widget.height,
                child: CustomPaint(
                  painter: _SparklinePainter(
                    series: widget.series,
                    color: widget.color,
                    strokeWidth: widget.strokeWidth,
                    active: i,
                  ),
                  child: Semantics(
                    label: i == null
                        ? (widget.series.last >= widget.series.first
                              ? "Price chart, up over the shown range"
                              : "Price chart, down over the shown range")
                        : "${widget.format(widget.series[i])}, ${_ago(i)}",
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.series,
    required this.color,
    required this.strokeWidth,
    required this.active,
  });

  final List<double> series;
  final Color color;
  final double strokeWidth;
  final int? active;

  @override
  void paint(Canvas canvas, Size size) {
    double lo = series.first, hi = series.first;
    for (final v in series) {
      lo = math.min(lo, v);
      hi = math.max(hi, v);
    }

    // A flat series has zero range. Dividing by it yields NaN and paints
    // nothing at all, so pin it to the middle instead — "no change" is a real
    // answer and should look like one.
    final range = hi - lo;
    final usable = size.height - strokeWidth;
    double y(double v) => range == 0
        ? size.height / 2
        : (strokeWidth / 2) + usable - ((v - lo) / range) * usable;

    final dx = size.width / (series.length - 1);
    final path = Path()..moveTo(0, y(series.first));
    for (var i = 1; i < series.length; i++) {
      path.lineTo(dx * i, y(series[i]));
    }

    // Fill under the line first so the stroke sits on top of its own edge.
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final i = active;
    if (i != null) {
      // Crosshair, then the point on top of it. Drawn at dx * i, the same
      // expression that placed the line, so the marker sits exactly on the
      // drawn point rather than near it.
      final x = dx * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..strokeWidth = 1,
      );
      final at = Offset(x, y(series[i]));
      // A ring in the well's own colour so the dot reads against the line it
      // is sitting on rather than merging with it.
      canvas.drawCircle(at, strokeWidth * 2.4, Paint()..color = color);
      canvas.drawCircle(
        at,
        strokeWidth * 1.1,
        Paint()..color = const Color(0xFF000000).withValues(alpha: 0.35),
      );
      return; // The endpoint marker below would double up under the crosshair.
    }

    // The most recent point, marked. Without it the line just stops, and which
    // end is "now" is not obvious.
    canvas.drawCircle(
      Offset(size.width, y(series.last)),
      strokeWidth * 1.4,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.active != active ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      !identical(old.series, series);
}

/// A price series at a glance: one line, no readout, no caption.
///
/// The interactive [PriceSparkline] above is the chart on the price screen,
/// where a touch should tell you the value under your finger. This is the
/// glyph beside a balance, which says only which way the day went. It takes
/// no touches at all, so the row it sits in stays one tap target rather than
/// two, and it reserves no room for a caption it will never show.
class MiniSparkline extends StatelessWidget {
  const MiniSparkline({
    super.key,
    required this.series,
    required this.color,
    this.height = 26,
    this.strokeWidth = 2,
  });

  final List<double> series;
  final Color color;
  final double height;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    // Below two points there is no line to draw.
    if (series.length < 2) return SizedBox(height: height);

    return IgnorePointer(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _MiniPainter(
            series: series,
            color: color,
            strokeWidth: strokeWidth,
          ),
        ),
      ),
    );
  }
}

class _MiniPainter extends CustomPainter {
  _MiniPainter({
    required this.series,
    required this.color,
    required this.strokeWidth,
  });

  final List<double> series;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    var low = series.first;
    var high = series.first;
    for (final v in series) {
      if (v < low) low = v;
      if (v > high) high = v;
    }
    // A price that never moved has no range to divide by. Down the middle is
    // the honest picture of one.
    final span = high - low;
    final inset = strokeWidth / 2;
    final usable = size.height - inset * 2;

    double y(double v) =>
        span == 0 ? size.height / 2 : inset + (1 - (v - low) / span) * usable;

    final path = Path()..moveTo(0, y(series.first));
    for (var i = 1; i < series.length; i++) {
      path.lineTo(i / (series.length - 1) * size.width, y(series[i]));
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_MiniPainter old) =>
      old.series != series ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
