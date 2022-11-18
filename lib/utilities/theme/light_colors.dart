import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';

class LightColors extends StackColorTheme {
  @override
  ThemeType get themeType => ThemeType.light;

  @override
  Color get background => const Color(0xFFF7F7F7);
  @override
  Color get overlay => const Color(0xFF111215);

  @override
  Color get accentColorBlue => const Color(0xFF0052DF);
  @override
  Color get accentColorGreen => const Color(0xFF4CC0A0);
  @override
  Color get accentColorYellow => const Color(0xFFF7D65D);
  @override
  Color get accentColorRed => const Color(0xFFD34E50);
  @override
  Color get accentColorOrange => const Color(0xFFFEA68D);
  @override
  Color get accentColorDark => const Color(0xFF232323);

  @override
  Color get shadow => const Color(0x0F2D3132);

  @override
  Color get textDark => const Color(0xFF232323);
  @override
  Color get textDark2 => const Color(0xFF414141);
  @override
  Color get textDark3 => const Color(0xFF747778);
  @override
  Color get textSubtitle1 => const Color(0xFF8E9192);
  @override
  Color get textSubtitle2 => const Color(0xFFA9ACAC);
  @override
  Color get textSubtitle3 => const Color(0xFFC4C7C7);
  @override
  Color get textSubtitle4 => const Color(0xFFE0E3E3);
  @override
  Color get textSubtitle5 => const Color(0xFFEEEFF1);
  @override
  Color get textSubtitle6 => const Color(0xFFF5F5F5);
  @override
  Color get textWhite => const Color(0xFFFFFFFF);
  @override
  Color get textFavoriteCard => const Color(0xFF232323);
  @override
  Color get textError => const Color(0xFF930006);

  // button background
  @override
  Color get buttonBackPrimary => const Color(0xFF232323);
  @override
  Color get buttonBackSecondary => const Color(0xFFE0E3E3);
  @override
  Color get buttonBackPrimaryDisabled => const Color(0xFFD7D7D7);
  @override
  Color get buttonBackSecondaryDisabled => const Color(0xFFF0F1F1);
  @override
  Color get buttonBackBorder => const Color(0xFF232323);
  @override
  Color get buttonBackBorderDisabled => const Color(0xFFB6B6B6);

  @override
  Color get numberBackDefault => const Color(0xFFFFFFFF);
  @override
  Color get numpadBackDefault => const Color(0xFF232323);
  @override
  Color get bottomNavBack => const Color(0xFFFFFFFF);

  // button text/element
  @override
  Color get buttonTextPrimary => const Color(0xFFFFFFFF);
  @override
  Color get buttonTextSecondary => const Color(0xFF232323);
  @override
  Color get buttonTextPrimaryDisabled => const Color(0xFFF8F8F8);
  @override
  Color get buttonTextSecondaryDisabled => const Color(0xFFB7B7B7);
  @override
  Color get buttonTextBorder => const Color(0xFF232323);
  @override
  Color get buttonTextDisabled => const Color(0xFFB6B6B6);
  @override
  Color get buttonTextBorderless => const Color(0xFF0052DF);
  @override
  Color get buttonTextBorderlessDisabled => const Color(0xFFB6B6B6);
  @override
  Color get numberTextDefault => const Color(0xFF232323);
  @override
  Color get numpadTextDefault => const Color(0xFFFFFFFF);
  @override
  Color get bottomNavText => const Color(0xFF232323);

  // switch
  @override
  Color get switchBGOn => const Color(0xFF0052DF);
  @override
  Color get switchBGOff => const Color(0xFFD8E4FB);
  @override
  Color get switchBGDisabled => const Color(0xFFC5C6C9);
  @override
  Color get switchCircleOn => const Color(0xFFDAE2FF);
  @override
  Color get switchCircleOff => const Color(0xFFFBFCFF);
  @override
  Color get switchCircleDisabled => const Color(0xFFFBFCFF);

  // step indicator background
  @override
  Color get stepIndicatorBGCheck => const Color(0xFFD9E2FF);
  @override
  Color get stepIndicatorBGNumber => const Color(0xFFD9E2FF);
  @override
  Color get stepIndicatorBGInactive => const Color(0xFFCDCDCD);
  @override
  Color get stepIndicatorBGLines => const Color(0xFF0056D2);
  @override
  Color get stepIndicatorBGLinesInactive => const Color(0xFFCDCDCD);
  @override
  Color get stepIndicatorIconText => const Color(0xFF0056D2);
  @override
  Color get stepIndicatorIconNumber => const Color(0xFF0056D2);
  @override
  Color get stepIndicatorIconInactive => const Color(0xFFF7F7F7);

  // checkbox
  @override
  Color get checkboxBGChecked => const Color(0xFF0056D2);
  @override
  Color get checkboxBorderEmpty => const Color(0xFF8E9192);
  @override
  Color get checkboxBGDisabled => const Color(0xFFADC7EC);
  @override
  Color get checkboxIconChecked => const Color(0xFFFFFFFF);
  @override
  Color get checkboxIconDisabled => const Color(0xFFFFFFFF);
  @override
  Color get checkboxTextLabel => const Color(0xFF232323);

  // snack bar
  @override
  Color get snackBarBackSuccess => const Color(0xFFB9E9D4);
  @override
  Color get snackBarBackError => const Color(0xFFFFDAD4);
  @override
  Color get snackBarBackInfo => const Color(0xFFDAE2FF);
  @override
  Color get snackBarTextSuccess => const Color(0xFF006C4D);
  @override
  Color get snackBarTextError => const Color(0xFF930006);
  @override
  Color get snackBarTextInfo => const Color(0xFF002A78);

  // icons
  @override
  Color get bottomNavIconBack => const Color(0xFFA2A2A2);
  @override
  Color get bottomNavIconIcon => const Color(0xFF232323);

  @override
  Color get topNavIconPrimary => const Color(0xFF232323);
  @override
  Color get topNavIconGreen => const Color(0xFF00A578);
  @override
  Color get topNavIconYellow => const Color(0xFFF4C517);
  @override
  Color get topNavIconRed => const Color(0xFFC00205);

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
  Color get textFieldActiveBG => const Color(0xFFEEEFF1);
  @override
  Color get textFieldDefaultBG => const Color(0xFFEEEFF1);
  @override
  Color get textFieldErrorBG => const Color(0xFFFFDAD4);
  @override
  Color get textFieldSuccessBG => const Color(0xFFB9E9D4);

  @override
  Color get textFieldActiveSearchIconLeft => const Color(0xFFA9ACAC);
  @override
  Color get textFieldDefaultSearchIconLeft => const Color(0xFFA9ACAC);
  @override
  Color get textFieldErrorSearchIconLeft => const Color(0xFF930006);
  @override
  Color get textFieldSuccessSearchIconLeft => const Color(0xFF006C4D);

  @override
  Color get textFieldActiveText => const Color(0xFF232323);
  @override
  Color get textFieldDefaultText => const Color(0xFFA9ACAC);
  @override
  Color get textFieldErrorText => const Color(0xFF000000);
  @override
  Color get textFieldSuccessText => const Color(0xFF000000);

  @override
  Color get textFieldActiveLabel => const Color(0xFFA9ACAC);
  @override
  Color get textFieldErrorLabel => const Color(0xFF930006);
  @override
  Color get textFieldSuccessLabel => const Color(0xFF006C4D);

  @override
  Color get textFieldActiveSearchIconRight => const Color(0xFF747778);
  @override
  Color get textFieldDefaultSearchIconRight => const Color(0xFF747778);
  @override
  Color get textFieldErrorSearchIconRight => const Color(0xFF930006);
  @override
  Color get textFieldSuccessSearchIconRight => const Color(0xFF006C4D);

  // settings item level2
  @override
  Color get settingsItem2ActiveBG => const Color(0xFFFFFFFF);
  @override
  Color get settingsItem2ActiveText => const Color(0xFF232323);
  @override
  Color get settingsItem2ActiveSub => const Color(0xFF8E9192);

  // radio buttons
  @override
  Color get radioButtonIconBorder => const Color(0xFF0056D2);
  @override
  Color get radioButtonIconBorderDisabled => const Color(0xFF8F909A);
  @override
  Color get radioButtonBorderEnabled => const Color(0xFF0056D2);
  @override
  Color get radioButtonBorderDisabled => const Color(0xFF8F909A);
  @override
  Color get radioButtonIconCircle => const Color(0xFF0056D2);
  @override
  Color get radioButtonIconEnabled => const Color(0xFF0056D2);
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
  Color get infoItemBG => const Color(0xFFFFFFFF);
  @override
  Color get infoItemLabel => const Color(0xFF8E9192);
  @override
  Color get infoItemText => const Color(0xFF232323);
  @override
  Color get infoItemIcons => const Color(0xFF0056D2);

  // popup
  @override
  Color get popupBG => const Color(0xFFFFFFFF);

  // currency list
  @override
  Color get currencyListItemBG => const Color(0xFFF9F9FC);

  // bottom nav
  @override
  Color get stackWalletBG => const Color(0xFFFFFFFF);
  @override
  Color get stackWalletMid => const Color(0xFFFFFFFF);
  @override
  Color get stackWalletBottom => const Color(0xFF232323);
  @override
  Color get bottomNavShadow => const Color(0xFF282E33);

  @override
  Color get favoriteStarActive => infoItemIcons;
  @override
  Color get favoriteStarInactive => textSubtitle3;

  @override
  Color get splash => const Color(0x358E9192);
  @override
  Color get highlight => const Color(0x44A9ACAC);
  @override
  Color get warningForeground => textDark;
  @override
  Color get warningBackground => const Color(0xFFFFDAD3);
  @override
  Color get loadingOverlayTextColor => const Color(0xFFF7F7F7);
  @override
  Color get myStackContactIconBG => textFieldDefaultBG;
  @override
  Color get textConfirmTotalAmount => const Color(0xFF232323);
  @override
  Color get textSelectedWordTableItem => const Color(0xFF232323);
}
