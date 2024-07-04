import 'dart:async';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../models/keys/cw_key_data.dart';
import '../../../../notifications/show_flush_bar.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/assets.dart';
import '../../../../utilities/clipboard_interface.dart';
import '../../../../utilities/constants.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../utilities/util.dart';
import '../../../../widgets/desktop/primary_button.dart';
import '../../../../widgets/detail_item.dart';
import '../../../../widgets/qr.dart';
import '../../../../widgets/rounded_white_container.dart';

class CNWalletKeys extends StatefulWidget {
  const CNWalletKeys({
    super.key,
    required this.cwKeyData,
    required this.walletId,
    this.clipboardInterface = const ClipboardWrapper(),
  });

  final CWKeyData cwKeyData;
  final String walletId;
  final ClipboardInterface clipboardInterface;

  @override
  State<CNWalletKeys> createState() => _CNWalletKeysState();
}

class _CNWalletKeysState extends State<CNWalletKeys> {
  late String _currentDropDownValue;

  String _current(String key) =>
      widget.cwKeyData.keys.firstWhere((e) => e.label == key).key;

  Future<void> _copy() async {
    await widget.clipboardInterface.setData(
      ClipboardData(text: _current(_currentDropDownValue)),
    );
    if (mounted) {
      unawaited(
        showFloatingFlushBar(
          type: FlushBarType.info,
          message: "Copied to clipboard",
          iconAsset: Assets.svg.copy,
          context: context,
        ),
      );
    }
  }

  @override
  void initState() {
    _currentDropDownValue = widget.cwKeyData.keys.first.label;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Util.isDesktop
          ? const EdgeInsets.symmetric(horizontal: 20)
          : EdgeInsets.zero,
      child: Column(
        mainAxisSize: Util.isDesktop ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: Util.isDesktop ? 12 : 16,
          ),
          DetailItemBase(
            horizontal: true,
            borderColor: Util.isDesktop
                ? Theme.of(context).extension<StackColors>()!.textFieldDefaultBG
                : null,
            title: Text(
              "Selected key",
              style: STextStyles.itemSubtitle(context),
            ),
            detail: SizedBox(
              width: Util.isDesktop ? 200 : 170,
              child: DropdownButtonHideUnderline(
                child: DropdownButton2<String>(
                  value: _currentDropDownValue,
                  items: [
                    ...widget.cwKeyData.keys.map(
                      (e) => DropdownMenuItem(
                        value: e.label,
                        child: Text(
                          e.label,
                          style: STextStyles.w500_14(context),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value is String) {
                      setState(() {
                        _currentDropDownValue = value;
                      });
                    }
                  },
                  isExpanded: true,
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
                  iconStyleData: IconStyleData(
                    icon: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: SvgPicture.asset(
                        Assets.svg.chevronDown,
                        width: 12,
                        height: 6,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textFieldActiveSearchIconRight,
                      ),
                    ),
                  ),
                  dropdownStyleData: DropdownStyleData(
                    offset: const Offset(0, -10),
                    elevation: 0,
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
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: Util.isDesktop ? 12 : 16,
          ),
          QR(
            data: _current(_currentDropDownValue),
            size:
                Util.isDesktop ? 256 : MediaQuery.of(context).size.width / 1.5,
          ),
          SizedBox(
            height: Util.isDesktop ? 12 : 16,
          ),
          RoundedWhiteContainer(
            borderColor: Util.isDesktop
                ? Theme.of(context).extension<StackColors>()!.textFieldDefaultBG
                : null,
            child: SelectableText(
              _current(_currentDropDownValue),
              style: STextStyles.w500_14(context),
            ),
          ),
          SizedBox(
            height: Util.isDesktop ? 12 : 16,
          ),
          if (!Util.isDesktop) const Spacer(),
          Row(
            children: [
              if (Util.isDesktop) const Spacer(),
              if (Util.isDesktop)
                const SizedBox(
                  width: 16,
                ),
              Expanded(
                child: PrimaryButton(
                  label: "Copy",
                  onPressed: _copy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
