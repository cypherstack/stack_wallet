import 'package:epicmobile/pages/add_wallet_views/create_restore_wallet_view.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/utilities/util.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/desktop/primary_button.dart';
import 'package:flutter/material.dart';

class IntroView extends StatefulWidget {
  const IntroView({Key? key}) : super(key: key);

  static const String routeName = "/introView";

  @override
  State<IntroView> createState() => _IntroViewState();
}

class _IntroViewState extends State<IntroView> {
  late final bool isDesktop;

  @override
  void initState() {
    isDesktop = Util.isDesktop;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType ");
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        body: GestureDetector(
          onHorizontalDragEnd: (DragEndDetails details) {
            //user didn't drag screen
            if (details.primaryVelocity == 0) return;

            if (details.primaryVelocity?.compareTo(0) == -1)
              print('dragged from left');
            else
              print('dragged from right');
          },
          child: PageView(
            children: [
              AppNameTextLeft(),
              AppNameTextRight(),
            ],
          ),
        ),
      ),
    );
  }
}

class AppNameTextLeft extends StatelessWidget {
  const AppNameTextLeft({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(
          flex: 5,
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width,
          ),
          child: Image(
            image: AssetImage(
              Assets.png.epicFast,
            ),
            width: MediaQuery.of(context).size.width,
            height: 145,
            alignment: Alignment.centerLeft,
          ),
        ),
        const Spacer(
          flex: 3,
        ),
        Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text(
            "Fast and reliable"
            "\ntransactions",
            textAlign: TextAlign.left,
            style: STextStyles.pageTitleH1(context).copyWith(fontSize: 40),
          ),
        ),
        const SizedBox(
          height: 32,
        ),
        // todo add screen swipe text
        const SizedBox(
          height: 118,
        ),
        Padding(
          padding: const EdgeInsets.all(40.0),
          child: PrimaryButton(
            label: "GET STARTED",
            onPressed: () => Navigator.of(context)
                .pushNamed(CreateRestoreWalletView.routeName),
          ),
        ),
      ],
    );
  }
}

class AppNameTextRight extends StatelessWidget {
  const AppNameTextRight({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(
          flex: 10,
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width,
          ),
          child: Image(
            image: AssetImage(
              Assets.png.epicClouds,
            ),
            width: MediaQuery.of(context).size.width,
            height: 333,
          ),
        ),
        const Spacer(
          flex: 2,
        ),
        Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text(
            "Everyday \nfinancial \nprivacy",
            textAlign: TextAlign.left,
            style: STextStyles.pageTitleH1(context).copyWith(fontSize: 40),
          ),
        ),
        // todo add screen swipe text
        const SizedBox(
          height: 112,
        ),
        Padding(
          padding: const EdgeInsets.all(40.0),
          child: PrimaryButton(
            label: "GET STARTED",
            onPressed: () => Navigator.of(context)
                .pushNamed(CreateRestoreWalletView.routeName),
          ),
        ),
      ],
    );
  }
}
