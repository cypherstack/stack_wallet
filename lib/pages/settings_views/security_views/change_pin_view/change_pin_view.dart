import 'dart:async';

import 'package:epicmobile/pages/settings_views/security_views/security_view.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/flutter_secure_storage_interface.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/custom_pin_put/custom_pin_put.dart';
import 'package:epicmobile/widgets/fullscreen_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';

class ChangePinView extends StatefulWidget {
  const ChangePinView({
    Key? key,
    this.secureStore = const SecureStorageWrapper(
      FlutterSecureStorage(),
    ),
  }) : super(key: key);

  static const String routeName = "/changePin";

  final FlutterSecureStorageInterface secureStore;

  @override
  State<ChangePinView> createState() => _ChangePinViewState();
}

class _ChangePinViewState extends State<ChangePinView> {
  BoxDecoration get _pinPutDecoration {
    return const BoxDecoration(
      color: Colors.transparent,
    );
  }

  final PageController _pageController =
      PageController(initialPage: 0, keepPage: true);

  // Attributes for Page 1 of the page view
  final TextEditingController _pinPutController1 = TextEditingController();
  final FocusNode _pinPutFocusNode1 = FocusNode();

  // Attributes for Page 2 of the page view
  final TextEditingController _pinPutController2 = TextEditingController();
  final FocusNode _pinPutFocusNode2 = FocusNode();

  late final FlutterSecureStorageInterface _secureStore;

  @override
  void initState() {
    _secureStore = widget.secureStore;
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pinPutController1.dispose();
    _pinPutController2.dispose();
    _pinPutFocusNode1.dispose();
    _pinPutFocusNode2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () async {
              if (FocusScope.of(context).hasFocus) {
                FocusScope.of(context).unfocus();
                await Future<void>.delayed(const Duration(milliseconds: 70));
              }
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: SafeArea(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // page 1
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Text(
                      "Enter new PIN",
                      style: STextStyles.titleH2(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textGold,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 52,
                  ),
                  CustomPinPut(
                    fieldsCount: Constants.pinLength,
                    textStyle: STextStyles.label(context).copyWith(
                      fontSize: 1,
                    ),
                    focusNode: _pinPutFocusNode1,
                    controller: _pinPutController1,
                    useNativeKeyboard: false,
                    obscureText: "",
                    inputDecoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      counterText: "",
                    ),
                    submittedFieldDecoration: _pinPutDecoration.copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .infoItemIcons,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    selectedFieldDecoration: _pinPutDecoration,
                    followingFieldDecoration: _pinPutDecoration,
                    onSubmit: (String pin) {
                      if (pin.length == Constants.pinLength) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.linear,
                        );
                      }
                    },
                  ),
                ],
              ),

              // page 2

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Text(
                      "Confirm new PIN",
                      style: STextStyles.titleH2(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textGold,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 52,
                  ),
                  CustomPinPut(
                    fieldsCount: Constants.pinLength,
                    textStyle: STextStyles.infoSmall(context).copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textSubtitle3,
                      fontSize: 1,
                    ),
                    focusNode: _pinPutFocusNode2,
                    controller: _pinPutController2,
                    useNativeKeyboard: false,
                    obscureText: "",
                    inputDecoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      counterText: "",
                    ),
                    submittedFieldDecoration: _pinPutDecoration.copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .infoItemIcons,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    selectedFieldDecoration: _pinPutDecoration,
                    followingFieldDecoration: _pinPutDecoration,
                    onSubmit: (String pin) async {
                      if (_pinPutController1.text == _pinPutController2.text) {
                        // This should never fail as we are overwriting the existing pin
                        assert((await _secureStore.read(key: "stack_pin")) !=
                            null);
                        await _secureStore.write(key: "stack_pin", value: pin);

                        await showDialog<void>(
                          context: context,
                          builder: (context) {
                            return FullScreenMessage(
                              icon: SvgPicture.asset(
                                Assets.svg.circleCheck,
                              ),
                              message: "New PIN has been set up",
                              duration: const Duration(milliseconds: 2000),
                            );
                          },
                        );

                        if (mounted) {
                          Navigator.of(context).popUntil(
                            ModalRoute.withName(SecurityView.routeName),
                          );
                        }
                      } else {
                        unawaited(
                          Future<void>.delayed(
                                  const Duration(milliseconds: 500))
                              .then(
                            (_) => _pageController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.linear,
                            ),
                          ),
                        );

                        _pinPutController1.text = '';
                        _pinPutController2.text = '';
                        await showDialog<void>(
                          context: context,
                          builder: (context) {
                            return FullScreenMessage(
                              icon: SvgPicture.asset(
                                Assets.svg.circleRedX,
                              ),
                              message: "PIN codes do not match.\nTry again.",
                              duration: const Duration(seconds: 2),
                            );
                          },
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
