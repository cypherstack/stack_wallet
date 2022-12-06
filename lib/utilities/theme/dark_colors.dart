import 'dart:ui';

import 'package:epicmobile/utilities/theme/color_theme.dart';
import 'package:flutter/material.dart';

class DarkColors extends StackColorTheme {
  @override
  ThemeType get themeType => ThemeType.dark;

  @override
  Color get background => Colors.transparent;
  @override
  Color get backgroundAppBar => background;
  @override
  Gradient? get gradientBackground => const LinearGradient(
        colors: [
          Color(0xFF121215),
          Color(0xFF222227),
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      );

  @override
  Color get overlay => const Color(0xFF111215);

  @override
  Color get accentColorBlue => const Color(0xFFD1A55C);
  @override
  Color get accentColorGreen => const Color(0xFF66B196);
  @override
  Color get accentColorYellow => const Color(0xFFD1A55C);
  @override
  Color get accentColorRed => const Color(0xFFFC718A);
  @override
  Color get accentColorOrange => const Color(0xFFFEA68D);
  @override
  Color get accentColorDark => const Color(0xFFF3F3F3);

  @override
  Color get shadow => const Color(0x0F2D3132);

  @override
  Color get textLight => const Color(0xFFE2E2E3);
  @override
  Color get textMedium => const Color(0xFFBABABC);
  @override
  Color get textDark => const Color(0xFF767679);
  @override
  Color get textSubtitle1 => const Color(0xFF9E9E9E);
  @override
  Color get textSubtitle2 => const Color(0xFF969696);
  @override
  Color get textSubtitle3 => const Color(0xFFA9ACAC);
  @override
  Color get textSubtitle4 => const Color(0xFF8E9192);
  @override
  Color get textSubtitle5 => const Color(0xFF747778);
  @override
  Color get textSubtitle6 => const Color(0xFF414141);
  @override
  Color get coal => const Color(0xFF343338);
  @override
  Color get textGold => const Color(0xFFD1A55C);
  @override
  Color get textError => const Color(0xFFF37475);

  // button background
  @override
  Color get buttonBackPrimary => const Color(0xFFD1A55C);
  @override
  Color get buttonBackSecondary => const Color(0xFF121215);
  @override
  Color get buttonBackPrimaryDisabled => const Color(0xFF38517C);
  @override
  Color get buttonBackSecondaryDisabled => const Color(0xFF3B3F46);
  @override
  Color get buttonBackBorder => const Color(0xFFD1A55C);
  @override
  Color get buttonBackBorderDisabled => const Color(0xFF314265);

  @override
  Color get numberBackDefault => const Color(0xFF222227);
  @override
  Color get numpadBackDefault => const Color(0xFF222227);
  @override
  Color get bottomNavBack => const Color(0xFF3E4148);

  // button text/element
  @override
  Color get buttonTextPrimary => const Color(0xFF121215);
  @override
  Color get buttonTextSecondary => const Color(0xFFD1A55C);
  @override
  Color get buttonTextPrimaryDisabled => const Color(0xFF121215);
  @override
  Color get buttonTextSecondaryDisabled => const Color(0xFFD1A55C);
  @override
  Color get buttonTextBorder => const Color(0xFFD1A55C);
  @override
  Color get buttonTextDisabled => const Color(0xFF314265);
  @override
  Color get buttonTextBorderless => const Color(0xFFD1A55C);
  @override
  Color get buttonTextBorderlessDisabled => const Color(0xFFD1A55C);
  @override
  Color get numberTextDefault => const Color(0xFFFFFFFF);
  @override
  Color get numpadTextDefault => const Color(0xFFFFFFFF);
  @override
  Color get bottomNavText => const Color(0xFFFFFFFF);

  // switch
  @override
  Color get switchBGOn => const Color(0xFFD1A55C);
  @override
  Color get switchBGOff => coal;
  @override
  Color get switchBGDisabled => popupBG;
  @override
  Color get switchCircleOn => textLight;
  @override
  Color get switchCircleOff => textMedium;
  @override
  Color get switchCircleDisabled => textDark;

  // step indicator background
  @override
  Color get stepIndicatorBGCheck => const Color(0xFFD1A55C);
  @override
  Color get stepIndicatorBGNumber => const Color(0xFFD1A55C);
  @override
  Color get stepIndicatorBGInactive => const Color(0xFF3B3F46);
  @override
  Color get stepIndicatorBGLines => const Color(0xFFD1A55C);
  @override
  Color get stepIndicatorBGLinesInactive => const Color(0xFF3B3F46);
  @override
  Color get stepIndicatorIconText => const Color(0xFFFFFFFF);
  @override
  Color get stepIndicatorIconNumber => const Color(0xFFFFFFFF);
  @override
  Color get stepIndicatorIconInactive => const Color(0xFF747474);

  // checkbox
  @override
  Color get checkboxBGChecked => const Color(0xFFD1A55C);
  @override
  Color get checkboxBorderEmpty => const Color(0xFF8E9192);
  @override
  Color get checkboxBGDisabled => const Color(0xFFADC7EC);
  @override
  Color get checkboxIconChecked => const Color(0xFFFFFFFF);
  @override
  Color get checkboxIconDisabled => const Color(0xFFFFFFFF);
  @override
  Color get checkboxTextLabel => const Color(0xFFFFFFFF);

  // snack bar
  @override
  Color get snackBarBackSuccess => const Color(0xFF8EF5C3);
  @override
  Color get snackBarBackError => const Color(0xFFFFB4A9);
  @override
  Color get snackBarBackInfo => const Color(0xFFB4C4FF);
  @override
  Color get snackBarTextSuccess => const Color(0xFF003921);
  @override
  Color get snackBarTextError => const Color(0xFFFC718A);
  @override
  Color get snackBarTextInfo => const Color(0xFF00297A);

  // icons
  @override
  Color get bottomNavIconBack => const Color(0xFF7F8185);
  @override
  Color get bottomNavIconIcon => const Color(0xFFFFFFFF);

  @override
  Color get topNavIconPrimary => const Color(0xFFBABABC);
  @override
  Color get topNavIconGreen => const Color(0xFF4CC0A0);
  @override
  Color get topNavIconYellow => const Color(0xFFF7D65D);
  @override
  Color get topNavIconRed => const Color(0xFFD34E50);

  @override
  Color get settingsIconBack => const Color(0xFFE0E3E3);
  @override
  Color get settingsIconIcon => const Color(0xFF232323);
  @override
  Color get settingsIconBack2 => const Color(0xFF94D6C4);
  @override
  Color get settingsIconElement => const Color(0xFF00A578);

  // text field
  @override
  Color get textFieldActiveBG => const Color(0xFF4C5360);
  @override
  Color get textFieldDefaultBG => const Color(0xFF444953);
  @override
  Color get textFieldErrorBG => const Color(0xFFFFB4A9);
  @override
  Color get textFieldSuccessBG => const Color(0xFF8EF5C3);

  @override
  Color get textFieldActiveSearchIconLeft => const Color(0xFFA9ACAC);
  @override
  Color get textFieldDefaultSearchIconLeft => const Color(0xFFA9ACAC);
  @override
  Color get textFieldErrorSearchIconLeft => const Color(0xFFFC718A);
  @override
  Color get textFieldSuccessSearchIconLeft => const Color(0xFF003921);

  @override
  Color get textFieldActiveText => const Color(0xFFFFFFFF);
  @override
  Color get textFieldDefaultText => const Color(0xFFA9ACAC);
  @override
  Color get textFieldErrorText => const Color(0xFF000000);
  @override
  Color get textFieldSuccessText => const Color(0xFF000000);

  @override
  Color get textFieldActiveLabel => const Color(0xFFA9ACAC);
  @override
  Color get textFieldErrorLabel => const Color(0xFFFC718A);
  @override
  Color get textFieldSuccessLabel => const Color(0xFF003921);

  @override
  Color get textFieldActiveSearchIconRight => textMedium;
  @override
  Color get textFieldDefaultSearchIconRight => const Color(0xFF747778);
  @override
  Color get textFieldErrorSearchIconRight => const Color(0xFFFC718A);
  @override
  Color get textFieldSuccessSearchIconRight => const Color(0xFF003921);

  // settings item level2
  @override
  Color get settingsItem2ActiveBG => const Color(0xFF484B51);
  @override
  Color get settingsItem2ActiveText => const Color(0xFFFFFFFF);
  @override
  Color get settingsItem2ActiveSub => const Color(0xFF9E9E9E);

  // radio buttons
  @override
  Color get radioButtonIconBorder => const Color(0xFFD1A55C);
  @override
  Color get radioButtonIconBorderDisabled => const Color(0xFF9E9E9E);
  @override
  Color get radioButtonBorderEnabled => const Color(0xFFD1A55C);
  @override
  Color get radioButtonBorderDisabled => const Color(0xFFCDCDCD);
  @override
  Color get radioButtonIconCircle => const Color(0xFF9E9E9E);
  @override
  Color get radioButtonIconEnabled => const Color(0xFFD1A55C);
  @override
  Color get radioButtonTextEnabled => const Color(0xFF44464E);
  @override
  Color get radioButtonTextDisabled => const Color(0xFF44464E);
  @override
  Color get radioButtonLabelEnabled => const Color(0xFF8E9192);
  @override
  Color get radioButtonLabelDisabled => const Color(0xFF8E9192);

  // info text
  @override
  Color get infoItemBG => const Color(0xFF333942);
  @override
  Color get infoItemLabel => const Color(0xFF9E9E9E);
  @override
  Color get infoItemText => const Color(0xFFFFFFFF);
  @override
  Color get infoItemIcons => const Color(0xFFD1A55C);

  // popup
  @override
  Color get popupBG => const Color(0xFF222227);

  // currency list
  @override
  Color get currencyListItemBG => const Color(0xFF484B51);

  // bottom nav
  @override
  Color get epicmobileBG => const Color(0xFF35383D);
  @override
  Color get epicmobileMid => const Color(0xFF292D34);
  @override
  Color get epicmobileBottom => const Color(0xFFFFFFFF);
  @override
  Color get bottomNavShadow => const Color(0xFF282E33);

  @override
  Color get favoriteStarActive => accentColorYellow;
  @override
  Color get favoriteStarInactive => textSubtitle2;

  @override
  Color get splash => const Color(0x358E9192);
  @override
  Color get highlight => const Color(0x44A9ACAC);
  @override
  Color get warningForeground => snackBarTextError;
  @override
  Color get warningBackground => const Color(0xFFFFB4A9);
  @override
  Color get loadingOverlayTextColor => const Color(0xFFF7F7F7);
  @override
  Color get myStackContactIconBG => const Color(0x88747778);
  @override
  Color get textConfirmTotalAmount => const Color(0xFF003921);
  @override
  Color get textSelectedWordTableItem => const Color(0xFF00297A);
}
