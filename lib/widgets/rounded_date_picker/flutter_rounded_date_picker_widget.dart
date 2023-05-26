// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
// import 'package:flutter_rounded_date_picker/src/dialogs/flutter_rounded_date_picker_dialog.dart';
import 'package:flutter_rounded_date_picker/src/era_mode.dart';
import 'package:flutter_rounded_date_picker/src/material_rounded_date_picker_style.dart';
import 'package:flutter_rounded_date_picker/src/material_rounded_year_picker_style.dart';
import 'package:flutter_rounded_date_picker/src/widgets/flutter_rounded_day_picker.dart';
import 'package:stackwallet/widgets/rounded_date_picker/flutter_rounded_date_picker_dialog.dart';

///
/// This file uses code taken from https://github.com/benznest/flutter_rounded_date_picker
///

// Examples can assume:
// BuildContext context;

/// Initial display mode of the date picker dialog.
///
/// Date picker UI mode for either showing a list of available years or a
/// monthly calendar initially in the dialog shown by calling [showDatePicker].
///

// Shows the selected date in large font and toggles between year and day mode

/// Signature for predicating dates for enabled date selections.
///
/// See [showDatePicker].
typedef SelectableDayPredicate = bool Function(DateTime day);

/// Shows a dialog containing a material design date picker.
///
/// The returned [Future] resolves to the date selected by the user when the
/// user closes the dialog. If the user cancels the dialog, null is returned.
///
/// An optional [selectableDayPredicate] function can be passed in to customize
/// the days to enable for selection. If provided, only the days that
/// [selectableDayPredicate] returned true for will be selectable.
///
/// An optional [initialDatePickerMode] argument can be used to display the
/// date picker initially in the year or month+day picker mode. It defaults
/// to month+day, and must not be null.
///
/// An optional [locale] argument can be used to set the locale for the date
/// picker. It defaults to the ambient locale provided by [Localizations].
///
/// An optional [textDirection] argument can be used to set the text direction
/// (RTL or LTR) for the date picker. It defaults to the ambient text direction
/// provided by [Directionality]. If both [locale] and [textDirection] are not
/// null, [textDirection] overrides the direction chosen for the [locale].
///
/// The [context] argument is passed to [showDialog], the documentation for
/// which discusses how it is used.
///
/// The [builder] parameter can be used to wrap the dialog widget
/// to add inherited widgets like [Theme].
///
/// {@tool sample}
/// Show a date picker with the dark theme.
///
/// ```dart
/// Future<DateTime> selectedDate = showDatePicker(
///   context: context,
///   initialDate: DateTime.now(),
///   firstDate: DateTime(2018),
///   lastDate: DateTime(2030),
///   builder: (BuildContext context, Widget child) {
///     return Theme(
///       data: ThemeData.dark(),
///       child: child,
///     );
///   },
/// );
/// ```
/// {@end-tool}
///
/// The [context], [initialDate], [firstDate], and [lastDate] parameters must
/// not be null.
///
/// See also:
///
///  * [showTimePicker], which shows a dialog that contains a material design
///    time picker.
///  * [DayPicker], which displays the days of a given month and allows
///    choosing a day.
///  * [MonthPicker], which displays a scrollable list of months to allow
///    picking a month.
///  * [YearPicker], which displays a scrollable list of years to allow picking
///    a year.
///

Future<DateTime?> showRoundedDatePicker(
    {required BuildContext context,
    double? height,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    SelectableDayPredicate? selectableDayPredicate,
    DatePickerMode initialDatePickerMode = DatePickerMode.day,
    Locale? locale,
    TextDirection? textDirection,
    ThemeData? theme,
    double borderRadius = 16,
    EraMode era = EraMode.CHRIST_YEAR,
    ImageProvider? imageHeader,
    String description = "",
    String? fontFamily,
    bool barrierDismissible = false,
    Color background = Colors.transparent,
    String? textNegativeButton,
    String? textPositiveButton,
    String? textActionButton,
    VoidCallback? onTapActionButton,
    MaterialRoundedDatePickerStyle? styleDatePicker,
    MaterialRoundedYearPickerStyle? styleYearPicker,
    List<String>? customWeekDays,
    BuilderDayOfDatePicker? builderDay,
    List<DateTime>? listDateDisabled,
    OnTapDay? onTapDay,
    Function? onMonthChange}) async {
  initialDate ??= DateTime.now();
  firstDate ??= DateTime(initialDate.year - 1);
  lastDate ??= DateTime(initialDate.year + 1);
  theme ??= ThemeData();

  assert(
    !initialDate.isBefore(firstDate),
    'initialDate must be on or after firstDate',
  );
  assert(
    !initialDate.isAfter(lastDate),
    'initialDate must be on or before lastDate',
  );
  assert(
    !firstDate.isAfter(lastDate),
    'lastDate must be on or after firstDate',
  );
  assert(
    selectableDayPredicate == null || selectableDayPredicate(initialDate),
    'Provided initialDate must satisfy provided selectableDayPredicate',
  );
  assert(
    (onTapActionButton != null && textActionButton != null) ||
        onTapActionButton == null,
    "If you provide onLeftBtn, you must provide leftBtn",
  );
  assert(debugCheckHasMaterialLocalizations(context));

  Widget child = GestureDetector(
    onTap: () {
      if (!barrierDismissible) {
        Navigator.pop(context);
      }
    },
    child: Container(
      color: background,
      child: GestureDetector(
        onTap: () {
          //
        },
        child: FlutterRoundedDatePickerDialog(
          height: height,
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
          selectableDayPredicate: selectableDayPredicate,
          initialDatePickerMode: initialDatePickerMode,
          era: era,
          locale: locale,
          borderRadius: borderRadius,
          imageHeader: imageHeader,
          description: description,
          fontFamily: fontFamily,
          textNegativeButton: textNegativeButton,
          textPositiveButton: textPositiveButton,
          textActionButton: textActionButton,
          onTapActionButton: onTapActionButton,
          styleDatePicker: styleDatePicker,
          styleYearPicker: styleYearPicker,
          customWeekDays: customWeekDays,
          builderDay: builderDay,
          listDateDisabled: listDateDisabled,
          onTapDay: onTapDay,
          onMonthChange: onMonthChange,
        ),
      ),
    ),
  );

  if (textDirection != null) {
    child = Directionality(
      textDirection: textDirection,
      child: child,
    );
  }

  if (locale != null) {
    child = Localizations.override(
      context: context,
      locale: locale,
      child: child,
    );
  }

  return await showDialog<DateTime>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (_) => Theme(data: theme!, child: child),
  );
}
