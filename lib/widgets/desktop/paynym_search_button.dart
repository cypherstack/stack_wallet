import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

class PaynymSearchButton extends StatefulWidget {
  const PaynymSearchButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  final VoidCallback onPressed;

  @override
  State<PaynymSearchButton> createState() => _PaynymSearchButtonState();
}

class _PaynymSearchButtonState extends State<PaynymSearchButton> {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: RoundedContainer(
          width: 56,
          height: 56,
          color:
              Theme.of(context).extension<StackColors>()!.buttonBackSecondary,
          child: Center(
            child: SvgPicture.asset(
              Assets.svg.search,
              width: 20,
              height: 20,
              color: Theme.of(context).extension<StackColors>()!.textDark,
            ),
          ),
        ),
      ),
    );
  }
}
