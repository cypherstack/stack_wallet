import 'package:epicpay/utilities/assets.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/utilities/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class RestoreFromDatePicker extends StatefulWidget {
  const RestoreFromDatePicker({
    Key? key,
    required this.onTap,
    required this.controller,
  }) : super(key: key);

  final VoidCallback onTap;
  final TextEditingController controller;

  @override
  State<RestoreFromDatePicker> createState() => _RestoreFromDatePickerState();
}

class _RestoreFromDatePickerState extends State<RestoreFromDatePicker> {
  late final TextEditingController _dateController;
  late final VoidCallback onTap;

  @override
  void initState() {
    onTap = widget.onTap;
    _dateController = widget.controller;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: TextField(
        autocorrect: Util.isDesktop ? false : true,
        enableSuggestions: Util.isDesktop ? false : true,
        onTap: onTap,
        controller: _dateController,
        style: STextStyles.field(context),
        decoration: InputDecoration(
          hintText: "Restore from...",
          hintStyle: STextStyles.body(context).copyWith(
            color: Theme.of(context).extension<StackColors>()!.textDark,
          ),
          suffixIcon: UnconstrainedBox(
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                ),
                SvgPicture.asset(
                  Assets.svg.calendar,
                  color: Theme.of(context).extension<StackColors>()!.textDark,
                  width: 16,
                  height: 16,
                ),
                const SizedBox(
                  width: 12,
                ),
              ],
            ),
          ),
        ),
        key: const Key("restoreOptionsViewDatePickerKey"),
        readOnly: true,
        toolbarOptions: const ToolbarOptions(
          copy: true,
          cut: false,
          paste: false,
          selectAll: false,
        ),
        onChanged: (newValue) {},
      ),
    );
  }
}
