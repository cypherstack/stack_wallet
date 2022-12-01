import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SettingsListButton extends StatelessWidget {
  const SettingsListButton({
    Key? key,
    required this.iconAssetName,
    required this.title,
    this.onPressed,
    this.iconSize = 20.0,
  }) : super(key: key);

  final String iconAssetName;
  final String title;
  final VoidCallback? onPressed;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
      constraints: const BoxConstraints(
        minHeight: 32,
        minWidth: 32,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          Constants.size.circularBorderRadius,
        ),
      ),
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).extension<StackColors>()!.background,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Center(
                    child: SvgPicture.asset(
                      iconAssetName,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorDark,
                      width: iconSize,
                      height: iconSize,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Text(
                title,
                style: STextStyles.smallMed14(context).copyWith(
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .accentColorDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
