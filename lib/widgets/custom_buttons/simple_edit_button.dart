import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/pages/generic/single_field_edit_view.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:tuple/tuple.dart';

class SimpleEditButton extends StatelessWidget {
  const SimpleEditButton({
    Key? key,
    required this.editValue,
    required this.editLabel,
    required this.onValueChanged,
  }) : super(key: key);

  final String editValue;
  final String editLabel;
  final void Function(String) onValueChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).pushNamed(
          SingleFieldEditView.routeName,
          arguments: Tuple2(
            editValue,
            editLabel,
          ),
        );
        if (result is String && result != editValue) {
          onValueChanged(result);
        }
      },
      child: Row(
        children: [
          SvgPicture.asset(
            Assets.svg.pencil,
            width: 10,
            height: 10,
            color: Theme.of(context).extension<StackColors>()!.infoItemIcons,
          ),
          const SizedBox(
            width: 4,
          ),
          Text(
            "Edit",
            style: STextStyles.link2(context),
          ),
        ],
      ),
    );
  }
}
