import 'package:epicpay/pages/add_wallet_views/create_restore_wallet_view.dart';
import 'package:epicpay/utilities/assets.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/utilities/util.dart';
import 'package:epicpay/widgets/background.dart';
import 'package:epicpay/widgets/desktop/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ui/intro_view_index_provider.dart';

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
    final width = MediaQuery.of(context).size.width;
    return Material(
      color: Colors.transparent,
      child: Background(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
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
              ),
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
                        _pageController.previousPage(
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
              Padding(
                padding: EdgeInsets.all(width < 350 ? 24 : 40.0),
                child: PrimaryButton(
                  label: "GET STARTED",
                  onPressed: () => Navigator.of(context)
                      .pushNamed(CreateRestoreWalletView.routeName),
                ),
              ),
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
    final width = MediaQuery.of(context).size.width;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(
                    flex: 5,
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: width,
                    ),
                    child: Image(
                      image: AssetImage(
                        Assets.png.epicFast,
                      ),
                      width: width,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  const Spacer(
                    flex: 3,
                  ),
                  Padding(
                    padding: EdgeInsets.all(width < 350 ? 24 : 40.0),
                    child: Text(
                      "Fast and reliable"
                      "\ntransactions",
                      textAlign: TextAlign.left,
                      style: width < 350
                          ? STextStyles.titleH1(context).copyWith(
                              fontSize: 32,
                            )
                          : STextStyles.titleH1(context),
                    ),
                  ),
                  const Spacer(
                    flex: 10,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AppNameTextRight extends StatelessWidget {
  const AppNameTextRight({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(
                    flex: 8,
                  ),
                  Image(
                    image: AssetImage(
                      Assets.png.epicClouds,
                    ),
                    width: width,
                  ),
                  const Spacer(
                    flex: 1,
                  ),
                  Padding(
                    padding: EdgeInsets.all(width < 350 ? 24 : 40.0),
                    child: Text(
                      "Everyday \nfinancial \nprivacy",
                      textAlign: TextAlign.left,
                      style: width < 350
                          ? STextStyles.titleH1(context).copyWith(
                              fontSize: 32,
                            )
                          : STextStyles.titleH1(context),
                    ),
                  ),
                  const Spacer(
                    flex: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
