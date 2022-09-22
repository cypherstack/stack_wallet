import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';

class RestoreFromDatePicker extends StatefulWidget {
  const RestoreFromDatePicker({Key? key, required this.onTap})
      : super(key: key);

  final VoidCallback onTap;

  @override
  State<RestoreFromDatePicker> createState() => _RestoreFromDatePickerState();
}

class _RestoreFromDatePickerState extends State<RestoreFromDatePicker> {
  late final TextEditingController _dateController;
  late final VoidCallback onTap;

  @override
  void initState() {
    onTap = widget.onTap;
    _dateController = TextEditingController();

    super.initState();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: TextField(
        onTap: onTap,
        controller: _dateController,
        style: STextStyles.field(context),
        decoration: InputDecoration(
          hintText: "Restore from...",
          suffixIcon: UnconstrainedBox(
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                ),
                SvgPicture.asset(
                  Assets.svg.calendar,
                  color: StackTheme.instance.color.textDark3,
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
