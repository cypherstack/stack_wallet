import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/appearance_settings/sub_widgets/stack_theme_card.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';

class ManageThemesView extends ConsumerStatefulWidget {
  const ManageThemesView({Key? key}) : super(key: key);

  static const String routeName = "/manageThemes";

  @override
  ConsumerState<ManageThemesView> createState() => _ManageThemesViewState();
}

class _ManageThemesViewState extends ConsumerState<ManageThemesView> {
  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: !Util.isDesktop,
      builder: (child) => Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
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
        body: Column(
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
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FutureBuilder(
            future: ref.watch(pThemeService).fetchThemes(),
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
