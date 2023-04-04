import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/pages/generic/single_field_edit_view.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:tuple/tuple.dart';

import '../desktop/desktop_dialog.dart';
import '../icon_widgets/pencil_icon.dart';

class SimpleEditButton extends StatelessWidget {
  const SimpleEditButton({
    Key? key,
    this.editValue,
    this.editLabel,
    this.onValueChanged,
    this.onPressedOverride,
  })  : assert(
          (editLabel != null && editValue != null && onValueChanged != null) ||
              (editLabel == null &&
                  editValue == null &&
                  onValueChanged == null &&
                  onPressedOverride != null),
        ),
        super(key: key);

  final String? editValue;
  final String? editLabel;
  final void Function(String)? onValueChanged;
  final VoidCallback? onPressedOverride;

  @override
  Widget build(BuildContext context) {
    if (Util.isDesktop) {
      return SizedBox(
        height: 26,
        width: 26,
        child: RawMaterialButton(
          fillColor:
              Theme.of(context).extension<StackColors>()!.buttonBackSecondary,
          elevation: 0,
          hoverElevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          onPressed: onPressedOverride ??
              () async {
                final result = await showDialog<String?>(
                  context: context,
                  builder: (context) {
                    return DesktopDialog(
                      maxWidth: 580,
                      maxHeight: 300,
                      child: SingleFieldEditView(
                        initialValue: editValue!,
                        label: editLabel!,
                      ),
                    );
                  },
                );
                if (result is String && result != editValue!) {
                  onValueChanged?.call(result);
                }
              },
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: PencilIcon(
              width: 16,
              height: 16,
              color: Theme.of(context).extension<StackColors>()!.textDark,
            ),
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: onPressedOverride ??
            () async {
              final result = await Navigator.of(context).pushNamed(
                SingleFieldEditView.routeName,
                arguments: Tuple2(
                  editValue!,
                  editLabel!,
                ),
              );
              if (result is String && result != editValue!) {
                onValueChanged?.call(result);
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
}
