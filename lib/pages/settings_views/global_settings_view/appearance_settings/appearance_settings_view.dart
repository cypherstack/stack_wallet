import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/appearance_settings/sub_widgets/theme_options_widget.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/draggable_switch_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

import 'manage_themes.dart';

class AppearanceSettingsView extends ConsumerWidget {
  const AppearanceSettingsView({Key? key}) : super(key: key);

  static const String routeName = "/appearanceSettings";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            "Appearance",
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
                          child: Consumer(
                            builder: (_, ref, __) {
                              return RawMaterialButton(
                                splashColor: Theme.of(context)
                                    .extension<StackColors>()!
                                    .highlight,
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
                                        style: STextStyles.titleBold12(context),
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
                                                .read(
                                                    prefsChangeNotifierProvider)
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
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Choose Theme",
                                        style: STextStyles.titleBold12(context),
                                        textAlign: TextAlign.left,
                                      ),
                                      const SizedBox(
                                        height: 12,
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: ThemeOptionsWidget(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              SecondaryButton(
                                label: "Add more themes",
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                    ManageThemesView.routeName,
                                  );
                                },
                              )
                            ],
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
