import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';

class ForestColors extends StackColorTheme {
  @override
  ThemeType get themeType => ThemeType.forest;
  @override
  Brightness get brightness => Brightness.light;

  @override
  Color get background => const Color(0xFFF3FAF5);
  @override
  Color get backgroundAppBar => background;
  @override
  Gradient? get gradientBackground => null;

  @override
  Color get overlay => const Color(0xFF111215);

  @override
  Color get accentColorBlue => const Color(0xFF077CBE);
  @override
  Color get accentColorGreen => const Color(0xFF00A591);
  @override
  Color get accentColorYellow => const Color(0xFFF4C517);
  @override
  Color get accentColorRed => const Color(0xFFD1382D);
  @override
  Color get accentColorOrange => const Color(0xFFFF985F);
  @override
  Color get accentColorDark => const Color(0xFF22867A);

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
  Color get textSubtitle2 => const Color(0xFF919393);
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
  Color get textError => const Color(0xFF8D0006);
  @override
  Color get textRestore => overlay;

  // button background
  @override
  Color get buttonBackPrimary => const Color(0xFF22867A);
  @override
  Color get buttonBackSecondary => const Color(0xFFC2E2D5);
  @override
  Color get buttonBackPrimaryDisabled => const Color(0xFFBDDBCB);
  @override
  Color get buttonBackSecondaryDisabled => const Color(0xFFBDBDBD);
  @override
  Color get buttonBackBorder => const Color(0xFF22867A);
  @override
  Color get buttonBackBorderDisabled => const Color(0xFFBDD5DB);
  @override
  Color get buttonBackBorderSecondary => buttonBackSecondary;
  @override
  Color get buttonBackBorderSecondaryDisabled => buttonBackSecondaryDisabled;

  @override
  Color get numberBackDefault => const Color(0xFFFFFFFF);
  @override
  Color get numpadBackDefault => const Color(0xFF22867A);
  @override
  Color get bottomNavBack => const Color(0xFFFFFFFF);

  // button text/element
  @override
  Color get buttonTextPrimary => const Color(0xFFFFFFFF);
  @override
  Color get buttonTextSecondary => const Color(0xFF232323);
  @override
  Color get buttonTextPrimaryDisabled => const Color(0xFFFFFFFF);
  @override
  Color get buttonTextSecondaryDisabled => const Color(0xFFBDD5DB);
  @override
  Color get buttonTextBorder => const Color(0xFFBDD5DB);
  @override
  Color get buttonTextDisabled => const Color(0xFF22867A);
  @override
  Color get buttonTextBorderless => const Color(0xFFFFFFFF);
  @override
  Color get buttonTextBorderlessDisabled => const Color(0xFF056EC6);
  @override
  Color get numberTextDefault => const Color(0xFF232323);
  @override
  Color get numpadTextDefault => const Color(0xFFFFFFFF);
  @override
  Color get bottomNavText => const Color(0xFF22867A);
  @override
  Color get customTextButtonEnabledText => infoItemIcons;
  @override
  Color get customTextButtonDisabledText => textSubtitle1;

  // switch
  @override
  Color get switchBGOn => const Color(0xFF2DAB9C);
  @override
  Color get switchBGOff => const Color(0xFFD6F0E8);
  @override
  Color get switchBGDisabled => const Color(0xFFC5C6C9);
  @override
  Color get switchCircleOn => const Color(0xFFDEFFF2);
  @override
  Color get switchCircleOff => const Color(0xFFFBFCFF);
  @override
  Color get switchCircleDisabled => const Color(0xFFFBFCFF);

  // step indicator background
  @override
  Color get stepIndicatorBGCheck => const Color(0xFFBBF0DB);
  @override
  Color get stepIndicatorBGNumber => const Color(0xFFCDD9FF);
  @override
  Color get stepIndicatorBGInactive => const Color(0xFFD2EDE5);
  @override
  Color get stepIndicatorBGLines => const Color(0xFF90B8DC);
  @override
  Color get stepIndicatorBGLinesInactive => const Color(0xFFBCEAD9);
  @override
  Color get stepIndicatorIconText => const Color(0xFF22867A);
  @override
  Color get stepIndicatorIconNumber => const Color(0xFF005BAF);
  @override
  Color get stepIndicatorIconInactive => const Color(0xFFD4DFFF);

  // checkbox
  @override
  Color get checkboxBGChecked => const Color(0xFF22867A);
  @override
  Color get checkboxBorderEmpty => const Color(0xFF8C8F90);
  @override
  Color get checkboxBGDisabled => const Color(0xFFB0C9ED);
  @override
  Color get checkboxIconChecked => const Color(0xFFFFFFFF);
  @override
  Color get checkboxIconDisabled => const Color(0xFFFFFFFF);
  @override
  Color get checkboxTextLabel => const Color(0xFF232323);

  // snack bar
  @override
  Color get snackBarBackSuccess => const Color(0xFFADD6D2);
  @override
  Color get snackBarBackError => const Color(0xFFADD6D2);
  @override
  Color get snackBarBackInfo => const Color(0xFFCCD7FF);
  @override
  Color get snackBarTextSuccess => const Color(0xFF075547);
  @override
  Color get snackBarTextError => const Color(0xFF8D0006);
  @override
  Color get snackBarTextInfo => const Color(0xFF002569);

  // icons
  @override
  Color get bottomNavIconBack => const Color(0xFFA7C7CF);
  @override
  Color get bottomNavIconIcon => const Color(0xFF22867A);

  @override
  Color get topNavIconPrimary => accentColorDark; //const Color(0xFF227386);
  @override
  Color get topNavIconGreen => accentColorDark; //const Color(0xFF00A591);
  @override
  Color get topNavIconYellow => const Color(0xFFFDD33A);
  @override
  Color get topNavIconRed => const Color(0xFFEA4649);

  @override
  Color get settingsIconBack => const Color(0xFFE0E3E3);
  @override
  Color get settingsIconIcon => const Color(0xFF232323);
  @override
  Color get settingsIconBack2 => const Color(0xFF80D2C8);
  @override
  Color get settingsIconElement => const Color(0xFF00A591);

  // text field
  @override
  Color get textFieldActiveBG => const Color(0xFFE3FFF3);
  @override
  Color get textFieldDefaultBG => const Color(0xFFDDF3EA);
  @override
  Color get textFieldErrorBG => const Color(0xFFF6C7C3);
  @override
  Color get textFieldSuccessBG => const Color(0xFFADD6D2);
  @override
  Color get textFieldErrorBorder => textFieldErrorBG;
  @override
  Color get textFieldSuccessBorder => textFieldSuccessBG;

  @override
  Color get textFieldActiveSearchIconLeft => const Color(0xFF86898C);
  @override
  Color get textFieldDefaultSearchIconLeft => const Color(0xFF86898C);
  @override
  Color get textFieldErrorSearchIconLeft => const Color(0xFF8D0006);
  @override
  Color get textFieldSuccessSearchIconLeft => const Color(0xFF006C4D);

  @override
  Color get textFieldActiveText => const Color(0xFF232323);
  @override
  Color get textFieldDefaultText => const Color(0xFF86898C);
  @override
  Color get textFieldErrorText => const Color(0xFF000000);
  @override
  Color get textFieldSuccessText => const Color(0xFF000000);

  @override
  Color get textFieldActiveLabel => const Color(0xFF86898C);
  @override
  Color get textFieldErrorLabel => const Color(0xFF8D0006);
  @override
  Color get textFieldSuccessLabel => const Color(0xFF077C6E);

  @override
  Color get textFieldActiveSearchIconRight => const Color(0xFF22867A);
  @override
  Color get textFieldDefaultSearchIconRight => const Color(0xFF22867A);
  @override
  Color get textFieldErrorSearchIconRight => const Color(0xFF8D0006);
  @override
  Color get textFieldSuccessSearchIconRight => const Color(0xFF077C6E);

  // settings item level2
  @override
  Color get settingsItem2ActiveBG => const Color(0xFFFFFFFF);
  @override
  Color get settingsItem2ActiveText => const Color(0xFF232323);
  @override
  Color get settingsItem2ActiveSub => const Color(0xFF8C8F90);

  // radio buttons
  @override
  Color get radioButtonIconBorder => const Color(0xFF056EC6);
  @override
  Color get radioButtonIconBorderDisabled => const Color(0xFF8C8D97);
  @override
  Color get radioButtonBorderEnabled => const Color(0xFF056EC6);
  @override
  Color get radioButtonBorderDisabled => const Color(0xFF8C8D97);
  @override
  Color get radioButtonIconCircle => const Color(0xFF056EC6);
  @override
  Color get radioButtonIconEnabled => const Color(0xFF056EC6);
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
  Color get infoItemBG => const Color(0xFFFFFFFF);
  @override
  Color get infoItemLabel => const Color(0xFF838788);
  @override
  Color get infoItemText => const Color(0xFF232323);
  @override
  Color get infoItemIcons => const Color(0xFF056EC6);

  // popup
  @override
  Color get popupBG => const Color(0xFFFFFFFF);

  // currency list
  @override
  Color get currencyListItemBG => const Color(0xFFF0F5F7);

  // bottom nav
  @override
  Color get stackWalletBG => const Color(0xFFFFFFFF);
  @override
  Color get stackWalletMid => const Color(0xFFFFFFFF);
  @override
  Color get stackWalletBottom => const Color(0xFF232323);
  @override
  Color get bottomNavShadow => const Color(0xFF388192);

  @override
  Color get favoriteStarActive => const Color(0xFFF4C517);
  @override
  Color get favoriteStarInactive => const Color(0xFFB0B2B2);

  @override
  Color get splash => const Color(0xFF8E9192);
  @override
  Color get highlight => const Color(0xFFA9ACAC);
  @override
  Color get warningForeground => const Color(0xFF232323);
  @override
  Color get warningBackground => const Color(0xFFF6C7C3);
  @override
  Color get loadingOverlayTextColor => const Color(0xFFF7F7F7);
  @override
  Color get myStackContactIconBG => const Color(0xFFD8E7EB);
  @override
  Color get textConfirmTotalAmount => const Color(0xFF232323);
  @override
  Color get textSelectedWordTableItem => const Color(0xFF232323);

  //rate type toggle
  @override
  Color get rateTypeToggleColorOn => textFieldDefaultBG;
  @override
  Color get rateTypeToggleColorOff => popupBG;
  @override
  Color get rateTypeToggleDesktopColorOn => textFieldDefaultBG;
  @override
  Color get rateTypeToggleDesktopColorOff => buttonBackSecondary;

  // token view colors
  @override
  Color get ethTagText => const Color(0xFFFFFFFF);
  @override
  Color get ethTagBG => const Color(0xFF4D5798);
  @override
  Color get ethWalletTagText => const Color(0xFF4D5798);
  @override
  Color get ethWalletTagBG => const Color(0xFFEBEFFE);
  @override
  Color get tokenSummaryTextPrimary => const Color(0xFF232323);
  @override
  Color get tokenSummaryTextSecondary => const Color(0xFF4D5798);
  @override
  Color get tokenSummaryBG => const Color(0xFFFFFFFF);
  @override
  Color get tokenSummaryButtonBG => const Color(0xFFE9FBEF);
  @override
  Color get tokenSummaryIcon => const Color(0xFF22867A);

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
