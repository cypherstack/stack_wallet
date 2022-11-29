import 'package:flutter/material.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';

class SendReceiveTabMenu extends StatefulWidget {
  const SendReceiveTabMenu({
    Key? key,
    this.initialIndex = 0,
    this.onChanged,
  }) : super(key: key);

  final int initialIndex;
  final void Function(int)? onChanged;

  @override
  State<SendReceiveTabMenu> createState() => _SendReceiveTabMenuState();
}

class _SendReceiveTabMenuState extends State<SendReceiveTabMenu> {
  late int _selectedIndex;

  void _onChanged(int newIndex) {
    if (_selectedIndex != newIndex) {
      setState(() {
        _selectedIndex = newIndex;
      });
      widget.onChanged?.call(_selectedIndex);
    }
  }

  @override
  void initState() {
    _selectedIndex = widget.initialIndex;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _onChanged(0),
            child: Container(
              color: Colors.transparent,
              child: Column(
                children: [
                  const SizedBox(
                    height: 16,
                  ),
                  Text(
                    "Send",
                    style: STextStyles.desktopTextExtraSmall(context).copyWith(
                      color: _selectedIndex == 0
                          ? Theme.of(context)
                              .extension<StackColors>()!
                              .accentColorBlue
                          : Theme.of(context)
                              .extension<StackColors>()!
                              .textSubtitle1,
                    ),
                  ),
                  const SizedBox(
                    height: 19,
                  ),
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: _selectedIndex == 0
                          ? Theme.of(context)
                              .extension<StackColors>()!
                              .accentColorBlue
                          : Theme.of(context)
                              .extension<StackColors>()!
                              .background,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _onChanged(1),
            child: Container(
              color: Colors.transparent,
              child: Column(
                children: [
                  const SizedBox(
                    height: 16,
                  ),
                  Text(
                    "Receive",
                    style: STextStyles.desktopTextExtraSmall(context).copyWith(
                      color: _selectedIndex == 1
                          ? Theme.of(context)
                              .extension<StackColors>()!
                              .accentColorBlue
                          : Theme.of(context)
                              .extension<StackColors>()!
                              .textSubtitle1,
                    ),
                  ),
                  const SizedBox(
                    height: 19,
                  ),
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: _selectedIndex == 1
                          ? Theme.of(context)
                              .extension<StackColors>()!
                              .accentColorBlue
                          : Theme.of(context)
                              .extension<StackColors>()!
                              .background,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
