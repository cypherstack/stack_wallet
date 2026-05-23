import 'dart:math';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/constants.dart';
import '../../utilities/format.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../conditional_parent.dart';
import '../desktop/primary_button.dart';
import '../desktop/secondary_button.dart';

part 'sw_date_picker.dart';

/// [value] holds selected dates. One if [range] is false. Start and end dates
/// otherwise.
Future<List<DateTime?>?> showSWDatePicker(
  BuildContext context, {
  DateTime? firstDate,
  DateTime? lastDate,
  List<DateTime?> value = const [],
  bool range = false,
}) async {
  final Size size;
  if (Util.isDesktop) {
    size = const Size(450, 450);
  } else {
    final _size = MediaQuery.of(context).size;
    size = Size(
      _size.width - 32,
      _size.height >= 550 ? 450 : _size.height - 32,
    );
  }

  final now = DateTime.now();

  final dates = await _showDatePickerDialog(
    context: context,
    value: value,
    dialogSize: size,
    config: CalendarDatePicker2WithActionButtonsConfig(
      firstDate: firstDate ?? DateTime(2007),
      lastDate: lastDate ?? now,
      currentDate: now,
      rangeBidirectional: range ? false : null,
      calendarType: range ? .range : null,
      buttonPadding: const EdgeInsets.only(right: 16),
      centerAlignModePicker: true,
      selectedDayHighlightColor: Theme.of(
        context,
      ).extension<StackColors>()!.accentColorDark,
      daySplashColor: Theme.of(
        context,
      ).extension<StackColors>()!.accentColorDark.withOpacity(0.6),
    ),
  );

  return dates;
}

Future<List<DateTime?>?> _showDatePickerDialog({
  required BuildContext context,
  required CalendarDatePicker2WithActionButtonsConfig config,
  required Size dialogSize,
  List<DateTime?> value = const [],
  bool useRootNavigator = true,
  bool barrierDismissible = true,
  Color? barrierColor = Colors.black54,
  bool useSafeArea = true,
  RouteSettings? routeSettings,
  String? barrierLabel,
  TransitionBuilder? builder,
}) {
  final dialog = Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    backgroundColor: Theme.of(context).extension<StackColors>()!.popupBG,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(
        Constants.size.circularBorderRadius * 2,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: SizedBox(
      width: dialogSize.width,
      height: max(dialogSize.height, 410),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SWDatePicker(
            value: value,
            config: config.copyWith(openedFromDialog: true),
          ),
        ],
      ),
    ),
  );

  return showDialog<List<DateTime?>>(
    context: context,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    builder: (BuildContext context) {
      return builder == null ? dialog : builder(context, dialog);
    },
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    useSafeArea: useSafeArea,
  );
}

class StackDateRangePicker extends StatelessWidget {
  const StackDateRangePicker({
    super.key,
    required this.fromDate,
    required this.toDate,
    this.firstDate,
    this.lastDate,
    required this.onChanged,
  });

  final DateTime? fromDate;
  final DateTime? toDate;
  final DateTime? firstDate, lastDate;
  final void Function(DateTime? from, DateTime? to) onChanged;

  @override
  Widget build(BuildContext context) {
    const middleSeparatorPadding = 2.0;
    const middleSeparatorWidth = 12.0;
    final isDesktop = Util.isDesktop;

    final String fromDateString = switch (fromDate) {
      null => "",
      final d => Format.formatDate(d),
    };
    final String toDateString = switch (toDate) {
      null => "",
      final d => Format.formatDate(d),
    };

    return Row(
      children: [
        Expanded(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              key: const Key("transactionSearchViewFromDatePickerKey"),
              onTap: () async {
                // check and hide keyboard
                if (FocusScope.of(context).hasFocus) {
                  FocusScope.of(context).unfocus();
                  await Future<void>.delayed(const Duration(milliseconds: 125));
                }

                if (context.mounted) {
                  final date = (await showSWDatePicker(
                    context,
                    firstDate: firstDate,
                    lastDate: lastDate,
                  ))?.first;
                  if (date != null) {
                    final newFrom = date;
                    DateTime? newTo = toDate;

                    // flag to adjust date so from date is always before to date
                    if (newTo != null && !newFrom.isBefore(newTo)) {
                      newTo = DateTime.fromMillisecondsSinceEpoch(
                        newFrom.millisecondsSinceEpoch,
                      );
                    }

                    onChanged(newFrom, newTo);
                  }
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).extension<StackColors>()!.textFieldDefaultBG,
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.textFieldDefaultBG,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: isDesktop ? 17 : 12,
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        Assets.svg.calendar,
                        height: 20,
                        width: 20,
                        color: Theme.of(
                          context,
                        ).extension<StackColors>()!.textSubtitle2,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          fromDateString.isEmpty ? "From..." : fromDateString,
                          style: STextStyles.fieldLabel(context).copyWith(
                            color: fromDateString.isEmpty
                                ? Theme.of(
                                    context,
                                  ).extension<StackColors>()!.textSubtitle2
                                : Theme.of(
                                    context,
                                  ).extension<StackColors>()!.accentColorDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: middleSeparatorPadding,
          ),
          child: Container(
            width: middleSeparatorWidth,
            // height: 1,
            // color: CFColors.smoke,
          ),
        ),
        Expanded(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              key: const Key("transactionSearchViewToDatePickerKey"),
              onTap: () async {
                // check and hide keyboard
                if (FocusScope.of(context).hasFocus) {
                  FocusScope.of(context).unfocus();
                  await Future<void>.delayed(const Duration(milliseconds: 125));
                }

                if (context.mounted) {
                  final date = (await showSWDatePicker(
                    context,
                    firstDate: firstDate,
                    lastDate: lastDate,
                  ))?.first;
                  if (date != null) {
                    final newTo = date;
                    DateTime? newFrom = fromDate;

                    // flag to adjust date so from date is always before to date
                    if (newFrom != null && !newTo.isAfter(newFrom)) {
                      newFrom = DateTime.fromMillisecondsSinceEpoch(
                        newTo.millisecondsSinceEpoch,
                      );
                    }

                    onChanged(newFrom, newTo);
                  }
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).extension<StackColors>()!.textFieldDefaultBG,
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.textFieldDefaultBG,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: isDesktop ? 17 : 12,
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        Assets.svg.calendar,
                        height: 20,
                        width: 20,
                        color: Theme.of(
                          context,
                        ).extension<StackColors>()!.textSubtitle2,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          toDateString.isEmpty ? "To..." : toDateString,
                          style: STextStyles.fieldLabel(context).copyWith(
                            color: toDateString.isEmpty
                                ? Theme.of(
                                    context,
                                  ).extension<StackColors>()!.textSubtitle2
                                : Theme.of(
                                    context,
                                  ).extension<StackColors>()!.accentColorDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
