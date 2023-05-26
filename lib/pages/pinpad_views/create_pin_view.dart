import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/home_view/home_view.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/biometrics.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_pin_put/custom_pin_put.dart';

class CreatePinView extends ConsumerStatefulWidget {
  const CreatePinView({
    Key? key,
    this.popOnSuccess = false,
    this.biometrics = const Biometrics(),
  }) : super(key: key);

  static const String routeName = "/createPin";

  final Biometrics biometrics;
  final bool popOnSuccess;

  @override
  ConsumerState<CreatePinView> createState() => _CreatePinViewState();
}

class _CreatePinViewState extends ConsumerState<CreatePinView> {
  BoxDecoration get _pinPutDecoration {
    return BoxDecoration(
      color: Theme.of(context).extension<StackColors>()!.infoItemIcons,
      border: Border.all(
        width: 1,
        color: Theme.of(context).extension<StackColors>()!.infoItemIcons,
      ),
      borderRadius: BorderRadius.circular(6),
    );
  }

  final PageController _pageController =
      PageController(initialPage: 0, keepPage: true);

  // Attributes for Page 1 of the pageview
  final TextEditingController _pinPutController1 = TextEditingController();
  final FocusNode _pinPutFocusNode1 = FocusNode();

  // Attributes for Page 2 of the pageview
  final TextEditingController _pinPutController2 = TextEditingController();
  final FocusNode _pinPutFocusNode2 = FocusNode();

  late SecureStorageInterface _secureStore;
  late Biometrics biometrics;

  int pinCount = 1;

  @override
  initState() {
    _secureStore = ref.read(secureStoreProvider);
    biometrics = widget.biometrics;

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
    // int pinCount = 1;
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
                Navigator.of(context).pop(widget.popOnSuccess);
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
                  Text(
                    "Create a PIN",
                    style: STextStyles.pageTitleH1(context),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    "This PIN protects access to your wallet.",
                    style: STextStyles.subtitle(context),
                  ),
                  const SizedBox(
                    height: 36,
                  ),
                  CustomPinPut(
                    fieldsCount: pinCount,
                    eachFieldHeight: 12,
                    eachFieldWidth: 12,
                    textStyle: STextStyles.label(context).copyWith(
                      fontSize: 1,
                    ),
                    focusNode: _pinPutFocusNode1,
                    controller: _pinPutController1,
                    useNativeKeyboard: false,
                    obscureText: "",
                    inputDecoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      fillColor: Theme.of(context)
                          .extension<StackColors>()!
                          .background,
                      counterText: "",
                    ),
                    isRandom:
                        ref.read(prefsChangeNotifierProvider).randomizePIN,
                    submittedFieldDecoration: _pinPutDecoration,
                    selectedFieldDecoration: _pinPutDecoration,
                    followingFieldDecoration: _pinPutDecoration,
                    onPinLengthChanged: (newLength) {
                      setState(() {
                        pinCount = newLength;
                      });
                    },
                    onSubmit: (String pin) {
                      if (pin.length < 4) {
                        showFloatingFlushBar(
                          type: FlushBarType.warning,
                          message: "PIN not long enough!",
                          iconAsset: Assets.svg.alertCircle,
                          context: context,
                        );
                      } else {
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
                  Text(
                    "Confirm PIN",
                    style: STextStyles.pageTitleH1(context),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    "This PIN protects access to your wallet.",
                    style: STextStyles.subtitle(context),
                  ),
                  const SizedBox(
                    height: 36,
                  ),
                  CustomPinPut(
                    fieldsCount: pinCount,
                    eachFieldHeight: 12,
                    eachFieldWidth: 12,
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
                    inputDecoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      fillColor: Theme.of(context)
                          .extension<StackColors>()!
                          .background,
                      counterText: "",
                    ),
                    submittedFieldDecoration: _pinPutDecoration.copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .infoItemIcons,
                      border: Border.all(
                        width: 1,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .infoItemIcons,
                      ),
                    ),
                    selectedFieldDecoration: _pinPutDecoration,
                    followingFieldDecoration: _pinPutDecoration,
                    isRandom:
                        ref.read(prefsChangeNotifierProvider).randomizePIN,
                    onSubmit: (String pin) async {
                      // _onSubmitCount++;
                      // if (_onSubmitCount - _onSubmitFailCount > 1) return;

                      if (_pinPutController1.text == _pinPutController2.text) {
                        // ask if want to use biometrics
                        final bool useBiometrics = (Platform.isLinux)
                            ? false
                            : await biometrics.authenticate(
                                cancelButtonText: "SKIP",
                                localizedReason:
                                    "You can use your fingerprint to unlock the wallet and confirm transactions.",
                                title: "Enable fingerprint authentication",
                              );

                        //TODO investigate why this crashes IOS, maybe ios persists securestorage even after an uninstall?
                        // This should never fail as we are writing a new pin
                        // assert(
                        //     (await _secureStore.read(key: "stack_pin")) == null);
                        // possible alternative to the above but it does not guarantee we aren't overwriting a pin
                        // if (!Platform.isLinux)
                        //   assert((await _secureStore.read(key: "stack_pin")) ==
                        //       null);
                        assert(ref.read(prefsChangeNotifierProvider).hasPin ==
                            false);

                        await _secureStore.write(key: "stack_pin", value: pin);

                        ref.read(prefsChangeNotifierProvider).useBiometrics =
                            useBiometrics;
                        ref.read(prefsChangeNotifierProvider).hasPin = true;

                        await Future<void>.delayed(
                            const Duration(milliseconds: 200));

                        if (mounted) {
                          if (!widget.popOnSuccess) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              HomeView.routeName,
                              (route) => false,
                            );
                          } else {
                            Navigator.of(context).pop();
                          }
                        }
                      } else {
                        // _onSubmitFailCount++;
                        _pageController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.linear,
                        );

                        showFloatingFlushBar(
                          type: FlushBarType.warning,
                          message: "PIN codes do not match. Try again.",
                          context: context,
                          iconAsset: Assets.svg.alertCircle,
                        );

                        _pinPutController1.text = '';
                        _pinPutController2.text = '';
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
