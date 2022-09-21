import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';

class NumberKey extends StatefulWidget {
  const NumberKey({
    Key? key,
    required this.number,
    required this.onPressed,
  }) : super(key: key);

  final String number;
  final ValueSetter<String> onPressed;

  @override
  State<NumberKey> createState() => _NumberKeyState();
}

class _NumberKeyState extends State<NumberKey> {
  late final String number;
  late final ValueSetter<String> onPressed;

  Color _color = CFColors.white;

  @override
  void initState() {
    number = widget.number;
    onPressed = widget.onPressed;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: 72,
      width: 72,
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: _color,
        shadows: const [],
      ),
      child: MaterialButton(
        // splashColor: CFColors.splashLight,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const StadiumBorder(),
        onPressed: () async {
          onPressed.call(number);
          setState(() {
            _color = CFColors.splashLight;
          });

          Future<void>.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              setState(() {
                _color = CFColors.white;
              });
            }
          });
        },
        child: Center(
          child: Text(
            number,
            style: GoogleFonts.roboto(
              color: CFColors.stackAccent,
              fontWeight: FontWeight.w400,
              fontSize: 26,
            ),
          ),
        ),
      ),
    );
  }
}

class BackspaceKey extends StatefulWidget {
  const BackspaceKey({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  final VoidCallback onPressed;

  @override
  State<BackspaceKey> createState() => _BackspaceKeyState();
}

class _BackspaceKeyState extends State<BackspaceKey> {
  late final VoidCallback onPressed;

  Color _color = CFColors.stackAccent;

  @override
  void initState() {
    onPressed = widget.onPressed;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: 72,
      width: 72,
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: _color,
        shadows: const [],
      ),
      child: MaterialButton(
        // splashColor: CFColors.splashLight,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const StadiumBorder(),
        onPressed: () {
          onPressed.call();
          setState(() {
            _color = CFColors.stackAccent.withOpacity(0.8);
          });

          Future<void>.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              setState(() {
                _color = CFColors.stackAccent;
              });
            }
          });
        },
        child: Center(
          child: SvgPicture.asset(
            Assets.svg.delete,
            width: 20,
            height: 20,
          ),
        ),
      ),
    );
  }
}

// class SubmitKey extends StatelessWidget {
//   const SubmitKey({
//     Key? key,
//     required this.onPressed,
//   }) : super(key: key);
//
//   final VoidCallback onPressed;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 72,
//       width: 72,
//       decoration: ShapeDecoration(
//         shape: StadiumBorder(),
//         color: CFColors.stackAccent,
//         shadows: [],
//       ),
//       child: MaterialButton(
//         // splashColor: CFColors.splashLight,
//         materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//         shape: StadiumBorder(),
//         onPressed: () {
//           onPressed.call();
//         },
//         child: Container(
//           child: Center(
//             child: SvgPicture.asset(
//               Assets.svg.arrowRight,
//               width: 20,
//               height: 20,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

class PinKeyboard extends StatelessWidget {
  const PinKeyboard({
    Key? key,
    required this.onNumberKeyPressed,
    required this.onBackPressed,
    required this.onSubmitPressed,
    this.backgroundColor,
    this.width = 264,
    this.height = 360,
  }) : super(key: key);

  final ValueSetter<String> onNumberKeyPressed;
  final VoidCallback onBackPressed;
  final VoidCallback onSubmitPressed;
  final Color? backgroundColor;
  final double? width;
  final double? height;

  void _backHandler() {
    onBackPressed.call();
  }

  // void _submitHandler() {
  //   onSubmitPressed.call();
  // }

  void _numberHandler(String number) {
    onNumberKeyPressed.call(number);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.transparent,
      child: Column(
        children: [
          Row(
            children: [
              NumberKey(
                number: "1",
                onPressed: _numberHandler,
              ),
              const SizedBox(
                width: 24,
              ),
              NumberKey(
                number: "2",
                onPressed: _numberHandler,
              ),
              const SizedBox(
                width: 24,
              ),
              NumberKey(
                number: "3",
                onPressed: _numberHandler,
              ),
            ],
          ),
          const SizedBox(
            height: 24,
          ),
          Row(
            children: [
              NumberKey(
                number: "4",
                onPressed: _numberHandler,
              ),
              const SizedBox(
                width: 24,
              ),
              NumberKey(
                number: "5",
                onPressed: _numberHandler,
              ),
              const SizedBox(
                width: 24,
              ),
              NumberKey(
                number: "6",
                onPressed: _numberHandler,
              ),
            ],
          ),
          const SizedBox(
            height: 24,
          ),
          Row(
            children: [
              NumberKey(
                number: "7",
                onPressed: _numberHandler,
              ),
              const SizedBox(
                width: 24,
              ),
              NumberKey(
                number: "8",
                onPressed: _numberHandler,
              ),
              const SizedBox(
                width: 24,
              ),
              NumberKey(
                number: "9",
                onPressed: _numberHandler,
              ),
            ],
          ),
          const SizedBox(
            height: 24,
          ),
          Row(
            children: [
              const SizedBox(
                height: 72,
                width: 72,
              ),
              const SizedBox(
                width: 24,
              ),
              NumberKey(
                number: "0",
                onPressed: _numberHandler,
              ),
              const SizedBox(
                width: 24,
              ),
              // SubmitKey(
              //   onPressed: _submitHandler,
              // )
              BackspaceKey(
                onPressed: _backHandler,
              ),
            ],
          )
        ],
      ),
    );
  }
}
