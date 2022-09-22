import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/draggable_switch_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class AppearanceSettingsView extends ConsumerWidget {
  const AppearanceSettingsView({Key? key}) : super(key: key);

  static const String routeName = "/appearanceSettings";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: StackTheme.instance.color.background,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "Appearance",
          style: STextStyles.navBarTitle,
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
                        child: Consumer(
                          builder: (_, ref, __) {
                            return RawMaterialButton(
                              splashColor: StackTheme.instance.color.highlight,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Constants.size.circularBorderRadius,
                                ),
                              ),
                              onPressed: null,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Display favorite wallets",
                                      style: STextStyles.titleBold12,
                                      textAlign: TextAlign.left,
                                    ),
                                    SizedBox(
                                      height: 20,
                                      width: 40,
                                      child: DraggableSwitchButton(
                                        isOn: ref.watch(
                                          prefsChangeNotifierProvider.select(
                                              (value) =>
                                                  value.showFavoriteWallets),
                                        ),
                                        onValueChanged: (newValue) {
                                          ref
                                              .read(prefsChangeNotifierProvider)
                                              .showFavoriteWallets = newValue;
                                        },
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      RoundedWhiteContainer(
                        child: Consumer(
                          builder: (_, ref, __) {
                            return RawMaterialButton(
                              splashColor: StackTheme.instance.color.highlight,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Constants.size.circularBorderRadius,
                                ),
                              ),
                              onPressed: null,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Enabled dark mode",
                                          style: STextStyles.titleBold12,
                                          textAlign: TextAlign.left,
                                        ),
                                        Text(
                                          "Requires restart",
                                          style: STextStyles.itemSubtitle,
                                          textAlign: TextAlign.left,
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 20,
                                      width: 40,
                                      child: DraggableSwitchButton(
                                        isOn: (DB.instance.get<dynamic>(
                                                    boxName: DB.boxNameTheme,
                                                    key: "colorScheme")
                                                as String?) ==
                                            "dark",
                                        onValueChanged: (newValue) {
                                          DB.instance.put<dynamic>(
                                            boxName: DB.boxNameTheme,
                                            key: "colorScheme",
                                            value: (newValue
                                                    ? ThemeType.dark
                                                    : ThemeType.light)
                                                .name,
                                          );
                                        },
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
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
    );
  }
}
