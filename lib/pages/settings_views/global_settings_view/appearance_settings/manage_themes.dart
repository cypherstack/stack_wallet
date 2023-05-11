import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/appearance_settings/sub_widgets/install_theme_from_file_dialog.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/appearance_settings/sub_widgets/stack_theme_card.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class ManageThemesView extends ConsumerStatefulWidget {
  const ManageThemesView({Key? key}) : super(key: key);

  static const String routeName = "/manageThemes";

  @override
  ConsumerState<ManageThemesView> createState() => _ManageThemesViewState();
}

class _ManageThemesViewState extends ConsumerState<ManageThemesView> {
  late bool _showThemes;

  Future<List<StackThemeMetaData>> future = Future(() => []);

  void _onInstallPressed() {
    showDialog<void>(
      context: context,
      builder: (context) => const InstallThemeFromFileDialog(),
    );
  }

  @override
  void initState() {
    _showThemes = ref.read(prefsChangeNotifierProvider).externalCalls;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: !Util.isDesktop,
      builder: (child) => Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: AppBarBackButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            title: Text(
              "Add more themes",
              style: STextStyles.navBarTitle(context),
            ),
          ),
          body: _showThemes
              ? Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          child: IntrinsicHeight(
                            child: child,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SecondaryButton(
                        label: "Install theme file",
                        onPressed: _onInstallPressed,
                      ),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      RoundedWhiteContainer(
                        child: Text(
                          "You are using Incognito Mode. Please press the"
                          " button below to load available themes from our server"
                          " or upload a theme file manually from your device.",
                          style: STextStyles.smallMed12(context),
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      PrimaryButton(
                        label: "Load themes",
                        onPressed: () {
                          setState(() {
                            _showThemes = true;
                            future = ref.watch(pThemeService).fetchThemes();
                          });
                        },
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      SecondaryButton(
                        label: "Install theme file",
                        onPressed: _onInstallPressed,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FutureBuilder(
            future: future,
            builder: (
              context,
              AsyncSnapshot<List<StackThemeMetaData>> snapshot,
            ) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: snapshot.data!
                      .map(
                        (e) => SizedBox(
                          width: (MediaQuery.of(context).size.width - 48) / 2,
                          child: StackThemeCard(
                            data: e,
                          ),
                        ),
                      )
                      .toList(),
                );
              } else {
                return Center(
                  child: LoadingIndicator(
                    width: (MediaQuery.of(context).size.width - 48) / 2,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
