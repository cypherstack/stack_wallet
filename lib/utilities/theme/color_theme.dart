import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:flutter/material.dart';

enum ThemeType {
  light,
  dark,
}

abstract class StackColorTheme {
  ThemeType get themeType;

  Color get background;
  Color get backgroundAppBar;

  Gradient? get gradientBackground;

  Color get overlay;

  Color get accentColorBlue;
  Color get accentColorGreen;
  Color get accentColorYellow;
  Color get accentColorRed;
  Color get accentColorOrange;
  Color get accentColorDark;

  Color get shadow;

  Color get textLight;
  Color get textMedium;
  Color get textDark;
  Color get textSubtitle1;
  Color get textSubtitle2;
  Color get textSubtitle3;
  Color get textSubtitle4;
  Color get textSubtitle5;
  Color get textSubtitle6;
  Color get textWhite;
  Color get textFavoriteCard;
  Color get textError;

// button background
  Color get buttonBackPrimary;
  Color get buttonBackSecondary;
  Color get buttonBackPrimaryDisabled;
  Color get buttonBackSecondaryDisabled;
  Color get buttonBackBorder;
  Color get buttonBackBorderDisabled;
  Color get numberBackDefault;
  Color get numpadBackDefault;
  Color get bottomNavBack;

// button text/element
  Color get buttonTextPrimary;
  Color get buttonTextSecondary;
  Color get buttonTextPrimaryDisabled;
  Color get buttonTextSecondaryDisabled;
  Color get buttonTextBorder;
  Color get buttonTextDisabled;
  Color get buttonTextBorderless;
  Color get buttonTextBorderlessDisabled;
  Color get numberTextDefault;
  Color get numpadTextDefault;
  Color get bottomNavText;

// switch background
  Color get switchBGOn;
  Color get switchBGOff;
  Color get switchBGDisabled;

// switch circle
  Color get switchCircleOn;
  Color get switchCircleOff;
  Color get switchCircleDisabled;

// step indicator background
  Color get stepIndicatorBGCheck;
  Color get stepIndicatorBGNumber;
  Color get stepIndicatorBGInactive;
  Color get stepIndicatorBGLines;
  Color get stepIndicatorBGLinesInactive;
  Color get stepIndicatorIconText;
  Color get stepIndicatorIconNumber;
  Color get stepIndicatorIconInactive;

// checkbox
  Color get checkboxBGChecked;
  Color get checkboxBorderEmpty;
  Color get checkboxBGDisabled;
  Color get checkboxIconChecked;
  Color get checkboxIconDisabled;
  Color get checkboxTextLabel;

// snack bar
  Color get snackBarBackSuccess;
  Color get snackBarBackError;
  Color get snackBarBackInfo;
  Color get snackBarTextSuccess;
  Color get snackBarTextError;
  Color get snackBarTextInfo;

// icons
  Color get bottomNavIconBack;
  Color get bottomNavIconIcon;
  Color get topNavIconPrimary;
  Color get topNavIconGreen;
  Color get topNavIconYellow;
  Color get topNavIconRed;
  Color get settingsIconBack;
  Color get settingsIconIcon;
  Color get settingsIconBack2;
  Color get settingsIconElement;

// text field
  Color get textFieldActiveBG;
  Color get textFieldDefaultBG;
  Color get textFieldErrorBG;
  Color get textFieldSuccessBG;
  Color get textFieldActiveSearchIconLeft;
  Color get textFieldDefaultSearchIconLeft;
  Color get textFieldErrorSearchIconLeft;
  Color get textFieldSuccessSearchIconLeft;
  Color get textFieldActiveText;
  Color get textFieldDefaultText;
  Color get textFieldErrorText;
  Color get textFieldSuccessText;
  Color get textFieldActiveLabel;
  Color get textFieldErrorLabel;
  Color get textFieldSuccessLabel;
  Color get textFieldActiveSearchIconRight;
  Color get textFieldDefaultSearchIconRight;
  Color get textFieldErrorSearchIconRight;
  Color get textFieldSuccessSearchIconRight;

// settings item level2
  Color get settingsItem2ActiveBG;
  Color get settingsItem2ActiveText;
  Color get settingsItem2ActiveSub;

// radio buttons
  Color get radioButtonIconBorder;
  Color get radioButtonIconBorderDisabled;
  Color get radioButtonBorderEnabled;
  Color get radioButtonBorderDisabled;
  Color get radioButtonIconCircle;
  Color get radioButtonIconEnabled;
  Color get radioButtonTextEnabled;
  Color get radioButtonTextDisabled;
  Color get radioButtonLabelEnabled;
  Color get radioButtonLabelDisabled;

// info text
  Color get infoItemBG;
  Color get infoItemLabel;
  Color get infoItemText;
  Color get infoItemIcons;

// popup
  Color get popupBG;

// currency list
  Color get currencyListItemBG;

// bottom nav
  Color get epicmobileBG;
  Color get epicmobileMid;
  Color get epicmobileBottom;
  Color get bottomNavShadow;

  Color get favoriteStarActive;
  Color get favoriteStarInactive;

  Color get splash;
  Color get highlight;
  Color get warningForeground;
  Color get warningBackground;

  Color get loadingOverlayTextColor;
  Color get myStackContactIconBG;
  Color get textConfirmTotalAmount;
  Color get textSelectedWordTableItem;
}

class CoinThemeColor {
  const CoinThemeColor();

  Color get epicCash => const Color(0xFFC5C7CB);

  Color forCoin(Coin coin) {
    switch (coin) {
      case Coin.epicCash:
        return epicCash;
    }
  }
}
