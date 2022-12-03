import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/theme/color_theme.dart';
import 'package:flutter/material.dart';

class StackColors extends ThemeExtension<StackColors> {
  final ThemeType themeType;

  final Color background;
  final Color backgroundAppBar;
  final Gradient? gradientBackground;

  final Color overlay;

  final Color accentColorBlue;
  final Color accentColorGreen;
  final Color accentColorYellow;
  final Color accentColorRed;
  final Color accentColorOrange;
  final Color accentColorDark;

  final Color shadow;

  final Color textLight;
  final Color textMedium;
  final Color textDark;
  final Color textSubtitle1;
  final Color textSubtitle2;
  final Color textSubtitle3;
  final Color textSubtitle4;
  final Color textSubtitle5;
  final Color textSubtitle6;
  final Color textWhite;
  final Color textFavoriteCard;
  final Color textError;

// button background
  final Color buttonBackPrimary;
  final Color buttonBackSecondary;
  final Color buttonBackPrimaryDisabled;
  final Color buttonBackSecondaryDisabled;
  final Color buttonBackBorder;
  final Color buttonBackBorderDisabled;
  final Color numberBackDefault;
  final Color numpadBackDefault;
  final Color bottomNavBack;

// button text/element
  final Color buttonTextPrimary;
  final Color buttonTextSecondary;
  final Color buttonTextPrimaryDisabled;
  final Color buttonTextSecondaryDisabled;
  final Color buttonTextBorder;
  final Color buttonTextDisabled;
  final Color buttonTextBorderless;
  final Color buttonTextBorderlessDisabled;
  final Color numberTextDefault;
  final Color numpadTextDefault;
  final Color bottomNavText;

// switch background
  final Color switchBGOn;
  final Color switchBGOff;
  final Color switchBGDisabled;

// switch circle
  final Color switchCircleOn;
  final Color switchCircleOff;
  final Color switchCircleDisabled;

// step indicator background
  final Color stepIndicatorBGCheck;
  final Color stepIndicatorBGNumber;
  final Color stepIndicatorBGInactive;
  final Color stepIndicatorBGLines;
  final Color stepIndicatorBGLinesInactive;
  final Color stepIndicatorIconText;
  final Color stepIndicatorIconNumber;
  final Color stepIndicatorIconInactive;

// checkbox
  final Color checkboxBGChecked;
  final Color checkboxBorderEmpty;
  final Color checkboxBGDisabled;
  final Color checkboxIconChecked;
  final Color checkboxIconDisabled;
  final Color checkboxTextLabel;

// snack bar
  final Color snackBarBackSuccess;
  final Color snackBarBackError;
  final Color snackBarBackInfo;
  final Color snackBarTextSuccess;
  final Color snackBarTextError;
  final Color snackBarTextInfo;

// icons
  final Color bottomNavIconBack;
  final Color bottomNavIconIcon;
  final Color topNavIconPrimary;
  final Color topNavIconGreen;
  final Color topNavIconYellow;
  final Color topNavIconRed;
  final Color settingsIconBack;
  final Color settingsIconIcon;
  final Color settingsIconBack2;
  final Color settingsIconElement;

// text field
  final Color textFieldActiveBG;
  final Color textFieldDefaultBG;
  final Color textFieldErrorBG;
  final Color textFieldSuccessBG;
  final Color textFieldActiveSearchIconLeft;
  final Color textFieldDefaultSearchIconLeft;
  final Color textFieldErrorSearchIconLeft;
  final Color textFieldSuccessSearchIconLeft;
  final Color textFieldActiveText;
  final Color textFieldDefaultText;
  final Color textFieldErrorText;
  final Color textFieldSuccessText;
  final Color textFieldActiveLabel;
  final Color textFieldErrorLabel;
  final Color textFieldSuccessLabel;
  final Color textFieldActiveSearchIconRight;
  final Color textFieldDefaultSearchIconRight;
  final Color textFieldErrorSearchIconRight;
  final Color textFieldSuccessSearchIconRight;

// settings item level2
  final Color settingsItem2ActiveBG;
  final Color settingsItem2ActiveText;
  final Color settingsItem2ActiveSub;

// radio buttons
  final Color radioButtonIconBorder;
  final Color radioButtonIconBorderDisabled;
  final Color radioButtonBorderEnabled;
  final Color radioButtonBorderDisabled;
  final Color radioButtonIconCircle;
  final Color radioButtonIconEnabled;
  final Color radioButtonTextEnabled;
  final Color radioButtonTextDisabled;
  final Color radioButtonLabelEnabled;
  final Color radioButtonLabelDisabled;

// info text
  final Color infoItemBG;
  final Color infoItemLabel;
  final Color infoItemText;
  final Color infoItemIcons;

// popup
  final Color popupBG;

// currency list
  final Color currencyListItemBG;

// bottom nav
  final Color epicmobileBG;
  final Color epicmobileMid;
  final Color epicmobileBottom;
  final Color bottomNavShadow;

  final Color favoriteStarActive;
  final Color favoriteStarInactive;

  final Color splash;
  final Color highlight;
  final Color warningForeground;
  final Color warningBackground;
  final Color loadingOverlayTextColor;
  final Color myStackContactIconBG;
  final Color textConfirmTotalAmount;
  final Color textSelectedWordTableItem;

  StackColors({
    required this.themeType,
    required this.background,
    required this.backgroundAppBar,
    required this.gradientBackground,
    required this.overlay,
    required this.accentColorBlue,
    required this.accentColorGreen,
    required this.accentColorYellow,
    required this.accentColorRed,
    required this.accentColorOrange,
    required this.accentColorDark,
    required this.shadow,
    required this.textLight,
    required this.textMedium,
    required this.textDark,
    required this.textSubtitle1,
    required this.textSubtitle2,
    required this.textSubtitle3,
    required this.textSubtitle4,
    required this.textSubtitle5,
    required this.textSubtitle6,
    required this.textWhite,
    required this.textFavoriteCard,
    required this.textError,
    required this.buttonBackPrimary,
    required this.buttonBackSecondary,
    required this.buttonBackPrimaryDisabled,
    required this.buttonBackSecondaryDisabled,
    required this.buttonBackBorder,
    required this.buttonBackBorderDisabled,
    required this.numberBackDefault,
    required this.numpadBackDefault,
    required this.bottomNavBack,
    required this.buttonTextPrimary,
    required this.buttonTextSecondary,
    required this.buttonTextPrimaryDisabled,
    required this.buttonTextSecondaryDisabled,
    required this.buttonTextBorder,
    required this.buttonTextDisabled,
    required this.buttonTextBorderless,
    required this.buttonTextBorderlessDisabled,
    required this.numberTextDefault,
    required this.numpadTextDefault,
    required this.bottomNavText,
    required this.switchBGOn,
    required this.switchBGOff,
    required this.switchBGDisabled,
    required this.switchCircleOn,
    required this.switchCircleOff,
    required this.switchCircleDisabled,
    required this.stepIndicatorBGCheck,
    required this.stepIndicatorBGNumber,
    required this.stepIndicatorBGInactive,
    required this.stepIndicatorBGLines,
    required this.stepIndicatorBGLinesInactive,
    required this.stepIndicatorIconText,
    required this.stepIndicatorIconNumber,
    required this.stepIndicatorIconInactive,
    required this.checkboxBGChecked,
    required this.checkboxBorderEmpty,
    required this.checkboxBGDisabled,
    required this.checkboxIconChecked,
    required this.checkboxIconDisabled,
    required this.checkboxTextLabel,
    required this.snackBarBackSuccess,
    required this.snackBarBackError,
    required this.snackBarBackInfo,
    required this.snackBarTextSuccess,
    required this.snackBarTextError,
    required this.snackBarTextInfo,
    required this.bottomNavIconBack,
    required this.bottomNavIconIcon,
    required this.topNavIconPrimary,
    required this.topNavIconGreen,
    required this.topNavIconYellow,
    required this.topNavIconRed,
    required this.settingsIconBack,
    required this.settingsIconIcon,
    required this.settingsIconBack2,
    required this.settingsIconElement,
    required this.textFieldActiveBG,
    required this.textFieldDefaultBG,
    required this.textFieldErrorBG,
    required this.textFieldSuccessBG,
    required this.textFieldActiveSearchIconLeft,
    required this.textFieldDefaultSearchIconLeft,
    required this.textFieldErrorSearchIconLeft,
    required this.textFieldSuccessSearchIconLeft,
    required this.textFieldActiveText,
    required this.textFieldDefaultText,
    required this.textFieldErrorText,
    required this.textFieldSuccessText,
    required this.textFieldActiveLabel,
    required this.textFieldErrorLabel,
    required this.textFieldSuccessLabel,
    required this.textFieldActiveSearchIconRight,
    required this.textFieldDefaultSearchIconRight,
    required this.textFieldErrorSearchIconRight,
    required this.textFieldSuccessSearchIconRight,
    required this.settingsItem2ActiveBG,
    required this.settingsItem2ActiveText,
    required this.settingsItem2ActiveSub,
    required this.radioButtonIconBorder,
    required this.radioButtonIconBorderDisabled,
    required this.radioButtonBorderEnabled,
    required this.radioButtonBorderDisabled,
    required this.radioButtonIconCircle,
    required this.radioButtonIconEnabled,
    required this.radioButtonTextEnabled,
    required this.radioButtonTextDisabled,
    required this.radioButtonLabelEnabled,
    required this.radioButtonLabelDisabled,
    required this.infoItemBG,
    required this.infoItemLabel,
    required this.infoItemText,
    required this.infoItemIcons,
    required this.popupBG,
    required this.currencyListItemBG,
    required this.epicmobileBG,
    required this.epicmobileMid,
    required this.epicmobileBottom,
    required this.bottomNavShadow,
    required this.favoriteStarActive,
    required this.favoriteStarInactive,
    required this.splash,
    required this.highlight,
    required this.warningForeground,
    required this.warningBackground,
    required this.loadingOverlayTextColor,
    required this.myStackContactIconBG,
    required this.textConfirmTotalAmount,
    required this.textSelectedWordTableItem,
  });

  factory StackColors.fromStackColorTheme(StackColorTheme colorTheme) {
    return StackColors(
      themeType: colorTheme.themeType,
      background: colorTheme.background,
      backgroundAppBar: colorTheme.backgroundAppBar,
      gradientBackground: colorTheme.gradientBackground,
      overlay: colorTheme.overlay,
      accentColorBlue: colorTheme.accentColorBlue,
      accentColorGreen: colorTheme.accentColorGreen,
      accentColorYellow: colorTheme.accentColorYellow,
      accentColorRed: colorTheme.accentColorRed,
      accentColorOrange: colorTheme.accentColorOrange,
      accentColorDark: colorTheme.accentColorDark,
      shadow: colorTheme.shadow,
      textLight: colorTheme.textLight,
      textMedium: colorTheme.textMedium,
      textDark: colorTheme.textDark,
      textSubtitle1: colorTheme.textSubtitle1,
      textSubtitle2: colorTheme.textSubtitle2,
      textSubtitle3: colorTheme.textSubtitle3,
      textSubtitle4: colorTheme.textSubtitle4,
      textSubtitle5: colorTheme.textSubtitle5,
      textSubtitle6: colorTheme.textSubtitle6,
      textWhite: colorTheme.textWhite,
      textFavoriteCard: colorTheme.textFavoriteCard,
      textError: colorTheme.textError,
      buttonBackPrimary: colorTheme.buttonBackPrimary,
      buttonBackSecondary: colorTheme.buttonBackSecondary,
      buttonBackPrimaryDisabled: colorTheme.buttonBackPrimaryDisabled,
      buttonBackSecondaryDisabled: colorTheme.buttonBackSecondaryDisabled,
      buttonBackBorder: colorTheme.buttonBackBorder,
      buttonBackBorderDisabled: colorTheme.buttonBackBorderDisabled,
      numberBackDefault: colorTheme.numberBackDefault,
      numpadBackDefault: colorTheme.numpadBackDefault,
      bottomNavBack: colorTheme.bottomNavBack,
      buttonTextPrimary: colorTheme.buttonTextPrimary,
      buttonTextSecondary: colorTheme.buttonTextSecondary,
      buttonTextPrimaryDisabled: colorTheme.buttonTextPrimaryDisabled,
      buttonTextSecondaryDisabled: colorTheme.buttonTextSecondaryDisabled,
      buttonTextBorder: colorTheme.buttonTextBorder,
      buttonTextDisabled: colorTheme.buttonTextDisabled,
      buttonTextBorderless: colorTheme.buttonTextBorderless,
      buttonTextBorderlessDisabled: colorTheme.buttonTextBorderlessDisabled,
      numberTextDefault: colorTheme.numberTextDefault,
      numpadTextDefault: colorTheme.numpadTextDefault,
      bottomNavText: colorTheme.bottomNavText,
      switchBGOn: colorTheme.switchBGOn,
      switchBGOff: colorTheme.switchBGOff,
      switchBGDisabled: colorTheme.switchBGDisabled,
      switchCircleOn: colorTheme.switchCircleOn,
      switchCircleOff: colorTheme.switchCircleOff,
      switchCircleDisabled: colorTheme.switchCircleDisabled,
      stepIndicatorBGCheck: colorTheme.stepIndicatorBGCheck,
      stepIndicatorBGNumber: colorTheme.stepIndicatorBGNumber,
      stepIndicatorBGInactive: colorTheme.stepIndicatorBGInactive,
      stepIndicatorBGLines: colorTheme.stepIndicatorBGLines,
      stepIndicatorBGLinesInactive: colorTheme.stepIndicatorBGLinesInactive,
      stepIndicatorIconText: colorTheme.stepIndicatorIconText,
      stepIndicatorIconNumber: colorTheme.stepIndicatorIconNumber,
      stepIndicatorIconInactive: colorTheme.stepIndicatorIconInactive,
      checkboxBGChecked: colorTheme.checkboxBGChecked,
      checkboxBorderEmpty: colorTheme.checkboxBorderEmpty,
      checkboxBGDisabled: colorTheme.checkboxBGDisabled,
      checkboxIconChecked: colorTheme.checkboxIconChecked,
      checkboxIconDisabled: colorTheme.checkboxIconDisabled,
      checkboxTextLabel: colorTheme.checkboxTextLabel,
      snackBarBackSuccess: colorTheme.snackBarBackSuccess,
      snackBarBackError: colorTheme.snackBarBackError,
      snackBarBackInfo: colorTheme.snackBarBackInfo,
      snackBarTextSuccess: colorTheme.snackBarTextSuccess,
      snackBarTextError: colorTheme.snackBarTextError,
      snackBarTextInfo: colorTheme.snackBarTextInfo,
      bottomNavIconBack: colorTheme.bottomNavIconBack,
      bottomNavIconIcon: colorTheme.bottomNavIconIcon,
      topNavIconPrimary: colorTheme.topNavIconPrimary,
      topNavIconGreen: colorTheme.topNavIconGreen,
      topNavIconYellow: colorTheme.topNavIconYellow,
      topNavIconRed: colorTheme.topNavIconRed,
      settingsIconBack: colorTheme.settingsIconBack,
      settingsIconIcon: colorTheme.settingsIconIcon,
      settingsIconBack2: colorTheme.settingsIconBack2,
      settingsIconElement: colorTheme.settingsIconElement,
      textFieldActiveBG: colorTheme.textFieldActiveBG,
      textFieldDefaultBG: colorTheme.textFieldDefaultBG,
      textFieldErrorBG: colorTheme.textFieldErrorBG,
      textFieldSuccessBG: colorTheme.textFieldSuccessBG,
      textFieldActiveSearchIconLeft: colorTheme.textFieldActiveSearchIconLeft,
      textFieldDefaultSearchIconLeft: colorTheme.textFieldDefaultSearchIconLeft,
      textFieldErrorSearchIconLeft: colorTheme.textFieldErrorSearchIconLeft,
      textFieldSuccessSearchIconLeft: colorTheme.textFieldSuccessSearchIconLeft,
      textFieldActiveText: colorTheme.textFieldActiveText,
      textFieldDefaultText: colorTheme.textFieldDefaultText,
      textFieldErrorText: colorTheme.textFieldErrorText,
      textFieldSuccessText: colorTheme.textFieldSuccessText,
      textFieldActiveLabel: colorTheme.textFieldActiveLabel,
      textFieldErrorLabel: colorTheme.textFieldErrorLabel,
      textFieldSuccessLabel: colorTheme.textFieldSuccessLabel,
      textFieldActiveSearchIconRight: colorTheme.textFieldActiveSearchIconRight,
      textFieldDefaultSearchIconRight:
          colorTheme.textFieldDefaultSearchIconRight,
      textFieldErrorSearchIconRight: colorTheme.textFieldErrorSearchIconRight,
      textFieldSuccessSearchIconRight:
          colorTheme.textFieldSuccessSearchIconRight,
      settingsItem2ActiveBG: colorTheme.settingsItem2ActiveBG,
      settingsItem2ActiveText: colorTheme.settingsItem2ActiveText,
      settingsItem2ActiveSub: colorTheme.settingsItem2ActiveSub,
      radioButtonIconBorder: colorTheme.radioButtonIconBorder,
      radioButtonIconBorderDisabled: colorTheme.radioButtonIconBorderDisabled,
      radioButtonBorderEnabled: colorTheme.radioButtonBorderEnabled,
      radioButtonBorderDisabled: colorTheme.radioButtonBorderDisabled,
      radioButtonIconCircle: colorTheme.radioButtonIconCircle,
      radioButtonIconEnabled: colorTheme.radioButtonIconEnabled,
      radioButtonTextEnabled: colorTheme.radioButtonTextEnabled,
      radioButtonTextDisabled: colorTheme.radioButtonTextDisabled,
      radioButtonLabelEnabled: colorTheme.radioButtonLabelEnabled,
      radioButtonLabelDisabled: colorTheme.radioButtonLabelDisabled,
      infoItemBG: colorTheme.infoItemBG,
      infoItemLabel: colorTheme.infoItemLabel,
      infoItemText: colorTheme.infoItemText,
      infoItemIcons: colorTheme.infoItemIcons,
      popupBG: colorTheme.popupBG,
      currencyListItemBG: colorTheme.currencyListItemBG,
      epicmobileBG: colorTheme.epicmobileBG,
      epicmobileMid: colorTheme.epicmobileMid,
      epicmobileBottom: colorTheme.epicmobileBottom,
      bottomNavShadow: colorTheme.bottomNavShadow,
      favoriteStarActive: colorTheme.favoriteStarActive,
      favoriteStarInactive: colorTheme.favoriteStarInactive,
      splash: colorTheme.splash,
      highlight: colorTheme.highlight,
      warningForeground: colorTheme.warningForeground,
      warningBackground: colorTheme.warningBackground,
      loadingOverlayTextColor: colorTheme.loadingOverlayTextColor,
      myStackContactIconBG: colorTheme.myStackContactIconBG,
      textConfirmTotalAmount: colorTheme.textConfirmTotalAmount,
      textSelectedWordTableItem: colorTheme.textSelectedWordTableItem,
    );
  }

  @override
  ThemeExtension<StackColors> copyWith({
    ThemeType? themeType,
    Color? background,
    Color? backgroundAppBar,
    Gradient? gradientBackground,
    Color? overlay,
    Color? accentColorBlue,
    Color? accentColorGreen,
    Color? accentColorYellow,
    Color? accentColorRed,
    Color? accentColorOrange,
    Color? accentColorDark,
    Color? shadow,
    Color? textDark,
    Color? textDark2,
    Color? textDark3,
    Color? textSubtitle1,
    Color? textSubtitle2,
    Color? textSubtitle3,
    Color? textSubtitle4,
    Color? textSubtitle5,
    Color? textSubtitle6,
    Color? textWhite,
    Color? textFavoriteCard,
    Color? textError,
    Color? buttonBackPrimary,
    Color? buttonBackSecondary,
    Color? buttonBackPrimaryDisabled,
    Color? buttonBackSecondaryDisabled,
    Color? buttonBackBorder,
    Color? buttonBackBorderDisabled,
    Color? numberBackDefault,
    Color? numpadBackDefault,
    Color? bottomNavBack,
    Color? buttonTextPrimary,
    Color? buttonTextSecondary,
    Color? buttonTextPrimaryDisabled,
    Color? buttonTextSecondaryDisabled,
    Color? buttonTextBorder,
    Color? buttonTextDisabled,
    Color? buttonTextBorderless,
    Color? buttonTextBorderlessDisabled,
    Color? numberTextDefault,
    Color? numpadTextDefault,
    Color? bottomNavText,
    Color? switchBGOn,
    Color? switchBGOff,
    Color? switchBGDisabled,
    Color? switchCircleOn,
    Color? switchCircleOff,
    Color? switchCircleDisabled,
    Color? stepIndicatorBGCheck,
    Color? stepIndicatorBGNumber,
    Color? stepIndicatorBGInactive,
    Color? stepIndicatorBGLines,
    Color? stepIndicatorBGLinesInactive,
    Color? stepIndicatorIconText,
    Color? stepIndicatorIconNumber,
    Color? stepIndicatorIconInactive,
    Color? checkboxBGChecked,
    Color? checkboxBorderEmpty,
    Color? checkboxBGDisabled,
    Color? checkboxIconChecked,
    Color? checkboxIconDisabled,
    Color? checkboxTextLabel,
    Color? snackBarBackSuccess,
    Color? snackBarBackError,
    Color? snackBarBackInfo,
    Color? snackBarTextSuccess,
    Color? snackBarTextError,
    Color? snackBarTextInfo,
    Color? bottomNavIconBack,
    Color? bottomNavIconIcon,
    Color? topNavIconPrimary,
    Color? topNavIconGreen,
    Color? topNavIconYellow,
    Color? topNavIconRed,
    Color? settingsIconBack,
    Color? settingsIconIcon,
    Color? settingsIconBack2,
    Color? settingsIconElement,
    Color? textFieldActiveBG,
    Color? textFieldDefaultBG,
    Color? textFieldErrorBG,
    Color? textFieldSuccessBG,
    Color? textFieldActiveSearchIconLeft,
    Color? textFieldDefaultSearchIconLeft,
    Color? textFieldErrorSearchIconLeft,
    Color? textFieldSuccessSearchIconLeft,
    Color? textFieldActiveText,
    Color? textFieldDefaultText,
    Color? textFieldErrorText,
    Color? textFieldSuccessText,
    Color? textFieldActiveLabel,
    Color? textFieldErrorLabel,
    Color? textFieldSuccessLabel,
    Color? textFieldActiveSearchIconRight,
    Color? textFieldDefaultSearchIconRight,
    Color? textFieldErrorSearchIconRight,
    Color? textFieldSuccessSearchIconRight,
    Color? settingsItem2ActiveBG,
    Color? settingsItem2ActiveText,
    Color? settingsItem2ActiveSub,
    Color? radioButtonIconBorder,
    Color? radioButtonIconBorderDisabled,
    Color? radioButtonBorderEnabled,
    Color? radioButtonBorderDisabled,
    Color? radioButtonIconCircle,
    Color? radioButtonIconEnabled,
    Color? radioButtonTextEnabled,
    Color? radioButtonTextDisabled,
    Color? radioButtonLabelEnabled,
    Color? radioButtonLabelDisabled,
    Color? infoItemBG,
    Color? infoItemLabel,
    Color? infoItemText,
    Color? infoItemIcons,
    Color? popupBG,
    Color? currencyListItemBG,
    Color? epicmobileBG,
    Color? epicmobileMid,
    Color? epicmobileBottom,
    Color? bottomNavShadow,
    Color? favoriteStarActive,
    Color? favoriteStarInactive,
    Color? splash,
    Color? highlight,
    Color? warningForeground,
    Color? warningBackground,
    Color? loadingOverlayTextColor,
    Color? myStackContactIconBG,
    Color? textConfirmTotalAmount,
    Color? textSelectedWordTableItem,
  }) {
    return StackColors(
      themeType: themeType ?? this.themeType,
      background: background ?? this.background,
      backgroundAppBar: backgroundAppBar ?? this.backgroundAppBar,
      gradientBackground: gradientBackground ?? this.gradientBackground,
      overlay: overlay ?? this.overlay,
      accentColorBlue: accentColorBlue ?? this.accentColorBlue,
      accentColorGreen: accentColorGreen ?? this.accentColorGreen,
      accentColorYellow: accentColorYellow ?? this.accentColorYellow,
      accentColorRed: accentColorRed ?? this.accentColorRed,
      accentColorOrange: accentColorOrange ?? this.accentColorOrange,
      accentColorDark: accentColorDark ?? this.accentColorDark,
      shadow: shadow ?? this.shadow,
      textLight: textDark ?? this.textLight,
      textMedium: textDark2 ?? this.textMedium,
      textDark: textDark3 ?? this.textDark,
      textSubtitle1: textSubtitle1 ?? this.textSubtitle1,
      textSubtitle2: textSubtitle2 ?? this.textSubtitle2,
      textSubtitle3: textSubtitle3 ?? this.textSubtitle3,
      textSubtitle4: textSubtitle4 ?? this.textSubtitle4,
      textSubtitle5: textSubtitle5 ?? this.textSubtitle5,
      textSubtitle6: textSubtitle6 ?? this.textSubtitle6,
      textWhite: textWhite ?? this.textWhite,
      textFavoriteCard: textFavoriteCard ?? this.textFavoriteCard,
      textError: textError ?? this.textError,
      buttonBackPrimary: buttonBackPrimary ?? this.buttonBackPrimary,
      buttonBackSecondary: buttonBackSecondary ?? this.buttonBackSecondary,
      buttonBackPrimaryDisabled:
          buttonBackPrimaryDisabled ?? this.buttonBackPrimaryDisabled,
      buttonBackSecondaryDisabled:
          buttonBackSecondaryDisabled ?? this.buttonBackSecondaryDisabled,
      buttonBackBorder: buttonBackBorder ?? this.buttonBackBorder,
      buttonBackBorderDisabled:
          buttonBackBorderDisabled ?? this.buttonBackBorderDisabled,
      numberBackDefault: numberBackDefault ?? this.numberBackDefault,
      numpadBackDefault: numpadBackDefault ?? this.numpadBackDefault,
      bottomNavBack: bottomNavBack ?? this.bottomNavBack,
      buttonTextPrimary: buttonTextPrimary ?? this.buttonTextPrimary,
      buttonTextSecondary: buttonTextSecondary ?? this.buttonTextSecondary,
      buttonTextPrimaryDisabled:
          buttonTextPrimaryDisabled ?? this.buttonTextPrimaryDisabled,
      buttonTextSecondaryDisabled:
          buttonTextSecondaryDisabled ?? this.buttonTextSecondaryDisabled,
      buttonTextBorder: buttonTextBorder ?? this.buttonTextBorder,
      buttonTextDisabled: buttonTextDisabled ?? this.buttonTextDisabled,
      buttonTextBorderless: buttonTextBorderless ?? this.buttonTextBorderless,
      buttonTextBorderlessDisabled:
          buttonTextBorderlessDisabled ?? this.buttonTextBorderlessDisabled,
      numberTextDefault: numberTextDefault ?? this.numberTextDefault,
      numpadTextDefault: numpadTextDefault ?? this.numpadTextDefault,
      bottomNavText: bottomNavText ?? this.bottomNavText,
      switchBGOn: switchBGOn ?? this.switchBGOn,
      switchBGOff: switchBGOff ?? this.switchBGOff,
      switchBGDisabled: switchBGDisabled ?? this.switchBGDisabled,
      switchCircleOn: switchCircleOn ?? this.switchCircleOn,
      switchCircleOff: switchCircleOff ?? this.switchCircleOff,
      switchCircleDisabled: switchCircleDisabled ?? this.switchCircleDisabled,
      stepIndicatorBGCheck: stepIndicatorBGCheck ?? this.stepIndicatorBGCheck,
      stepIndicatorBGNumber:
          stepIndicatorBGNumber ?? this.stepIndicatorBGNumber,
      stepIndicatorBGInactive:
          stepIndicatorBGInactive ?? this.stepIndicatorBGInactive,
      stepIndicatorBGLines: stepIndicatorBGLines ?? this.stepIndicatorBGLines,
      stepIndicatorBGLinesInactive:
          stepIndicatorBGLinesInactive ?? this.stepIndicatorBGLinesInactive,
      stepIndicatorIconText:
          stepIndicatorIconText ?? this.stepIndicatorIconText,
      stepIndicatorIconNumber:
          stepIndicatorIconNumber ?? this.stepIndicatorIconNumber,
      stepIndicatorIconInactive:
          stepIndicatorIconInactive ?? this.stepIndicatorIconInactive,
      checkboxBGChecked: checkboxBGChecked ?? this.checkboxBGChecked,
      checkboxBorderEmpty: checkboxBorderEmpty ?? this.checkboxBorderEmpty,
      checkboxBGDisabled: checkboxBGDisabled ?? this.checkboxBGDisabled,
      checkboxIconChecked: checkboxIconChecked ?? this.checkboxIconChecked,
      checkboxIconDisabled: checkboxIconDisabled ?? this.checkboxIconDisabled,
      checkboxTextLabel: checkboxTextLabel ?? this.checkboxTextLabel,
      snackBarBackSuccess: snackBarBackSuccess ?? this.snackBarBackSuccess,
      snackBarBackError: snackBarBackError ?? this.snackBarBackError,
      snackBarBackInfo: snackBarBackInfo ?? this.snackBarBackInfo,
      snackBarTextSuccess: snackBarTextSuccess ?? this.snackBarTextSuccess,
      snackBarTextError: snackBarTextError ?? this.snackBarTextError,
      snackBarTextInfo: snackBarTextInfo ?? this.snackBarTextInfo,
      bottomNavIconBack: bottomNavIconBack ?? this.bottomNavIconBack,
      bottomNavIconIcon: bottomNavIconIcon ?? this.bottomNavIconIcon,
      topNavIconPrimary: topNavIconPrimary ?? this.topNavIconPrimary,
      topNavIconGreen: topNavIconGreen ?? this.topNavIconGreen,
      topNavIconYellow: topNavIconYellow ?? this.topNavIconYellow,
      topNavIconRed: topNavIconRed ?? this.topNavIconRed,
      settingsIconBack: settingsIconBack ?? this.settingsIconBack,
      settingsIconIcon: settingsIconIcon ?? this.settingsIconIcon,
      settingsIconBack2: settingsIconBack2 ?? this.settingsIconBack2,
      settingsIconElement: settingsIconElement ?? this.settingsIconElement,
      textFieldActiveBG: textFieldActiveBG ?? this.textFieldActiveBG,
      textFieldDefaultBG: textFieldDefaultBG ?? this.textFieldDefaultBG,
      textFieldErrorBG: textFieldErrorBG ?? this.textFieldErrorBG,
      textFieldSuccessBG: textFieldSuccessBG ?? this.textFieldSuccessBG,
      textFieldActiveSearchIconLeft:
          textFieldActiveSearchIconLeft ?? this.textFieldActiveSearchIconLeft,
      textFieldDefaultSearchIconLeft:
          textFieldDefaultSearchIconLeft ?? this.textFieldDefaultSearchIconLeft,
      textFieldErrorSearchIconLeft:
          textFieldErrorSearchIconLeft ?? this.textFieldErrorSearchIconLeft,
      textFieldSuccessSearchIconLeft:
          textFieldSuccessSearchIconLeft ?? this.textFieldSuccessSearchIconLeft,
      textFieldActiveText: textFieldActiveText ?? this.textFieldActiveText,
      textFieldDefaultText: textFieldDefaultText ?? this.textFieldDefaultText,
      textFieldErrorText: textFieldErrorText ?? this.textFieldErrorText,
      textFieldSuccessText: textFieldSuccessText ?? this.textFieldSuccessText,
      textFieldActiveLabel: textFieldActiveLabel ?? this.textFieldActiveLabel,
      textFieldErrorLabel: textFieldErrorLabel ?? this.textFieldErrorLabel,
      textFieldSuccessLabel:
          textFieldSuccessLabel ?? this.textFieldSuccessLabel,
      textFieldActiveSearchIconRight:
          textFieldActiveSearchIconRight ?? this.textFieldActiveSearchIconRight,
      textFieldDefaultSearchIconRight: textFieldDefaultSearchIconRight ??
          this.textFieldDefaultSearchIconRight,
      textFieldErrorSearchIconRight:
          textFieldErrorSearchIconRight ?? this.textFieldErrorSearchIconRight,
      textFieldSuccessSearchIconRight: textFieldSuccessSearchIconRight ??
          this.textFieldSuccessSearchIconRight,
      settingsItem2ActiveBG:
          settingsItem2ActiveBG ?? this.settingsItem2ActiveBG,
      settingsItem2ActiveText:
          settingsItem2ActiveText ?? this.settingsItem2ActiveText,
      settingsItem2ActiveSub:
          settingsItem2ActiveSub ?? this.settingsItem2ActiveSub,
      radioButtonIconBorder:
          radioButtonIconBorder ?? this.radioButtonIconBorder,
      radioButtonIconBorderDisabled:
          radioButtonIconBorderDisabled ?? this.radioButtonIconBorderDisabled,
      radioButtonBorderEnabled:
          radioButtonBorderEnabled ?? this.radioButtonBorderEnabled,
      radioButtonBorderDisabled:
          radioButtonBorderDisabled ?? this.radioButtonBorderDisabled,
      radioButtonIconCircle:
          radioButtonIconCircle ?? this.radioButtonIconCircle,
      radioButtonIconEnabled:
          radioButtonIconEnabled ?? this.radioButtonIconEnabled,
      radioButtonTextEnabled:
          radioButtonTextEnabled ?? this.radioButtonTextEnabled,
      radioButtonTextDisabled:
          radioButtonTextDisabled ?? this.radioButtonTextDisabled,
      radioButtonLabelEnabled:
          radioButtonLabelEnabled ?? this.radioButtonLabelEnabled,
      radioButtonLabelDisabled:
          radioButtonLabelDisabled ?? this.radioButtonLabelDisabled,
      infoItemBG: infoItemBG ?? this.infoItemBG,
      infoItemLabel: infoItemLabel ?? this.infoItemLabel,
      infoItemText: infoItemText ?? this.infoItemText,
      infoItemIcons: infoItemIcons ?? this.infoItemIcons,
      popupBG: popupBG ?? this.popupBG,
      currencyListItemBG: currencyListItemBG ?? this.currencyListItemBG,
      epicmobileBG: epicmobileBG ?? this.epicmobileBG,
      epicmobileMid: epicmobileMid ?? this.epicmobileMid,
      epicmobileBottom: epicmobileBottom ?? this.epicmobileBottom,
      bottomNavShadow: bottomNavShadow ?? this.bottomNavShadow,
      favoriteStarActive: favoriteStarActive ?? this.favoriteStarActive,
      favoriteStarInactive: favoriteStarInactive ?? this.favoriteStarInactive,
      splash: splash ?? this.splash,
      highlight: highlight ?? this.highlight,
      warningForeground: warningForeground ?? this.warningForeground,
      warningBackground: warningBackground ?? this.warningBackground,
      loadingOverlayTextColor:
          loadingOverlayTextColor ?? this.loadingOverlayTextColor,
      myStackContactIconBG: myStackContactIconBG ?? this.myStackContactIconBG,
      textConfirmTotalAmount:
          textConfirmTotalAmount ?? this.textConfirmTotalAmount,
      textSelectedWordTableItem:
          textSelectedWordTableItem ?? this.textSelectedWordTableItem,
    );
  }

  @override
  ThemeExtension<StackColors> lerp(
    ThemeExtension<StackColors>? other,
    double t,
  ) {
    if (other is! StackColors) {
      return this;
    }

    return StackColors(
      themeType: other.themeType,
      gradientBackground: other.gradientBackground,
      background: Color.lerp(
        background,
        other.background,
        t,
      )!,
      backgroundAppBar: Color.lerp(
        backgroundAppBar,
        other.backgroundAppBar,
        t,
      )!,
      overlay: Color.lerp(
        overlay,
        other.overlay,
        t,
      )!,
      accentColorBlue: Color.lerp(
        accentColorBlue,
        other.accentColorBlue,
        t,
      )!,
      accentColorGreen: Color.lerp(
        accentColorGreen,
        other.accentColorGreen,
        t,
      )!,
      accentColorYellow: Color.lerp(
        accentColorYellow,
        other.accentColorYellow,
        t,
      )!,
      accentColorRed: Color.lerp(
        accentColorRed,
        other.accentColorRed,
        t,
      )!,
      accentColorOrange: Color.lerp(
        accentColorOrange,
        other.accentColorOrange,
        t,
      )!,
      accentColorDark: Color.lerp(
        accentColorDark,
        other.accentColorDark,
        t,
      )!,
      shadow: Color.lerp(
        shadow,
        other.shadow,
        t,
      )!,
      textLight: Color.lerp(
        textLight,
        other.textLight,
        t,
      )!,
      textMedium: Color.lerp(
        textMedium,
        other.textMedium,
        t,
      )!,
      textDark: Color.lerp(
        textDark,
        other.textDark,
        t,
      )!,
      textSubtitle1: Color.lerp(
        textSubtitle1,
        other.textSubtitle1,
        t,
      )!,
      textSubtitle2: Color.lerp(
        textSubtitle2,
        other.textSubtitle2,
        t,
      )!,
      textSubtitle3: Color.lerp(
        textSubtitle3,
        other.textSubtitle3,
        t,
      )!,
      textSubtitle4: Color.lerp(
        textSubtitle4,
        other.textSubtitle4,
        t,
      )!,
      textSubtitle5: Color.lerp(
        textSubtitle5,
        other.textSubtitle5,
        t,
      )!,
      textSubtitle6: Color.lerp(
        textSubtitle6,
        other.textSubtitle6,
        t,
      )!,
      textWhite: Color.lerp(
        textWhite,
        other.textWhite,
        t,
      )!,
      textFavoriteCard: Color.lerp(
        textFavoriteCard,
        other.textFavoriteCard,
        t,
      )!,
      textError: Color.lerp(
        textError,
        other.textError,
        t,
      )!,
      buttonBackPrimary: Color.lerp(
        buttonBackPrimary,
        other.buttonBackPrimary,
        t,
      )!,
      buttonBackSecondary: Color.lerp(
        buttonBackSecondary,
        other.buttonBackSecondary,
        t,
      )!,
      buttonBackPrimaryDisabled: Color.lerp(
        buttonBackPrimaryDisabled,
        other.buttonBackPrimaryDisabled,
        t,
      )!,
      buttonBackSecondaryDisabled: Color.lerp(
        buttonBackSecondaryDisabled,
        other.buttonBackSecondaryDisabled,
        t,
      )!,
      buttonBackBorder: Color.lerp(
        buttonBackBorder,
        other.buttonBackBorder,
        t,
      )!,
      buttonBackBorderDisabled: Color.lerp(
        buttonBackBorderDisabled,
        other.buttonBackBorderDisabled,
        t,
      )!,
      numberBackDefault: Color.lerp(
        numberBackDefault,
        other.numberBackDefault,
        t,
      )!,
      numpadBackDefault: Color.lerp(
        numpadBackDefault,
        other.numpadBackDefault,
        t,
      )!,
      bottomNavBack: Color.lerp(
        bottomNavBack,
        other.bottomNavBack,
        t,
      )!,
      buttonTextPrimary: Color.lerp(
        buttonTextPrimary,
        other.buttonTextPrimary,
        t,
      )!,
      buttonTextSecondary: Color.lerp(
        buttonTextSecondary,
        other.buttonTextSecondary,
        t,
      )!,
      buttonTextPrimaryDisabled: Color.lerp(
        buttonTextPrimaryDisabled,
        other.buttonTextPrimaryDisabled,
        t,
      )!,
      buttonTextSecondaryDisabled: Color.lerp(
        buttonTextSecondaryDisabled,
        other.buttonTextSecondaryDisabled,
        t,
      )!,
      buttonTextBorder: Color.lerp(
        buttonTextBorder,
        other.buttonTextBorder,
        t,
      )!,
      buttonTextDisabled: Color.lerp(
        buttonTextDisabled,
        other.buttonTextDisabled,
        t,
      )!,
      buttonTextBorderless: Color.lerp(
        buttonTextBorderless,
        other.buttonTextBorderless,
        t,
      )!,
      buttonTextBorderlessDisabled: Color.lerp(
        buttonTextBorderlessDisabled,
        other.buttonTextBorderlessDisabled,
        t,
      )!,
      numberTextDefault: Color.lerp(
        numberTextDefault,
        other.numberTextDefault,
        t,
      )!,
      numpadTextDefault: Color.lerp(
        numpadTextDefault,
        other.numpadTextDefault,
        t,
      )!,
      bottomNavText: Color.lerp(
        bottomNavText,
        other.bottomNavText,
        t,
      )!,
      switchBGOn: Color.lerp(
        switchBGOn,
        other.switchBGOn,
        t,
      )!,
      switchBGOff: Color.lerp(
        switchBGOff,
        other.switchBGOff,
        t,
      )!,
      switchBGDisabled: Color.lerp(
        switchBGDisabled,
        other.switchBGDisabled,
        t,
      )!,
      switchCircleOn: Color.lerp(
        switchCircleOn,
        other.switchCircleOn,
        t,
      )!,
      switchCircleOff: Color.lerp(
        switchCircleOff,
        other.switchCircleOff,
        t,
      )!,
      switchCircleDisabled: Color.lerp(
        switchCircleDisabled,
        other.switchCircleDisabled,
        t,
      )!,
      stepIndicatorBGCheck: Color.lerp(
        stepIndicatorBGCheck,
        other.stepIndicatorBGCheck,
        t,
      )!,
      stepIndicatorBGNumber: Color.lerp(
        stepIndicatorBGNumber,
        other.stepIndicatorBGNumber,
        t,
      )!,
      stepIndicatorBGInactive: Color.lerp(
        stepIndicatorBGInactive,
        other.stepIndicatorBGInactive,
        t,
      )!,
      stepIndicatorBGLines: Color.lerp(
        stepIndicatorBGLines,
        other.stepIndicatorBGLines,
        t,
      )!,
      stepIndicatorBGLinesInactive: Color.lerp(
        stepIndicatorBGLinesInactive,
        other.stepIndicatorBGLinesInactive,
        t,
      )!,
      stepIndicatorIconText: Color.lerp(
        stepIndicatorIconText,
        other.stepIndicatorIconText,
        t,
      )!,
      stepIndicatorIconNumber: Color.lerp(
        stepIndicatorIconNumber,
        other.stepIndicatorIconNumber,
        t,
      )!,
      stepIndicatorIconInactive: Color.lerp(
        stepIndicatorIconInactive,
        other.stepIndicatorIconInactive,
        t,
      )!,
      checkboxBGChecked: Color.lerp(
        checkboxBGChecked,
        other.checkboxBGChecked,
        t,
      )!,
      checkboxBorderEmpty: Color.lerp(
        checkboxBorderEmpty,
        other.checkboxBorderEmpty,
        t,
      )!,
      checkboxBGDisabled: Color.lerp(
        checkboxBGDisabled,
        other.checkboxBGDisabled,
        t,
      )!,
      checkboxIconChecked: Color.lerp(
        checkboxIconChecked,
        other.checkboxIconChecked,
        t,
      )!,
      checkboxIconDisabled: Color.lerp(
        checkboxIconDisabled,
        other.checkboxIconDisabled,
        t,
      )!,
      checkboxTextLabel: Color.lerp(
        checkboxTextLabel,
        other.checkboxTextLabel,
        t,
      )!,
      snackBarBackSuccess: Color.lerp(
        snackBarBackSuccess,
        other.snackBarBackSuccess,
        t,
      )!,
      snackBarBackError: Color.lerp(
        snackBarBackError,
        other.snackBarBackError,
        t,
      )!,
      snackBarBackInfo: Color.lerp(
        snackBarBackInfo,
        other.snackBarBackInfo,
        t,
      )!,
      snackBarTextSuccess: Color.lerp(
        snackBarTextSuccess,
        other.snackBarTextSuccess,
        t,
      )!,
      snackBarTextError: Color.lerp(
        snackBarTextError,
        other.snackBarTextError,
        t,
      )!,
      snackBarTextInfo: Color.lerp(
        snackBarTextInfo,
        other.snackBarTextInfo,
        t,
      )!,
      bottomNavIconBack: Color.lerp(
        bottomNavIconBack,
        other.bottomNavIconBack,
        t,
      )!,
      bottomNavIconIcon: Color.lerp(
        bottomNavIconIcon,
        other.bottomNavIconIcon,
        t,
      )!,
      topNavIconPrimary: Color.lerp(
        topNavIconPrimary,
        other.topNavIconPrimary,
        t,
      )!,
      topNavIconGreen: Color.lerp(
        topNavIconGreen,
        other.topNavIconGreen,
        t,
      )!,
      topNavIconYellow: Color.lerp(
        topNavIconYellow,
        other.topNavIconYellow,
        t,
      )!,
      topNavIconRed: Color.lerp(
        topNavIconRed,
        other.topNavIconRed,
        t,
      )!,
      settingsIconBack: Color.lerp(
        settingsIconBack,
        other.settingsIconBack,
        t,
      )!,
      settingsIconIcon: Color.lerp(
        settingsIconIcon,
        other.settingsIconIcon,
        t,
      )!,
      settingsIconBack2: Color.lerp(
        settingsIconBack2,
        other.settingsIconBack2,
        t,
      )!,
      settingsIconElement: Color.lerp(
        settingsIconElement,
        other.settingsIconElement,
        t,
      )!,
      textFieldActiveBG: Color.lerp(
        textFieldActiveBG,
        other.textFieldActiveBG,
        t,
      )!,
      textFieldDefaultBG: Color.lerp(
        textFieldDefaultBG,
        other.textFieldDefaultBG,
        t,
      )!,
      textFieldErrorBG: Color.lerp(
        textFieldErrorBG,
        other.textFieldErrorBG,
        t,
      )!,
      textFieldSuccessBG: Color.lerp(
        textFieldSuccessBG,
        other.textFieldSuccessBG,
        t,
      )!,
      textFieldActiveSearchIconLeft: Color.lerp(
        textFieldActiveSearchIconLeft,
        other.textFieldActiveSearchIconLeft,
        t,
      )!,
      textFieldDefaultSearchIconLeft: Color.lerp(
        textFieldDefaultSearchIconLeft,
        other.textFieldDefaultSearchIconLeft,
        t,
      )!,
      textFieldErrorSearchIconLeft: Color.lerp(
        textFieldErrorSearchIconLeft,
        other.textFieldErrorSearchIconLeft,
        t,
      )!,
      textFieldSuccessSearchIconLeft: Color.lerp(
        textFieldSuccessSearchIconLeft,
        other.textFieldSuccessSearchIconLeft,
        t,
      )!,
      textFieldActiveText: Color.lerp(
        textFieldActiveText,
        other.textFieldActiveText,
        t,
      )!,
      textFieldDefaultText: Color.lerp(
        textFieldDefaultText,
        other.textFieldDefaultText,
        t,
      )!,
      textFieldErrorText: Color.lerp(
        textFieldErrorText,
        other.textFieldErrorText,
        t,
      )!,
      textFieldSuccessText: Color.lerp(
        textFieldSuccessText,
        other.textFieldSuccessText,
        t,
      )!,
      textFieldActiveLabel: Color.lerp(
        textFieldActiveLabel,
        other.textFieldActiveLabel,
        t,
      )!,
      textFieldErrorLabel: Color.lerp(
        textFieldErrorLabel,
        other.textFieldErrorLabel,
        t,
      )!,
      textFieldSuccessLabel: Color.lerp(
        textFieldSuccessLabel,
        other.textFieldSuccessLabel,
        t,
      )!,
      textFieldActiveSearchIconRight: Color.lerp(
        textFieldActiveSearchIconRight,
        other.textFieldActiveSearchIconRight,
        t,
      )!,
      textFieldDefaultSearchIconRight: Color.lerp(
          textFieldDefaultSearchIconRight,
          other.textFieldDefaultSearchIconRight,
          t)!,
      textFieldErrorSearchIconRight: Color.lerp(
        textFieldErrorSearchIconRight,
        other.textFieldErrorSearchIconRight,
        t,
      )!,
      textFieldSuccessSearchIconRight: Color.lerp(
          textFieldSuccessSearchIconRight,
          other.textFieldSuccessSearchIconRight,
          t)!,
      settingsItem2ActiveBG: Color.lerp(
        settingsItem2ActiveBG,
        other.settingsItem2ActiveBG,
        t,
      )!,
      settingsItem2ActiveText: Color.lerp(
        settingsItem2ActiveText,
        other.settingsItem2ActiveText,
        t,
      )!,
      settingsItem2ActiveSub: Color.lerp(
        settingsItem2ActiveSub,
        other.settingsItem2ActiveSub,
        t,
      )!,
      radioButtonIconBorder: Color.lerp(
        radioButtonIconBorder,
        other.radioButtonIconBorder,
        t,
      )!,
      radioButtonIconBorderDisabled: Color.lerp(
        radioButtonIconBorderDisabled,
        other.radioButtonIconBorderDisabled,
        t,
      )!,
      radioButtonBorderEnabled: Color.lerp(
        radioButtonBorderEnabled,
        other.radioButtonBorderEnabled,
        t,
      )!,
      radioButtonBorderDisabled: Color.lerp(
        radioButtonBorderDisabled,
        other.radioButtonBorderDisabled,
        t,
      )!,
      radioButtonIconCircle: Color.lerp(
        radioButtonIconCircle,
        other.radioButtonIconCircle,
        t,
      )!,
      radioButtonIconEnabled: Color.lerp(
        radioButtonIconEnabled,
        other.radioButtonIconEnabled,
        t,
      )!,
      radioButtonTextEnabled: Color.lerp(
        radioButtonTextEnabled,
        other.radioButtonTextEnabled,
        t,
      )!,
      radioButtonTextDisabled: Color.lerp(
        radioButtonTextDisabled,
        other.radioButtonTextDisabled,
        t,
      )!,
      radioButtonLabelEnabled: Color.lerp(
        radioButtonLabelEnabled,
        other.radioButtonLabelEnabled,
        t,
      )!,
      radioButtonLabelDisabled: Color.lerp(
        radioButtonLabelDisabled,
        other.radioButtonLabelDisabled,
        t,
      )!,
      infoItemBG: Color.lerp(
        infoItemBG,
        other.infoItemBG,
        t,
      )!,
      infoItemLabel: Color.lerp(
        infoItemLabel,
        other.infoItemLabel,
        t,
      )!,
      infoItemText: Color.lerp(
        infoItemText,
        other.infoItemText,
        t,
      )!,
      infoItemIcons: Color.lerp(
        infoItemIcons,
        other.infoItemIcons,
        t,
      )!,
      popupBG: Color.lerp(
        popupBG,
        other.popupBG,
        t,
      )!,
      currencyListItemBG: Color.lerp(
        currencyListItemBG,
        other.currencyListItemBG,
        t,
      )!,
      epicmobileBG: Color.lerp(
        epicmobileBG,
        other.epicmobileBG,
        t,
      )!,
      epicmobileMid: Color.lerp(
        epicmobileMid,
        other.epicmobileMid,
        t,
      )!,
      epicmobileBottom: Color.lerp(
        epicmobileBottom,
        other.epicmobileBottom,
        t,
      )!,
      bottomNavShadow: Color.lerp(
        bottomNavShadow,
        other.bottomNavShadow,
        t,
      )!,
      favoriteStarActive: Color.lerp(
        favoriteStarActive,
        other.favoriteStarActive,
        t,
      )!,
      favoriteStarInactive: Color.lerp(
        favoriteStarInactive,
        other.favoriteStarInactive,
        t,
      )!,
      splash: Color.lerp(
        splash,
        other.splash,
        t,
      )!,
      highlight: Color.lerp(
        highlight,
        other.highlight,
        t,
      )!,
      warningForeground: Color.lerp(
        warningForeground,
        other.warningForeground,
        t,
      )!,
      warningBackground: Color.lerp(
        warningBackground,
        other.warningBackground,
        t,
      )!,
      loadingOverlayTextColor: Color.lerp(
        loadingOverlayTextColor,
        other.loadingOverlayTextColor,
        t,
      )!,
      myStackContactIconBG: Color.lerp(
        myStackContactIconBG,
        other.myStackContactIconBG,
        t,
      )!,
      textConfirmTotalAmount: Color.lerp(
        textConfirmTotalAmount,
        other.textConfirmTotalAmount,
        t,
      )!,
      textSelectedWordTableItem: Color.lerp(
        textSelectedWordTableItem,
        other.textSelectedWordTableItem,
        t,
      )!,
    );
  }

  Color colorForCoin(Coin coin) {
    switch (coin) {
      case Coin.epicCash:
        return _coin.epicCash;
    }
  }

  static const _coin = CoinThemeColor();

  BoxShadow get standardBoxShadow => BoxShadow(
        color: shadow,
        spreadRadius: 3,
        blurRadius: 4,
      );

  Color colorForStatus(String status) {
    switch (status) {
      case "New":
      case "new":
      case "Waiting":
      case "waiting":
      case "Confirming":
      case "confirming":
      case "Exchanging":
      case "exchanging":
      case "Sending":
      case "sending":
      case "Verifying":
      case "verifying":
        return const Color(0xFFD3A90F);
      case "Finished":
      case "finished":
        return accentColorGreen;
      case "Failed":
      case "failed":
      case "closed":
      case "expired":
        return accentColorRed;
      case "Refunded":
      case "refunded":
        return textSubtitle2;
      default:
        return const Color(0xFFD3A90F);
    }
  }

  ButtonStyle? getDeleteEnabledButtonColor(BuildContext context) =>
      Theme.of(context).textButtonTheme.style?.copyWith(
            backgroundColor: MaterialStateProperty.all<Color>(
              textFieldErrorBG,
            ),
          );

  ButtonStyle? getDeleteDisabledButtonColor(BuildContext context) =>
      Theme.of(context).textButtonTheme.style?.copyWith(
            backgroundColor: MaterialStateProperty.all<Color>(
              buttonBackSecondaryDisabled,
            ),
          );

  ButtonStyle? getPrimaryEnabledButtonColor(BuildContext context) =>
      Theme.of(context).textButtonTheme.style?.copyWith(
            backgroundColor: MaterialStateProperty.all<Color>(
              buttonBackPrimary,
            ),
          );

  ButtonStyle? getPrimaryDisabledButtonColor(BuildContext context) =>
      Theme.of(context).textButtonTheme.style?.copyWith(
            backgroundColor: MaterialStateProperty.all<Color>(
              buttonBackPrimaryDisabled,
            ),
          );

  ButtonStyle? getSecondaryEnabledButtonColor(BuildContext context) =>
      Theme.of(context).textButtonTheme.style?.copyWith(
            backgroundColor: MaterialStateProperty.all<Color>(
              buttonBackSecondary,
            ),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                side: BorderSide(
                  color: buttonBackBorder,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(1000),
              ),
            ),
          );

  ButtonStyle? getSecondaryDisabledButtonColor(BuildContext context) =>
      Theme.of(context).textButtonTheme.style?.copyWith(
            backgroundColor: MaterialStateProperty.all<Color>(
              buttonBackSecondaryDisabled,
            ),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                side: BorderSide(
                  color: buttonBackBorderDisabled,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(1000),
              ),
            ),
          );

  ButtonStyle? getSmallSecondaryEnabledButtonColor(BuildContext context) =>
      Theme.of(context).textButtonTheme.style?.copyWith(
            backgroundColor: MaterialStateProperty.all<Color>(
              textFieldDefaultBG,
            ),
          );

  ButtonStyle? getDesktopMenuButtonColor(BuildContext context) =>
      Theme.of(context).textButtonTheme.style?.copyWith(
            backgroundColor: MaterialStateProperty.all<Color>(
              popupBG,
            ),
          );

  ButtonStyle? getDesktopMenuButtonColorSelected(BuildContext context) =>
      Theme.of(context).textButtonTheme.style?.copyWith(
            backgroundColor: MaterialStateProperty.all<Color>(
              textFieldDefaultBG,
            ),
          );

  ButtonStyle? getDesktopSettingsButtonColor(BuildContext context) =>
      Theme.of(context).textButtonTheme.style?.copyWith(
            backgroundColor: MaterialStateProperty.all<Color>(
              background,
            ),
            overlayColor: MaterialStateProperty.all<Color>(
              Colors.transparent,
            ),
          );
}
