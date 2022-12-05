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
  final PageController _pageController = PageController();
  double currentIndex = 0;

  @override
  void initState() {
    isDesktop = Util.isDesktop;

    _pageController.addListener(() {
      setState(() {
        currentIndex = _pageController.page!;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType ");
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        body: Stack(
          children: [
            GestureDetector(
              onHorizontalDragEnd: (DragEndDetails details) {
                //user didn't drag screen
                if (details.primaryVelocity == 0) return;

                if (details.primaryVelocity?.compareTo(0) == -1)
                  print('dragged from left');
                else
                  print('dragged from right');
              },
              child: PageView(
                children: const [
                  AppNameTextLeft(),
                  AppNameTextRight(),
                ],
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    currentIndex = page as double;
                  });
                },
              ),
            ),
            Container(
              alignment: Alignment.bottomCenter,
              // width: 311,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            _pageController.nextPage(
                              duration: const Duration(
                                milliseconds: 100,
                              ),
                              curve: Curves.linear,
                            );
                          },
                          child: Container(
                            height: 10,
                            width: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: currentIndex == 0
                                  ? Theme.of(context)
                                      .extension<StackColors>()!
                                      .buttonBackPrimary
                                  : Theme.of(context)
                                      .extension<StackColors>()!
                                      .textDark,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        InkWell(
                          onTap: () {
                            _pageController.nextPage(
                              duration: Duration(
                                milliseconds: 100,
                              ),
                              curve: Curves.linear,
                            );
                          },
                          child: Container(
                            height: 10,
                            width: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: currentIndex == 1
                                  ? Theme.of(context)
                                      .extension<StackColors>()!
                                      .buttonBackPrimary
                                  : Theme.of(context)
                                      .extension<StackColors>()!
                                      .textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: PrimaryButton(
                          width: 311,
                          label: "GET STARTED",
                          onPressed: () => Navigator.of(context)
                              .pushNamed(CreateRestoreWalletView.routeName),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
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
          height: 150,
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
        const SizedBox(
          height: 150,
        ),
      ],
    );
  }
}
