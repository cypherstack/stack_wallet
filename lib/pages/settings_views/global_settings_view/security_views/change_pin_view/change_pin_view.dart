import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/security_views/security_view.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_pin_put/custom_pin_put.dart';

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
    return BoxDecoration(
      color: CFColors.gray3,
      border: Border.all(width: 1, color: CFColors.gray3),
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
    return Scaffold(
      backgroundColor: CFColors.almostWhite,
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
                    style: STextStyles.pageTitleH1,
                  ),
                ),
                const SizedBox(
                  height: 52,
                ),
                CustomPinPut(
                  fieldsCount: Constants.pinLength,
                  eachFieldHeight: 12,
                  eachFieldWidth: 12,
                  textStyle: STextStyles.label.copyWith(
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
                    fillColor: CFColors.almostWhite,
                    counterText: "",
                  ),
                  submittedFieldDecoration: _pinPutDecoration.copyWith(
                    color: CFColors.link2,
                    border: Border.all(
                      width: 1,
                      color: CFColors.link2,
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
                    style: STextStyles.pageTitleH1,
                  ),
                ),
                const SizedBox(
                  height: 52,
                ),
                CustomPinPut(
                  fieldsCount: Constants.pinLength,
                  eachFieldHeight: 12,
                  eachFieldWidth: 12,
                  textStyle: GoogleFonts.workSans(
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
                    fillColor: CFColors.almostWhite,
                    counterText: "",
                  ),
                  submittedFieldDecoration: _pinPutDecoration.copyWith(
                    color: CFColors.link2,
                    border: Border.all(
                      width: 1,
                      color: CFColors.link2,
                    ),
                  ),
                  selectedFieldDecoration: _pinPutDecoration,
                  followingFieldDecoration: _pinPutDecoration,
                  onSubmit: (String pin) async {
                    if (_pinPutController1.text == _pinPutController2.text) {
                      // This should never fail as we are overwriting the existing pin
                      assert(
                          (await _secureStore.read(key: "stack_pin")) != null);
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
    );
  }
}
