import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';
import 'package:stackwallet/utilities/theme/dark_colors.dart';
import 'package:stackwallet/utilities/theme/light_colors.dart';

class StackTheme {
  StackTheme._();
  static final StackTheme _instance = StackTheme._();
  static StackTheme get instance => _instance;

  late StackColorTheme color;
  late ThemeType theme;

  void setTheme(ThemeType theme) {
    this.theme = theme;
    switch (theme) {
      case ThemeType.light:
        color = LightColors();
        break;
      case ThemeType.dark:
        color = DarkColors();
        break;
    }
  }

  BoxShadow get standardBoxShadow => BoxShadow(
        color: color.shadow,
        spreadRadius: 3,
        blurRadius: 4,
      );

  ButtonStyle? getPrimaryEnabledButtonColor(BuildContext context) =>
      Theme.of(context).textButtonTheme.style?.copyWith(
            backgroundColor: MaterialStateProperty.all<Color>(
              color.buttonBackPrimary,
            ),
          );

  ButtonStyle? getPrimaryDisabledButtonColor(BuildContext context) =>
      Theme.of(context).textButtonTheme.style?.copyWith(
            backgroundColor: MaterialStateProperty.all<Color>(
              color.buttonBackPrimaryDisabled,
            ),
          );

  ButtonStyle? getSecondaryEnabledButtonColor(BuildContext context) =>
      Theme.of(context).textButtonTheme.style?.copyWith(
            backgroundColor: MaterialStateProperty.all<Color>(
              color.buttonBackSecondary,
            ),
          );

  ButtonStyle? getSmallSecondaryEnabledButtonColor(BuildContext context) =>
      Theme.of(context).textButtonTheme.style?.copyWith(
            backgroundColor: MaterialStateProperty.all<Color>(
              color.textFieldDefaultBG,
            ),
          );

  ButtonStyle? getDesktopMenuButtonColor(BuildContext context) =>
      Theme.of(context).textButtonTheme.style?.copyWith(
            backgroundColor: MaterialStateProperty.all<Color>(
              color.popupBG,
            ),
          );

  ButtonStyle? getDesktopMenuButtonColorSelected(BuildContext context) =>
      Theme.of(context).textButtonTheme.style?.copyWith(
            backgroundColor: MaterialStateProperty.all<Color>(
              color.textFieldDefaultBG,
            ),
          );
}
