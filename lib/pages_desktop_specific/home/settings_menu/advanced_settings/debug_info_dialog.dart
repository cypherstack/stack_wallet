import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/isar/models/log.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';

// import '../../../utilities/assets.dart';
// import '../../../utilities/util.dart';
// import '../../../widgets/icon_widgets/x_icon.dart';
// import '../../../widgets/stack_text_field.dart';
// import '../../../widgets/textfield_icon_button.dart';

class DebugInfoDialog extends StatefulWidget {
  const DebugInfoDialog({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DebugInfoDialog();
}

class _DebugInfoDialog extends State<DebugInfoDialog> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  final scrollController = ScrollController();

  String _searchTerm = "";

  List<Log> filtered(List<Log> unfiltered, String filter) {
    if (filter == "") {
      return unfiltered;
    }
    return unfiltered
        .where(
            (e) => (e.toString().toLowerCase().contains(filter.toLowerCase())))
        .toList();
  }

  BorderRadius? _borderRadius(int index, int listLength) {
    if (index == 0 && listLength == 1) {
      return BorderRadius.circular(
        Constants.size.circularBorderRadius,
      );
    } else if (index == 0) {
      return BorderRadius.vertical(
        bottom: Radius.circular(
          Constants.size.circularBorderRadius,
        ),
      );
    } else if (index == listLength - 1) {
      return BorderRadius.vertical(
        top: Radius.circular(
          Constants.size.circularBorderRadius,
        ),
      );
    }
    return null;
  }

  @override
  void initState() {
    // ref.read(debugServiceProvider).updateRecentLogs();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    scrollController.dispose();
    _searchFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      maxHeight: 800,
      maxWidth: 600,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  "Debug info",
                  style: STextStyles.desktopH3(context),
                  textAlign: TextAlign.center,
                ),
              ),
              const DesktopDialogCloseButton(),
            ],
          ),
          Row(
            children: [
              // ClipRRect(
              //   borderRadius: BorderRadius.circular(
              //     Constants.size.circularBorderRadius,
              //   ),
              //   child: TextField(
              //     key: const Key("desktopSettingDebugInfo"),
              //     autocorrect: Util.isDesktop ? false : true,
              //     enableSuggestions: Util.isDesktop ? false : true,
              //     controller: _searchController,
              //     focusNode: _searchFocusNode,
              //     // onChanged: (newString) {
              //     //   setState(() => _searchTerm = newString);
              //     // },
              //     style: STextStyles.field(context),
              //     decoration: standardInputDecoration(
              //       "Search",
              //       _searchFocusNode,
              //       context,
              //     ).copyWith(
              //       prefixIcon: Padding(
              //         padding: const EdgeInsets.symmetric(
              //           horizontal: 10,
              //           vertical: 16,
              //         ),
              //         child: SvgPicture.asset(
              //           Assets.svg.search,
              //           width: 16,
              //           height: 16,
              //         ),
              //       ),
              //       suffixIcon: _searchController.text.isNotEmpty
              //           ? Padding(
              //               padding: const EdgeInsets.only(right: 0),
              //               child: UnconstrainedBox(
              //                 child: Row(
              //                   children: [
              //                     TextFieldIconButton(
              //                       child: const XIcon(),
              //                       onTap: () async {
              //                         setState(() {
              //                           _searchController.text = "";
              //                           _searchTerm = "";
              //                         });
              //                       },
              //                     ),
              //                   ],
              //                 ),
              //               ),
              //             )
              //           : null,
              //     ),
              //   ),
              // ),
            ],
          ),
          // Column(
          //   children: [
          //
          //   ],
          // ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: "Clear logs",
                    onPressed: () {},
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: PrimaryButton(
                    label: "Save logs to file",
                    onPressed: () {},
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
