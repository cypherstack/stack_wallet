import 'package:flutter/widgets.dart';

class DesktopAddressBookScaffold extends StatelessWidget {
  const DesktopAddressBookScaffold({
    Key? key,
    required this.controlsLeft,
    required this.controlsRight,
    required this.filterItems,
    required this.upperLabel,
    required this.lowerLabel,
    required this.favorites,
    required this.all,
    required this.details,
  }) : super(key: key);

  final Widget? controlsLeft;
  final Widget? controlsRight;
  final Widget? filterItems;
  final Widget? upperLabel;
  final Widget? lowerLabel;
  final Widget? favorites;
  final Widget? all;
  final Widget? details;

  static const double weirdRowHeight = 30;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              flex: 6,
              child: controlsLeft ?? Container(),
            ),
            const SizedBox(
              width: 20,
            ),
            Expanded(
              flex: 5,
              child: controlsRight ?? Container(),
            ),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          children: [
            Expanded(
              child: filterItems ?? Container(),
            ),
          ],
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      primary: false,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: weirdRowHeight,
                                child: upperLabel,
                              ),
                              favorites ?? Container(),
                              lowerLabel ?? Container(),
                              all ?? Container(),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    const SizedBox(
                      height: weirdRowHeight,
                    ),
                    Flexible(
                      child: details ?? Container(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
