import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';

class LightColors extends StackColorTheme {
  @override
  ThemeType get themeType => ThemeType.light;

  @override
  Color get background =>
      const Color(0xFFF7F7F7); //change this to background svg
  @override
  Color get backgroundAppBar => background;
  @override
  Gradient? get gradientBackground => null;

  @override
  Color get overlay => const Color(0xFF111215);

  @override
  Color get accentColorBlue => const Color(0xFF1276EB);
  @override
  Color get accentColorGreen => const Color(0xFF00A578);
  @override
  Color get accentColorYellow => const Color(0xFFFDC800);
  @override
  Color get accentColorRed => const Color(0xFFDD5869);
  @override
  Color get accentColorOrange => const Color(0xFFF8894B);
  @override
  Color get accentColorDark => const Color(0xFFF95369);

  @override
  Color get shadow => const Color(0x0F2D3132);

  @override
  Color get textDark => const Color(0xFF232323);
  @override
  Color get textDark2 => const Color(0xFF333333);
  @override
  Color get textDark3 => const Color(0xFF696B6C);
  @override
  Color get textSubtitle1 => const Color(0xFF7E8284);
  @override
  Color get textSubtitle2 => const Color(0xFF8E9192);
  @override
  Color get textSubtitle3 => const Color(0xFFB0B2B2);
  @override
  Color get textSubtitle4 => const Color(0xFFD1D3D3);
  @override
  Color get textSubtitle5 => const Color(0xFFDEDFE1);
  @override
  Color get textSubtitle6 => const Color(0xFFF1F1F1);
  @override
  Color get textWhite => const Color(0xFFFFFFFF);
  @override
  Color get textFavoriteCard => const Color(0xFF232323);
  @override
  Color get textError => const Color(0xFFA8000C);
  @override
  Color get textRestore => overlay;

  // button background
  @override
  Color get buttonBackPrimary => const Color(0xFFF95369);
  @override
  Color get buttonBackSecondary => const Color(0xFFFDCBD2);
  @override
  Color get buttonBackPrimaryDisabled => const Color(0xFFFDC3CB);
  @override
  Color get buttonBackSecondaryDisabled => const Color(0xFFFEEAED);
  @override
  Color get buttonBackBorder => const Color(0xFFF95369);
  @override
  Color get buttonBackBorderDisabled => const Color(0xFFFCA7B3);

  @override
  Color get numberBackDefault => const Color(0xFFFFF8EE);
  @override
  Color get numpadBackDefault => const Color(0xFFF95369);
  @override
  Color get bottomNavBack => const Color(0xFFFFFFFF);

  // button text/element
  @override
  Color get buttonTextPrimary => const Color(0xFFFFFFFF);
  @override
  Color get buttonTextSecondary => const Color(0xFF9D3241);
  @override
  Color get buttonTextPrimaryDisabled => const Color(0xFFFFFFFF);
  @override
  Color get buttonTextSecondaryDisabled => const Color(0xFFD8ADB3);
  @override
  Color get buttonTextBorder => const Color(0xFFF95369);
  @override
  Color get buttonTextDisabled => const Color(0xFFFFFFFF);
  @override
  Color get buttonTextBorderless => const Color(0xFFF95369);
  @override
  Color get buttonTextBorderlessDisabled => const Color(0xFFFFFFFF);
  @override
  Color get numberTextDefault => const Color(0xFF232323);
  @override
  Color get numpadTextDefault => const Color(0xFFFFFFFF);
  @override
  Color get bottomNavText => const Color(0xFFD12B41);

  // switch
  @override
  Color get switchBGOn => const Color(0xFFF95369);
  @override
  Color get switchBGOff => const Color(0xFFFCADB2);
  @override
  Color get switchBGDisabled => const Color(0xFFC5C6C9);
  @override
  Color get switchCircleOn => const Color(0xFFFFEEF0);
  @override
  Color get switchCircleOff => const Color(0xFFFFFCF5);
  @override
  Color get switchCircleDisabled => const Color(0xFFFFFCF5);

  // step indicator background
  @override
  Color get stepIndicatorBGCheck => const Color(0xFFFFC6AE);
  @override
  Color get stepIndicatorBGNumber => const Color(0xFFFFC6AE);
  @override
  Color get stepIndicatorBGInactive => const Color(0xFFBFBFBF);
  @override
  Color get stepIndicatorBGLines => const Color(0xFFF39774);
  @override
  Color get stepIndicatorBGLinesInactive => const Color(0xFFB3B3B3);
  @override
  Color get stepIndicatorIconText => const Color(0xFFE12F09);
  @override
  Color get stepIndicatorIconNumber => const Color(0xFFE12F09);
  @override
  Color get stepIndicatorIconInactive => const Color(0xFFFFCFBA);

  // checkbox
  @override
  Color get checkboxBGChecked => const Color(0xFFF95369);
  @override
  Color get checkboxBorderEmpty => const Color(0xFF8C8F90);
  @override
  Color get checkboxBGDisabled => const Color(0xFFFDB0AE);
  @override
  Color get checkboxIconChecked => const Color(0xFFFFFFFF);
  @override
  Color get checkboxIconDisabled => const Color(0xFFFFFFFF);
  @override
  Color get checkboxTextLabel => const Color(0xFF232323);

  // snack bar
  @override
  Color get snackBarBackSuccess => const Color(0xFFB7F0CC);
  @override
  Color get snackBarBackError => const Color(0xFFFCBDBA);
  @override
  Color get snackBarBackInfo => const Color(0xFFDAE2FF);
  @override
  Color get snackBarTextSuccess => const Color(0xFF2E7356);
  @override
  Color get snackBarTextError => const Color(0xFFBC0D20);
  @override
  Color get snackBarTextInfo => const Color(0xFF143E8C);

  // icons
  @override
  Color get bottomNavIconBack => const Color(0xFFFDBAC3);
  @override
  Color get bottomNavIconIcon => const Color(0xFFD12B41);

  @override
  Color get topNavIconPrimary => const Color(0xFFF95369);
  @override
  Color get topNavIconGreen => const Color(0xFF00A578);
  @override
  Color get topNavIconYellow => const Color(0xFFF8894B);
  @override
  Color get topNavIconRed => const Color(0xFFD91B1B);

  @override
  Color get settingsIconBack => const Color(0xFFFED7CA);
  @override
  Color get settingsIconIcon => const Color(0xFFF95369);
  @override
  Color get settingsIconBack2 => const Color(0xFF80D2BB);
  @override
  Color get settingsIconElement => const Color(0xFF00A578);

  // text field
  @override
  Color get textFieldActiveBG => const Color(0xFFFFFBF6);
  @override
  Color get textFieldDefaultBG => const Color(0xFFFFF8EE);
  @override
  Color get textFieldErrorBG => const Color(0xFFFCBDBA);
  @override
  Color get textFieldSuccessBG => const Color(0xFFB7F0CC);
  @override
  Color get textFieldErrorBorder => textFieldErrorBG;
  @override
  Color get textFieldSuccessBorder => textFieldSuccessBG;

  @override
  Color get textFieldActiveSearchIconLeft => const Color(0xFF86898C);
  @override
  Color get textFieldDefaultSearchIconLeft => const Color(0xFF9A9DA0);
  @override
  Color get textFieldErrorSearchIconLeft => const Color(0xFFBC0D20);
  @override
  Color get textFieldSuccessSearchIconLeft => const Color(0xFF387D60);

  @override
  Color get textFieldActiveText => const Color(0xFF232323);
  @override
  Color get textFieldDefaultText => const Color(0xFF86898C);
  @override
  Color get textFieldErrorText => const Color(0xFF232323);
  @override
  Color get textFieldSuccessText => const Color(0xFF232323);

  @override
  Color get textFieldActiveLabel => const Color(0xFF86898C);
  @override
  Color get textFieldErrorLabel => const Color(0xFFBC0D20);
  @override
  Color get textFieldSuccessLabel => const Color(0xFF387D60);

  @override
  Color get textFieldActiveSearchIconRight => const Color(0xFFF95369);
  @override
  Color get textFieldDefaultSearchIconRight => const Color(0xFFF95369);
  @override
  Color get textFieldErrorSearchIconRight => const Color(0xFFBC0D20);
  @override
  Color get textFieldSuccessSearchIconRight => const Color(0xFF387D60);

  // settings item level2
  @override
  Color get settingsItem2ActiveBG => const Color(0xFFFFFFFF);
  @override
  Color get settingsItem2ActiveText => const Color(0xFF232323);
  @override
  Color get settingsItem2ActiveSub => const Color(0xFFFED7CA);

  // radio buttons
  @override
  Color get radioButtonIconBorder => const Color(0xFFF95369);
  @override
  Color get radioButtonIconBorderDisabled => const Color(0xFF8C8D97);
  @override
  Color get radioButtonBorderEnabled => const Color(0xFFF95369);
  @override
  Color get radioButtonBorderDisabled => const Color(0xFF8C8D97);
  @override
  Color get radioButtonIconCircle => const Color(0xFFF95369);
  @override
  Color get radioButtonIconEnabled => const Color(0xFFF95369);
  @override
  Color get radioButtonTextEnabled => const Color(0xFF42444B);
  @override
  Color get radioButtonTextDisabled => const Color(0xFF42444B);
  @override
  Color get radioButtonLabelEnabled => const Color(0xFF8C8F90);
  @override
  Color get radioButtonLabelDisabled => const Color(0xFF8C8F90);

  // info text
  @override
  Color get infoItemBG => const Color(0xFFFFF8EE);
  @override
  Color get infoItemLabel => const Color(0xFF838788);
  @override
  Color get infoItemText => const Color(0xFF232323);
  @override
  Color get infoItemIcons => const Color(0xFF0A6CE1);

  // popup
  @override
  Color get popupBG => const Color(0xFFFFF8EE);

  // currency list
  @override
  Color get currencyListItemBG => const Color(0xFFFFEBE0);

  // bottom nav
  @override
  Color get stackWalletBG => const Color(0xFFFFFFFF);
  @override
  Color get stackWalletMid => const Color(0xFF666666);
  @override
  Color get stackWalletBottom => const Color(0xFF232323);
  @override
  Color get bottomNavShadow => const Color(0xFFFE7160);

  @override
  Color get favoriteStarActive => infoItemIcons;
  @override
  Color get favoriteStarInactive => textSubtitle3;

  @override
  Color get splash => const Color(0xFF8E9192);
  @override
  Color get highlight => const Color(0xFFA9ACAC);
  @override
  Color get warningForeground => textDark;
  @override
  Color get warningBackground => const Color(0xFFFCBDBA);
  @override
  Color get loadingOverlayTextColor => const Color(0xFFF7F7F7);
  @override
  Color get myStackContactIconBG => textFieldDefaultBG;
  @override
  Color get textConfirmTotalAmount => const Color(0xFF232323);
  @override
  Color get textSelectedWordTableItem => const Color(0xFF232323);
}
