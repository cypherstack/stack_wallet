import 'dart:async';

import 'package:epicpay/pages/home_view/home_view.dart';
import 'package:epicpay/pages/wallet_view/wallet_view.dart';
import 'package:epicpay/providers/global/prefs_provider.dart';
import 'package:epicpay/providers/global/wallet_provider.dart';
import 'package:epicpay/utilities/assets.dart';
import 'package:epicpay/utilities/biometrics.dart';
import 'package:epicpay/utilities/constants.dart';
import 'package:epicpay/utilities/flutter_secure_storage_interface.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/widgets/background.dart';
import 'package:epicpay/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicpay/widgets/custom_pin_put/custom_pin_put.dart';
import 'package:epicpay/widgets/fullscreen_message.dart';
import 'package:epicpay/widgets/shake/shake.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tuple/tuple.dart';

class LockscreenView extends ConsumerStatefulWidget {
  const LockscreenView({
    Key? key,
    required this.routeOnSuccess,
    required this.biometricsAuthenticationTitle,
    required this.biometricsLocalizedReason,
    required this.biometricsCancelButtonString,
    this.showBackButton = false,
    this.popOnSuccess = false,
    this.isInitialAppLogin = false,
    this.routeOnSuccessArguments,
    this.secureStore = const SecureStorageWrapper(
      FlutterSecureStorage(),
    ),
    this.biometrics = const Biometrics(),
    this.onSuccess,
  }) : super(key: key);

  static const String routeName = "/lockscreen";

  final String routeOnSuccess;
  final Object? routeOnSuccessArguments;
  final bool showBackButton;
  final bool popOnSuccess;
  final bool isInitialAppLogin;
  final String biometricsAuthenticationTitle;
  final String biometricsLocalizedReason;
  final String biometricsCancelButtonString;
  final FlutterSecureStorageInterface secureStore;
  final Biometrics biometrics;
  final VoidCallback? onSuccess;

  @override
  ConsumerState<LockscreenView> createState() => _LockscreenViewState();
}

class _LockscreenViewState extends ConsumerState<LockscreenView> {
  late final ShakeController _shakeController;

  late int _attempts;
  bool _attemptLock = false;
  late Duration _timeout;
  static const maxAttemptsBeforeThrottling = 3;
  Timer? _timer;

  Future<void> _onUnlock() async {
    final now = DateTime.now().toUtc();
    ref.read(prefsChangeNotifierProvider).lastUnlocked =
        now.millisecondsSinceEpoch ~/ 1000;

    // if (widget.isInitialAppLogin) {
    //   ref.read(hasAuthenticatedOnStartStateProvider.state).state = true;
    //   ref.read(shouldShowLockscreenOnResumeStateProvider.state).state = true;
    // }

    widget.onSuccess?.call();

    if (widget.popOnSuccess) {
      Navigator.of(context).pop(widget.routeOnSuccessArguments);
    } else {
      unawaited(Navigator.of(context).pushReplacementNamed(
        widget.routeOnSuccess,
        arguments: widget.routeOnSuccessArguments,
      ));
      if (widget.routeOnSuccess == HomeView.routeName &&
          widget.routeOnSuccessArguments is String) {
        final walletId = widget.routeOnSuccessArguments as String;
        unawaited(
          Navigator.of(context).pushNamed(
            WalletView.routeName,
            arguments: Tuple2(
              walletId,
              ref.read(walletProvider)!,
            ),
          ),
        );
      }
    }
  }

  Future<void> _checkUseBiometrics() async {
    if (!ref.read(prefsChangeNotifierProvider).isInitialized) {
      await ref.read(prefsChangeNotifierProvider).init();
    }

    final bool useBiometrics =
        ref.read(prefsChangeNotifierProvider).useBiometrics;

    final title = widget.biometricsAuthenticationTitle;
    final localizedReason = widget.biometricsLocalizedReason;
    final cancelButtonText = widget.biometricsCancelButtonString;

    if (useBiometrics) {
      if (await biometrics.authenticate(
          title: title,
          localizedReason: localizedReason,
          cancelButtonText: cancelButtonText)) {
        // check if initial log in
        // if (widget.routeOnSuccess == "/mainview") {
        //   await logIn(await walletsService.networkName, currentWalletName,
        //       await walletsService.getWalletId(currentWalletName));
        // }

        unawaited(_onUnlock());
      }
      // leave this commented to enable pin fall back should biometrics not work properly
      // else {
      //   Navigator.pop(context);
      // }
    }
  }

  @override
  void initState() {
    _shakeController = ShakeController();

    _secureStore = widget.secureStore;
    biometrics = widget.biometrics;
    _attempts = 0;
    _timeout = Duration.zero;

    _checkUseBiometrics();
    super.initState();
  }

  @override
  dispose() {
    // _shakeController.dispose();
    super.dispose();
  }

  BoxDecoration get _pinPutDecoration {
    return const BoxDecoration(
      color: Colors.transparent,
    );
  }

  final _pinTextController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  late FlutterSecureStorageInterface _secureStore;
  late Biometrics biometrics;

  Widget get _body => Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: widget.showBackButton
                ? AppBarBackButton(
                    onPressed: () async {
                      if (FocusScope.of(context).hasFocus) {
                        FocusScope.of(context).unfocus();
                        await Future<void>.delayed(
                            const Duration(milliseconds: 70));
                      }
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  )
                : Container(),
          ),
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Shake(
                  animationDuration: const Duration(milliseconds: 700),
                  animationRange: 12,
                  controller: _shakeController,
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Text(
                            "Enter PIN",
                            style: STextStyles.titleH2(context).copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textGold,
                            ),
                          ),
                        ),
                        MediaQuery.of(context).size.height > 600
                            ? const SizedBox(
                                height: 52,
                              )
                            : const SizedBox(
                                height: 12,
                              ),
                        CustomPinPut(
                          fieldsCount: Constants.pinLength,
                          textStyle: STextStyles.label(context).copyWith(
                            fontSize: 1,
                          ),
                          focusNode: _pinFocusNode,
                          controller: _pinTextController,
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
                            _attempts++;

                            if (_attempts > maxAttemptsBeforeThrottling) {
                              _attemptLock = true;
                              switch (_attempts) {
                                case 4:
                                  _timeout = const Duration(seconds: 30);
                                  break;

                                case 5:
                                  _timeout = const Duration(seconds: 60);
                                  break;

                                case 6:
                                  _timeout = const Duration(minutes: 5);
                                  break;

                                case 7:
                                  _timeout = const Duration(minutes: 10);
                                  break;

                                case 8:
                                  _timeout = const Duration(minutes: 20);
                                  break;

                                case 9:
                                  _timeout = const Duration(minutes: 30);
                                  break;

                                default:
                                  _timeout = const Duration(minutes: 60);
                              }

                              _timer?.cancel();
                              _timer = Timer(_timeout, () {
                                _attemptLock = false;
                                _attempts = 0;
                              });
                            }

                            if (_attemptLock) {
                              String prettyTime = "";
                              if (_timeout.inSeconds >= 60) {
                                prettyTime += "${_timeout.inMinutes} minutes";
                              } else {
                                prettyTime += "${_timeout.inSeconds} seconds";
                              }
                              _pinTextController.text = '';
                              await showDialog<void>(
                                context: context,
                                builder: (context) {
                                  return FullScreenMessage(
                                    icon: SvgPicture.asset(
                                      Assets.svg.circleRedX,
                                    ),
                                    message:
                                        "Incorrect PIN entered too many times.\nPlease wait $prettyTime",
                                    duration: const Duration(seconds: 2),
                                  );
                                },
                              );

                              return;
                            }

                            final storedPin =
                                await _secureStore.read(key: 'stack_pin');

                            if (storedPin == pin) {
                              await Future<void>.delayed(
                                  const Duration(milliseconds: 200));
                              unawaited(_onUnlock());
                            } else {
                              unawaited(_shakeController.shake());

                              _pinTextController.text = '';

                              await showDialog<void>(
                                context: context,
                                builder: (context) {
                                  return FullScreenMessage(
                                    icon: SvgPicture.asset(
                                      Assets.svg.circleRedX,
                                    ),
                                    message: "Incorrect PIN."
                                        "\nPlease try again.",
                                    duration: const Duration(seconds: 2),
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return widget.showBackButton
        ? _body
        : WillPopScope(
            onWillPop: () async {
              return widget.showBackButton;
            },
            child: _body,
          );
  }
}
