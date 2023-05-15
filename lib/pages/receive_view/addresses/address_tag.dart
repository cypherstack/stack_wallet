import 'package:flutter/material.dart';
import 'package:flutter_native_splash/cli_commands.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

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
      color: Theme.of(context).extension<StackColors>()!.buttonBackPrimary,
      child: Text(
        tag.capitalize(),
        style: STextStyles.w500_14(context).copyWith(
          color: Theme.of(context).extension<StackColors>()!.buttonTextPrimary,
        ),
      ),
    );
  }
}
