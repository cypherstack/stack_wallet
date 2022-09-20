import 'package:flutter/material.dart';

abstract class DarkColors {
  // button background
  static const Color buttonBackPrimary = Color(0xFF4C86E9);
  static const Color buttonBackSecondary = Color(0xFF444E5C);
  static const Color buttonBackPrimaryDisabled = Color(0xFF38517C);
  static const Color buttonBackSecondaryDisabled = Color(0xFF3B3F46);
  static const Color buttonBackBorder = Color(0xFF4C86E9);
  static const Color buttonBackBorderDisabled = Color(0xFF314265);

  static const Color numberBackDefault = Color(0xFF484B51);
  static const Color numpadBackDefault = Color(0xFF4C86E9);
  static const Color bottomNavBack = Color(0xFFA2A2A2);

  // button text/element
  static const Color buttonTextPrimary = Color(0xFFFFFFFF);
  static const Color buttonTextSecondary = Color(0xFFFFFFFF);
  static const Color buttonTextPrimaryDisabled = Color(0xFFFFFFFF);
  static const Color buttonTextSecondaryDisabled = Color(0xFF6A6C71);
  static const Color buttonTextBorder = Color(0xFF4C86E9);
  static const Color buttonTextDisabled = Color(0xFF314265);
  static const Color buttonTextBorderless = Color(0xFF4C86E9);
  static const Color buttonTextBorderlessDisabled = Color(0xFFB6B6B6);
  static const Color numberTextDefault = Color(0xFFFFFFFF);
  static const Color numpadTextDefault = Color(0xFFFFFFFF);
  static const Color bottomNavText = Color(0xFFFFFFFF);

  // switch background
  static const Color switchBGOn = Color(0xFF4C86E9);
  static const Color switchBGOff = Color(0xFFC1D9FF);
  static const Color switchBGDisabled = Color(0xFFB5B7BA);

  // switch circle
  static const Color switchCircleOn = Color(0xFFC9DDFF);
  static const Color switchCircleOff = Color(0xFFFFFFFF);
  static const Color switchCircleDisabled = Color(0xFFFFFFFF);

  // step indicator background
  static const Color stepIndicatorBGCheck = Color(0xFF4C86E9);
  static const Color stepIndicatorBGNumber = Color(0xFF4C86E9);
  static const Color stepIndicatorBGInactive = Color(0xFF3B3F46);
  static const Color stepIndicatorBGLines = Color(0xFF747474);
  static const Color stepIndicatorIconText = Color(0xFFFFFFFF);
  static const Color stepIndicatorIconNumber = Color(0xFFFFFFFF);
  static const Color stepIndicatorIconInactive = Color(0xFF747474);

  // checkbox
  static const Color checkboxBGChecked = Color(0xFF4C86E9);
  static const Color checkboxBorderEmpty = Color(0xFF8E9192);
  static const Color checkboxBGDisabled = Color(0xFF4C86E9);
  static const Color checkboxIconChecked = Color(0xFFFFFFFF); // ??
  static const Color checkboxIconDisabled = Color(0xFFFFFFFF); // ??
  static const Color checkboxTextLabel = Color(0xFFFFFFFF); // ??

  // snack bar
  static const Color snackBarBackSuccess = Color(0xFF8EF5C3);
  static const Color snackBarBackError = Color(0xFFFFB4A9);
  static const Color snackBarBackInfo = Color(0xFFB4C4FF);
  static const Color snackBarTextSuccess = Color(0xFF003921);
  static const Color snackBarTextError = Color(0xFF690001);
  static const Color snackBarTextInfo = Color(0xFF00297A);

  // icons
  static const Color bottomNavIconBack = Color(0xFF7F8185);
  static const Color bottomNavIconIcon = Color(0xFFFFFFFF);

  static const Color topNavIconPrimary = Color(0xFFFFFFFF);
  static const Color topNavIconGreen = Color(0xFF4CC0A0);
  static const Color topNavIconYellow = Color(0xFFF7D65D);
  static const Color topNavIconRed = Color(0xFFD34E50);

  static const Color settingsIconBack = Color(0xFFE0E3E3);
  static const Color settingsIconIcon = Color(0xFF232323);
  static const Color settingsIconBack2 = Color(0xFF94D6C4);
  static const Color settingsIconElement = Color(0xFF00A578);

  // text field
  static const Color textFieldActiveBG = Color(0xFF4C5360);
  static const Color textFieldDefaultBG = Color(0xFF444953);
  static const Color textFieldErrorBG = Color(0xFFFFB4A9);
  static const Color textFieldSuccessBG = Color(0xFFB9E9D4);

  static const Color textFieldActiveSearchIconLeft = Color(0xFFA9ACAC);
  static const Color textFieldDefaultSearchIconLeft = Color(0xFFA9ACAC);
  static const Color textFieldErrorSearchIconLeft = Color(0xFF690001);
  static const Color textFieldSuccessSearchIconLeft = Color(0xFF003921);

  static const Color textFieldActiveText = Color(0xFFFFFFFF);
  static const Color textFieldDefaultText = Color(0xFFA9ACAC);
  static const Color textFieldErrorText = Color(0xFF000000);
  static const Color textFieldSuccessText = Color(0xFF000000);

  static const Color textFieldActiveLabel = Color(0xFFA9ACAC);
  static const Color textFieldErrorLabel = Color(0xFF690001);
  static const Color textFieldSuccessLabel = Color(0xFF003921);

  static const Color textFieldActiveSearchIconRight = Color(0xFFC4C7C7);
  static const Color textFieldDefaultSearchIconRight = Color(0xFF747778);
  static const Color textFieldErrorSearchIconRight = Color(0xFF690001);
  static const Color textFieldSuccessSearchIconRight = Color(0xFF003921);

  // settings item level2
  static const Color settingsItem2ActiveBG = Color(0xFF484B51);
  static const Color settingsItem2ActiveText = Color(0xFFFFFFFF);
  static const Color settingsItem2ActiveSub = Color(0xFF9E9E9E);

  // radio buttons
  static const Color radioButtonIconBorder = Color(0xFF4C86E9);
  static const Color radioButtonIconBorderDisabled = Color(0xFF9E9E9E);
  static const Color radioButtonBorderEnabled = Color(0xFF4C86E9);
  static const Color radioButtonBorderDisabled = Color(0xFFCDCDCD);
  static const Color radioButtonIconCircle = Color(0xFF9E9E9E);
  static const Color radioButtonIconEnabled = Color(0xFF4C86E9);
  static const Color radioButtonTextEnabled = Color(0xFF44464E);
  static const Color radioButtonTextDisabled = Color(0xFF44464E);
  static const Color radioButtonLabelEnabled = Color(0xFF8E9192);
  static const Color radioButtonLabelDisabled = Color(0xFF8E9192);

  // info text
  static const Color infoItemBG = Color(0xFF333942);
  static const Color infoItemLabel = Color(0xFF9E9E9E);
  static const Color infoItemText = Color(0xFFFFFFFF);
  static const Color infoItemIcons = Color(0xFF4C86E9);

  // popup
  static const Color popupBG = Color(0xFF333942);

  // currency list
  static const Color currencyListItemBG = Color(0xFF35383D);

  // bottom nav
  static const Color stackWalletBG = Color(0xFF35383D);
  static const Color stackWalletMid = Color(0xFF292D34);
  static const Color stackWalletBottom = Color(0xFFFFFFFF);
  static const Color bottomNavShadow = Color(0xFF282E33);
}
