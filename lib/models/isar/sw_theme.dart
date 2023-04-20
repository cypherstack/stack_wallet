import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/extensions/impl/gradient.dart';
import 'package:stackwallet/utilities/extensions/impl/string.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';
import 'package:uuid/uuid.dart';

@Collection(inheritance: false)
class StackTheme {
  final String assetBundleUrl;

  /// should be a uuid
  @Index(unique: true, replace: true)
  final String internalId;

  /// the theme name that will be displayed in app
  final String name;

  // system brightness
  final String brightnessString;

  /// convenience enum conversion for stored [brightnessString]
  @ignore
  Brightness get brightness {
    switch (brightnessString) {
      case "light":
        return Brightness.light;
      case "dark":
        return Brightness.dark;
      default:
        // just return light instead of a possible crash causing error
        return Brightness.light;
    }
  }

// ==== background =====================================================

  @ignore
  Color get background => _background ??= Color(backgroundInt);
  @ignore
  Color? _background;
  final int backgroundInt;

  // ==== backgroundAppBar =====================================================

  @ignore
  Color get backgroundAppBar =>
      _backgroundAppBar ??= Color(backgroundAppBarInt);
  @ignore
  Color? _backgroundAppBar;
  final int backgroundAppBarInt;

  // ==== gradientBackground =====================================================

  @ignore
  Gradient get gradientBackground =>
      _gradientBackground ??= GradientExt.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(gradientBackgroundString) as Map,
        ),
      );
  @ignore
  Gradient? _gradientBackground;
  final String gradientBackgroundString;

  // ==== overlay =====================================================

  @ignore
  Color get overlay => _overlay ??= Color(overlayInt);
  @ignore
  Color? _overlay;
  final int overlayInt;

  // ==== accentColorBlue =====================================================

  @ignore
  Color get accentColorBlue => _accentColorBlue ??= Color(
        accentColorBlueInt,
      );
  @ignore
  Color? _accentColorBlue;
  final int accentColorBlueInt;

  // ==== accentColorGreen =====================================================

  @ignore
  Color get accentColorGreen => _accentColorGreen ??= Color(
        accentColorGreenInt,
      );
  @ignore
  Color? _accentColorGreen;
  final int accentColorGreenInt;

  // ==== accentColorYellow =====================================================

  @ignore
  Color get accentColorYellow => _accentColorYellow ??= Color(
        accentColorYellowInt,
      );
  @ignore
  Color? _accentColorYellow;
  final int accentColorYellowInt;

  // ==== accentColorRed =====================================================

  @ignore
  Color get accentColorRed => _accentColorRed ??= Color(
        accentColorRedInt,
      );
  @ignore
  Color? _accentColorRed;
  final int accentColorRedInt;

  // ==== accentColorOrange =====================================================

  @ignore
  Color get accentColorOrange => _accentColorOrange ??= Color(
        accentColorOrangeInt,
      );
  @ignore
  Color? _accentColorOrange;
  final int accentColorOrangeInt;

  // ==== accentColorDark =====================================================

  @ignore
  Color get accentColorDark => _accentColorDark ??= Color(
        accentColorDarkInt,
      );
  @ignore
  Color? _accentColorDark;
  final int accentColorDarkInt;

  // ==== shadow =====================================================

  @ignore
  Color get shadow => _shadow ??= Color(
        shadowInt,
      );
  @ignore
  Color? _shadow;
  final int shadowInt;

  // ==== textDark =====================================================

  @ignore
  Color get textDark => _textDark ??= Color(
        textDarkInt,
      );
  @ignore
  Color? _textDark;
  final int textDarkInt;

  // ==== textDark2 =====================================================

  @ignore
  Color get textDark2 => _textDark2 ??= Color(
        textDark2Int,
      );
  @ignore
  Color? _textDark2;
  final int textDark2Int;

  // ==== textDark3 =====================================================

  @ignore
  Color get textDark3 => _textDark3 ??= Color(
        textDark3Int,
      );
  @ignore
  Color? _textDark3;
  final int textDark3Int;

  // ==== textSubtitle1 =====================================================

  @ignore
  Color get textSubtitle1 => _textSubtitle1 ??= Color(
        textSubtitle1Int,
      );
  @ignore
  Color? _textSubtitle1;
  final int textSubtitle1Int;

  // ==== textSubtitle2 =====================================================

  @ignore
  Color get textSubtitle2 => _textSubtitle2 ??= Color(
        textSubtitle2Int,
      );
  @ignore
  Color? _textSubtitle2;
  final int textSubtitle2Int;

  // ==== textSubtitle3 =====================================================

  @ignore
  Color get textSubtitle3 => _textSubtitle3 ??= Color(
        textSubtitle3Int,
      );
  @ignore
  Color? _textSubtitle3;
  final int textSubtitle3Int;

  // ==== textSubtitle4 =====================================================

  @ignore
  Color get textSubtitle4 => _textSubtitle4 ??= Color(
        textSubtitle4Int,
      );
  @ignore
  Color? _textSubtitle4;
  final int textSubtitle4Int;

  // ==== textSubtitle5 =====================================================

  @ignore
  Color get textSubtitle5 => _textSubtitle5 ??= Color(
        textSubtitle5Int,
      );
  @ignore
  Color? _textSubtitle5;
  final int textSubtitle5Int;

  // ==== textSubtitle6 =====================================================

  @ignore
  Color get textSubtitle6 => _textSubtitle6 ??= Color(
        textSubtitle6Int,
      );
  @ignore
  Color? _textSubtitle6;
  final int textSubtitle6Int;

  // ==== textWhite =====================================================

  @ignore
  Color get textWhite => _textWhite ??= Color(
        textWhiteInt,
      );
  @ignore
  Color? _textWhite;
  final int textWhiteInt;

  // ==== textFavoriteCard =====================================================

  @ignore
  Color get textFavoriteCard => _textFavoriteCard ??= Color(
        textFavoriteCardInt,
      );
  @ignore
  Color? _textFavoriteCard;
  final int textFavoriteCardInt;

  // ==== textError =====================================================

  @ignore
  Color get textError => _textError ??= Color(
        textErrorInt,
      );
  @ignore
  Color? _textError;
  final int textErrorInt;

  // ==== textRestore =====================================================

  @ignore
  Color get textRestore => _textRestore ??= Color(
        textRestoreInt,
      );
  @ignore
  Color? _textRestore;
  final int textRestoreInt;

  // ==== buttonBackPrimary =====================================================

  @ignore
  Color get buttonBackPrimary => _buttonBackPrimary ??= Color(
        buttonBackPrimaryInt,
      );
  @ignore
  Color? _buttonBackPrimary;
  final int buttonBackPrimaryInt;

  // ==== buttonBackSecondary =====================================================

  @ignore
  Color get buttonBackSecondary => _buttonBackSecondary ??= Color(
        buttonBackSecondaryInt,
      );
  @ignore
  Color? _buttonBackSecondary;
  final int buttonBackSecondaryInt;

  // ==== buttonBackPrimaryDisabled =====================================================

  @ignore
  Color get buttonBackPrimaryDisabled => _buttonBackPrimaryDisabled ??= Color(
        buttonBackPrimaryDisabledInt,
      );
  @ignore
  Color? _buttonBackPrimaryDisabled;
  final int buttonBackPrimaryDisabledInt;

  // ==== buttonBackSecondaryDisabled =====================================================

  @ignore
  Color get buttonBackSecondaryDisabled =>
      _buttonBackSecondaryDisabled ??= Color(
        buttonBackSecondaryDisabledInt,
      );
  @ignore
  Color? _buttonBackSecondaryDisabled;
  final int buttonBackSecondaryDisabledInt;

  // ==== buttonBackBorder =====================================================

  @ignore
  Color get buttonBackBorder => _buttonBackBorder ??= Color(
        buttonBackBorderInt,
      );
  @ignore
  Color? _buttonBackBorder;
  final int buttonBackBorderInt;

  // ==== buttonBackBorderDisabled =====================================================

  @ignore
  Color get buttonBackBorderDisabled => _buttonBackBorderDisabled ??= Color(
        buttonBackBorderDisabledInt,
      );
  @ignore
  Color? _buttonBackBorderDisabled;
  final int buttonBackBorderDisabledInt;

  // ==== buttonBackBorderSecondary =====================================================

  @ignore
  Color get buttonBackBorderSecondary => _buttonBackBorderSecondary ??= Color(
        buttonBackBorderSecondaryInt,
      );
  @ignore
  Color? _buttonBackBorderSecondary;
  final int buttonBackBorderSecondaryInt;

  // ==== buttonBackBorderSecondaryDisabled =====================================================

  @ignore
  Color get buttonBackBorderSecondaryDisabled =>
      _buttonBackBorderSecondaryDisabled ??= Color(
        buttonBackBorderSecondaryDisabledInt,
      );
  @ignore
  Color? _buttonBackBorderSecondaryDisabled;
  final int buttonBackBorderSecondaryDisabledInt;

  // ==== numberBackDefault =====================================================

  @ignore
  Color get numberBackDefault => _numberBackDefault ??= Color(
        numberBackDefaultInt,
      );
  @ignore
  Color? _numberBackDefault;
  final int numberBackDefaultInt;

  // ==== numpadBackDefault =====================================================

  @ignore
  Color get numpadBackDefault => _numpadBackDefault ??= Color(
        numpadBackDefaultInt,
      );
  @ignore
  Color? _numpadBackDefault;
  final int numpadBackDefaultInt;

  // ==== bottomNavBack =====================================================

  @ignore
  Color get bottomNavBack => _bottomNavBack ??= Color(
        bottomNavBackInt,
      );
  @ignore
  Color? _bottomNavBack;
  final int bottomNavBackInt;

  // ==== buttonTextPrimary =====================================================

  @ignore
  Color get buttonTextPrimary => _buttonTextPrimary ??= Color(
        buttonTextPrimaryInt,
      );
  @ignore
  Color? _buttonTextPrimary;
  final int buttonTextPrimaryInt;

  // ==== buttonTextSecondary =====================================================

  @ignore
  Color get buttonTextSecondary => _buttonTextSecondary ??= Color(
        buttonTextSecondaryInt,
      );
  @ignore
  Color? _buttonTextSecondary;
  final int buttonTextSecondaryInt;

  // ==== buttonTextPrimaryDisabled =====================================================

  @ignore
  Color get buttonTextPrimaryDisabled => _buttonTextPrimaryDisabled ??= Color(
        buttonTextPrimaryDisabledInt,
      );
  @ignore
  Color? _buttonTextPrimaryDisabled;
  final int buttonTextPrimaryDisabledInt;

  // ==== buttonTextSecondaryDisabled =====================================================

  @ignore
  Color get buttonTextSecondaryDisabled =>
      _buttonTextSecondaryDisabled ??= Color(buttonTextSecondaryDisabledInt);
  @ignore
  Color? _buttonTextSecondaryDisabled;
  final int buttonTextSecondaryDisabledInt;

  // ==== buttonTextBorder =====================================================

  @ignore
  Color get buttonTextBorder =>
      _buttonTextBorder ??= Color(buttonTextBorderInt);
  @ignore
  Color? _buttonTextBorder;
  final int buttonTextBorderInt;

  // ==== buttonTextDisabled =====================================================

  @ignore
  Color get buttonTextDisabled =>
      _buttonTextDisabled ??= Color(buttonTextDisabledInt);
  @ignore
  Color? _buttonTextDisabled;
  final int buttonTextDisabledInt;

  // ==== buttonTextBorderless =====================================================

  @ignore
  Color get buttonTextBorderless =>
      _buttonTextBorderless ??= Color(buttonTextBorderlessInt);
  @ignore
  Color? _buttonTextBorderless;
  final int buttonTextBorderlessInt;

  // ==== buttonTextBorderlessDisabled =====================================================

  @ignore
  Color get buttonTextBorderlessDisabled =>
      _buttonTextBorderlessDisabled ??= Color(buttonTextBorderlessDisabledInt);
  @ignore
  Color? _buttonTextBorderlessDisabled;
  final int buttonTextBorderlessDisabledInt;

  // ==== numberTextDefault =====================================================

  @ignore
  Color get numberTextDefault =>
      _numberTextDefault ??= Color(numberTextDefaultInt);
  @ignore
  Color? _numberTextDefault;
  final int numberTextDefaultInt;

  // ==== numpadTextDefault =====================================================

  @ignore
  Color get numpadTextDefault =>
      _numpadTextDefault ??= Color(numpadTextDefaultInt);
  @ignore
  Color? _numpadTextDefault;
  final int numpadTextDefaultInt;

  // ==== bottomNavText =====================================================

  @ignore
  Color get bottomNavText => _bottomNavText ??= Color(bottomNavTextInt);
  @ignore
  Color? _bottomNavText;
  final int bottomNavTextInt;

  // ==== customTextButtonEnabledText =====================================================

  @ignore
  Color get customTextButtonEnabledText =>
      _customTextButtonEnabledText ??= Color(customTextButtonEnabledTextInt);
  @ignore
  Color? _customTextButtonEnabledText;
  final int customTextButtonEnabledTextInt;

  // ==== customTextButtonDisabledText =====================================================

  @ignore
  Color get customTextButtonDisabledText =>
      _customTextButtonDisabledText ??= Color(customTextButtonDisabledTextInt);
  @ignore
  Color? _customTextButtonDisabledText;
  final int customTextButtonDisabledTextInt;

  // ==== switchBGOn =====================================================

  @ignore
  Color get switchBGOn => _switchBGOn ??= Color(switchBGOnInt);
  @ignore
  Color? _switchBGOn;
  final int switchBGOnInt;

  // ==== switchBGOff =====================================================

  @ignore
  Color get switchBGOff => _switchBGOff ??= Color(switchBGOffInt);
  @ignore
  Color? _switchBGOff;
  final int switchBGOffInt;

  // ==== switchBGDisabled =====================================================

  @ignore
  Color get switchBGDisabled =>
      _switchBGDisabled ??= Color(switchBGDisabledInt);
  @ignore
  Color? _switchBGDisabled;
  final int switchBGDisabledInt;

  // ==== switchCircleOn =====================================================

  @ignore
  Color get switchCircleOn => _switchCircleOn ??= Color(switchCircleOnInt);
  @ignore
  Color? _switchCircleOn;
  final int switchCircleOnInt;

  // ==== switchCircleOff =====================================================

  @ignore
  Color get switchCircleOff => _switchCircleOff ??= Color(switchCircleOffInt);
  @ignore
  Color? _switchCircleOff;
  final int switchCircleOffInt;

  // ==== switchCircleDisabled =====================================================

  @ignore
  Color get switchCircleDisabled =>
      _switchCircleDisabled ??= Color(switchCircleDisabledInt);
  @ignore
  Color? _switchCircleDisabled;
  final int switchCircleDisabledInt;

  // ==== stepIndicatorBGCheck =====================================================

  @ignore
  Color get stepIndicatorBGCheck =>
      _stepIndicatorBGCheck ??= Color(stepIndicatorBGCheckInt);
  @ignore
  Color? _stepIndicatorBGCheck;
  final int stepIndicatorBGCheckInt;

  // ==== stepIndicatorBGNumber =====================================================

  @ignore
  Color get stepIndicatorBGNumber =>
      _stepIndicatorBGNumber ??= Color(stepIndicatorBGNumberInt);
  @ignore
  Color? _stepIndicatorBGNumber;
  final int stepIndicatorBGNumberInt;

  // ==== stepIndicatorBGInactive =====================================================

  @ignore
  Color get stepIndicatorBGInactive =>
      _stepIndicatorBGInactive ??= Color(stepIndicatorBGInactiveInt);
  @ignore
  Color? _stepIndicatorBGInactive;
  final int stepIndicatorBGInactiveInt;

  // ==== stepIndicatorBGLines =====================================================

  @ignore
  Color get stepIndicatorBGLines =>
      _stepIndicatorBGLines ??= Color(stepIndicatorBGLinesInt);
  @ignore
  Color? _stepIndicatorBGLines;
  final int stepIndicatorBGLinesInt;

  // ==== stepIndicatorBGLinesInactive =====================================================

  @ignore
  Color get stepIndicatorBGLinesInactive =>
      _stepIndicatorBGLinesInactive ??= Color(stepIndicatorBGLinesInactiveInt);
  @ignore
  Color? _stepIndicatorBGLinesInactive;
  final int stepIndicatorBGLinesInactiveInt;

  // ==== stepIndicatorIconText =====================================================

  @ignore
  Color get stepIndicatorIconText =>
      _stepIndicatorIconText ??= Color(stepIndicatorIconTextInt);
  @ignore
  Color? _stepIndicatorIconText;
  final int stepIndicatorIconTextInt;

  // ==== stepIndicatorIconNumber =====================================================

  @ignore
  Color get stepIndicatorIconNumber =>
      _stepIndicatorIconNumber ??= Color(stepIndicatorIconNumberInt);
  @ignore
  Color? _stepIndicatorIconNumber;
  final int stepIndicatorIconNumberInt;

  // ==== stepIndicatorIconInactive =====================================================

  @ignore
  Color get stepIndicatorIconInactive =>
      _stepIndicatorIconInactive ??= Color(stepIndicatorIconInactiveInt);
  @ignore
  Color? _stepIndicatorIconInactive;
  final int stepIndicatorIconInactiveInt;

  // ==== checkboxBGChecked =====================================================

  @ignore
  Color get checkboxBGChecked =>
      _checkboxBGChecked ??= Color(checkboxBGCheckedInt);
  @ignore
  Color? _checkboxBGChecked;
  final int checkboxBGCheckedInt;

  // ==== checkboxBorderEmpty =====================================================

  @ignore
  Color get checkboxBorderEmpty =>
      _checkboxBorderEmpty ??= Color(checkboxBorderEmptyInt);
  @ignore
  Color? _checkboxBorderEmpty;
  final int checkboxBorderEmptyInt;

  // ==== checkboxBGDisabled =====================================================

  @ignore
  Color get checkboxBGDisabled =>
      _checkboxBGDisabled ??= Color(checkboxBGDisabledInt);
  @ignore
  Color? _checkboxBGDisabled;
  final int checkboxBGDisabledInt;

  // ==== checkboxIconChecked =====================================================

  @ignore
  Color get checkboxIconChecked =>
      _checkboxIconChecked ??= Color(checkboxIconCheckedInt);
  @ignore
  Color? _checkboxIconChecked;
  final int checkboxIconCheckedInt;

  // ==== checkboxIconDisabled =====================================================

  @ignore
  Color get checkboxIconDisabled =>
      _checkboxIconDisabled ??= Color(checkboxIconDisabledInt);
  @ignore
  Color? _checkboxIconDisabled;
  final int checkboxIconDisabledInt;

  // ==== checkboxTextLabel =====================================================

  @ignore
  Color get checkboxTextLabel =>
      _checkboxTextLabel ??= Color(checkboxTextLabelInt);
  @ignore
  Color? _checkboxTextLabel;
  final int checkboxTextLabelInt;

  // ==== snackBarBackSuccess =====================================================

  @ignore
  Color get snackBarBackSuccess =>
      _snackBarBackSuccess ??= Color(snackBarBackSuccessInt);
  @ignore
  Color? _snackBarBackSuccess;
  final int snackBarBackSuccessInt;

  // ==== snackBarBackError =====================================================

  @ignore
  Color get snackBarBackError =>
      _snackBarBackError ??= Color(snackBarBackErrorInt);
  @ignore
  Color? _snackBarBackError;
  final int snackBarBackErrorInt;

  // ==== snackBarBackInfo =====================================================

  @ignore
  Color get snackBarBackInfo =>
      _snackBarBackInfo ??= Color(snackBarBackInfoInt);
  @ignore
  Color? _snackBarBackInfo;
  final int snackBarBackInfoInt;

  // ==== snackBarTextSuccess =====================================================

  @ignore
  Color get snackBarTextSuccess =>
      _snackBarTextSuccess ??= Color(snackBarTextSuccessInt);
  @ignore
  Color? _snackBarTextSuccess;
  final int snackBarTextSuccessInt;

  // ==== snackBarTextError =====================================================

  @ignore
  Color get snackBarTextError =>
      _snackBarTextError ??= Color(snackBarTextErrorInt);
  @ignore
  Color? _snackBarTextError;
  final int snackBarTextErrorInt;

  // ==== snackBarTextInfo =====================================================

  @ignore
  Color get snackBarTextInfo =>
      _snackBarTextInfo ??= Color(snackBarTextInfoInt);
  @ignore
  Color? _snackBarTextInfo;
  final int snackBarTextInfoInt;

  // ==== bottomNavIconBack =====================================================

  @ignore
  Color get bottomNavIconBack =>
      _bottomNavIconBack ??= Color(bottomNavIconBackInt);
  @ignore
  Color? _bottomNavIconBack;
  final int bottomNavIconBackInt;

  // ==== bottomNavIconIcon =====================================================

  @ignore
  Color get bottomNavIconIcon =>
      _bottomNavIconIcon ??= Color(bottomNavIconIconInt);
  @ignore
  Color? _bottomNavIconIcon;
  final int bottomNavIconIconInt;

  // ==== topNavIconPrimary =====================================================

  @ignore
  Color get topNavIconPrimary =>
      _topNavIconPrimary ??= Color(topNavIconPrimaryInt);
  @ignore
  Color? _topNavIconPrimary;
  final int topNavIconPrimaryInt;

  // ==== topNavIconGreen =====================================================

  @ignore
  Color get topNavIconGreen => _topNavIconGreen ??= Color(topNavIconGreenInt);
  @ignore
  Color? _topNavIconGreen;
  final int topNavIconGreenInt;

  // ==== topNavIconYellow =====================================================

  @ignore
  Color get topNavIconYellow =>
      _topNavIconYellow ??= Color(topNavIconYellowInt);
  @ignore
  Color? _topNavIconYellow;
  final int topNavIconYellowInt;

  // ==== topNavIconRed =====================================================

  @ignore
  Color get topNavIconRed => _topNavIconRed ??= Color(topNavIconRedInt);
  @ignore
  Color? _topNavIconRed;
  final int topNavIconRedInt;

  // ==== settingsIconBack =====================================================

  @ignore
  Color get settingsIconBack =>
      _settingsIconBack ??= Color(settingsIconBackInt);
  @ignore
  Color? _settingsIconBack;
  final int settingsIconBackInt;

  // ==== settingsIconIcon =====================================================

  @ignore
  Color get settingsIconIcon =>
      _settingsIconIcon ??= Color(settingsIconIconInt);
  @ignore
  Color? _settingsIconIcon;
  final int settingsIconIconInt;

  // ==== settingsIconBack2 =====================================================

  @ignore
  Color get settingsIconBack2 =>
      _settingsIconBack2 ??= Color(settingsIconBack2Int);
  @ignore
  Color? _settingsIconBack2;
  final int settingsIconBack2Int;

  // ==== settingsIconElement =====================================================

  @ignore
  Color get settingsIconElement =>
      _settingsIconElement ??= Color(settingsIconElementInt);
  @ignore
  Color? _settingsIconElement;
  final int settingsIconElementInt;

  // ==== textFieldActiveBG =====================================================

  @ignore
  Color get textFieldActiveBG =>
      _textFieldActiveBG ??= Color(textFieldActiveBGInt);
  @ignore
  Color? _textFieldActiveBG;
  final int textFieldActiveBGInt;

  // ==== textFieldDefaultBG =====================================================

  @ignore
  Color get textFieldDefaultBG =>
      _textFieldDefaultBG ??= Color(textFieldDefaultBGInt);
  @ignore
  Color? _textFieldDefaultBG;
  final int textFieldDefaultBGInt;

  // ==== textFieldErrorBG =====================================================

  @ignore
  Color get textFieldErrorBG =>
      _textFieldErrorBG ??= Color(textFieldErrorBGInt);
  @ignore
  Color? _textFieldErrorBG;
  final int textFieldErrorBGInt;

  // ==== textFieldSuccessBG =====================================================

  @ignore
  Color get textFieldSuccessBG =>
      _textFieldSuccessBG ??= Color(textFieldSuccessBGInt);
  @ignore
  Color? _textFieldSuccessBG;
  final int textFieldSuccessBGInt;

  // ==== textFieldErrorBorder =====================================================

  @ignore
  Color get textFieldErrorBorder =>
      _textFieldErrorBorder ??= Color(textFieldErrorBorderInt);
  @ignore
  Color? _textFieldErrorBorder;
  final int textFieldErrorBorderInt;

  // ==== textFieldSuccessBorder =====================================================

  @ignore
  Color get textFieldSuccessBorder =>
      _textFieldSuccessBorder ??= Color(textFieldSuccessBorderInt);
  @ignore
  Color? _textFieldSuccessBorder;
  final int textFieldSuccessBorderInt;

  // ==== textFieldActiveSearchIconLeft =====================================================

  @ignore
  Color get textFieldActiveSearchIconLeft => _textFieldActiveSearchIconLeft ??=
      Color(textFieldActiveSearchIconLeftInt);
  @ignore
  Color? _textFieldActiveSearchIconLeft;
  final int textFieldActiveSearchIconLeftInt;

  // ==== textFieldDefaultSearchIconLeft =====================================================

  @ignore
  Color get textFieldDefaultSearchIconLeft =>
      _textFieldDefaultSearchIconLeft ??=
          Color(textFieldDefaultSearchIconLeftInt);
  @ignore
  Color? _textFieldDefaultSearchIconLeft;
  final int textFieldDefaultSearchIconLeftInt;

  // ==== textFieldErrorSearchIconLeft =====================================================

  @ignore
  Color get textFieldErrorSearchIconLeft =>
      _textFieldErrorSearchIconLeft ??= Color(textFieldErrorSearchIconLeftInt);
  @ignore
  Color? _textFieldErrorSearchIconLeft;
  final int textFieldErrorSearchIconLeftInt;

  // ==== textFieldSuccessSearchIconLeft =====================================================

  @ignore
  Color get textFieldSuccessSearchIconLeft =>
      _textFieldSuccessSearchIconLeft ??=
          Color(textFieldSuccessSearchIconLeftInt);
  @ignore
  Color? _textFieldSuccessSearchIconLeft;
  final int textFieldSuccessSearchIconLeftInt;

  // ==== textFieldActiveText =====================================================

  @ignore
  Color get textFieldActiveText =>
      _textFieldActiveText ??= Color(textFieldActiveTextInt);
  @ignore
  Color? _textFieldActiveText;
  final int textFieldActiveTextInt;

  // ==== textFieldDefaultText =====================================================

  @ignore
  Color get textFieldDefaultText =>
      _textFieldDefaultText ??= Color(textFieldDefaultTextInt);
  @ignore
  Color? _textFieldDefaultText;
  final int textFieldDefaultTextInt;

  // ==== textFieldErrorText =====================================================

  @ignore
  Color get textFieldErrorText =>
      _textFieldErrorText ??= Color(textFieldErrorTextInt);
  @ignore
  Color? _textFieldErrorText;
  final int textFieldErrorTextInt;

  // ==== textFieldSuccessText =====================================================

  @ignore
  Color get textFieldSuccessText =>
      _textFieldSuccessText ??= Color(textFieldSuccessTextInt);
  @ignore
  Color? _textFieldSuccessText;
  final int textFieldSuccessTextInt;

  // ==== textFieldActiveLabel =====================================================

  @ignore
  Color get textFieldActiveLabel =>
      _textFieldActiveLabel ??= Color(textFieldActiveLabelInt);
  @ignore
  Color? _textFieldActiveLabel;
  final int textFieldActiveLabelInt;

  // ==== textFieldErrorLabel =====================================================

  @ignore
  Color get textFieldErrorLabel =>
      _textFieldErrorLabel ??= Color(textFieldErrorLabelInt);
  @ignore
  Color? _textFieldErrorLabel;
  final int textFieldErrorLabelInt;

  // ==== textFieldSuccessLabel =====================================================

  @ignore
  Color get textFieldSuccessLabel =>
      _textFieldSuccessLabel ??= Color(textFieldSuccessLabelInt);
  @ignore
  Color? _textFieldSuccessLabel;
  final int textFieldSuccessLabelInt;

  // ==== textFieldActiveSearchIconRight =====================================================

  @ignore
  Color get textFieldActiveSearchIconRight =>
      _textFieldActiveSearchIconRight ??=
          Color(textFieldActiveSearchIconRightInt);
  @ignore
  Color? _textFieldActiveSearchIconRight;
  final int textFieldActiveSearchIconRightInt;

  // ==== textFieldDefaultSearchIconRight =====================================================

  @ignore
  Color get textFieldDefaultSearchIconRight =>
      _textFieldDefaultSearchIconRight ??=
          Color(textFieldDefaultSearchIconRightInt);
  @ignore
  Color? _textFieldDefaultSearchIconRight;
  final int textFieldDefaultSearchIconRightInt;

  // ==== textFieldErrorSearchIconRight =====================================================

  @ignore
  Color get textFieldErrorSearchIconRight => _textFieldErrorSearchIconRight ??=
      Color(textFieldErrorSearchIconRightInt);
  @ignore
  Color? _textFieldErrorSearchIconRight;
  final int textFieldErrorSearchIconRightInt;

  // ==== textFieldSuccessSearchIconRight =====================================================

  @ignore
  Color get textFieldSuccessSearchIconRight =>
      _textFieldSuccessSearchIconRight ??=
          Color(textFieldSuccessSearchIconRightInt);
  @ignore
  Color? _textFieldSuccessSearchIconRight;
  final int textFieldSuccessSearchIconRightInt;

  // ==== settingsItem2ActiveBG =====================================================

  @ignore
  Color get settingsItem2ActiveBG =>
      _settingsItem2ActiveBG ??= Color(settingsItem2ActiveBGInt);
  @ignore
  Color? _settingsItem2ActiveBG;
  final int settingsItem2ActiveBGInt;

  // ==== settingsItem2ActiveText =====================================================

  @ignore
  Color get settingsItem2ActiveText =>
      _settingsItem2ActiveText ??= Color(settingsItem2ActiveTextInt);
  @ignore
  Color? _settingsItem2ActiveText;
  final int settingsItem2ActiveTextInt;

  // ==== settingsItem2ActiveSub =====================================================

  @ignore
  Color get settingsItem2ActiveSub =>
      _settingsItem2ActiveSub ??= Color(settingsItem2ActiveSubInt);
  @ignore
  Color? _settingsItem2ActiveSub;
  final int settingsItem2ActiveSubInt;

  // ==== radioButtonIconBorder =====================================================

  @ignore
  Color get radioButtonIconBorder =>
      _radioButtonIconBorder ??= Color(radioButtonIconBorderInt);
  @ignore
  Color? _radioButtonIconBorder;
  final int radioButtonIconBorderInt;

  // ==== radioButtonIconBorderDisabled =====================================================

  @ignore
  Color get radioButtonIconBorderDisabled => _radioButtonIconBorderDisabled ??=
      Color(radioButtonIconBorderDisabledInt);
  @ignore
  Color? _radioButtonIconBorderDisabled;
  final int radioButtonIconBorderDisabledInt;

  // ==== radioButtonBorderEnabled =====================================================

  @ignore
  Color get radioButtonBorderEnabled =>
      _radioButtonBorderEnabled ??= Color(radioButtonBorderEnabledInt);
  @ignore
  Color? _radioButtonBorderEnabled;
  final int radioButtonBorderEnabledInt;

  // ==== radioButtonBorderDisabled =====================================================

  @ignore
  Color get radioButtonBorderDisabled =>
      _radioButtonBorderDisabled ??= Color(radioButtonBorderDisabledInt);
  @ignore
  Color? _radioButtonBorderDisabled;
  final int radioButtonBorderDisabledInt;

  // ==== radioButtonIconCircle =====================================================

  @ignore
  Color get radioButtonIconCircle =>
      _radioButtonIconCircle ??= Color(radioButtonIconCircleInt);
  @ignore
  Color? _radioButtonIconCircle;
  final int radioButtonIconCircleInt;

  // ==== radioButtonIconEnabled =====================================================

  @ignore
  Color get radioButtonIconEnabled =>
      _radioButtonIconEnabled ??= Color(radioButtonIconEnabledInt);
  @ignore
  Color? _radioButtonIconEnabled;
  final int radioButtonIconEnabledInt;

  // ==== radioButtonTextEnabled =====================================================

  @ignore
  Color get radioButtonTextEnabled =>
      _radioButtonTextEnabled ??= Color(radioButtonTextEnabledInt);
  @ignore
  Color? _radioButtonTextEnabled;
  final int radioButtonTextEnabledInt;

  // ==== radioButtonTextDisabled =====================================================

  @ignore
  Color get radioButtonTextDisabled =>
      _radioButtonTextDisabled ??= Color(radioButtonTextDisabledInt);
  @ignore
  Color? _radioButtonTextDisabled;
  final int radioButtonTextDisabledInt;

  // ==== radioButtonLabelEnabled =====================================================

  @ignore
  Color get radioButtonLabelEnabled =>
      _radioButtonLabelEnabled ??= Color(radioButtonLabelEnabledInt);
  @ignore
  Color? _radioButtonLabelEnabled;
  final int radioButtonLabelEnabledInt;

  // ==== radioButtonLabelDisabled =====================================================

  @ignore
  Color get radioButtonLabelDisabled =>
      _radioButtonLabelDisabled ??= Color(radioButtonLabelDisabledInt);
  @ignore
  Color? _radioButtonLabelDisabled;
  final int radioButtonLabelDisabledInt;

  // ==== infoItemBG =====================================================

  @ignore
  Color get infoItemBG => _infoItemBG ??= Color(infoItemBGInt);
  @ignore
  Color? _infoItemBG;
  final int infoItemBGInt;

  // ==== infoItemLabel =====================================================

  @ignore
  Color get infoItemLabel => _infoItemLabel ??= Color(infoItemLabelInt);
  @ignore
  Color? _infoItemLabel;
  final int infoItemLabelInt;

  // ==== infoItemText =====================================================

  @ignore
  Color get infoItemText => _infoItemText ??= Color(infoItemTextInt);
  @ignore
  Color? _infoItemText;
  final int infoItemTextInt;

  // ==== infoItemIcons =====================================================

  @ignore
  Color get infoItemIcons => _infoItemIcons ??= Color(infoItemIconsInt);
  @ignore
  Color? _infoItemIcons;
  final int infoItemIconsInt;

  // ==== popupBG =====================================================

  @ignore
  Color get popupBG => _popupBG ??= Color(popupBGInt);
  @ignore
  Color? _popupBG;
  final int popupBGInt;

  // ==== currencyListItemBG =====================================================

  @ignore
  Color get currencyListItemBG =>
      _currencyListItemBG ??= Color(currencyListItemBGInt);
  @ignore
  Color? _currencyListItemBG;
  final int currencyListItemBGInt;

  // ==== stackWalletBG =====================================================

  @ignore
  Color get stackWalletBG => _stackWalletBG ??= Color(stackWalletBGInt);
  @ignore
  Color? _stackWalletBG;
  final int stackWalletBGInt;

  // ==== stackWalletMid =====================================================

  @ignore
  Color get stackWalletMid => _stackWalletMid ??= Color(stackWalletMidInt);
  @ignore
  Color? _stackWalletMid;
  final int stackWalletMidInt;

  // ==== stackWalletBottom =====================================================

  @ignore
  Color get stackWalletBottom =>
      _stackWalletBottom ??= Color(stackWalletBottomInt);
  @ignore
  Color? _stackWalletBottom;
  final int stackWalletBottomInt;

  // ==== bottomNavShadow =====================================================

  @ignore
  Color get bottomNavShadow => _bottomNavShadow ??= Color(bottomNavShadowInt);
  @ignore
  Color? _bottomNavShadow;
  final int bottomNavShadowInt;

  // ==== favoriteStarActive =====================================================

  @ignore
  Color get favoriteStarActive =>
      _favoriteStarActive ??= Color(favoriteStarActiveInt);
  @ignore
  Color? _favoriteStarActive;
  final int favoriteStarActiveInt;

  // ==== favoriteStarInactive =====================================================

  @ignore
  Color get favoriteStarInactive =>
      _favoriteStarInactive ??= Color(favoriteStarInactiveInt);
  @ignore
  Color? _favoriteStarInactive;
  final int favoriteStarInactiveInt;

  // ==== splash =====================================================

  @ignore
  Color get splash => _splash ??= Color(splashInt);
  @ignore
  Color? _splash;
  final int splashInt;

  // ==== highlight =====================================================

  @ignore
  Color get highlight => _highlight ??= Color(highlightInt);
  @ignore
  Color? _highlight;
  final int highlightInt;

  // ==== warningForeground =====================================================

  @ignore
  Color get warningForeground =>
      _warningForeground ??= Color(warningForegroundInt);
  @ignore
  Color? _warningForeground;
  final int warningForegroundInt;

  // ==== warningBackground =====================================================

  @ignore
  Color get warningBackground =>
      _warningBackground ??= Color(warningBackgroundInt);
  @ignore
  Color? _warningBackground;
  final int warningBackgroundInt;

  // ==== loadingOverlayTextColor =====================================================

  @ignore
  Color get loadingOverlayTextColor =>
      _loadingOverlayTextColor ??= Color(loadingOverlayTextColorInt);
  @ignore
  Color? _loadingOverlayTextColor;
  final int loadingOverlayTextColorInt;

  // ==== myStackContactIconBG =====================================================

  @ignore
  Color get myStackContactIconBG =>
      _myStackContactIconBG ??= Color(myStackContactIconBGInt);
  @ignore
  Color? _myStackContactIconBG;
  final int myStackContactIconBGInt;

  // ==== textConfirmTotalAmount =====================================================

  @ignore
  Color get textConfirmTotalAmount =>
      _textConfirmTotalAmount ??= Color(textConfirmTotalAmountInt);
  @ignore
  Color? _textConfirmTotalAmount;
  final int textConfirmTotalAmountInt;

  // ==== textSelectedWordTableItem =====================================================

  @ignore
  Color get textSelectedWordTableItem =>
      _textSelectedWordTableItem ??= Color(textSelectedWordTableItemInt);
  @ignore
  Color? _textSelectedWordTableItem;
  final int textSelectedWordTableItemInt;

  // ==== rateTypeToggleColorOn =====================================================

  @ignore
  Color get rateTypeToggleColorOn =>
      _rateTypeToggleColorOn ??= Color(rateTypeToggleColorOnInt);
  @ignore
  Color? _rateTypeToggleColorOn;
  final int rateTypeToggleColorOnInt;

  // ==== rateTypeToggleColorOff =====================================================

  @ignore
  Color get rateTypeToggleColorOff =>
      _rateTypeToggleColorOff ??= Color(rateTypeToggleColorOffInt);
  @ignore
  Color? _rateTypeToggleColorOff;
  final int rateTypeToggleColorOffInt;

  // ==== rateTypeToggleDesktopColorOn =====================================================

  @ignore
  Color get rateTypeToggleDesktopColorOn =>
      _rateTypeToggleDesktopColorOn ??= Color(rateTypeToggleDesktopColorOnInt);
  @ignore
  Color? _rateTypeToggleDesktopColorOn;
  final int rateTypeToggleDesktopColorOnInt;

  // ==== rateTypeToggleDesktopColorOff =====================================================

  @ignore
  Color get rateTypeToggleDesktopColorOff => _rateTypeToggleDesktopColorOff ??=
      Color(rateTypeToggleDesktopColorOffInt);
  @ignore
  Color? _rateTypeToggleDesktopColorOff;
  final int rateTypeToggleDesktopColorOffInt;

  // ==== ethTagText =====================================================

  @ignore
  Color get ethTagText => _ethTagText ??= Color(ethTagTextInt);
  @ignore
  Color? _ethTagText;
  final int ethTagTextInt;

  // ==== ethTagBG =====================================================

  @ignore
  Color get ethTagBG => _ethTagBG ??= Color(ethTagBGInt);
  @ignore
  Color? _ethTagBG;
  final int ethTagBGInt;

  // ==== ethWalletTagText =====================================================

  @ignore
  Color get ethWalletTagText =>
      _ethWalletTagText ??= Color(ethWalletTagTextInt);
  @ignore
  Color? _ethWalletTagText;
  final int ethWalletTagTextInt;

  // ==== ethWalletTagBG =====================================================

  @ignore
  Color get ethWalletTagBG => _ethWalletTagBG ??= Color(ethWalletTagBGInt);
  @ignore
  Color? _ethWalletTagBG;
  final int ethWalletTagBGInt;

  // ==== tokenSummaryTextPrimary =====================================================

  @ignore
  Color get tokenSummaryTextPrimary =>
      _tokenSummaryTextPrimary ??= Color(tokenSummaryTextPrimaryInt);
  @ignore
  Color? _tokenSummaryTextPrimary;
  final int tokenSummaryTextPrimaryInt;

  // ==== tokenSummaryTextSecondary =====================================================

  @ignore
  Color get tokenSummaryTextSecondary =>
      _tokenSummaryTextSecondary ??= Color(tokenSummaryTextSecondaryInt);
  @ignore
  Color? _tokenSummaryTextSecondary;
  final int tokenSummaryTextSecondaryInt;

  // ==== tokenSummaryBG =====================================================

  @ignore
  Color get tokenSummaryBG => _tokenSummaryBG ??= Color(tokenSummaryBGInt);
  @ignore
  Color? _tokenSummaryBG;
  final int tokenSummaryBGInt;

  // ==== tokenSummaryButtonBG =====================================================

  @ignore
  Color get tokenSummaryButtonBG =>
      _tokenSummaryButtonBG ??= Color(tokenSummaryButtonBGInt);
  @ignore
  Color? _tokenSummaryButtonBG;
  final int tokenSummaryButtonBGInt;

  // ==== tokenSummaryIcon =====================================================

  @ignore
  Color get tokenSummaryIcon =>
      _tokenSummaryIcon ??= Color(tokenSummaryIconInt);
  @ignore
  Color? _tokenSummaryIcon;
  final int tokenSummaryIconInt;

  // ==== coinColors =====================================================

  @ignore
  Map<Coin, Color> get coinColors =>
      _coinColors ??= parseCoinColors(coinColorsJsonString);
  @ignore
  Map<Coin, Color>? _coinColors;
  final String coinColorsJsonString;

  // ===========================================================================

  // ==== assets =====================================================
  final String circleLock;

  final ThemeAssets assets;

  // ===========================================================================
  // ===========================================================================

  StackTheme({
    required this.internalId,
    required this.assetBundleUrl,
    required this.name,
    required this.assets,
    required this.brightnessString,
    required this.backgroundInt,
    required this.backgroundAppBarInt,
    required this.gradientBackgroundString,
    required this.overlayInt,
    required this.accentColorBlueInt,
    required this.accentColorGreenInt,
    required this.accentColorYellowInt,
    required this.accentColorRedInt,
    required this.accentColorOrangeInt,
    required this.accentColorDarkInt,
    required this.shadowInt,
    required this.textDarkInt,
    required this.textDark2Int,
    required this.textDark3Int,
    required this.textSubtitle1Int,
    required this.textSubtitle2Int,
    required this.textSubtitle3Int,
    required this.textSubtitle4Int,
    required this.textSubtitle5Int,
    required this.textSubtitle6Int,
    required this.textWhiteInt,
    required this.textFavoriteCardInt,
    required this.textErrorInt,
    required this.textRestoreInt,
    required this.buttonBackPrimaryInt,
    required this.buttonBackSecondaryInt,
    required this.buttonBackPrimaryDisabledInt,
    required this.buttonBackSecondaryDisabledInt,
    required this.buttonBackBorderInt,
    required this.buttonBackBorderDisabledInt,
    required this.buttonBackBorderSecondaryInt,
    required this.buttonBackBorderSecondaryDisabledInt,
    required this.numberBackDefaultInt,
    required this.numpadBackDefaultInt,
    required this.bottomNavBackInt,
    required this.buttonTextPrimaryInt,
    required this.buttonTextSecondaryInt,
    required this.buttonTextPrimaryDisabledInt,
    required this.buttonTextSecondaryDisabledInt,
    required this.buttonTextBorderInt,
    required this.buttonTextDisabledInt,
    required this.buttonTextBorderlessInt,
    required this.buttonTextBorderlessDisabledInt,
    required this.numberTextDefaultInt,
    required this.numpadTextDefaultInt,
    required this.bottomNavTextInt,
    required this.customTextButtonEnabledTextInt,
    required this.customTextButtonDisabledTextInt,
    required this.switchBGOnInt,
    required this.switchBGOffInt,
    required this.switchBGDisabledInt,
    required this.switchCircleOnInt,
    required this.switchCircleOffInt,
    required this.switchCircleDisabledInt,
    required this.stepIndicatorBGCheckInt,
    required this.stepIndicatorBGNumberInt,
    required this.stepIndicatorBGInactiveInt,
    required this.stepIndicatorBGLinesInt,
    required this.stepIndicatorBGLinesInactiveInt,
    required this.stepIndicatorIconTextInt,
    required this.stepIndicatorIconNumberInt,
    required this.stepIndicatorIconInactiveInt,
    required this.checkboxBGCheckedInt,
    required this.checkboxBorderEmptyInt,
    required this.checkboxBGDisabledInt,
    required this.checkboxIconCheckedInt,
    required this.checkboxIconDisabledInt,
    required this.checkboxTextLabelInt,
    required this.snackBarBackSuccessInt,
    required this.snackBarBackErrorInt,
    required this.snackBarBackInfoInt,
    required this.snackBarTextSuccessInt,
    required this.snackBarTextErrorInt,
    required this.snackBarTextInfoInt,
    required this.bottomNavIconBackInt,
    required this.bottomNavIconIconInt,
    required this.topNavIconPrimaryInt,
    required this.topNavIconGreenInt,
    required this.topNavIconYellowInt,
    required this.topNavIconRedInt,
    required this.settingsIconBackInt,
    required this.settingsIconIconInt,
    required this.settingsIconBack2Int,
    required this.settingsIconElementInt,
    required this.textFieldActiveBGInt,
    required this.textFieldDefaultBGInt,
    required this.textFieldErrorBGInt,
    required this.textFieldSuccessBGInt,
    required this.textFieldErrorBorderInt,
    required this.textFieldSuccessBorderInt,
    required this.textFieldActiveSearchIconLeftInt,
    required this.textFieldDefaultSearchIconLeftInt,
    required this.textFieldErrorSearchIconLeftInt,
    required this.textFieldSuccessSearchIconLeftInt,
    required this.textFieldActiveTextInt,
    required this.textFieldDefaultTextInt,
    required this.textFieldErrorTextInt,
    required this.textFieldSuccessTextInt,
    required this.textFieldActiveLabelInt,
    required this.textFieldErrorLabelInt,
    required this.textFieldSuccessLabelInt,
    required this.textFieldActiveSearchIconRightInt,
    required this.textFieldDefaultSearchIconRightInt,
    required this.textFieldErrorSearchIconRightInt,
    required this.textFieldSuccessSearchIconRightInt,
    required this.settingsItem2ActiveBGInt,
    required this.settingsItem2ActiveTextInt,
    required this.settingsItem2ActiveSubInt,
    required this.radioButtonIconBorderInt,
    required this.radioButtonIconBorderDisabledInt,
    required this.radioButtonBorderEnabledInt,
    required this.radioButtonBorderDisabledInt,
    required this.radioButtonIconCircleInt,
    required this.radioButtonIconEnabledInt,
    required this.radioButtonTextEnabledInt,
    required this.radioButtonTextDisabledInt,
    required this.radioButtonLabelEnabledInt,
    required this.radioButtonLabelDisabledInt,
    required this.infoItemBGInt,
    required this.infoItemLabelInt,
    required this.infoItemTextInt,
    required this.infoItemIconsInt,
    required this.popupBGInt,
    required this.currencyListItemBGInt,
    required this.stackWalletBGInt,
    required this.stackWalletMidInt,
    required this.stackWalletBottomInt,
    required this.bottomNavShadowInt,
    required this.favoriteStarActiveInt,
    required this.favoriteStarInactiveInt,
    required this.splashInt,
    required this.highlightInt,
    required this.warningForegroundInt,
    required this.warningBackgroundInt,
    required this.loadingOverlayTextColorInt,
    required this.myStackContactIconBGInt,
    required this.textConfirmTotalAmountInt,
    required this.textSelectedWordTableItemInt,
    required this.rateTypeToggleColorOnInt,
    required this.rateTypeToggleColorOffInt,
    required this.rateTypeToggleDesktopColorOnInt,
    required this.rateTypeToggleDesktopColorOffInt,
    required this.ethTagTextInt,
    required this.ethTagBGInt,
    required this.ethWalletTagTextInt,
    required this.ethWalletTagBGInt,
    required this.tokenSummaryTextPrimaryInt,
    required this.tokenSummaryTextSecondaryInt,
    required this.tokenSummaryBGInt,
    required this.tokenSummaryButtonBGInt,
    required this.tokenSummaryIconInt,
    required this.coinColorsJsonString,
    required this.circleLock,
  });

  factory StackTheme.fromJson({
    required Map<String, dynamic> json,
    required String applicationThemesDirectoryPath,
  }) {
    final _id = const Uuid().v1();
    return StackTheme(
      internalId: _id,
      name: json["name"] as String,
      assetBundleUrl: json["assetBundleUrl"] as String,
      brightnessString: json["brightness"] as String,
      backgroundInt: parseColor(json["colors"]["background"] as String),
      backgroundAppBarInt:
          parseColor(json["colors"]["backgroundAppBar"] as String),
      gradientBackgroundString:
          jsonEncode(json["gradients"]["gradientBackground"] as Map),
      coinColorsJsonString: jsonEncode(json["coinColors"] as Map),
      assets: ThemeAssets.fromJson(
        json: json,
        applicationThemesDirectoryPath: applicationThemesDirectoryPath,
        internalThemeUuid: _id,
      ),
    );
  }

  /// Grab the int value of the hex color string.
  /// 8 char string value expected where the first 2 are opacity
  static int parseColor(String colorHex) {
    try {
      final int colorValue = colorHex.toBigIntFromHex.toInt();
      if (colorValue >= 0 && colorValue <= 0xFFFFFFFF) {
        return colorValue;
      } else {
        throw ArgumentError(
          '"$colorHex" and corresponding int '
          'value "$colorValue" is not a valid color.',
        );
      }
    } catch (_) {
      throw ArgumentError(
        '"$colorHex" is not a valid hex number',
      );
    }
  }

  /// parse coin colors json and fetch color or use default
  static Map<Coin, Color> parseCoinColors(String jsonString) {
    final json = jsonDecode(jsonString) as Map;
    final map = Map<String, dynamic>.from(json);

    final Map<Coin, Color> result = {};

    for (final coin in Coin.values) {
      if (map[coin.name] is String) {
        result[coin] = Color(
          (map[coin.name] as String).toBigIntFromHex.toInt(),
        );
      } else {
        result[coin] = kCoinThemeColorDefaults.forCoin(coin);
      }
    }

    return result;
  }
}

@Embedded(inheritance: false)
class ThemeAssets {
  final String plus;

  // todo: add all assets expected in json

  ThemeAssets({
    required this.plus,
  });

  factory ThemeAssets.fromJson({
    required Map<String, dynamic> json,
    required String applicationThemesDirectoryPath,
    required String internalThemeUuid,
  }) {
    return ThemeAssets(
      plus:
          "$applicationThemesDirectoryPath/$internalThemeUuid/${json["assets"]["svg"]["plus.svg"] as String}",
    );
  }
}
