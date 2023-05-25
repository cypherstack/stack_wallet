import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/themes/color_theme.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/extensions/impl/box_shadow.dart';
import 'package:stackwallet/utilities/extensions/impl/gradient.dart';
import 'package:stackwallet/utilities/extensions/impl/string.dart';

part 'stack_theme.g.dart';

@Collection(inheritance: false)
class StackTheme {
  Id id = Isar.autoIncrement;

  /// id of theme on themes server
  @Index(unique: true, replace: true)
  late final String themeId;

  /// the theme name that will be displayed in app
  late final String name;

  // system brightness
  late final String brightnessString;

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
  late final int backgroundInt;

  // ==== backgroundAppBar =====================================================

  @ignore
  Color get backgroundAppBar =>
      _backgroundAppBar ??= Color(backgroundAppBarInt);
  @ignore
  Color? _backgroundAppBar;
  late final int backgroundAppBarInt;

  // ==== gradientBackground =====================================================

  @ignore
  Gradient? get gradientBackground {
    if (gradientBackgroundString == null) {
      _gradientBackground = null;
    } else {
      _gradientBackground ??= GradientExt.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(gradientBackgroundString!) as Map,
        ),
      );
    }
    return _gradientBackground;
  }

  @ignore
  Gradient? _gradientBackground;
  late final String? gradientBackgroundString;

  // ==== boxShadows =====================================================

  @ignore
  BoxShadow get standardBoxShadow =>
      _standardBoxShadow ??= BoxShadowExt.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(standardBoxShadowString) as Map,
        ),
      );
  @ignore
  BoxShadow? _standardBoxShadow;
  late final String standardBoxShadowString;

  @ignore
  BoxShadow? get homeViewButtonBarBoxShadow {
    if (homeViewButtonBarBoxShadowString == null) {
      _homeViewButtonBarBoxShadow = null;
    } else {
      _homeViewButtonBarBoxShadow ??= BoxShadowExt.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(homeViewButtonBarBoxShadowString!) as Map,
        ),
      );
    }

    return _homeViewButtonBarBoxShadow;
  }

  @ignore
  BoxShadow? _homeViewButtonBarBoxShadow;
  late final String? homeViewButtonBarBoxShadowString;

  // ==== overlay =====================================================

  @ignore
  Color get overlay => _overlay ??= Color(overlayInt);
  @ignore
  Color? _overlay;
  late final int overlayInt;

  // ==== accentColorBlue =====================================================

  @ignore
  Color get accentColorBlue => _accentColorBlue ??= Color(
        accentColorBlueInt,
      );
  @ignore
  Color? _accentColorBlue;
  late final int accentColorBlueInt;

  // ==== accentColorGreen =====================================================

  @ignore
  Color get accentColorGreen => _accentColorGreen ??= Color(
        accentColorGreenInt,
      );
  @ignore
  Color? _accentColorGreen;
  late final int accentColorGreenInt;

  // ==== accentColorYellow =====================================================

  @ignore
  Color get accentColorYellow => _accentColorYellow ??= Color(
        accentColorYellowInt,
      );
  @ignore
  Color? _accentColorYellow;
  late final int accentColorYellowInt;

  // ==== accentColorRed =====================================================

  @ignore
  Color get accentColorRed => _accentColorRed ??= Color(
        accentColorRedInt,
      );
  @ignore
  Color? _accentColorRed;
  late final int accentColorRedInt;

  // ==== accentColorOrange =====================================================

  @ignore
  Color get accentColorOrange => _accentColorOrange ??= Color(
        accentColorOrangeInt,
      );
  @ignore
  Color? _accentColorOrange;
  late final int accentColorOrangeInt;

  // ==== accentColorDark =====================================================

  @ignore
  Color get accentColorDark => _accentColorDark ??= Color(
        accentColorDarkInt,
      );
  @ignore
  Color? _accentColorDark;
  late final int accentColorDarkInt;

  // ==== shadow =====================================================

  @ignore
  Color get shadow => _shadow ??= Color(
        shadowInt,
      );
  @ignore
  Color? _shadow;
  late final int shadowInt;

  // ==== textDark =====================================================

  @ignore
  Color get textDark => _textDark ??= Color(
        textDarkInt,
      );
  @ignore
  Color? _textDark;
  late final int textDarkInt;

  // ==== textDark2 =====================================================

  @ignore
  Color get textDark2 => _textDark2 ??= Color(
        textDark2Int,
      );
  @ignore
  Color? _textDark2;
  late final int textDark2Int;

  // ==== textDark3 =====================================================

  @ignore
  Color get textDark3 => _textDark3 ??= Color(
        textDark3Int,
      );
  @ignore
  Color? _textDark3;
  late final int textDark3Int;

  // ==== textSubtitle1 =====================================================

  @ignore
  Color get textSubtitle1 => _textSubtitle1 ??= Color(
        textSubtitle1Int,
      );
  @ignore
  Color? _textSubtitle1;
  late final int textSubtitle1Int;

  // ==== textSubtitle2 =====================================================

  @ignore
  Color get textSubtitle2 => _textSubtitle2 ??= Color(
        textSubtitle2Int,
      );
  @ignore
  Color? _textSubtitle2;
  late final int textSubtitle2Int;

  // ==== textSubtitle3 =====================================================

  @ignore
  Color get textSubtitle3 => _textSubtitle3 ??= Color(
        textSubtitle3Int,
      );
  @ignore
  Color? _textSubtitle3;
  late final int textSubtitle3Int;

  // ==== textSubtitle4 =====================================================

  @ignore
  Color get textSubtitle4 => _textSubtitle4 ??= Color(
        textSubtitle4Int,
      );
  @ignore
  Color? _textSubtitle4;
  late final int textSubtitle4Int;

  // ==== textSubtitle5 =====================================================

  @ignore
  Color get textSubtitle5 => _textSubtitle5 ??= Color(
        textSubtitle5Int,
      );
  @ignore
  Color? _textSubtitle5;
  late final int textSubtitle5Int;

  // ==== textSubtitle6 =====================================================

  @ignore
  Color get textSubtitle6 => _textSubtitle6 ??= Color(
        textSubtitle6Int,
      );
  @ignore
  Color? _textSubtitle6;
  late final int textSubtitle6Int;

  // ==== textWhite =====================================================

  @ignore
  Color get textWhite => _textWhite ??= Color(
        textWhiteInt,
      );
  @ignore
  Color? _textWhite;
  late final int textWhiteInt;

  // ==== textFavoriteCard =====================================================

  @ignore
  Color get textFavoriteCard => _textFavoriteCard ??= Color(
        textFavoriteCardInt,
      );
  @ignore
  Color? _textFavoriteCard;
  late final int textFavoriteCardInt;

  // ==== textError =====================================================

  @ignore
  Color get textError => _textError ??= Color(
        textErrorInt,
      );
  @ignore
  Color? _textError;
  late final int textErrorInt;

  // ==== textRestore =====================================================

  @ignore
  Color get textRestore => _textRestore ??= Color(
        textRestoreInt,
      );
  @ignore
  Color? _textRestore;
  late final int textRestoreInt;

  // ==== buttonBackPrimary =====================================================

  @ignore
  Color get buttonBackPrimary => _buttonBackPrimary ??= Color(
        buttonBackPrimaryInt,
      );
  @ignore
  Color? _buttonBackPrimary;
  late final int buttonBackPrimaryInt;

  // ==== buttonBackSecondary =====================================================

  @ignore
  Color get buttonBackSecondary => _buttonBackSecondary ??= Color(
        buttonBackSecondaryInt,
      );
  @ignore
  Color? _buttonBackSecondary;
  late final int buttonBackSecondaryInt;

  // ==== buttonBackPrimaryDisabled =====================================================

  @ignore
  Color get buttonBackPrimaryDisabled => _buttonBackPrimaryDisabled ??= Color(
        buttonBackPrimaryDisabledInt,
      );
  @ignore
  Color? _buttonBackPrimaryDisabled;
  late final int buttonBackPrimaryDisabledInt;

  // ==== buttonBackSecondaryDisabled =====================================================

  @ignore
  Color get buttonBackSecondaryDisabled =>
      _buttonBackSecondaryDisabled ??= Color(
        buttonBackSecondaryDisabledInt,
      );
  @ignore
  Color? _buttonBackSecondaryDisabled;
  late final int buttonBackSecondaryDisabledInt;

  // ==== buttonBackBorder =====================================================

  @ignore
  Color get buttonBackBorder => _buttonBackBorder ??= Color(
        buttonBackBorderInt,
      );
  @ignore
  Color? _buttonBackBorder;
  late final int buttonBackBorderInt;

  // ==== buttonBackBorderDisabled =====================================================

  @ignore
  Color get buttonBackBorderDisabled => _buttonBackBorderDisabled ??= Color(
        buttonBackBorderDisabledInt,
      );
  @ignore
  Color? _buttonBackBorderDisabled;
  late final int buttonBackBorderDisabledInt;

  // ==== buttonBackBorderSecondary =====================================================

  @ignore
  Color get buttonBackBorderSecondary => _buttonBackBorderSecondary ??= Color(
        buttonBackBorderSecondaryInt,
      );
  @ignore
  Color? _buttonBackBorderSecondary;
  late final int buttonBackBorderSecondaryInt;

  // ==== buttonBackBorderSecondaryDisabled =====================================================

  @ignore
  Color get buttonBackBorderSecondaryDisabled =>
      _buttonBackBorderSecondaryDisabled ??= Color(
        buttonBackBorderSecondaryDisabledInt,
      );
  @ignore
  Color? _buttonBackBorderSecondaryDisabled;
  late final int buttonBackBorderSecondaryDisabledInt;

  // ==== numberBackDefault =====================================================

  @ignore
  Color get numberBackDefault => _numberBackDefault ??= Color(
        numberBackDefaultInt,
      );
  @ignore
  Color? _numberBackDefault;
  late final int numberBackDefaultInt;

  // ==== numpadBackDefault =====================================================

  @ignore
  Color get numpadBackDefault => _numpadBackDefault ??= Color(
        numpadBackDefaultInt,
      );
  @ignore
  Color? _numpadBackDefault;
  late final int numpadBackDefaultInt;

  // ==== bottomNavBack =====================================================

  @ignore
  Color get bottomNavBack => _bottomNavBack ??= Color(
        bottomNavBackInt,
      );
  @ignore
  Color? _bottomNavBack;
  late final int bottomNavBackInt;

  // ==== buttonTextPrimary =====================================================

  @ignore
  Color get buttonTextPrimary => _buttonTextPrimary ??= Color(
        buttonTextPrimaryInt,
      );
  @ignore
  Color? _buttonTextPrimary;
  late final int buttonTextPrimaryInt;

  // ==== buttonTextSecondary =====================================================

  @ignore
  Color get buttonTextSecondary => _buttonTextSecondary ??= Color(
        buttonTextSecondaryInt,
      );
  @ignore
  Color? _buttonTextSecondary;
  late final int buttonTextSecondaryInt;

  // ==== buttonTextPrimaryDisabled =====================================================

  @ignore
  Color get buttonTextPrimaryDisabled => _buttonTextPrimaryDisabled ??= Color(
        buttonTextPrimaryDisabledInt,
      );
  @ignore
  Color? _buttonTextPrimaryDisabled;
  late final int buttonTextPrimaryDisabledInt;

  // ==== buttonTextSecondaryDisabled =====================================================

  @ignore
  Color get buttonTextSecondaryDisabled =>
      _buttonTextSecondaryDisabled ??= Color(buttonTextSecondaryDisabledInt);
  @ignore
  Color? _buttonTextSecondaryDisabled;
  late final int buttonTextSecondaryDisabledInt;

  // ==== buttonTextBorder =====================================================

  @ignore
  Color get buttonTextBorder =>
      _buttonTextBorder ??= Color(buttonTextBorderInt);
  @ignore
  Color? _buttonTextBorder;
  late final int buttonTextBorderInt;

  // ==== buttonTextDisabled =====================================================

  @ignore
  Color get buttonTextDisabled =>
      _buttonTextDisabled ??= Color(buttonTextDisabledInt);
  @ignore
  Color? _buttonTextDisabled;
  late final int buttonTextDisabledInt;

  // ==== buttonTextBorderless =====================================================

  @ignore
  Color get buttonTextBorderless =>
      _buttonTextBorderless ??= Color(buttonTextBorderlessInt);
  @ignore
  Color? _buttonTextBorderless;
  late final int buttonTextBorderlessInt;

  // ==== buttonTextBorderlessDisabled =====================================================

  @ignore
  Color get buttonTextBorderlessDisabled =>
      _buttonTextBorderlessDisabled ??= Color(buttonTextBorderlessDisabledInt);
  @ignore
  Color? _buttonTextBorderlessDisabled;
  late final int buttonTextBorderlessDisabledInt;

  // ==== numberTextDefault =====================================================

  @ignore
  Color get numberTextDefault =>
      _numberTextDefault ??= Color(numberTextDefaultInt);
  @ignore
  Color? _numberTextDefault;
  late final int numberTextDefaultInt;

  // ==== numpadTextDefault =====================================================

  @ignore
  Color get numpadTextDefault =>
      _numpadTextDefault ??= Color(numpadTextDefaultInt);
  @ignore
  Color? _numpadTextDefault;
  late final int numpadTextDefaultInt;

  // ==== bottomNavText =====================================================

  @ignore
  Color get bottomNavText => _bottomNavText ??= Color(bottomNavTextInt);
  @ignore
  Color? _bottomNavText;
  late final int bottomNavTextInt;

  // ==== customTextButtonEnabledText =====================================================

  @ignore
  Color get customTextButtonEnabledText =>
      _customTextButtonEnabledText ??= Color(customTextButtonEnabledTextInt);
  @ignore
  Color? _customTextButtonEnabledText;
  late final int customTextButtonEnabledTextInt;

  // ==== customTextButtonDisabledText =====================================================

  @ignore
  Color get customTextButtonDisabledText =>
      _customTextButtonDisabledText ??= Color(customTextButtonDisabledTextInt);
  @ignore
  Color? _customTextButtonDisabledText;
  late final int customTextButtonDisabledTextInt;

  // ==== switchBGOn =====================================================

  @ignore
  Color get switchBGOn => _switchBGOn ??= Color(switchBGOnInt);
  @ignore
  Color? _switchBGOn;
  late final int switchBGOnInt;

  // ==== switchBGOff =====================================================

  @ignore
  Color get switchBGOff => _switchBGOff ??= Color(switchBGOffInt);
  @ignore
  Color? _switchBGOff;
  late final int switchBGOffInt;

  // ==== switchBGDisabled =====================================================

  @ignore
  Color get switchBGDisabled =>
      _switchBGDisabled ??= Color(switchBGDisabledInt);
  @ignore
  Color? _switchBGDisabled;
  late final int switchBGDisabledInt;

  // ==== switchCircleOn =====================================================

  @ignore
  Color get switchCircleOn => _switchCircleOn ??= Color(switchCircleOnInt);
  @ignore
  Color? _switchCircleOn;
  late final int switchCircleOnInt;

  // ==== switchCircleOff =====================================================

  @ignore
  Color get switchCircleOff => _switchCircleOff ??= Color(switchCircleOffInt);
  @ignore
  Color? _switchCircleOff;
  late final int switchCircleOffInt;

  // ==== switchCircleDisabled =====================================================

  @ignore
  Color get switchCircleDisabled =>
      _switchCircleDisabled ??= Color(switchCircleDisabledInt);
  @ignore
  Color? _switchCircleDisabled;
  late final int switchCircleDisabledInt;

  // ==== stepIndicatorBGCheck =====================================================

  @ignore
  Color get stepIndicatorBGCheck =>
      _stepIndicatorBGCheck ??= Color(stepIndicatorBGCheckInt);
  @ignore
  Color? _stepIndicatorBGCheck;
  late final int stepIndicatorBGCheckInt;

  // ==== stepIndicatorBGNumber =====================================================

  @ignore
  Color get stepIndicatorBGNumber =>
      _stepIndicatorBGNumber ??= Color(stepIndicatorBGNumberInt);
  @ignore
  Color? _stepIndicatorBGNumber;
  late final int stepIndicatorBGNumberInt;

  // ==== stepIndicatorBGInactive =====================================================

  @ignore
  Color get stepIndicatorBGInactive =>
      _stepIndicatorBGInactive ??= Color(stepIndicatorBGInactiveInt);
  @ignore
  Color? _stepIndicatorBGInactive;
  late final int stepIndicatorBGInactiveInt;

  // ==== stepIndicatorBGLines =====================================================

  @ignore
  Color get stepIndicatorBGLines =>
      _stepIndicatorBGLines ??= Color(stepIndicatorBGLinesInt);
  @ignore
  Color? _stepIndicatorBGLines;
  late final int stepIndicatorBGLinesInt;

  // ==== stepIndicatorBGLinesInactive =====================================================

  @ignore
  Color get stepIndicatorBGLinesInactive =>
      _stepIndicatorBGLinesInactive ??= Color(stepIndicatorBGLinesInactiveInt);
  @ignore
  Color? _stepIndicatorBGLinesInactive;
  late final int stepIndicatorBGLinesInactiveInt;

  // ==== stepIndicatorIconText =====================================================

  @ignore
  Color get stepIndicatorIconText =>
      _stepIndicatorIconText ??= Color(stepIndicatorIconTextInt);
  @ignore
  Color? _stepIndicatorIconText;
  late final int stepIndicatorIconTextInt;

  // ==== stepIndicatorIconNumber =====================================================

  @ignore
  Color get stepIndicatorIconNumber =>
      _stepIndicatorIconNumber ??= Color(stepIndicatorIconNumberInt);
  @ignore
  Color? _stepIndicatorIconNumber;
  late final int stepIndicatorIconNumberInt;

  // ==== stepIndicatorIconInactive =====================================================

  @ignore
  Color get stepIndicatorIconInactive =>
      _stepIndicatorIconInactive ??= Color(stepIndicatorIconInactiveInt);
  @ignore
  Color? _stepIndicatorIconInactive;
  late final int stepIndicatorIconInactiveInt;

  // ==== checkboxBGChecked =====================================================

  @ignore
  Color get checkboxBGChecked =>
      _checkboxBGChecked ??= Color(checkboxBGCheckedInt);
  @ignore
  Color? _checkboxBGChecked;
  late final int checkboxBGCheckedInt;

  // ==== checkboxBorderEmpty =====================================================

  @ignore
  Color get checkboxBorderEmpty =>
      _checkboxBorderEmpty ??= Color(checkboxBorderEmptyInt);
  @ignore
  Color? _checkboxBorderEmpty;
  late final int checkboxBorderEmptyInt;

  // ==== checkboxBGDisabled =====================================================

  @ignore
  Color get checkboxBGDisabled =>
      _checkboxBGDisabled ??= Color(checkboxBGDisabledInt);
  @ignore
  Color? _checkboxBGDisabled;
  late final int checkboxBGDisabledInt;

  // ==== checkboxIconChecked =====================================================

  @ignore
  Color get checkboxIconChecked =>
      _checkboxIconChecked ??= Color(checkboxIconCheckedInt);
  @ignore
  Color? _checkboxIconChecked;
  late final int checkboxIconCheckedInt;

  // ==== checkboxIconDisabled =====================================================

  @ignore
  Color get checkboxIconDisabled =>
      _checkboxIconDisabled ??= Color(checkboxIconDisabledInt);
  @ignore
  Color? _checkboxIconDisabled;
  late final int checkboxIconDisabledInt;

  // ==== checkboxTextLabel =====================================================

  @ignore
  Color get checkboxTextLabel =>
      _checkboxTextLabel ??= Color(checkboxTextLabelInt);
  @ignore
  Color? _checkboxTextLabel;
  late final int checkboxTextLabelInt;

  // ==== snackBarBackSuccess =====================================================

  @ignore
  Color get snackBarBackSuccess =>
      _snackBarBackSuccess ??= Color(snackBarBackSuccessInt);
  @ignore
  Color? _snackBarBackSuccess;
  late final int snackBarBackSuccessInt;

  // ==== snackBarBackError =====================================================

  @ignore
  Color get snackBarBackError =>
      _snackBarBackError ??= Color(snackBarBackErrorInt);
  @ignore
  Color? _snackBarBackError;
  late final int snackBarBackErrorInt;

  // ==== snackBarBackInfo =====================================================

  @ignore
  Color get snackBarBackInfo =>
      _snackBarBackInfo ??= Color(snackBarBackInfoInt);
  @ignore
  Color? _snackBarBackInfo;
  late final int snackBarBackInfoInt;

  // ==== snackBarTextSuccess =====================================================

  @ignore
  Color get snackBarTextSuccess =>
      _snackBarTextSuccess ??= Color(snackBarTextSuccessInt);
  @ignore
  Color? _snackBarTextSuccess;
  late final int snackBarTextSuccessInt;

  // ==== snackBarTextError =====================================================

  @ignore
  Color get snackBarTextError =>
      _snackBarTextError ??= Color(snackBarTextErrorInt);
  @ignore
  Color? _snackBarTextError;
  late final int snackBarTextErrorInt;

  // ==== snackBarTextInfo =====================================================

  @ignore
  Color get snackBarTextInfo =>
      _snackBarTextInfo ??= Color(snackBarTextInfoInt);
  @ignore
  Color? _snackBarTextInfo;
  late final int snackBarTextInfoInt;

  // ==== bottomNavIconBack =====================================================

  @ignore
  Color get bottomNavIconBack =>
      _bottomNavIconBack ??= Color(bottomNavIconBackInt);
  @ignore
  Color? _bottomNavIconBack;
  late final int bottomNavIconBackInt;

  // ==== bottomNavIconIcon =====================================================

  @ignore
  Color get bottomNavIconIcon =>
      _bottomNavIconIcon ??= Color(bottomNavIconIconInt);
  @ignore
  Color? _bottomNavIconIcon;
  late final int bottomNavIconIconInt;

  // ==== bottomNavIconIcon highlighted =====================================================

  @ignore
  Color get bottomNavIconIconHighlighted =>
      _bottomNavIconIconHighlighted ??= Color(bottomNavIconIconHighlightedInt);
  @ignore
  Color? _bottomNavIconIconHighlighted;
  late final int bottomNavIconIconHighlightedInt;

  // ==== topNavIconPrimary =====================================================

  @ignore
  Color get topNavIconPrimary =>
      _topNavIconPrimary ??= Color(topNavIconPrimaryInt);
  @ignore
  Color? _topNavIconPrimary;
  late final int topNavIconPrimaryInt;

  // ==== topNavIconGreen =====================================================

  @ignore
  Color get topNavIconGreen => _topNavIconGreen ??= Color(topNavIconGreenInt);
  @ignore
  Color? _topNavIconGreen;
  late final int topNavIconGreenInt;

  // ==== topNavIconYellow =====================================================

  @ignore
  Color get topNavIconYellow =>
      _topNavIconYellow ??= Color(topNavIconYellowInt);
  @ignore
  Color? _topNavIconYellow;
  late final int topNavIconYellowInt;

  // ==== topNavIconRed =====================================================

  @ignore
  Color get topNavIconRed => _topNavIconRed ??= Color(topNavIconRedInt);
  @ignore
  Color? _topNavIconRed;
  late final int topNavIconRedInt;

  // ==== settingsIconBack =====================================================

  @ignore
  Color get settingsIconBack =>
      _settingsIconBack ??= Color(settingsIconBackInt);
  @ignore
  Color? _settingsIconBack;
  late final int settingsIconBackInt;

  // ==== settingsIconIcon =====================================================

  @ignore
  Color get settingsIconIcon =>
      _settingsIconIcon ??= Color(settingsIconIconInt);
  @ignore
  Color? _settingsIconIcon;
  late final int settingsIconIconInt;

  // ==== settingsIconBack2 =====================================================

  @ignore
  Color get settingsIconBack2 =>
      _settingsIconBack2 ??= Color(settingsIconBack2Int);
  @ignore
  Color? _settingsIconBack2;
  late final int settingsIconBack2Int;

  // ==== settingsIconElement =====================================================

  @ignore
  Color get settingsIconElement =>
      _settingsIconElement ??= Color(settingsIconElementInt);
  @ignore
  Color? _settingsIconElement;
  late final int settingsIconElementInt;

  // ==== textFieldActiveBG =====================================================

  @ignore
  Color get textFieldActiveBG =>
      _textFieldActiveBG ??= Color(textFieldActiveBGInt);
  @ignore
  Color? _textFieldActiveBG;
  late final int textFieldActiveBGInt;

  // ==== textFieldDefaultBG =====================================================

  @ignore
  Color get textFieldDefaultBG =>
      _textFieldDefaultBG ??= Color(textFieldDefaultBGInt);
  @ignore
  Color? _textFieldDefaultBG;
  late final int textFieldDefaultBGInt;

  // ==== textFieldErrorBG =====================================================

  @ignore
  Color get textFieldErrorBG =>
      _textFieldErrorBG ??= Color(textFieldErrorBGInt);
  @ignore
  Color? _textFieldErrorBG;
  late final int textFieldErrorBGInt;

  // ==== textFieldSuccessBG =====================================================

  @ignore
  Color get textFieldSuccessBG =>
      _textFieldSuccessBG ??= Color(textFieldSuccessBGInt);
  @ignore
  Color? _textFieldSuccessBG;
  late final int textFieldSuccessBGInt;

  // ==== textFieldErrorBorder =====================================================

  @ignore
  Color get textFieldErrorBorder =>
      _textFieldErrorBorder ??= Color(textFieldErrorBorderInt);
  @ignore
  Color? _textFieldErrorBorder;
  late final int textFieldErrorBorderInt;

  // ==== textFieldSuccessBorder =====================================================

  @ignore
  Color get textFieldSuccessBorder =>
      _textFieldSuccessBorder ??= Color(textFieldSuccessBorderInt);
  @ignore
  Color? _textFieldSuccessBorder;
  late final int textFieldSuccessBorderInt;

  // ==== textFieldActiveSearchIconLeft =====================================================

  @ignore
  Color get textFieldActiveSearchIconLeft => _textFieldActiveSearchIconLeft ??=
      Color(textFieldActiveSearchIconLeftInt);
  @ignore
  Color? _textFieldActiveSearchIconLeft;
  late final int textFieldActiveSearchIconLeftInt;

  // ==== textFieldDefaultSearchIconLeft =====================================================

  @ignore
  Color get textFieldDefaultSearchIconLeft =>
      _textFieldDefaultSearchIconLeft ??=
          Color(textFieldDefaultSearchIconLeftInt);
  @ignore
  Color? _textFieldDefaultSearchIconLeft;
  late final int textFieldDefaultSearchIconLeftInt;

  // ==== textFieldErrorSearchIconLeft =====================================================

  @ignore
  Color get textFieldErrorSearchIconLeft =>
      _textFieldErrorSearchIconLeft ??= Color(textFieldErrorSearchIconLeftInt);
  @ignore
  Color? _textFieldErrorSearchIconLeft;
  late final int textFieldErrorSearchIconLeftInt;

  // ==== textFieldSuccessSearchIconLeft =====================================================

  @ignore
  Color get textFieldSuccessSearchIconLeft =>
      _textFieldSuccessSearchIconLeft ??=
          Color(textFieldSuccessSearchIconLeftInt);
  @ignore
  Color? _textFieldSuccessSearchIconLeft;
  late final int textFieldSuccessSearchIconLeftInt;

  // ==== textFieldActiveText =====================================================

  @ignore
  Color get textFieldActiveText =>
      _textFieldActiveText ??= Color(textFieldActiveTextInt);
  @ignore
  Color? _textFieldActiveText;
  late final int textFieldActiveTextInt;

  // ==== textFieldDefaultText =====================================================

  @ignore
  Color get textFieldDefaultText =>
      _textFieldDefaultText ??= Color(textFieldDefaultTextInt);
  @ignore
  Color? _textFieldDefaultText;
  late final int textFieldDefaultTextInt;

  // ==== textFieldErrorText =====================================================

  @ignore
  Color get textFieldErrorText =>
      _textFieldErrorText ??= Color(textFieldErrorTextInt);
  @ignore
  Color? _textFieldErrorText;
  late final int textFieldErrorTextInt;

  // ==== textFieldSuccessText =====================================================

  @ignore
  Color get textFieldSuccessText =>
      _textFieldSuccessText ??= Color(textFieldSuccessTextInt);
  @ignore
  Color? _textFieldSuccessText;
  late final int textFieldSuccessTextInt;

  // ==== textFieldActiveLabel =====================================================

  @ignore
  Color get textFieldActiveLabel =>
      _textFieldActiveLabel ??= Color(textFieldActiveLabelInt);
  @ignore
  Color? _textFieldActiveLabel;
  late final int textFieldActiveLabelInt;

  // ==== textFieldErrorLabel =====================================================

  @ignore
  Color get textFieldErrorLabel =>
      _textFieldErrorLabel ??= Color(textFieldErrorLabelInt);
  @ignore
  Color? _textFieldErrorLabel;
  late final int textFieldErrorLabelInt;

  // ==== textFieldSuccessLabel =====================================================

  @ignore
  Color get textFieldSuccessLabel =>
      _textFieldSuccessLabel ??= Color(textFieldSuccessLabelInt);
  @ignore
  Color? _textFieldSuccessLabel;
  late final int textFieldSuccessLabelInt;

  // ==== textFieldActiveSearchIconRight =====================================================

  @ignore
  Color get textFieldActiveSearchIconRight =>
      _textFieldActiveSearchIconRight ??=
          Color(textFieldActiveSearchIconRightInt);
  @ignore
  Color? _textFieldActiveSearchIconRight;
  late final int textFieldActiveSearchIconRightInt;

  // ==== textFieldDefaultSearchIconRight =====================================================

  @ignore
  Color get textFieldDefaultSearchIconRight =>
      _textFieldDefaultSearchIconRight ??=
          Color(textFieldDefaultSearchIconRightInt);
  @ignore
  Color? _textFieldDefaultSearchIconRight;
  late final int textFieldDefaultSearchIconRightInt;

  // ==== textFieldErrorSearchIconRight =====================================================

  @ignore
  Color get textFieldErrorSearchIconRight => _textFieldErrorSearchIconRight ??=
      Color(textFieldErrorSearchIconRightInt);
  @ignore
  Color? _textFieldErrorSearchIconRight;
  late final int textFieldErrorSearchIconRightInt;

  // ==== textFieldSuccessSearchIconRight =====================================================

  @ignore
  Color get textFieldSuccessSearchIconRight =>
      _textFieldSuccessSearchIconRight ??=
          Color(textFieldSuccessSearchIconRightInt);
  @ignore
  Color? _textFieldSuccessSearchIconRight;
  late final int textFieldSuccessSearchIconRightInt;

  // ==== settingsItem2ActiveBG =====================================================

  @ignore
  Color get settingsItem2ActiveBG =>
      _settingsItem2ActiveBG ??= Color(settingsItem2ActiveBGInt);
  @ignore
  Color? _settingsItem2ActiveBG;
  late final int settingsItem2ActiveBGInt;

  // ==== settingsItem2ActiveText =====================================================

  @ignore
  Color get settingsItem2ActiveText =>
      _settingsItem2ActiveText ??= Color(settingsItem2ActiveTextInt);
  @ignore
  Color? _settingsItem2ActiveText;
  late final int settingsItem2ActiveTextInt;

  // ==== settingsItem2ActiveSub =====================================================

  @ignore
  Color get settingsItem2ActiveSub =>
      _settingsItem2ActiveSub ??= Color(settingsItem2ActiveSubInt);
  @ignore
  Color? _settingsItem2ActiveSub;
  late final int settingsItem2ActiveSubInt;

  // ==== radioButtonIconBorder =====================================================

  @ignore
  Color get radioButtonIconBorder =>
      _radioButtonIconBorder ??= Color(radioButtonIconBorderInt);
  @ignore
  Color? _radioButtonIconBorder;
  late final int radioButtonIconBorderInt;

  // ==== radioButtonIconBorderDisabled =====================================================

  @ignore
  Color get radioButtonIconBorderDisabled => _radioButtonIconBorderDisabled ??=
      Color(radioButtonIconBorderDisabledInt);
  @ignore
  Color? _radioButtonIconBorderDisabled;
  late final int radioButtonIconBorderDisabledInt;

  // ==== radioButtonBorderEnabled =====================================================

  @ignore
  Color get radioButtonBorderEnabled =>
      _radioButtonBorderEnabled ??= Color(radioButtonBorderEnabledInt);
  @ignore
  Color? _radioButtonBorderEnabled;
  late final int radioButtonBorderEnabledInt;

  // ==== radioButtonBorderDisabled =====================================================

  @ignore
  Color get radioButtonBorderDisabled =>
      _radioButtonBorderDisabled ??= Color(radioButtonBorderDisabledInt);
  @ignore
  Color? _radioButtonBorderDisabled;
  late final int radioButtonBorderDisabledInt;

  // ==== radioButtonIconCircle =====================================================

  @ignore
  Color get radioButtonIconCircle =>
      _radioButtonIconCircle ??= Color(radioButtonIconCircleInt);
  @ignore
  Color? _radioButtonIconCircle;
  late final int radioButtonIconCircleInt;

  // ==== radioButtonIconEnabled =====================================================

  @ignore
  Color get radioButtonIconEnabled =>
      _radioButtonIconEnabled ??= Color(radioButtonIconEnabledInt);
  @ignore
  Color? _radioButtonIconEnabled;
  late final int radioButtonIconEnabledInt;

  // ==== radioButtonTextEnabled =====================================================

  @ignore
  Color get radioButtonTextEnabled =>
      _radioButtonTextEnabled ??= Color(radioButtonTextEnabledInt);
  @ignore
  Color? _radioButtonTextEnabled;
  late final int radioButtonTextEnabledInt;

  // ==== radioButtonTextDisabled =====================================================

  @ignore
  Color get radioButtonTextDisabled =>
      _radioButtonTextDisabled ??= Color(radioButtonTextDisabledInt);
  @ignore
  Color? _radioButtonTextDisabled;
  late final int radioButtonTextDisabledInt;

  // ==== radioButtonLabelEnabled =====================================================

  @ignore
  Color get radioButtonLabelEnabled =>
      _radioButtonLabelEnabled ??= Color(radioButtonLabelEnabledInt);
  @ignore
  Color? _radioButtonLabelEnabled;
  late final int radioButtonLabelEnabledInt;

  // ==== radioButtonLabelDisabled =====================================================

  @ignore
  Color get radioButtonLabelDisabled =>
      _radioButtonLabelDisabled ??= Color(radioButtonLabelDisabledInt);
  @ignore
  Color? _radioButtonLabelDisabled;
  late final int radioButtonLabelDisabledInt;

  // ==== infoItemBG =====================================================

  @ignore
  Color get infoItemBG => _infoItemBG ??= Color(infoItemBGInt);
  @ignore
  Color? _infoItemBG;
  late final int infoItemBGInt;

  // ==== infoItemLabel =====================================================

  @ignore
  Color get infoItemLabel => _infoItemLabel ??= Color(infoItemLabelInt);
  @ignore
  Color? _infoItemLabel;
  late final int infoItemLabelInt;

  // ==== infoItemText =====================================================

  @ignore
  Color get infoItemText => _infoItemText ??= Color(infoItemTextInt);
  @ignore
  Color? _infoItemText;
  late final int infoItemTextInt;

  // ==== infoItemIcons =====================================================

  @ignore
  Color get infoItemIcons => _infoItemIcons ??= Color(infoItemIconsInt);
  @ignore
  Color? _infoItemIcons;
  late final int infoItemIconsInt;

  // ==== popupBG =====================================================

  @ignore
  Color get popupBG => _popupBG ??= Color(popupBGInt);
  @ignore
  Color? _popupBG;
  late final int popupBGInt;

  // ==== currencyListItemBG =====================================================

  @ignore
  Color get currencyListItemBG =>
      _currencyListItemBG ??= Color(currencyListItemBGInt);
  @ignore
  Color? _currencyListItemBG;
  late final int currencyListItemBGInt;

  // ==== stackWalletBG =====================================================

  @ignore
  Color get stackWalletBG => _stackWalletBG ??= Color(stackWalletBGInt);
  @ignore
  Color? _stackWalletBG;
  late final int stackWalletBGInt;

  // ==== stackWalletMid =====================================================

  @ignore
  Color get stackWalletMid => _stackWalletMid ??= Color(stackWalletMidInt);
  @ignore
  Color? _stackWalletMid;
  late final int stackWalletMidInt;

  // ==== stackWalletBottom =====================================================

  @ignore
  Color get stackWalletBottom =>
      _stackWalletBottom ??= Color(stackWalletBottomInt);
  @ignore
  Color? _stackWalletBottom;
  late final int stackWalletBottomInt;

  // ==== bottomNavShadow =====================================================

  @ignore
  Color get bottomNavShadow => _bottomNavShadow ??= Color(bottomNavShadowInt);
  @ignore
  Color? _bottomNavShadow;
  late final int bottomNavShadowInt;

  // ==== favoriteStarActive =====================================================

  @ignore
  Color get favoriteStarActive =>
      _favoriteStarActive ??= Color(favoriteStarActiveInt);
  @ignore
  Color? _favoriteStarActive;
  late final int favoriteStarActiveInt;

  // ==== favoriteStarInactive =====================================================

  @ignore
  Color get favoriteStarInactive =>
      _favoriteStarInactive ??= Color(favoriteStarInactiveInt);
  @ignore
  Color? _favoriteStarInactive;
  late final int favoriteStarInactiveInt;

  // ==== splash =====================================================

  @ignore
  Color get splash => _splash ??= Color(splashInt);
  @ignore
  Color? _splash;
  late final int splashInt;

  // ==== highlight =====================================================

  @ignore
  Color get highlight => _highlight ??= Color(highlightInt);
  @ignore
  Color? _highlight;
  late final int highlightInt;

  // ==== warningForeground =====================================================

  @ignore
  Color get warningForeground =>
      _warningForeground ??= Color(warningForegroundInt);
  @ignore
  Color? _warningForeground;
  late final int warningForegroundInt;

  // ==== warningBackground =====================================================

  @ignore
  Color get warningBackground =>
      _warningBackground ??= Color(warningBackgroundInt);
  @ignore
  Color? _warningBackground;
  late final int warningBackgroundInt;

  // ==== loadingOverlayTextColor =====================================================

  @ignore
  Color get loadingOverlayTextColor =>
      _loadingOverlayTextColor ??= Color(loadingOverlayTextColorInt);
  @ignore
  Color? _loadingOverlayTextColor;
  late final int loadingOverlayTextColorInt;

  // ==== myStackContactIconBG =====================================================

  @ignore
  Color get myStackContactIconBG =>
      _myStackContactIconBG ??= Color(myStackContactIconBGInt);
  @ignore
  Color? _myStackContactIconBG;
  late final int myStackContactIconBGInt;

  // ==== textConfirmTotalAmount =====================================================

  @ignore
  Color get textConfirmTotalAmount =>
      _textConfirmTotalAmount ??= Color(textConfirmTotalAmountInt);
  @ignore
  Color? _textConfirmTotalAmount;
  late final int textConfirmTotalAmountInt;

  // ==== textSelectedWordTableItem =====================================================

  @ignore
  Color get textSelectedWordTableItem =>
      _textSelectedWordTableItem ??= Color(textSelectedWordTableItemInt);
  @ignore
  Color? _textSelectedWordTableItem;
  late final int textSelectedWordTableItemInt;

  // ==== rateTypeToggleColorOn =====================================================

  @ignore
  Color get rateTypeToggleColorOn =>
      _rateTypeToggleColorOn ??= Color(rateTypeToggleColorOnInt);
  @ignore
  Color? _rateTypeToggleColorOn;
  late final int rateTypeToggleColorOnInt;

  // ==== rateTypeToggleColorOff =====================================================

  @ignore
  Color get rateTypeToggleColorOff =>
      _rateTypeToggleColorOff ??= Color(rateTypeToggleColorOffInt);
  @ignore
  Color? _rateTypeToggleColorOff;
  late final int rateTypeToggleColorOffInt;

  // ==== rateTypeToggleDesktopColorOn =====================================================

  @ignore
  Color get rateTypeToggleDesktopColorOn =>
      _rateTypeToggleDesktopColorOn ??= Color(rateTypeToggleDesktopColorOnInt);
  @ignore
  Color? _rateTypeToggleDesktopColorOn;
  late final int rateTypeToggleDesktopColorOnInt;

  // ==== rateTypeToggleDesktopColorOff =====================================================

  @ignore
  Color get rateTypeToggleDesktopColorOff => _rateTypeToggleDesktopColorOff ??=
      Color(rateTypeToggleDesktopColorOffInt);
  @ignore
  Color? _rateTypeToggleDesktopColorOff;
  late final int rateTypeToggleDesktopColorOffInt;

  // ==== ethTagText =====================================================

  @ignore
  Color get ethTagText => _ethTagText ??= Color(ethTagTextInt);
  @ignore
  Color? _ethTagText;
  late final int ethTagTextInt;

  // ==== ethTagBG =====================================================

  @ignore
  Color get ethTagBG => _ethTagBG ??= Color(ethTagBGInt);
  @ignore
  Color? _ethTagBG;
  late final int ethTagBGInt;

  // ==== ethWalletTagText =====================================================

  @ignore
  Color get ethWalletTagText =>
      _ethWalletTagText ??= Color(ethWalletTagTextInt);
  @ignore
  Color? _ethWalletTagText;
  late final int ethWalletTagTextInt;

  // ==== ethWalletTagBG =====================================================

  @ignore
  Color get ethWalletTagBG => _ethWalletTagBG ??= Color(ethWalletTagBGInt);
  @ignore
  Color? _ethWalletTagBG;
  late final int ethWalletTagBGInt;

  // ==== tokenSummaryTextPrimary =====================================================

  @ignore
  Color get tokenSummaryTextPrimary =>
      _tokenSummaryTextPrimary ??= Color(tokenSummaryTextPrimaryInt);
  @ignore
  Color? _tokenSummaryTextPrimary;
  late final int tokenSummaryTextPrimaryInt;

  // ==== tokenSummaryTextSecondary =====================================================

  @ignore
  Color get tokenSummaryTextSecondary =>
      _tokenSummaryTextSecondary ??= Color(tokenSummaryTextSecondaryInt);
  @ignore
  Color? _tokenSummaryTextSecondary;
  late final int tokenSummaryTextSecondaryInt;

  // ==== tokenSummaryBG =====================================================

  @ignore
  Color get tokenSummaryBG => _tokenSummaryBG ??= Color(tokenSummaryBGInt);
  @ignore
  Color? _tokenSummaryBG;
  late final int tokenSummaryBGInt;

  // ==== tokenSummaryButtonBG =====================================================

  @ignore
  Color get tokenSummaryButtonBG =>
      _tokenSummaryButtonBG ??= Color(tokenSummaryButtonBGInt);
  @ignore
  Color? _tokenSummaryButtonBG;
  late final int tokenSummaryButtonBGInt;

  // ==== tokenSummaryIcon =====================================================

  @ignore
  Color get tokenSummaryIcon =>
      _tokenSummaryIcon ??= Color(tokenSummaryIconInt);
  @ignore
  Color? _tokenSummaryIcon;
  late final int tokenSummaryIconInt;

  // ==== coinColors =====================================================

  @ignore
  Map<Coin, Color> get coinColors =>
      _coinColors ??= parseCoinColors(coinColorsJsonString);
  @ignore
  Map<Coin, Color>? _coinColors;
  late final String coinColorsJsonString;

  // ==== assets =====================================================

  @Name("assets") // legacy "column" name
  late final ThemeAssets? assetsV1;

  late final ThemeAssetsV2? assetsV2;

  @ignore
  IThemeAssets get assets => assetsV2 ?? assetsV1!;

  // ===========================================================================

  late final int? version;

  StackTheme();

  factory StackTheme.fromJson({
    required Map<String, dynamic> json,
    required String applicationThemesDirectoryPath,
  }) {
    final version = json["version"] as int? ?? 1;

    return StackTheme()
      ..version = version
      ..assetsV1 = version == 1
          ? ThemeAssets.fromJson(
              json: Map<String, dynamic>.from(json["assets"] as Map),
              applicationThemesDirectoryPath: applicationThemesDirectoryPath,
              themeId: json["id"] as String,
            )
          : null
      ..assetsV2 = version == 2
          ? ThemeAssetsV2.fromJson(
              json: Map<String, dynamic>.from(json["assets"] as Map),
              applicationThemesDirectoryPath: applicationThemesDirectoryPath,
              themeId: json["id"] as String,
            )
          : null
      ..themeId = json["id"] as String
      ..name = json["name"] as String
      ..brightnessString = json["brightness"] as String
      ..backgroundInt = parseColor(json["colors"]["background"] as String)
      ..backgroundAppBarInt =
          parseColor(json["colors"]["background_app_bar"] as String)
      ..gradientBackgroundString = json["colors"]["gradients"] != null
          ? jsonEncode(json["colors"]["gradients"])
          : null
      ..standardBoxShadowString =
          jsonEncode(json["colors"]["box_shadows"]["standard"] as Map)
      ..homeViewButtonBarBoxShadowString =
          json["colors"]["box_shadows"]["home_view_button_bar"] == null
              ? null
              : jsonEncode(
                  json["colors"]["box_shadows"]["home_view_button_bar"] as Map)
      ..coinColorsJsonString = jsonEncode(json["colors"]['coin'] as Map)
      ..overlayInt = parseColor(json["colors"]["overlay"] as String)
      ..accentColorBlueInt =
          parseColor(json["colors"]["accent_color_blue"] as String)
      ..accentColorGreenInt =
          parseColor(json["colors"]["accent_color_green"] as String)
      ..accentColorYellowInt =
          parseColor(json["colors"]["accent_color_yellow"] as String)
      ..accentColorRedInt =
          parseColor(json["colors"]["accent_color_red"] as String)
      ..accentColorOrangeInt =
          parseColor(json["colors"]["accent_color_orange"] as String)
      ..accentColorDarkInt =
          parseColor(json["colors"]["accent_color_dark"] as String)
      ..shadowInt = parseColor(json["colors"]["shadow"] as String)
      ..textDarkInt = parseColor(json["colors"]["text_dark_one"] as String)
      ..textDark2Int = parseColor(json["colors"]["text_dark_two"] as String)
      ..textDark3Int = parseColor(json["colors"]["text_dark_three"] as String)
      ..textWhiteInt = parseColor(json["colors"]["text_white"] as String)
      ..textFavoriteCardInt =
          parseColor(json["colors"]["text_favorite"] as String)
      ..textErrorInt = parseColor(json["colors"]["text_error"] as String)
      ..textRestoreInt = parseColor(json["colors"]["text_restore"] as String)
      ..buttonBackPrimaryInt =
          parseColor(json["colors"]["button_back_primary"] as String)
      ..buttonBackSecondaryInt =
          parseColor(json["colors"]["button_back_secondary"] as String)
      ..buttonBackPrimaryDisabledInt =
          parseColor(json["colors"]["button_back_primary_disabled"] as String)
      ..buttonBackSecondaryDisabledInt =
          parseColor(json["colors"]["button_back_secondary_disabled"] as String)
      ..buttonBackBorderInt =
          parseColor(json["colors"]["button_back_border"] as String)
      ..buttonBackBorderDisabledInt =
          parseColor(json["colors"]["button_back_border_disabled"] as String)
      ..buttonBackBorderSecondaryInt =
          parseColor(json["colors"]["button_back_border_secondary"] as String)
      ..buttonBackBorderSecondaryDisabledInt = parseColor(
          json["colors"]["button_back_border_secondary_disabled"] as String)
      ..numberBackDefaultInt =
          parseColor(json["colors"]["number_back_default"] as String)
      ..numpadBackDefaultInt =
          parseColor(json["colors"]["numpad_back_default"] as String)
      ..bottomNavBackInt =
          parseColor(json["colors"]["bottom_nav_back"] as String)
      ..textSubtitle1Int =
          parseColor(json["colors"]["text_subtitle_one"] as String)
      ..textSubtitle2Int =
          parseColor(json["colors"]["text_subtitle_two"] as String)
      ..textSubtitle3Int =
          parseColor(json["colors"]["text_subtitle_three"] as String)
      ..textSubtitle4Int =
          parseColor(json["colors"]["text_subtitle_four"] as String)
      ..textSubtitle5Int =
          parseColor(json["colors"]["text_subtitle_five"] as String)
      ..textSubtitle6Int =
          parseColor(json["colors"]["text_subtitle_six"] as String)
      ..buttonTextPrimaryInt =
          parseColor(json["colors"]["button_text_primary"] as String)
      ..buttonTextSecondaryInt =
          parseColor(json["colors"]["button_text_secondary"] as String)
      ..buttonTextPrimaryDisabledInt =
          parseColor(json["colors"]["button_text_primary_disabled"] as String)
      ..buttonTextSecondaryDisabledInt =
          parseColor(json["colors"]["button_text_secondary_disabled"] as String)
      ..buttonTextBorderInt =
          parseColor(json["colors"]["button_text_border"] as String)
      ..buttonTextDisabledInt =
          parseColor(json["colors"]["button_text_disabled"] as String)
      ..buttonTextBorderlessInt =
          parseColor(json["colors"]["button_text_borderless"] as String)
      ..buttonTextBorderlessDisabledInt = parseColor(
          json["colors"]["button_text_borderless_disabled"] as String)
      ..numberTextDefaultInt =
          parseColor(json["colors"]["number_text_default"] as String)
      ..numpadTextDefaultInt =
          parseColor(json["colors"]["numpad_text_default"] as String)
      ..bottomNavTextInt =
          parseColor(json["colors"]["bottom_nav_text"] as String)
      ..customTextButtonEnabledTextInt = parseColor(
          json["colors"]["custom_text_button_enabled_text"] as String)
      ..customTextButtonDisabledTextInt = parseColor(
          json["colors"]["custom_text_button_disabled_text"] as String)
      ..switchBGOnInt = parseColor(json["colors"]["switch_bg_on"] as String)
      ..switchBGOffInt = parseColor(json["colors"]["switch_bg_off"] as String)
      ..switchBGDisabledInt =
          parseColor(json["colors"]["switch_bg_disabled"] as String)
      ..switchCircleOnInt =
          parseColor(json["colors"]["switch_circle_on"] as String)
      ..switchCircleOffInt =
          parseColor(json["colors"]["switch_circle_off"] as String)
      ..switchCircleDisabledInt =
          parseColor(json["colors"]["switch_circle_disabled"] as String)
      ..stepIndicatorBGCheckInt =
          parseColor(json["colors"]["step_indicator_bg_check"] as String)
      ..stepIndicatorBGNumberInt =
          parseColor(json["colors"]["step_indicator_bg_number"] as String)
      ..stepIndicatorBGInactiveInt =
          parseColor(json["colors"]["step_indicator_bg_inactive"] as String)
      ..stepIndicatorBGLinesInt =
          parseColor(json["colors"]["step_indicator_bg_lines"] as String)
      ..stepIndicatorBGLinesInactiveInt = parseColor(
          json["colors"]["step_indicator_bg_lines_inactive"] as String)
      ..stepIndicatorIconTextInt =
          parseColor(json["colors"]["step_indicator_icon_text"] as String)
      ..stepIndicatorIconNumberInt =
          parseColor(json["colors"]["step_indicator_icon_number"] as String)
      ..stepIndicatorIconInactiveInt =
          parseColor(json["colors"]["step_indicator_icon_inactive"] as String)
      ..checkboxBGCheckedInt =
          parseColor(json["colors"]["checkbox_bg_checked"] as String)
      ..checkboxBorderEmptyInt =
          parseColor(json["colors"]["checkbox_border_empty"] as String)
      ..checkboxBGDisabledInt =
          parseColor(json["colors"]["checkbox_bg_disabled"] as String)
      ..checkboxIconCheckedInt =
          parseColor(json["colors"]["checkbox_icon_checked"] as String)
      ..checkboxIconDisabledInt =
          parseColor(json["colors"]["checkbox_icon_disabled"] as String)
      ..checkboxTextLabelInt =
          parseColor(json["colors"]["checkbox_text_label"] as String)
      ..snackBarBackSuccessInt =
          parseColor(json["colors"]["snack_bar_back_success"] as String)
      ..snackBarBackErrorInt =
          parseColor(json["colors"]["snack_bar_back_error"] as String)
      ..snackBarBackInfoInt =
          parseColor(json["colors"]["snack_bar_back_info"] as String)
      ..snackBarTextSuccessInt =
          parseColor(json["colors"]["snack_bar_text_success"] as String)
      ..snackBarTextErrorInt =
          parseColor(json["colors"]["snack_bar_text_error"] as String)
      ..snackBarTextInfoInt =
          parseColor(json["colors"]["snack_bar_text_info"] as String)
      ..bottomNavIconBackInt =
          parseColor(json["colors"]["bottom_nav_icon_back"] as String)
      ..bottomNavIconIconInt =
          parseColor(json["colors"]["bottom_nav_icon_icon"] as String)
      ..bottomNavIconIconHighlightedInt = parseColor(
          json["colors"]["bottom_nav_icon_icon_highlighted"] as String)
      ..topNavIconPrimaryInt =
          parseColor(json["colors"]["top_nav_icon_primary"] as String)
      ..topNavIconGreenInt =
          parseColor(json["colors"]["top_nav_icon_green"] as String)
      ..topNavIconYellowInt =
          parseColor(json["colors"]["top_nav_icon_yellow"] as String)
      ..topNavIconRedInt =
          parseColor(json["colors"]["top_nav_icon_red"] as String)
      ..settingsIconBackInt =
          parseColor(json["colors"]["settings_icon_back"] as String)
      ..settingsIconIconInt =
          parseColor(json["colors"]["settings_icon_icon"] as String)
      ..settingsIconBack2Int =
          parseColor(json["colors"]["settings_icon_back_two"] as String)
      ..settingsIconElementInt =
          parseColor(json["colors"]["settings_icon_element"] as String)
      ..textFieldActiveBGInt =
          parseColor(json["colors"]["text_field_active_bg"] as String)
      ..textFieldDefaultBGInt =
          parseColor(json["colors"]["text_field_default_bg"] as String)
      ..textFieldErrorBGInt =
          parseColor(json["colors"]["text_field_error_bg"] as String)
      ..textFieldSuccessBGInt =
          parseColor(json["colors"]["text_field_success_bg"] as String)
      ..textFieldErrorBorderInt =
          parseColor(json["colors"]["text_field_error_border"] as String)
      ..textFieldSuccessBorderInt =
          parseColor(json["colors"]["text_field_success_border"] as String)
      ..textFieldActiveSearchIconLeftInt = parseColor(
          json["colors"]["text_field_active_search_icon_left"] as String)
      ..textFieldDefaultSearchIconLeftInt = parseColor(
          json["colors"]["text_field_default_search_icon_left"] as String)
      ..textFieldErrorSearchIconLeftInt = parseColor(
          json["colors"]["text_field_error_search_icon_left"] as String)
      ..textFieldSuccessSearchIconLeftInt = parseColor(
          json["colors"]["text_field_success_search_icon_left"] as String)
      ..textFieldActiveTextInt =
          parseColor(json["colors"]["text_field_active_text"] as String)
      ..textFieldDefaultTextInt =
          parseColor(json["colors"]["text_field_default_text"] as String)
      ..textFieldErrorTextInt =
          parseColor(json["colors"]["text_field_error_text"] as String)
      ..textFieldSuccessTextInt =
          parseColor(json["colors"]["text_field_success_text"] as String)
      ..textFieldActiveLabelInt =
          parseColor(json["colors"]["text_field_active_label"] as String)
      ..textFieldErrorLabelInt =
          parseColor(json["colors"]["text_field_error_label"] as String)
      ..textFieldSuccessLabelInt =
          parseColor(json["colors"]["text_field_success_label"] as String)
      ..textFieldActiveSearchIconRightInt = parseColor(
          json["colors"]["text_field_active_search_icon_right"] as String)
      ..textFieldDefaultSearchIconRightInt = parseColor(
          json["colors"]["text_field_default_search_icon_right"] as String)
      ..textFieldErrorSearchIconRightInt = parseColor(
          json["colors"]["text_field_error_search_icon_right"] as String)
      ..textFieldSuccessSearchIconRightInt = parseColor(
          json["colors"]["text_field_success_search_icon_right"] as String)
      ..settingsItem2ActiveBGInt = parseColor(
          json["colors"]["settings_item_level_two_active_bg"] as String)
      ..settingsItem2ActiveTextInt = parseColor(
          json["colors"]["settings_item_level_two_active_text"] as String)
      ..settingsItem2ActiveSubInt = parseColor(
          json["colors"]["settings_item_level_two_active_sub"] as String)
      ..radioButtonIconBorderInt =
          parseColor(json["colors"]["radio_button_icon_border"] as String)
      ..radioButtonIconBorderDisabledInt = parseColor(
          json["colors"]["radio_button_icon_border_disabled"] as String)
      ..radioButtonBorderEnabledInt =
          parseColor(json["colors"]["radio_button_border_enabled"] as String)
      ..radioButtonBorderDisabledInt =
          parseColor(json["colors"]["radio_button_border_disabled"] as String)
      ..radioButtonIconCircleInt =
          parseColor(json["colors"]["radio_button_icon_circle"] as String)
      ..radioButtonIconEnabledInt =
          parseColor(json["colors"]["radio_button_icon_enabled"] as String)
      ..radioButtonTextEnabledInt =
          parseColor(json["colors"]["radio_button_text_enabled"] as String)
      ..radioButtonTextDisabledInt =
          parseColor(json["colors"]["radio_button_text_disabled"] as String)
      ..radioButtonLabelEnabledInt =
          parseColor(json["colors"]["radio_button_label_enabled"] as String)
      ..radioButtonLabelDisabledInt =
          parseColor(json["colors"]["radio_button_label_disabled"] as String)
      ..infoItemBGInt = parseColor(json["colors"]["info_item_bg"] as String)
      ..infoItemLabelInt =
          parseColor(json["colors"]["info_item_label"] as String)
      ..infoItemTextInt = parseColor(json["colors"]["info_item_text"] as String)
      ..infoItemIconsInt =
          parseColor(json["colors"]["info_item_icons"] as String)
      ..popupBGInt = parseColor(json["colors"]["popup_bg"] as String)
      ..currencyListItemBGInt =
          parseColor(json["colors"]["currency_list_item_bg"] as String)
      ..stackWalletBGInt = parseColor(json["colors"]["sw_bg"] as String)
      ..stackWalletMidInt = parseColor(json["colors"]["sw_mid"] as String)
      ..stackWalletBottomInt = parseColor(json["colors"]["sw_bottom"] as String)
      ..bottomNavShadowInt =
          parseColor(json["colors"]["bottom_nav_shadow"] as String)
      ..splashInt = parseColor(json["colors"]["splash"] as String)
      ..highlightInt = parseColor(json["colors"]["highlight"] as String)
      ..warningForegroundInt =
          parseColor(json["colors"]["warning_foreground"] as String)
      ..warningBackgroundInt =
          parseColor(json["colors"]["warning_background"] as String)
      ..loadingOverlayTextColorInt =
          parseColor(json["colors"]["loading_overlay_text_color"] as String)
      ..myStackContactIconBGInt =
          parseColor(json["colors"]["my_stack_contact_icon_bg"] as String)
      ..textConfirmTotalAmountInt =
          parseColor(json["colors"]["text_confirm_total_amount"] as String)
      ..textSelectedWordTableItemInt =
          parseColor(json["colors"]["text_selected_word_table_iterm"] as String)
      ..favoriteStarActiveInt =
          parseColor(json["colors"]["favorite_star_active"] as String)
      ..favoriteStarInactiveInt =
          parseColor(json["colors"]["favorite_star_inactive"] as String)
      ..rateTypeToggleColorOnInt =
          parseColor(json["colors"]["rate_type_toggle_color_on"] as String)
      ..rateTypeToggleColorOffInt =
          parseColor(json["colors"]["rate_type_toggle_color_off"] as String)
      ..rateTypeToggleDesktopColorOnInt = parseColor(
          json["colors"]["rate_type_toggle_desktop_color_on"] as String)
      ..rateTypeToggleDesktopColorOffInt = parseColor(
          json["colors"]["rate_type_toggle_desktop_color_off"] as String)
      ..ethTagTextInt = parseColor(json["colors"]["eth_tag_text"] as String)
      ..ethTagBGInt = parseColor(json["colors"]["eth_tag_bg"] as String)
      ..ethWalletTagTextInt =
          parseColor(json["colors"]["eth_wallet_tag_text"] as String)
      ..ethWalletTagBGInt =
          parseColor(json["colors"]["eth_wallet_tag_bg"] as String)
      ..tokenSummaryTextPrimaryInt =
          parseColor(json["colors"]["token_summary_text_primary"] as String)
      ..tokenSummaryTextSecondaryInt =
          parseColor(json["colors"]["token_summary_text_secondary"] as String)
      ..tokenSummaryBGInt =
          parseColor(json["colors"]["token_summary_bg"] as String)
      ..tokenSummaryButtonBGInt =
          parseColor(json["colors"]["token_summary_button_bg"] as String)
      ..tokenSummaryIconInt =
          parseColor(json["colors"]["token_summary_icon"] as String);
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
class ThemeAssets implements IThemeAssets {
  @override
  late final String bellNew;
  @override
  late final String buy;
  @override
  late final String exchange;
  @override
  late final String personaIncognito;
  @override
  late final String personaEasy;
  @override
  late final String stack;
  @override
  late final String stackIcon;
  @override
  late final String receive;
  @override
  late final String receivePending;
  @override
  late final String receiveCancelled;
  @override
  late final String send;
  @override
  late final String sendPending;
  @override
  late final String sendCancelled;
  @override
  late final String themeSelector;
  @override
  late final String themePreview;
  @override
  late final String txExchange;
  @override
  late final String txExchangePending;
  @override
  late final String txExchangeFailed;

  late final String bitcoin;
  late final String litecoin;
  late final String bitcoincash;
  late final String dogecoin;
  late final String epicCash;
  late final String ethereum;
  late final String firo;
  late final String monero;
  late final String wownero;
  late final String namecoin;
  late final String particl;
  late final String bitcoinImage;
  late final String bitcoincashImage;
  late final String dogecoinImage;
  late final String epicCashImage;
  late final String ethereumImage;
  late final String firoImage;
  late final String litecoinImage;
  late final String moneroImage;
  late final String wowneroImage;
  late final String namecoinImage;
  late final String particlImage;
  late final String bitcoinImageSecondary;
  late final String bitcoincashImageSecondary;
  late final String dogecoinImageSecondary;
  late final String epicCashImageSecondary;
  late final String ethereumImageSecondary;
  late final String firoImageSecondary;
  late final String litecoinImageSecondary;
  late final String moneroImageSecondary;
  late final String wowneroImageSecondary;
  late final String namecoinImageSecondary;
  late final String particlImageSecondary;
  @override
  late final String? loadingGif;
  @override
  late final String? background;

  // todo: add all assets expected in json

  ThemeAssets();

  factory ThemeAssets.fromJson({
    required Map<String, dynamic> json,
    required String applicationThemesDirectoryPath,
    required String themeId,
  }) {
    return ThemeAssets()
      ..bellNew =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["bell_new"] as String}"
      ..buy =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["buy"] as String}"
      ..exchange =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["exchange"] as String}"
      ..personaIncognito =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["persona_incognito"] as String}"
      ..personaEasy =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["persona_easy"] as String}"
      ..stack =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["stack"] as String}"
      ..stackIcon =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["stack_icon"] as String}"
      ..receive =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["receive"] as String}"
      ..receivePending =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["receive_pending"] as String}"
      ..receiveCancelled =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["receive_cancelled"] as String}"
      ..send =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["send"] as String}"
      ..sendPending =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["send_pending"] as String}"
      ..sendCancelled =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["send_cancelled"] as String}"
      ..themeSelector =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["theme_selector"] as String}"
      ..themePreview =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["theme_preview"] as String}"
      ..txExchange =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["tx_exchange"] as String}"
      ..txExchangePending =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["tx_exchange_pending"] as String}"
      ..txExchangeFailed =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["tx_exchange_failed"] as String}"
      ..bitcoin =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["bitcoin"] as String}"
      ..litecoin =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["litecoin"] as String}"
      ..bitcoincash =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["bitcoincash"] as String}"
      ..dogecoin =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["dogecoin"] as String}"
      ..epicCash =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["epicCash"] as String}"
      ..ethereum =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["ethereum"] as String}"
      ..firo =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["firo"] as String}"
      ..monero =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["monero"] as String}"
      ..wownero =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["wownero"] as String}"
      ..namecoin =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["namecoin"] as String}"
      ..particl =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["particl"] as String}"
      ..bitcoinImage =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["bitcoin_image"] as String}"
      ..bitcoincashImage =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["bitcoincash_image"] as String}"
      ..dogecoinImage =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["dogecoin_image"] as String}"
      ..epicCashImage =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["epicCash_image"] as String}"
      ..ethereumImage =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["ethereum_image"] as String}"
      ..firoImage =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["firo_image"] as String}"
      ..litecoinImage =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["litecoin_image"] as String}"
      ..moneroImage =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["monero_image"] as String}"
      ..wowneroImage =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["wownero_image"] as String}"
      ..namecoinImage =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["namecoin_image"] as String}"
      ..particlImage =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["particl_image"] as String}"
      ..bitcoinImageSecondary =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["bitcoin_image_secondary"] as String}"
      ..bitcoincashImageSecondary =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["bitcoincash_image_secondary"] as String}"
      ..dogecoinImageSecondary =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["dogecoin_image_secondary"] as String}"
      ..epicCashImageSecondary =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["epicCash_image_secondary"] as String}"
      ..ethereumImageSecondary =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["ethereum_image_secondary"] as String}"
      ..firoImageSecondary =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["firo_image_secondary"] as String}"
      ..litecoinImageSecondary =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["litecoin_image_secondary"] as String}"
      ..moneroImageSecondary =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["monero_image_secondary"] as String}"
      ..wowneroImageSecondary =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["wownero_image_secondary"] as String}"
      ..namecoinImageSecondary =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["namecoin_image_secondary"] as String}"
      ..particlImageSecondary =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["particl_image_secondary"] as String}"
      ..loadingGif = json["loading_gif"] is String
          ? "$applicationThemesDirectoryPath/$themeId/assets/${json["loading_gif"] as String}"
          : null
      ..background = json["background"] is String
          ? "$applicationThemesDirectoryPath/$themeId/assets/${json["background"] as String}"
          : null;
  }
}

@Embedded(inheritance: false)
class ThemeAssetsV2 implements IThemeAssets {
  @override
  late final String bellNew;
  @override
  late final String buy;
  @override
  late final String exchange;
  @override
  late final String personaIncognito;
  @override
  late final String personaEasy;
  @override
  late final String stack;
  @override
  late final String stackIcon;
  @override
  late final String receive;
  @override
  late final String receivePending;
  @override
  late final String receiveCancelled;
  @override
  late final String send;
  @override
  late final String sendPending;
  @override
  late final String sendCancelled;
  @override
  late final String themeSelector;
  @override
  late final String themePreview;
  @override
  late final String txExchange;
  @override
  late final String txExchangePending;
  @override
  late final String txExchangeFailed;
  @override
  late final String? loadingGif;
  @override
  late final String? background;

  late final String coinPlaceholder;

  @ignore
  Map<Coin, String> get coinIcons => _coinIcons ??= parseCoinAssetsString(
        coinIconsString,
        placeHolder: coinPlaceholder,
      );
  @ignore
  Map<Coin, String>? _coinIcons;
  late final String coinIconsString;

  @ignore
  Map<Coin, String> get coinImages => _coinImages ??= parseCoinAssetsString(
        coinImagesString,
        placeHolder: coinPlaceholder,
      );
  @ignore
  Map<Coin, String>? _coinImages;
  late final String coinImagesString;

  @ignore
  Map<Coin, String> get coinSecondaryImages =>
      _coinSecondaryImages ??= parseCoinAssetsString(
        coinSecondaryImagesString,
        placeHolder: coinPlaceholder,
      );
  @ignore
  Map<Coin, String>? _coinSecondaryImages;
  late final String coinSecondaryImagesString;

  ThemeAssetsV2();

  factory ThemeAssetsV2.fromJson({
    required Map<String, dynamic> json,
    required String applicationThemesDirectoryPath,
    required String themeId,
  }) {
    return ThemeAssetsV2()
      ..bellNew =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["bell_new"] as String}"
      ..buy =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["buy"] as String}"
      ..exchange =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["exchange"] as String}"
      ..personaIncognito =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["persona_incognito"] as String}"
      ..personaEasy =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["persona_easy"] as String}"
      ..stack =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["stack"] as String}"
      ..stackIcon =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["stack_icon"] as String}"
      ..receive =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["receive"] as String}"
      ..receivePending =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["receive_pending"] as String}"
      ..receiveCancelled =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["receive_cancelled"] as String}"
      ..send =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["send"] as String}"
      ..sendPending =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["send_pending"] as String}"
      ..sendCancelled =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["send_cancelled"] as String}"
      ..themeSelector =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["theme_selector"] as String}"
      ..themePreview =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["theme_preview"] as String}"
      ..txExchange =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["tx_exchange"] as String}"
      ..txExchangePending =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["tx_exchange_pending"] as String}"
      ..txExchangeFailed =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["tx_exchange_failed"] as String}"
      ..coinPlaceholder =
          "$applicationThemesDirectoryPath/$themeId/assets/${json["coin_placeholder"] as String}"
      ..coinIconsString = createCoinAssetsString(
        "$applicationThemesDirectoryPath/$themeId/assets",
        Map<String, dynamic>.from(json["coins"]["icons"] as Map),
      )
      ..coinImagesString = createCoinAssetsString(
        "$applicationThemesDirectoryPath/$themeId/assets",
        Map<String, dynamic>.from(json["coins"]["images"] as Map),
      )
      ..coinSecondaryImagesString = createCoinAssetsString(
        "$applicationThemesDirectoryPath/$themeId/assets",
        Map<String, dynamic>.from(json["coins"]["secondaries"] as Map),
      )
      ..loadingGif = json["loading_gif"] is String
          ? "$applicationThemesDirectoryPath/$themeId/assets/${json["loading_gif"] as String}"
          : null
      ..background = json["background"] is String
          ? "$applicationThemesDirectoryPath/$themeId/assets/${json["background"] as String}"
          : null;
  }

  static String createCoinAssetsString(String path, Map<String, dynamic> json) {
    final Map<String, dynamic> map = {};
    for (final entry in json.entries) {
      map[entry.key] = "$path/${entry.value as String}";
    }
    return jsonEncode(map);
  }

  static Map<Coin, String> parseCoinAssetsString(
    String jsonString, {
    required String placeHolder,
  }) {
    final json = jsonDecode(jsonString) as Map;
    final map = Map<String, dynamic>.from(json);

    final Map<Coin, String> result = {};

    for (final coin in Coin.values) {
      result[coin] = map[coin.name] as String? ?? placeHolder;
    }

    return result;
  }
}

abstract class IThemeAssets {
  String get bellNew;
  String get buy;
  String get exchange;
  String get personaIncognito;
  String get personaEasy;
  String get stack;
  String get stackIcon;
  String get receive;
  String get receivePending;
  String get receiveCancelled;
  String get send;
  String get sendPending;
  String get sendCancelled;
  String get themeSelector;
  String get themePreview;
  String get txExchange;
  String get txExchangePending;
  String get txExchangeFailed;

  String? get loadingGif;
  String? get background;
}
