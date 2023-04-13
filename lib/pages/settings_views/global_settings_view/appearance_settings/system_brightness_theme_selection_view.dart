import 'package:flutter/material.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/appearance_settings/sub_widgets/theme_option.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class SystemBrightnessThemeSelectionView extends StatelessWidget {
  const SystemBrightnessThemeSelectionView({
    Key? key,
    required this.brightness,
    required this.current,
  }) : super(key: key);

  final String brightness;
  final ThemeType current;

  static const String routeName = "/chooseSystemTheme";

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () async {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            "Choose $brightness theme",
            style: STextStyles.navBarTitle(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RoundedWhiteContainer(
                          padding: const EdgeInsets.all(0),
                          child: RawMaterialButton(
                            // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
                            padding: const EdgeInsets.all(0),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                Constants.size.circularBorderRadius,
                              ),
                            ),
                            onPressed: null,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          children: [
                                            for (int i = 0;
                                                i <
                                                    (2 *
                                                            ThemeType.values
                                                                .length) -
                                                        1;
                                                i++)
                                              (i % 2 == 1)
                                                  ? const SizedBox(
                                                      height: 10,
                                                    )
                                                  : ThemeOption(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop(ThemeType
                                                                    .values[
                                                                i ~/ 2]);
                                                      },
                                                      onChanged: (newValue) {
                                                        if (newValue ==
                                                            ThemeType.values[
                                                                i ~/ 2]) {
                                                          Navigator.of(context)
                                                              .pop(ThemeType
                                                                      .values[
                                                                  i ~/ 2]);
                                                        }
                                                      },
                                                      value: ThemeType
                                                          .values[i ~/ 2],
                                                      groupValue: current,
                                                    ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
