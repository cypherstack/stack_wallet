import 'package:epicpay/pages/add_wallet_views/create_restore_wallet_view.dart';
import 'package:epicpay/providers/ui/intro_view_index_provider.dart';
import 'package:epicpay/utilities/assets.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/utilities/util.dart';
import 'package:epicpay/widgets/background.dart';
import 'package:epicpay/widgets/desktop/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IntroView extends ConsumerStatefulWidget {
  const IntroView({Key? key}) : super(key: key);

  static const String routeName = "/introView";

  @override
  ConsumerState<IntroView> createState() => _IntroViewState();
}

class _IntroViewState extends ConsumerState<IntroView> {
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

                if (details.primaryVelocity?.compareTo(0) == -1) {
                } else {}
              },
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  // setState(() {
                  ref.read(introViewIndexProvider.state).state = page;
                  // });
                },
                children: const [
                  AppNameTextLeft(),
                  AppNameTextRight(),
                ],
              ),
            ),
            Container(
              alignment: Alignment.bottomCenter,
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
                            height: 7.5,
                            width: 7.5,
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
                              duration: const Duration(
                                milliseconds: 100,
                              ),
                              curve: Curves.linear,
                            );
                          },
                          child: Container(
                            height: 7.5,
                            width: 7.5,
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
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: PrimaryButton(
                          width: 330,
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
            style: STextStyles.pageTitleH1(context).copyWith(fontSize: 35),
          ),
        ),
        const SizedBox(
          height: 200,
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
            style: STextStyles.pageTitleH1(context).copyWith(fontSize: 35),
          ),
        ),
        const SizedBox(
          height: 150,
        ),
      ],
    );
  }
}
