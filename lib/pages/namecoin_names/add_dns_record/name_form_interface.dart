import 'package:flutter/material.dart';

import '../../../models/namecoin_dns/dns_record.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/constants.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';

abstract class NameFormStatefulWidget extends StatefulWidget {
  const NameFormStatefulWidget({super.key, required this.name});

  final String name;
}

abstract class NameFormState<T extends NameFormStatefulWidget>
    extends State<T> {
  DNSRecord buildRecord();
}

class DNSFieldText extends StatelessWidget {
  const DNSFieldText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Util.isDesktop
          ? STextStyles.w500_12(context).copyWith(
              color: Theme.of(context).extension<StackColors>()!.textDark3,
            )
          : STextStyles.w500_14(context).copyWith(
              color: Theme.of(context).extension<StackColors>()!.textDark3,
            ),
    );
  }
}

class DNSFormField extends StatelessWidget {
  const DNSFormField({super.key, required this.controller, this.keyboardType});

  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        Constants.size.circularBorderRadius,
      ),
      child: TextField(
        controller: controller,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.all(16),
          hintStyle: STextStyles.fieldLabel(context),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
