import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../models/namecoin_dns/dns_record_type.dart';
import '../../../route_generator.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/constants.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../widgets/desktop/desktop_dialog.dart';
import '../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/stack_dialog.dart';
import 'add_dns_step_2.dart';

class AddDnsStep1 extends StatefulWidget {
  const AddDnsStep1({super.key, required this.name});

  final String name;

  @override
  State<AddDnsStep1> createState() => _AddDnsStep1State();
}

class _AddDnsStep1State extends State<AddDnsStep1> {
  DNSRecordType? _recordType;

  bool _nextLock = false;
  void _next() {
    if (_nextLock) return;
    _nextLock = true;
    try {
      if (mounted) {
        Navigator.of(context).push(
          RouteGenerator.getRoute(
            builder: (context) {
              return Util.isDesktop
                  ? DesktopDialog(
                      maxHeight: double.infinity,
                      maxWidth: 580,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 32,
                                ),
                                child: Text(
                                  "Add DNS record",
                                  style: STextStyles.desktopH3(
                                    context,
                                  ),
                                ),
                              ),
                              const DesktopDialogCloseButton(),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                            ),
                            child: AddDnsStep2(
                              recordType: _recordType!,
                              name: widget.name,
                            ),
                          ),
                        ],
                      ),
                    )
                  : StackDialogBase(
                      keyboardPaddingAmount:
                          MediaQuery.of(context).viewInsets.bottom,
                      child: AddDnsStep2(
                        recordType: _recordType!,
                        name: widget.name,
                      ),
                    );
            },
          ),
        );
      }
    } finally {
      _nextLock = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!Util.isDesktop)
          Text(
            "Add DNS record",
            style: STextStyles.pageTitleH2(context),
          ),
        SizedBox(
          height: Util.isDesktop ? 24 : 16,
        ),
        Text(
          "Choose a record type",
          style: Util.isDesktop
              ? STextStyles.w500_12(context).copyWith(
                  color: Theme.of(context).extension<StackColors>()!.textDark3,
                )
              : STextStyles.w500_14(context).copyWith(
                  color: Theme.of(context).extension<StackColors>()!.textDark3,
                ),
        ),
        SizedBox(
          height: Util.isDesktop ? 12 : 8,
        ),
        DropdownButtonHideUnderline(
          child: DropdownButton2<DNSRecordType>(
            hint: Text(
              "Choose a record type",
              style: STextStyles.fieldLabel(context),
            ),
            buttonStyleData: ButtonStyleData(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldDefaultBG,
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
              ),
            ),
            dropdownStyleData: DropdownStyleData(
              offset: const Offset(0, -10),
              elevation: 0,
              maxHeight: Util.isDesktop ? null : 200,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldDefaultBG,
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
              ),
            ),
            menuItemStyleData: const MenuItemStyleData(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
            ),
            isExpanded: true,
            value: _recordType,
            onChanged: (value) {
              if (value is DNSRecordType && _recordType != value) {
                setState(() {
                  _recordType = value;
                });
              }
            },
            iconStyleData: IconStyleData(
              icon: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: SvgPicture.asset(
                  Assets.svg.chevronDown,
                  width: 10,
                  height: 5,
                  color: Theme.of(context).extension<StackColors>()!.textDark3,
                ),
              ),
            ),
            items: [
              ...DNSRecordType.values.map(
                (e) => DropdownMenuItem<DNSRecordType>(
                  value: e,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      e.name,
                      style: STextStyles.desktopTextExtraExtraSmall(context)
                          .copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textDark,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_recordType != null)
          SizedBox(
            height: Util.isDesktop ? 10 : 6,
          ),
        if (_recordType != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _recordType!.info,
                    style: Util.isDesktop
                        ? STextStyles.w500_10(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .infoItemLabel,
                          )
                        : STextStyles.w500_8(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .infoItemLabel,
                          ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          height: Util.isDesktop ? 24 : 16,
        ),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: "Cancel",
                buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
              ),
            ),
            const SizedBox(
              width: 16,
            ),
            Expanded(
              child: PrimaryButton(
                label: "Next",
                enabled: _recordType != null,
                onPressed: _next,
                buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
              ),
            ),
          ],
        ),
        if (Util.isDesktop)
          const SizedBox(
            height: 32,
          ),
      ],
    );
  }
}
