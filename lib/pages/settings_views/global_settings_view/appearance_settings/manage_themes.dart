import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
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
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: child,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(
            height: 16,
          ),
          GridView.builder(
            shrinkWrap: true,
            primary: false,
            itemCount: 100,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2 / 2.7,
            ),
            itemBuilder: (_, index) {
              return StackThemeCard(
                name: index.toString(),
                size: "lol GB",
              );
            },
          ),
          const SizedBox(
            height: 28,
          ),
          SecondaryButton(
            label: "Install theme file",
            onPressed: () {},
          ),
          const SizedBox(
            height: 16,
          ),
        ],
      ),
    );
  }
}

class StackThemeCard extends StatefulWidget {
  const StackThemeCard({
    Key? key,
    required this.name,
    required this.size,
  }) : super(key: key);

  final String name;
  final String size;

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
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 18,
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: RoundedContainer(
                color: Colors.grey,
                radiusMultiplier: 100,
              ),
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            widget.name,
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            widget.size,
          ),
          const Spacer(),
          PrimaryButton(
            label: buttonLabel,
            buttonHeight: ButtonHeight.l,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
