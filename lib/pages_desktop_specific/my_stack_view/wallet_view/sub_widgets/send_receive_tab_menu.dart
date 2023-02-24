import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

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
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _onChanged(0),
              child: Container(
                color: Colors.transparent,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 16,
                    ),
                    AnimatedCrossFade(
                      firstChild: Text(
                        "Send",
                        style:
                            STextStyles.desktopTextExtraSmall(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .accentColorBlue,
                        ),
                      ),
                      secondChild: Text(
                        "Send",
                        style:
                            STextStyles.desktopTextExtraSmall(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textSubtitle1,
                        ),
                      ),
                      crossFadeState: _selectedIndex == 0
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 250),
                    ),
                    const SizedBox(
                      height: 19,
                    ),
                    Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .backgroundAppBar,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _onChanged(1),
              child: Container(
                color: Colors.transparent,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 16,
                    ),
                    AnimatedCrossFade(
                      firstChild: Text(
                        "Receive",
                        style:
                            STextStyles.desktopTextExtraSmall(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .accentColorBlue,
                        ),
                      ),
                      secondChild: Text(
                        "Receive",
                        style:
                            STextStyles.desktopTextExtraSmall(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textSubtitle1,
                        ),
                      ),
                      crossFadeState: _selectedIndex == 1
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 250),
                    ),
                    const SizedBox(
                      height: 19,
                    ),
                    Stack(
                      children: [
                        Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .backgroundAppBar,
                          ),
                        ),
                        AnimatedSlide(
                          offset: Offset(_selectedIndex == 0 ? -1 : 0, 0),
                          duration: const Duration(milliseconds: 250),
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .accentColorBlue),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
