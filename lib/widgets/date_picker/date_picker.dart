import 'package:flutter/material.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';

Future<DateTime?> showSWDatePicker(BuildContext context) async {
  final date = await showRoundedDatePicker(
    context: context,
    initialDate: DateTime.now(),
    height: MediaQuery.of(context).size.height / 3.0,
    theme: ThemeData(
      primarySwatch: Util.createMaterialColor(
          Theme.of(context).extension<StackColors>()!.accentColorDark),
    ),
    //TODO pick a better initial date
    // 2007 chosen as that is just before bitcoin launched
    firstDate: DateTime(2007),
    lastDate: DateTime.now(),
    borderRadius: Constants.size.circularBorderRadius * 2,

    textPositiveButton: "SELECT",

    styleDatePicker: _buildDatePickerStyle(context),
    styleYearPicker: _buildYearPickerStyle(context),
  );
  return date;
}

MaterialRoundedDatePickerStyle _buildDatePickerStyle(BuildContext context) {
  final baseColor = Theme.of(context).extension<StackColors>()!.textSubtitle2;
  return MaterialRoundedDatePickerStyle(
    backgroundPicker: Theme.of(context).extension<StackColors>()!.popupBG,
    paddingMonthHeader: const EdgeInsets.only(top: 11),
    colorArrowNext: Theme.of(context).extension<StackColors>()!.textSubtitle1,
    colorArrowPrevious:
        Theme.of(context).extension<StackColors>()!.textSubtitle1,
    textStyleButtonNegative: STextStyles.datePicker600(context).copyWith(
      color: baseColor,
    ),
    textStyleButtonPositive: STextStyles.datePicker600(context).copyWith(
      color: baseColor,
    ),
    textStyleCurrentDayOnCalendar: STextStyles.datePicker400(context),
    textStyleDayHeader: STextStyles.datePicker600(context),
    textStyleDayOnCalendar: STextStyles.datePicker400(context).copyWith(
      color: baseColor,
    ),
    textStyleDayOnCalendarDisabled: STextStyles.datePicker400(context).copyWith(
      color: Theme.of(context).extension<StackColors>()!.textSubtitle3,
    ),
    textStyleDayOnCalendarSelected: STextStyles.datePicker400(context).copyWith(
      color: Theme.of(context).extension<StackColors>()!.textWhite,
    ),
    textStyleMonthYearHeader: STextStyles.datePicker600(context).copyWith(
      color: Theme.of(context).extension<StackColors>()!.textSubtitle1,
    ),
    textStyleYearButton: STextStyles.datePicker600(context).copyWith(
      color: Theme.of(context).extension<StackColors>()!.textWhite,
    ),
    textStyleButtonAction: GoogleFonts.inter(),
  );
}

MaterialRoundedYearPickerStyle _buildYearPickerStyle(BuildContext context) {
  return MaterialRoundedYearPickerStyle(
    backgroundPicker: Theme.of(context).extension<StackColors>()!.popupBG,
    textStyleYear: STextStyles.datePicker600(context).copyWith(
      color: Theme.of(context).extension<StackColors>()!.textSubtitle2,
      fontSize: 16,
    ),
    textStyleYearSelected: STextStyles.datePicker600(context).copyWith(
      fontSize: 18,
    ),
  );
}
