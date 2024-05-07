import 'dart:math';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';

part 'sw_date_picker.dart';

Future<DateTime?> showSWDatePicker(BuildContext context) async {
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
  print("=====================================");
  print(size);

  final now = DateTime.now();

  final date = await _showDatePickerDialog(
    context: context,
    value: [now],
    dialogSize: size,
    config: CalendarDatePicker2WithActionButtonsConfig(
      firstDate: DateTime(2007),
      lastDate: now,
      currentDate: now,
      buttonPadding: const EdgeInsets.only(
        right: 16,
      ),
      centerAlignModePicker: true,
      selectedDayHighlightColor:
          Theme.of(context).extension<StackColors>()!.accentColorDark,
      daySplashColor: Theme.of(context)
          .extension<StackColors>()!
          .accentColorDark
          .withOpacity(0.6),
    ),
  );
  return date?.first;
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
    insetPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
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
