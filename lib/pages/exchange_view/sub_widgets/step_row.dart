import 'package:flutter/cupertino.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/step_indicator.dart';
import 'package:stackwallet/utilities/cfcolors.dart';

class StepRow extends StatelessWidget {
  const StepRow({
    Key? key,
    required this.count,
    required this.current,
    required this.width,
    this.indicatorSize = 16,
    this.minSpacing = 4,
  }) : super(key: key);

  final int count;
  final int current;
  final double width;
  final double indicatorSize;
  final double minSpacing;

  Color getColor(int index) {
    if (current >= count - 1) {
      return CFColors.stackAccent;
    }

    if (current <= index) {
      return CFColors.stackAccent.withOpacity(0.2);
    } else {
      return CFColors.link2;
    }
  }

  StepIndicatorStatus getStatus(int index) {
    if (current < index) {
      return StepIndicatorStatus.incomplete;
    } else if (current > index) {
      return StepIndicatorStatus.completed;
    } else {
      return StepIndicatorStatus.current;
    }
  }

  List<Widget> _buildList(double spacerWidth) {
    List<Widget> list = [];
    for (int i = 0; i < count - 1; i++) {
      list.add(StepIndicator(
        step: i + 1,
        status: getStatus(i),
      ));
      list.add(_SpacerRow(
        width: spacerWidth,
        dotSize: 1.5,
        spacing: 4,
        color: getColor(i),
      ));
    }
    list.add(StepIndicator(
      step: count - 1,
      status: getStatus(count - 1),
    ));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final spacerWidth =
        ((width - (indicatorSize * count)) / (count - 1)) - (2 * minSpacing);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ..._buildList(spacerWidth),
      ],
    );
  }
}

class _SpacerRow extends StatelessWidget {
  const _SpacerRow({
    Key? key,
    required this.width,
    required this.dotSize,
    required this.spacing,
    required this.color,
  }) : super(key: key);

  final Color color;
  final double width;
  final double dotSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final count = ((width - dotSize) / (dotSize + spacing)).floor() + 1;
    return Row(
      children: [
        for (int i = 0; i < count - 1; i++)
          Row(
            children: [
              _SpacerDot(
                color: color,
                size: dotSize,
              ),
              SizedBox(
                width: spacing,
              ),
            ],
          ),
        _SpacerDot(
          color: color,
          size: dotSize,
        ),
      ],
    );
  }
}

class _SpacerDot extends StatelessWidget {
  const _SpacerDot({
    Key? key,
    required this.color,
    this.size = 1.5,
  }) : super(key: key);

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}
