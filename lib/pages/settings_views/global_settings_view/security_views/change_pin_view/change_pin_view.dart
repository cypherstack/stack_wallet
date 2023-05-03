import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/security_views/security_view.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_pin_put/custom_pin_put.dart';

class ChangePinView extends ConsumerStatefulWidget {
  const ChangePinView({
    Key? key,
  }) : super(key: key);

  static const String routeName = "/changePin";

  @override
  ConsumerState<ChangePinView> createState() => _ChangePinViewState();
}

class _ChangePinViewState extends ConsumerState<ChangePinView> {
  BoxDecoration get _pinPutDecoration {
    return BoxDecoration(
      color: Theme.of(context).extension<StackColors>()!.textSubtitle2,
      border: Border.all(
          width: 1,
          color: Theme.of(context).extension<StackColors>()!.textSubtitle2),
      borderRadius: BorderRadius.circular(6),
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

  late final SecureStorageInterface _secureStore;

  @override
  void initState() {
    _secureStore = ref.read(secureStoreProvider);
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
                      "Create new PIN",
                      style: STextStyles.pageTitleH1(context),
                    ),
                  ),
                  const SizedBox(
                    height: 52,
                  ),
                  CustomPinPut(
                    fieldsCount: Constants.pinLength,
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
                      style: STextStyles.pageTitleH1(context),
                    ),
                  ),
                  const SizedBox(
                    height: 52,
                  ),
                  CustomPinPut(
                    fieldsCount: Constants.pinLength,
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
                    isRandom:
                        ref.read(prefsChangeNotifierProvider).randomizePIN,
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
                    onSubmit: (String pin) async {
                      if (_pinPutController1.text == _pinPutController2.text) {
                        // This should never fail as we are overwriting the existing pin
                        assert((await _secureStore.read(key: "stack_pin")) !=
                            null);
                        await _secureStore.write(key: "stack_pin", value: pin);

                        showFloatingFlushBar(
                          type: FlushBarType.success,
                          message: "New PIN is set up",
                          context: context,
                          iconAsset: Assets.svg.check,
                        );

                        await Future<void>.delayed(
                            const Duration(milliseconds: 1200));

                        if (mounted) {
                          Navigator.of(context).popUntil(
                            ModalRoute.withName(SecurityView.routeName),
                          );
                        }
                      } else {
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
