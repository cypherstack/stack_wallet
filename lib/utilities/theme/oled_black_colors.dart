import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';

class OledBlackColors extends StackColorTheme {
  @override
  ThemeType get themeType => ThemeType.oledBlack;

  @override
  Color get background => const Color(0xFF000000);
  @override
  Color get backgroundAppBar => background;
  @override
  Gradient? get gradientBackground => null;

  @override
  Color get overlay => const Color(0xFF121212);

  @override
  Color get accentColorBlue => const Color(0xFFF26822);
  @override
  Color get accentColorGreen => const Color(0xFF4CC0A0);
  @override
  Color get accentColorYellow => const Color(0xFFD4A51E);
  @override
  Color get accentColorRed => const Color(0xFFD34E50);
  @override
  Color get accentColorOrange => const Color(0xFFDE7456);
  //accent color white (0xFFDEDEDE)
  @override
  Color get accentColorDark => const Color(0xFFDEDEDE);

  @override
  Color get shadow => const Color(0x0F2D3132); //not done yet

  @override
  Color get textDark => const Color(0xFFDEDEDE);
  @override
  Color get textDark2 => const Color(0xFFCCCCCC);
  @override
  Color get textDark3 => const Color(0xFFB2B2B2);
  @override
  Color get textSubtitle1 => const Color(0xFFB2B2B2);
  @override
  Color get textSubtitle2 => const Color(0xFFA0A0A0);
  @override
  Color get textSubtitle3 => const Color(0xFF878A8A);
  @override
  Color get textSubtitle4 => const Color(0xFF878A8A);
  @override
  Color get textSubtitle5 => const Color(0xFF878A8A);
  @override
  Color get textSubtitle6 => const Color(0xFF878A8A);
  @override
  Color get textWhite => const Color(0xFF242424);
  @override
  Color get textFavoriteCard => const Color(0xFF232323);
  @override
  Color get textError => const Color(0xFFCF6679);
  @override
  Color get textRestore => textDark;

  // button background
  @override
  Color get buttonBackPrimary => const Color(0xFFF26822);
  @override
  Color get buttonBackSecondary => const Color(0xFF1F1F1F);
  @override
  Color get buttonBackPrimaryDisabled => const Color(0xFF491F0A);
  @override
  Color get buttonBackSecondaryDisabled => const Color(0xFF0F0F0F);
  @override
  Color get buttonBackBorder => const Color(0xFFF26822);
  @override
  Color get buttonBackBorderDisabled => const Color(0xFF491F0A);
  @override
  Color get buttonBackBorderSecondary => buttonBackSecondary;
  @override
  Color get buttonBackBorderSecondaryDisabled => buttonBackSecondaryDisabled;

  @override
  Color get numberBackDefault => const Color(0xFF242424);
  @override
  Color get numpadBackDefault => const Color(0xFFF26822);
  @override
  Color get bottomNavBack => const Color(0xFF202122);

  // button text/element
  @override
  Color get buttonTextPrimary => const Color(0xFF000000);
  @override
  Color get buttonTextSecondary => const Color(0xFFDEDEDE);
  @override
  Color get buttonTextPrimaryDisabled => const Color(0xFF000000);
  @override
  Color get buttonTextSecondaryDisabled => const Color(0xFF6F6F6F);
  @override
  Color get buttonTextBorder => const Color(0xFFF26822);
  @override
  Color get buttonTextDisabled => const Color(0xFF000000);
  @override
  Color get buttonTextBorderless => const Color(0xFFF26822);
  @override
  Color get buttonTextBorderlessDisabled => const Color(0xFF491F0A);
  @override
  Color get numberTextDefault => const Color(0xFFD3D3D3);
  @override
  Color get numpadTextDefault => const Color(0xFF000000);
  @override
  Color get bottomNavText => const Color(0xFFDEDEDE);

  // switch
  @override
  Color get switchBGOn => const Color(0xFFF26822);
  @override
  Color get switchBGOff => const Color(0xFF403F3F);
  @override
  Color get switchBGDisabled => const Color(0xFF333538);
  @override
  Color get switchCircleOn => const Color(0xFFFFE8DC);
  @override
  Color get switchCircleOff => const Color(0xFFFAF6F3);
  @override
  Color get switchCircleDisabled => const Color(0xFF848484);

  // step indicator background
  @override
  Color get stepIndicatorBGCheck => const Color(0xFFF26822);
  @override
  Color get stepIndicatorBGNumber => const Color(0xFFF26822);
  @override
  Color get stepIndicatorBGInactive => const Color(0xFF3B3F46);
  @override
  Color get stepIndicatorBGLines => const Color(0xFFF26822);
  @override
  Color get stepIndicatorBGLinesInactive => const Color(0xFF63676E);
  @override
  Color get stepIndicatorIconText => const Color(0xFF000000);
  @override
  Color get stepIndicatorIconNumber => const Color(0xFF000000);
  @override
  Color get stepIndicatorIconInactive => const Color(0xFFAFAFAF);

  // checkbox
  @override
  Color get checkboxBGChecked => const Color(0xFFF26822);
  @override
  Color get checkboxBorderEmpty => const Color(0xFF66696A);
  @override
  Color get checkboxBGDisabled => const Color(0xFF783818);
  @override
  Color get checkboxIconChecked => const Color(0xFF000000);
  @override
  Color get checkboxIconDisabled => const Color(0xFF000000);
  @override
  Color get checkboxTextLabel => const Color(0xFFDEDEDE);

  // snack bar
  @override
  Color get snackBarBackSuccess => const Color(0xFF1F1F1F);
  @override
  Color get snackBarBackError => const Color(0xFF1F1F1F);
  @override
  Color get snackBarBackInfo => const Color(0xFF1F1F1F);
  @override
  Color get snackBarTextSuccess => const Color(0xFF69C297);
  @override
  Color get snackBarTextError => const Color(0xFFCF6679);
  @override
  Color get snackBarTextInfo => const Color(0xFFABAEFF);

  // icons
  @override
  Color get bottomNavIconBack => const Color(0xFF69696A);
  @override
  Color get bottomNavIconIcon => const Color(0xFFDEDEDE);

  @override
  Color get topNavIconPrimary => const Color(0xFFDEDEDE);
  @override
  Color get topNavIconGreen => const Color(0xFF4CC0A0);
  @override
  Color get topNavIconYellow => const Color(0xFFD4A51E);
  @override
  Color get topNavIconRed => const Color(0xFFD34E50);

  @override
  Color get settingsIconBack => const Color(0xFFDEDEDE);
  @override
  Color get settingsIconIcon => const Color(0xFF232323);
  @override
  Color get settingsIconBack2 => const Color(0xFF94D6C4);
  @override
  Color get settingsIconElement => const Color(0xFF4CC0A0);

  // text field
  @override
  Color get textFieldActiveBG => const Color(0xFF232323);
  @override
  Color get textFieldDefaultBG => const Color(0xFF171717);
  @override
  Color get textFieldErrorBG => const Color(0xFF141414);
  @override
  Color get textFieldSuccessBG => const Color(0xFF141414);
  //add border color vars here
  @override
  Color get textFieldErrorBorder => const Color(0xFFCF6679);
  @override
  Color get textFieldSuccessBorder => const Color(0xFF23CFA1);

  @override
  Color get textFieldActiveSearchIconLeft => const Color(0xFF9C9C9C);
  @override
  Color get textFieldDefaultSearchIconLeft => const Color(0xFF979797);
  @override
  Color get textFieldErrorSearchIconLeft => const Color(0xFFCF6679);
  @override
  Color get textFieldSuccessSearchIconLeft => const Color(0xFF23CFA1);

  @override
  Color get textFieldActiveText => const Color(0xFFC2C2C2);
  @override
  Color get textFieldDefaultText => const Color(0xFF979797);
  @override
  Color get textFieldErrorText => const Color(0xFFCF6679);
  @override
  Color get textFieldSuccessText => const Color(0xFFDEDEDE);

  @override
  Color get textFieldActiveLabel => const Color(0xFF979797);
  @override
  Color get textFieldErrorLabel => const Color(0xFFCF6679);
  @override
  Color get textFieldSuccessLabel => const Color(0xFF69C297);

  @override
  Color get textFieldActiveSearchIconRight => const Color(0xFF9C9C9C);
  @override
  Color get textFieldDefaultSearchIconRight => const Color(0xFF5D5D5D);
  @override
  Color get textFieldErrorSearchIconRight => const Color(0xFFCF6679);
  @override
  Color get textFieldSuccessSearchIconRight => const Color(0xFF69C297);

  // settings item level2
  @override
  Color get settingsItem2ActiveBG => const Color(0xFF242424);
  @override
  Color get settingsItem2ActiveText => const Color(0xFFD3D3D3);
  @override
  Color get settingsItem2ActiveSub => const Color(0xFFB2B2B2);

  // radio buttons
  @override
  Color get radioButtonIconBorder => const Color(0xFFF26822);
  @override
  Color get radioButtonIconBorderDisabled => const Color(0xFF7D7D7D);
  @override
  Color get radioButtonBorderEnabled => const Color(0xFFF26822);
  @override
  Color get radioButtonBorderDisabled => const Color(0xFF7D7D7D);
  @override
  Color get radioButtonIconCircle => const Color(0xFFF26822);
  @override
  Color get radioButtonIconEnabled => const Color(0xFFF26822);
  @override
  Color get radioButtonTextEnabled => const Color(0xFFA8AAB2);
  @override
  Color get radioButtonTextDisabled => const Color(0xFFA8AAB2);
  @override
  Color get radioButtonLabelEnabled => const Color(0xFF878A8A);
  @override
  Color get radioButtonLabelDisabled => const Color(0xFF878A8A);

  // info text
  @override
  Color get infoItemBG => const Color(0xFF141414);
  @override
  Color get infoItemLabel => const Color(0xFFB2B2B2);
  @override
  Color get infoItemText => const Color(0xFFDEDEDE);
  @override
  Color get infoItemIcons => const Color(0xFF5C94F4);

  // popup
  @override
  Color get popupBG => const Color(0xFF212121);

  // currency list
  @override
  Color get currencyListItemBG => const Color(0xFF252525);

  // bottom nav
  @override
  Color get stackWalletBG => const Color(0xFF35383D);
  @override
  Color get stackWalletMid => const Color(0xFF292D34);
  @override
  Color get stackWalletBottom => const Color(0xFF292D34);
  @override
  Color get bottomNavShadow => const Color(0xFF282E33);

  @override
  Color get favoriteStarActive => accentColorYellow;
  @override
  Color get favoriteStarInactive => textSubtitle2;

  @override
  Color get splash => const Color(0xFF7A7D7E);
  @override
  Color get highlight => const Color(0xFF878A8A);
  @override
  Color get warningForeground => snackBarTextError;
  @override
  Color get warningBackground => const Color(0xFF1F1F1F);
  @override
  Color get loadingOverlayTextColor => const Color(0xFFCFCFCF);
  @override
  Color get myStackContactIconBG => const Color(0xFF747778);
  @override
  Color get textConfirmTotalAmount => const Color(0xFF144D35);
  @override
  Color get textSelectedWordTableItem => const Color(0xFF143D8E);

  //rate type toggle
  @override
  Color get rateTypeToggleColorOn => textFieldDefaultBG;
  @override
  Color get rateTypeToggleColorOff => popupBG;
  @override
  Color get rateTypeToggleDesktopColorOn => buttonBackSecondary;
  @override
  Color get rateTypeToggleDesktopColorOff => buttonBackSecondary;

  @override
  BoxShadow get standardBoxShadow => BoxShadow(
        color: shadow,
        spreadRadius: 3,
        blurRadius: 4,
      );

  @override
  BoxShadow? get homeViewButtonBarBoxShadow => BoxShadow(
        color: shadow,
        spreadRadius: 3,
        blurRadius: 4,
      );
}
