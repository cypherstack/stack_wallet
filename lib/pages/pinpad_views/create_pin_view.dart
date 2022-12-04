import 'dart:async';
import 'dart:io';

import 'package:epicmobile/pages/add_wallet_views/restore_wallet_view/restore_options_view/restore_options_view.dart';
import 'package:epicmobile/pages/home_view/home_view.dart';
import 'package:epicmobile/providers/global/prefs_provider.dart';
import 'package:epicmobile/providers/global/wallet_provider.dart';
import 'package:epicmobile/providers/global/wallets_service_provider.dart';
import 'package:epicmobile/providers/ui/verify_recovery_phrase/mnemonic_word_count_state_provider.dart';
import 'package:epicmobile/services/coins/epiccash/epiccash_wallet.dart';
import 'package:epicmobile/services/coins/manager.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/biometrics.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/flutter_secure_storage_interface.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/custom_pin_put/custom_pin_put.dart';
import 'package:epicmobile/widgets/fullscreen_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tuple/tuple.dart';

class CreatePinView extends ConsumerStatefulWidget {
  const CreatePinView({
    Key? key,
    required this.isNewWallet,
    this.popOnSuccess = false,
    this.secureStore = const SecureStorageWrapper(
      FlutterSecureStorage(),
    ),
    this.biometrics = const Biometrics(),
  }) : super(key: key);

  static const String routeName = "/createPin";

  final FlutterSecureStorageInterface secureStore;
  final Biometrics biometrics;
  final bool popOnSuccess;
  final bool isNewWallet;

  @override
  ConsumerState<CreatePinView> createState() => _CreatePinViewState();
}

class _CreatePinViewState extends ConsumerState<CreatePinView> {
  BoxDecoration get _pinPutDecoration {
    return const BoxDecoration(
      color: Colors.transparent,
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

  late FlutterSecureStorageInterface _secureStore;
  late Biometrics biometrics;

  Future<void> createWallet() async {
    final newWalletId =
        await ref.read(walletsServiceChangeNotifierProvider).addNewWallet(
              name: "Epic Wallet",
              coin: Coin.epicCash,
              shouldNotifyListeners: false,
            );

    ref.read(walletStateProvider.state).state = Manager(
      EpicCashWallet(
        walletId: newWalletId!,
        walletName: "Epic Wallet",
        coin: Coin.epicCash,
      ),
    );

    await ref.read(walletProvider)!.initializeNew();

    await ref
        .read(walletsServiceChangeNotifierProvider)
        .setMnemonicVerified(walletId: newWalletId);
  }

  @override
  initState() {
    _secureStore = widget.secureStore;
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
                    style: STextStyles.titleH2(context).copyWith(
                      color:
                          Theme.of(context).extension<StackColors>()!.textGold,
                    ),
                  ),
                  const SizedBox(
                    height: 36,
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
                  Text(
                    "Confirm PIN",
                    style: STextStyles.titleH2(context).copyWith(
                      color:
                          Theme.of(context).extension<StackColors>()!.textGold,
                    ),
                  ),
                  const SizedBox(
                    height: 36,
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

                        await Future<void>.delayed(
                            const Duration(milliseconds: 200));

                        if (mounted) {
                          if (!widget.popOnSuccess) {
                            if (widget.isNewWallet == true) {
                              assert(ref
                                      .read(prefsChangeNotifierProvider)
                                      .hasPin ==
                                  false);

                              final controller = FullScreenMessageController();
                              unawaited(
                                showDialog<void>(
                                  context: context,
                                  builder: (context) {
                                    return FullScreenMessage(
                                      icon: SvgPicture.asset(
                                        Assets.svg.circleCheck,
                                      ),
                                      message: "Wallet created",
                                      controller: controller,
                                    );
                                  },
                                ),
                              );
                              await _secureStore.write(
                                  key: "stack_pin", value: pin);

                              ref
                                  .read(prefsChangeNotifierProvider)
                                  .useBiometrics = useBiometrics;

                              await createWallet();

                              ref.read(prefsChangeNotifierProvider).hasPin =
                                  true;

                              await Future<void>.delayed(
                                  const Duration(seconds: 2));

                              if (mounted) {
                                //pop dialog
                                controller.forcePop!.call();

                                unawaited(
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    HomeView.routeName,
                                    (route) => false,
                                  ),
                                );
                              }
                            } else {
                              //!isNewWallet
                              ref
                                  .read(mnemonicWordCountStateProvider.state)
                                  .state = Constants.possibleLengthsForCoin(
                                      Coin.epicCash)
                                  .first;

                              await _secureStore.write(
                                  key: "stack_pin", value: pin);

                              ref
                                  .read(prefsChangeNotifierProvider)
                                  .useBiometrics = useBiometrics;

                              ref.read(prefsChangeNotifierProvider).hasPin =
                                  true;

                              if (mounted) {
                                unawaited(
                                  Navigator.of(context).pushNamed(
                                    RestoreOptionsView.routeName,
                                    arguments: const Tuple2(
                                      "Epic Wallet",
                                      Coin.epicCash,
                                    ),
                                  ),
                                );
                              }
                            }
                          } else {
                            Navigator.of(context).pop();
                          }
                        }
                      } else {
                        // _onSubmitFailCount++;
                        unawaited(
                          _pageController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.linear,
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
                              message: "Incorrect PIN."
                                  "\nSet up your PIN again.",
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
