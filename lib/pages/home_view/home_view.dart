import 'dart:async';

import 'package:epicmobile/pages/settings_views/global_settings_view/global_settings_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/hidden_settings.dart';
import 'package:epicmobile/pages/wallet_view/wallet_view.dart';
import 'package:epicmobile/providers/global/wallet_provider.dart';
import 'package:epicmobile/providers/ui/home_view_index_provider.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/stack_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  static const routeName = "/home";

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();

  late final PageController _pageController;

  late final List<Widget> _children;

  DateTime? _cachedTime;

  bool _exitEnabled = false;

  Future<bool> _onWillPop() async {
    // go to home view when tapping back on the main exchange view
    if (ref.read(homeViewPageIndexStateProvider.state).state == 1) {
      ref.read(homeViewPageIndexStateProvider.state).state = 0;
      return false;
    }

    if (_exitEnabled) {
      return true;
    }

    final now = DateTime.now();
    const timeout = Duration(milliseconds: 1500);
    if (_cachedTime == null || now.difference(_cachedTime!) > timeout) {
      _cachedTime = now;
      await showDialog<dynamic>(
        context: context,
        barrierDismissible: false,
        builder: (_) => WillPopScope(
          onWillPop: () async {
            _exitEnabled = true;
            return true;
          },
          child: const StackDialog(title: "Tap back again to exit"),
        ),
      ).timeout(
        timeout,
        onTimeout: () {
          _exitEnabled = false;
          Navigator.of(context).pop();
        },
      );
    }
    return _exitEnabled;
  }

  @override
  void initState() {
    _pageController = PageController();
    _children = [
      WalletView(
        walletId: ref.read(walletProvider)!.walletId,
      ),

      // const BuyView(),
    ];

    super.initState();
  }

  @override
  dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _hiddenTime = DateTime.now();
  int _hiddenCount = 0;

  void _hiddenOptions() {
    if (_hiddenCount == 5) {
      Navigator.of(context).pushNamed(HiddenSettings.routeName);
    }
    final now = DateTime.now();
    const timeout = Duration(seconds: 1);
    if (now.difference(_hiddenTime) < timeout) {
      _hiddenCount++;
    } else {
      _hiddenCount = 0;
    }
    _hiddenTime = now;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          key: _key,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                GestureDetector(
                  onTap: _hiddenOptions,
                  child: SvgPicture.asset(
                    Assets.svg.stackIcon(context),
                    width: 24,
                    height: 24,
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
                Text(
                  "My Stack",
                  style: STextStyles.navBarTitle(context),
                )
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 10,
                  bottom: 10,
                  right: 10,
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AppBarIconButton(
                    key: const Key("walletsViewSettingsButton"),
                    size: 36,
                    shadows: const [],
                    color:
                        Theme.of(context).extension<StackColors>()!.background,
                    icon: SvgPicture.asset(
                      Assets.svg.gear,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .topNavIconPrimary,
                      width: 20,
                      height: 20,
                    ),
                    onPressed: () {
                      debugPrint("main view settings tapped");
                      Navigator.of(context)
                          .pushNamed(GlobalSettingsView.routeName);
                    },
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Consumer(
                  builder: (_, _ref, __) {
                    _ref.listen(homeViewPageIndexStateProvider,
                        (previous, next) {
                      if (next is int) {
                        if (next >= 0 && next <= 1) {
                          _pageController.animateToPage(
                            next,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.decelerate,
                          );
                        }
                      }
                    });
                    return PageView(
                      controller: _pageController,
                      children: _children,
                      onPageChanged: (pageIndex) {
                        ref.read(homeViewPageIndexStateProvider.state).state =
                            pageIndex;
                      },
                    );
                  },
                ),
              ),
              // Expanded(
              //   child: HomeStack(
              //     children: _children,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
