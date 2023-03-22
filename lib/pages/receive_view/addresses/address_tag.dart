import 'package:flutter/material.dart';
import 'package:flutter_native_splash/cli_commands.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/widgets/rounded_container.dart';

class AddressTag extends StatelessWidget {
  const AddressTag({Key? key, required this.tag}) : super(key: key);

  final String tag;

  @override
  Widget build(BuildContext context) {
    return RoundedContainer(
      radiusMultiplier: 0.5,
      padding: const EdgeInsets.symmetric(
        vertical: 5,
        horizontal: 7,
      ),
      color: Colors.black,
      child: Text(
        tag.capitalize(),
        style: STextStyles.w500_14(context),
      ),
    );
  }
}
