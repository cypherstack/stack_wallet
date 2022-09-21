import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/startup_preferences/startup_wallet_selection_view.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class StartupPreferencesView extends ConsumerStatefulWidget {
  const StartupPreferencesView({Key? key}) : super(key: key);

  static const String routeName = "/startupPreferences";

  @override
  ConsumerState<StartupPreferencesView> createState() =>
      _StartupPreferencesViewState();
}

class _StartupPreferencesViewState
    extends ConsumerState<StartupPreferencesView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StackTheme.instance.color.background,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "Startup preferences",
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
                        padding: const EdgeInsets.all(0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: RawMaterialButton(
                                // splashColor: CFColors.splashLight,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    Constants.size.circularBorderRadius,
                                  ),
                                ),
                                onPressed: () {
                                  ref
                                      .read(prefsChangeNotifierProvider)
                                      .gotoWalletOnStartup = false;
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Radio(
                                            activeColor: StackTheme.instance
                                                .color.radioButtonIconEnabled,
                                            value: false,
                                            groupValue: ref.watch(
                                              prefsChangeNotifierProvider
                                                  .select((value) => value
                                                      .gotoWalletOnStartup),
                                            ),
                                            onChanged: (value) {
                                              if (value is bool) {
                                                ref
                                                    .read(
                                                        prefsChangeNotifierProvider)
                                                    .gotoWalletOnStartup = value;
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 12,
                                        ),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Home screen",
                                                style: STextStyles.titleBold12,
                                                textAlign: TextAlign.left,
                                              ),
                                              Text(
                                                "Stack Wallet home screen",
                                                style: STextStyles.itemSubtitle,
                                                textAlign: TextAlign.left,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: RawMaterialButton(
                                // splashColor: CFColors.splashLight,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    Constants.size.circularBorderRadius,
                                  ),
                                ),
                                onPressed: () {
                                  ref
                                      .read(prefsChangeNotifierProvider)
                                      .gotoWalletOnStartup = true;
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Radio(
                                            activeColor: StackTheme.instance
                                                .color.radioButtonIconEnabled,
                                            value: true,
                                            groupValue: ref.watch(
                                              prefsChangeNotifierProvider
                                                  .select((value) => value
                                                      .gotoWalletOnStartup),
                                            ),
                                            onChanged: (value) {
                                              if (value is bool) {
                                                ref
                                                    .read(
                                                        prefsChangeNotifierProvider)
                                                    .gotoWalletOnStartup = value;
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 12,
                                        ),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Specific wallet",
                                                style: STextStyles.titleBold12,
                                                textAlign: TextAlign.left,
                                              ),
                                              Text(
                                                "Select a specific wallet to load into on startup",
                                                style: STextStyles.itemSubtitle,
                                                textAlign: TextAlign.left,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (!ref.watch(prefsChangeNotifierProvider
                                .select((value) => value.gotoWalletOnStartup)))
                              const SizedBox(
                                height: 12,
                              ),
                            if (ref.watch(prefsChangeNotifierProvider
                                .select((value) => value.gotoWalletOnStartup)))
                              Container(
                                color: Colors.transparent,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 12.0,
                                    right: 12,
                                    bottom: 12,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                        width: 12 + 20,
                                        height: 12,
                                      ),
                                      Flexible(
                                        child: RawMaterialButton(
                                          // splashColor: CFColors.splashLight,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              Constants
                                                  .size.circularBorderRadius,
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pushNamed(
                                                StartupWalletSelectionView
                                                    .routeName);
                                          },
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Select wallet...",
                                                style: STextStyles.link2,
                                                textAlign: TextAlign.left,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
    );
  }
}
