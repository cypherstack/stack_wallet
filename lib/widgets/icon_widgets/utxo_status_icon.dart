import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

import '../../utilities/theme/stack_colors.dart';

enum UTXOStatusIconStatus {
  confirmed,
  unconfirmed;
}

class UTXOStatusIcon extends StatelessWidget {
  const UTXOStatusIcon({
    Key? key,
    required this.width,
    required this.height,
    required this.blocked,
    required this.selected,
    required this.status,
    required this.background,
  }) : super(key: key);

  final double width;
  final double height;
  final bool blocked;
  final bool selected;
  final UTXOStatusIconStatus status;
  final Color background;

  final _availableColor = const Color(0xFFF7931A);
  final _blockedColor = const Color(0xFF96B0D6);

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: status == UTXOStatusIconStatus.unconfirmed,
      builder: (child) => Stack(
        children: [
          child,
          Positioned(
            right: 0,
            bottom: 0,
            child: Stack(
              children: [
                RoundedContainer(
                  radiusMultiplier: 100,
                  color: background,
                  width: width / 2.8,
                  height: height / 2.8,
                ),
                Positioned(
                  right: width / 2.8 - width / 3,
                  left: width / 2.8 - width / 3,
                  top: height / 2.8 - height / 3,
                  child: SvgPicture.asset(
                    Assets.svg.pending,
                    width: width / 3,
                    height: height / 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          RoundedContainer(
            radiusMultiplier: 100,
            color: selected
                ? Theme.of(context).extension<StackColors>()!.infoItemIcons
                : blocked
                    ? _blockedColor.withOpacity(0.3)
                    : _availableColor.withOpacity(0.2),
            width: width,
            height: height,
          ),
          SvgPicture.asset(
            selected
                ? Assets.svg.coinControl.selected
                : blocked
                    ? Assets.svg.coinControl.blocked
                    : Assets.svg.coinControl.unBlocked,
            width: 20,
            height: 20,
            color: selected
                ? Colors.white
                : blocked
                    ? _blockedColor
                    : _availableColor,
          ),
        ],
      ),
    );
  }
}
