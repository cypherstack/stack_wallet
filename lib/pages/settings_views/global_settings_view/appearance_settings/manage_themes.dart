import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class ManageThemesView extends StatefulWidget {
  const ManageThemesView({Key? key}) : super(key: key);

  static const String routeName = "/manageThemes";

  @override
  State<ManageThemesView> createState() => _ManageThemesViewState();
}

class _ManageThemesViewState extends State<ManageThemesView> {
  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: !Util.isDesktop,
      builder: (child) => Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: AppBarBackButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            title: Text(
              "Settings",
              style: STextStyles.navBarTitle(context),
            ),
          ),
          body: LayoutBuilder(
            builder: (builderContext, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: child,
                  ),
                ),
              );
            },
          )),
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 100,
              ),
              itemBuilder: (_, index) {
                return Container(
                  width: 25,
                  height: 25,
                  color: Colors.red,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class StackThemeCard extends StatefulWidget {
  const StackThemeCard({Key? key}) : super(key: key);

  @override
  State<StackThemeCard> createState() => _StackThemeCardState();
}

class _StackThemeCardState extends State<StackThemeCard> {
  String buttonLabel = "Download";

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      child: Column(
        children: [
          RoundedContainer(
            color: Colors.grey,
            radiusMultiplier: 100,
          ),
          Text(
            "Theme name",
          ),
          Text(
            "10.6 GB (lol)",
          ),
          PrimaryButton(
            label: buttonLabel,
            buttonHeight: ButtonHeight.m,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
