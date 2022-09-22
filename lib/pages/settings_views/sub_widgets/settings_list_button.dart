import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';

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
      // splashColor: StackTheme.instance.color.highlight,
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
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: StackTheme.instance.color.buttonBackSecondary,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Center(
                    child: SvgPicture.asset(
                      iconAssetName,
                      color: StackTheme.instance.color.accentColorDark,
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
                style: STextStyles.smallMed14.copyWith(
                  color: StackTheme.instance.color.accentColorDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
