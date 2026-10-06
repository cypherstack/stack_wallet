import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utilities/constants.dart';
import '../utilities/util.dart';
import 'stack_colors.dart';

ThemeData stackThemeData(StackColors colors) {
  InputBorder outlineInputBorder() => OutlineInputBorder(
    borderSide: BorderSide(width: 1, color: colors.textFieldDefaultBG),
    borderRadius: BorderRadius.circular(Constants.size.circularBorderRadius),
  );

  return ThemeData(
    extensions: [colors],
    highlightColor: colors.highlight,
    brightness: colors.brightness,
    fontFamily: GoogleFonts.inter().fontFamily,
    unselectedWidgetColor: colors.radioButtonBorderDisabled,
    radioTheme: const RadioThemeData(
      splashRadius: 0,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    splashColor: Colors.transparent,
    buttonTheme: ButtonThemeData(splashColor: colors.splash),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        overlayColor: MaterialStateProperty.all(colors.splash),
        minimumSize: MaterialStateProperty.all<Size>(const Size(46, 46)),
        foregroundColor: MaterialStateProperty.all(colors.buttonTextSecondary),
        backgroundColor: MaterialStateProperty.all<Color>(
          colors.buttonBackSecondary,
        ),
        shape: MaterialStateProperty.all<OutlinedBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(1000)),
        ),
      ),
    ),
    primaryColor: colors.accentColorDark,
    primarySwatch: Util.createMaterialColor(colors.accentColorDark),
    checkboxTheme: CheckboxThemeData(
      splashRadius: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          Constants.size.checkboxBorderRadius,
        ),
      ),
      checkColor: MaterialStateColor.resolveWith((state) {
        if (state.contains(MaterialState.selected)) {
          return colors.checkboxIconChecked;
        }
        return colors.checkboxBGChecked;
      }),
      fillColor: MaterialStateColor.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return colors.checkboxBGChecked;
        }
        return colors.checkboxBorderEmpty;
      }),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      color: colors.background,
      surfaceTintColor: colors.background,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      focusColor: colors.textFieldDefaultBG,
      fillColor: colors.textFieldDefaultBG,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      enabledBorder: outlineInputBorder(),
      focusedBorder: outlineInputBorder(),
      errorBorder: outlineInputBorder(),
      disabledBorder: outlineInputBorder(),
      focusedErrorBorder: outlineInputBorder(),
    ),
  );
}
