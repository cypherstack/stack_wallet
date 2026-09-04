import 'package:flutter/material.dart';

import '../../../themes/stack_colors.dart';
import '../../../utilities/constants.dart';
import '../../../utilities/text_styles.dart';
import '../../../widgets/custom_buttons/draggable_switch_button.dart';
import '../../../widgets/stack_text_field.dart';

class SaveRecipientControls extends StatelessWidget {
  const SaveRecipientControls({
    super.key,
    required this.enabled,
    required this.isDesktop,
    required this.onChanged,
    required this.controller,
    required this.focusNode,
  });

  final bool enabled;
  final bool isDesktop;
  final ValueChanged<bool> onChanged;
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final labelStyle = isDesktop
        ? STextStyles.desktopTextExtraSmall(context).copyWith(
            color: Theme.of(
              context,
            ).extension<StackColors>()!.textFieldActiveSearchIconRight,
          )
        : STextStyles.smallMed12(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text('Save recipient to contacts', style: labelStyle),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 20,
              width: 40,
              child: DraggableSwitchButton(
                isOn: enabled,
                onValueChanged: onChanged,
              ),
            ),
          ],
        ),
        if (enabled) SizedBox(height: isDesktop ? 10 : 8),
        if (enabled)
          ClipRRect(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autocorrect: !isDesktop,
              enableSuggestions: !isDesktop,
              style: isDesktop
                  ? STextStyles.desktopTextExtraSmall(context).copyWith(
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.textFieldActiveText,
                    )
                  : STextStyles.field(context),
              decoration: standardInputDecoration(
                'Contact name',
                focusNode,
                context,
                desktopMed: isDesktop,
              ),
            ),
          ),
      ],
    );
  }
}
