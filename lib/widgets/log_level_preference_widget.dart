import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../providers/global/prefs_provider.dart';
import '../themes/stack_colors.dart';
import '../utilities/extensions/extensions.dart';
import '../utilities/text_styles.dart';
import '../utilities/util.dart';
import 'rounded_container.dart';

class LogLevelPreferenceWidget extends ConsumerStatefulWidget {
  const LogLevelPreferenceWidget({super.key});

  @override
  ConsumerState<LogLevelPreferenceWidget> createState() =>
      _LogLevelPreferenceWidgetState();
}

class _LogLevelPreferenceWidgetState
    extends ConsumerState<LogLevelPreferenceWidget> {
  double _sliderValue = 0;
  static const List<Level> _levels = [
    Level.off,
    Level.fatal,
    Level.error,
    Level.warning,
    Level.info,
    Level.debug,
    Level.trace,
  ];

  @override
  void initState() {
    super.initState();
    _sliderValue = _levels
        .indexOf(ref.read(prefsChangeNotifierProvider).logLevel)
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final current =
        ref.watch(prefsChangeNotifierProvider.select((s) => s.logLevel));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Current level: ${current.name.capitalize()}",
          style: Util.isDesktop
              ? STextStyles.desktopTextFieldLabel(context)
              : STextStyles.fieldLabel(context),
          textAlign: TextAlign.left,
        ),
        Slider(
          min: 0,
          max: _levels.length - 1,
          divisions: _levels.length - 1,
          value: _sliderValue,
          onChanged: (value) {
            // setState(() {
            _sliderValue = value;
            // });
            ref.read(prefsChangeNotifierProvider).logLevel =
                _levels[_sliderValue.toInt()];
          },
        ),
        if (current == Level.debug ||
            current == Level.trace ||
            current == Level.info)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: RoundedContainer(
              color:
                  Theme.of(context).extension<StackColors>()!.warningBackground,
              child: SelectableText.rich(
                TextSpan(
                  text: "Privacy Warning: ",
                  style: STextStyles.label700(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .warningForeground,
                    fontSize: Util.isDesktop ? 14 : 12,
                  ),
                  children: [
                    TextSpan(
                      text: "Selecting ",
                      style: STextStyles.label(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .warningForeground,
                        fontSize: Util.isDesktop ? 14 : 12,
                      ),
                    ),
                    TextSpan(
                      text: "Trace",
                      style: STextStyles.label700(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .warningForeground,
                        fontSize: Util.isDesktop ? 14 : 12,
                      ),
                    ),
                    TextSpan(
                      text: " or ",
                      style: STextStyles.label(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .warningForeground,
                        fontSize: Util.isDesktop ? 14 : 12,
                      ),
                    ),
                    TextSpan(
                      text: "Debug",
                      style: STextStyles.label700(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .warningForeground,
                        fontSize: Util.isDesktop ? 14 : 12,
                      ),
                    ),
                    TextSpan(
                      text: " may log sensitive metadata, such as transaction"
                          " details, amounts, addresses, or network activity. While ",
                      style: STextStyles.label(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .warningForeground,
                        fontSize: Util.isDesktop ? 14 : 12,
                      ),
                    ),
                    TextSpan(
                      text: "Info",
                      style: STextStyles.label700(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .warningForeground,
                        fontSize: Util.isDesktop ? 14 : 12,
                      ),
                    ),
                    TextSpan(
                      text: " logs are less likely to contain sensitive data, "
                          "they may still include some. No private keys, "
                          "mnemonics, or credentials will ever be logged, but "
                          "enabling these levels could expose information that "
                          "might compromise privacy if accessed by unauthorized parties.",
                      style: STextStyles.label(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .warningForeground,
                        fontSize: Util.isDesktop ? 14 : 12,
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
