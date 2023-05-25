import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/home_view/home_view.dart';
import 'package:stackwallet/pages/wallet_view/wallet_view.dart';
// import 'package:stackwallet/providers/global/has_authenticated_start_state_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
// import 'package:stackwallet/providers/global/should_show_lockscreen_on_resume_state_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/biometrics.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/show_loading.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/custom_pin_put/custom_pin_put.dart';
import 'package:stackwallet/widgets/shake/shake.dart';
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
    this.biometrics = const Biometrics(),
    this.onSuccess,
    this.customKeyLabel = "Button",
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
  final Biometrics biometrics;
  final VoidCallback? onSuccess;
  final String customKeyLabel;

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
      final loadIntoWallet = widget.routeOnSuccess == HomeView.routeName &&
          widget.routeOnSuccessArguments is String;

      if (loadIntoWallet) {
        final walletId = widget.routeOnSuccessArguments as String;

        final manager =
            ref.read(walletsChangeNotifierProvider).getManager(walletId);
        if (manager.coin == Coin.monero) {
          await showLoading(
            opaqueBG: true,
            whileFuture: manager.initializeExisting(),
            context: context,
            message: "Loading ${manager.coin.prettyName} wallet...",
          );
        }
      }

      if (mounted) {
        unawaited(
          Navigator.of(context).pushReplacementNamed(
            widget.routeOnSuccess,
            arguments: widget.routeOnSuccessArguments,
          ),
        );

        if (loadIntoWallet) {
          final walletId = widget.routeOnSuccessArguments as String;

          unawaited(
            Navigator.of(context).pushNamed(
              WalletView.routeName,
              arguments: Tuple2(
                walletId,
                ref
                    .read(walletsChangeNotifierProvider)
                    .getManagerProvider(walletId),
              ),
            ),
          );
        }
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
  void didChangeDependencies() {
    if (widget.isInitialAppLogin) {
      // unawaited(Assets.precache(context));
    }
    super.didChangeDependencies();
  }

  @override
  void initState() {
    _shakeController = ShakeController();

    _secureStore = ref.read(secureStoreProvider);
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
    return BoxDecoration(
      color: Theme.of(context).extension<StackColors>()!.infoItemIcons,
      border: Border.all(
        width: 1,
        color: Theme.of(context).extension<StackColors>()!.infoItemIcons,
      ),
      borderRadius: BorderRadius.circular(6),
    );
  }

  final _pinTextController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  late SecureStorageInterface _secureStore;
  late Biometrics biometrics;
  int pinCount = 1;

  Widget get _body => Background(
        child: SafeArea(
          child: Scaffold(
            extendBodyBehindAppBar: true,
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
              actions: [
                // check prefs and hide if user has biometrics toggle off?
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        right: 16.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (ref
                                  .read(prefsChangeNotifierProvider)
                                  .useBiometrics ==
                              true)
                            CustomTextButton(
                              text: "Use biometrics",
                              onTap: () async {
                                await _checkUseBiometrics();
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: Column(
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
                            style: STextStyles.pageTitleH1(context),
                          ),
                        ),
                        const SizedBox(
                          height: 52,
                        ),
                        CustomPinPut(
                          fieldsCount: pinCount,
                          eachFieldHeight: 12,
                          eachFieldWidth: 12,
                          textStyle: STextStyles.label(context).copyWith(
                            fontSize: 1,
                          ),
                          focusNode: _pinFocusNode,
                          controller: _pinTextController,
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
                          submittedFieldDecoration: _pinPutDecoration,
                          isRandom: ref
                              .read(prefsChangeNotifierProvider)
                              .randomizePIN,
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

                              unawaited(showFloatingFlushBar(
                                type: FlushBarType.warning,
                                message:
                                    "Incorrect PIN entered too many times. Please wait $prettyTime",
                                context: context,
                                iconAsset: Assets.svg.alertCircle,
                              ));

                              await Future<void>.delayed(
                                  const Duration(milliseconds: 100));

                              _pinTextController.text = '';

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
                              unawaited(showFloatingFlushBar(
                                type: FlushBarType.warning,
                                message: "Incorrect PIN. Please try again",
                                context: context,
                                iconAsset: Assets.svg.alertCircle,
                              ));

                              await Future<void>.delayed(
                                  const Duration(milliseconds: 100));

                              _pinTextController.text = '';
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
