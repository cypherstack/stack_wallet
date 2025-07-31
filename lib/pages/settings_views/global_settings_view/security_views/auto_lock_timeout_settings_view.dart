import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/providers.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/constants.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../utilities/util.dart';
import '../../../../widgets/background.dart';
import '../../../../widgets/conditional_parent.dart';
import '../../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../../widgets/custom_buttons/draggable_switch_button.dart';
import '../../../../widgets/desktop/primary_button.dart';
import '../../../../widgets/rounded_white_container.dart';

class AutoLockTimeoutSettingsView extends ConsumerStatefulWidget {
  const AutoLockTimeoutSettingsView({super.key});

  static const routeName = "/autoLockTimeoutSettingsView";

  @override
  ConsumerState<AutoLockTimeoutSettingsView> createState() =>
      _AutoLockTimeoutSettingsViewState();
}

class _AutoLockTimeoutSettingsViewState
    extends ConsumerState<AutoLockTimeoutSettingsView> {
  final isDesktop = Util.isDesktop;
  final TextEditingController _timeController = TextEditingController();
  late bool _enabled;
  bool _lock = false;

  Future<void> _save() async {
    if (_lock) return;
    _lock = true;

    try {
      final minutes = int.tryParse(_timeController.text);

      if (minutes == null) {
        // this should not hit unless logic in validating text field input is
        // wrong
        return;
      }

      ref.read(prefsChangeNotifierProvider).autoLockInfo = (
        enabled: _enabled,
        minutes: minutes,
      );

      Navigator.of(context, rootNavigator: isDesktop).pop();
    } finally {
      _lock = false;
    }
  }

  int _minutesCache = 1;

  int _clampMinutes(int input) {
    if (input > 60) return 60;
    if (input < 1) return 1;
    return input;
  }

  @override
  void initState() {
    super.initState();
    _enabled = ref.read(prefsChangeNotifierProvider).autoLockInfo.enabled;
    _minutesCache = _clampMinutes(
      ref.read(prefsChangeNotifierProvider).autoLockInfo.minutes,
    );
    _timeController.text = _minutesCache.toString();
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: !isDesktop,
      builder:
          (child) => Background(
            child: Scaffold(
              backgroundColor:
                  Theme.of(context).extension<StackColors>()!.background,
              appBar: AppBar(
                leading: AppBarBackButton(
                  onPressed: () async {
                    if (FocusScope.of(context).hasFocus) {
                      FocusScope.of(context).unfocus();
                      await Future<void>.delayed(
                        const Duration(milliseconds: 70),
                      );
                    }
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RoundedWhiteContainer(
            child: RawMaterialButton(
              splashColor:
                  Theme.of(context).extension<StackColors>()!.highlight,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
              ),
              onPressed: null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Toggle auto lock",
                      style: STextStyles.titleBold12(context),
                      textAlign: TextAlign.left,
                    ),
                    SizedBox(
                      height: 20,
                      width: 40,
                      child: DraggableSwitchButton(
                        isOn: _enabled,
                        onValueChanged: (newValue) {
                          _enabled = newValue;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: isDesktop ? 24 : 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text("Minutes", style: STextStyles.titleBold12(context)),
                const SizedBox(width: 16),
                Flexible(
                  child: TextField(
                    controller: _timeController,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: STextStyles.field(context),
                    inputFormatters: [
                      TextInputFormatter.withFunction(
                        (oldValue, newValue) =>
                            RegExp(r'^([0-9]*)$').hasMatch(newValue.text)
                                ? newValue
                                : oldValue,
                      ),
                    ],
                    onChanged: (value) {
                      final number = int.tryParse(value);
                      if (number == null || number < 1 || number > 60) {
                        _timeController.text = _minutesCache.toString();
                        return;
                      }

                      _minutesCache = _clampMinutes(number);
                    },
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: false,
                      decimal: false,
                    ),
                    decoration: InputDecoration(
                      hintText: "Minutes",
                      hintStyle: STextStyles.fieldLabel(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isDesktop ? 40 : 16),
          if (!isDesktop) const Spacer(),
          ConditionalParent(
            condition: isDesktop,
            builder:
                (child) => Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [child],
                ),
            child: PrimaryButton(
              buttonHeight: isDesktop ? ButtonHeight.l : null,
              width: isDesktop ? 200 : null,
              label: "Save",
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}
