import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mutex/mutex.dart';

import '../../notifications/show_flush_bar.dart';
import '../../providers/global/duress_provider.dart';
import '../../providers/global/prefs_provider.dart';
import '../../providers/global/secure_store_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/biometrics.dart';
import '../../utilities/flutter_secure_storage_interface.dart';
import '../../utilities/text_styles.dart';
import '../../widgets/custom_pin_put/custom_pin_put.dart';
import '../../widgets/shake/shake.dart';
import '../../widgets/stack_dialog.dart';
import 'lock_screen_view.dart';

class PinpadDialog extends ConsumerStatefulWidget {
  const PinpadDialog({
    super.key,
    required this.biometricsAuthenticationTitle,
    required this.biometricsLocalizedReason,
    required this.biometricsCancelButtonString,
    this.biometrics = const Biometrics(),
    this.customKeyLabel = "Button",
  });

  final String biometricsAuthenticationTitle;
  final String biometricsLocalizedReason;
  final String biometricsCancelButtonString;
  final Biometrics biometrics;
  final String customKeyLabel;

  @override
  ConsumerState<PinpadDialog> createState() => _PinpadDialogState();
}

class _PinpadDialogState extends ConsumerState<PinpadDialog> {
  late final ShakeController _shakeController;

  late final bool _autoPin;

  late int _attempts;
  bool _attemptLock = false;
  late Duration _timeout;
  static const maxAttemptsBeforeThrottling = 3;
  Timer? _timer;

  final FocusNode _pinFocusNode = FocusNode();

  late SecureStorageInterface _secureStore;
  late Biometrics biometrics;
  int pinCount = 1;

  final _pinTextController = TextEditingController();

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

  final Mutex _autoPinCheckLock = Mutex();
  void _onPinChangedAutologinCheck() async {
    if (mounted) {
      await _autoPinCheckLock.acquire();
    }

    try {
      if (_autoPin && _pinTextController.text.length >= 4) {
        final String? storedPin;
        if (ref.read(pDuress)) {
          storedPin = await _secureStore.read(key: kDuressPinKey);
        } else {
          storedPin = await _secureStore.read(key: kPinKey);
        }
        if (_pinTextController.text == storedPin) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          unawaited(_onUnlock());
        }
      }
    } finally {
      _autoPinCheckLock.release();
    }
  }

  Future<void> _onUnlock() async {
    final now = DateTime.now().toUtc();
    ref.read(prefsChangeNotifierProvider).lastUnlocked =
        now.millisecondsSinceEpoch ~/ 1000;

    Navigator.of(context).pop("verified success");
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
        cancelButtonText: cancelButtonText,
      )) {
        unawaited(_onUnlock());
      }
      // leave this commented to enable pin fall back should biometrics not work properly
      // else {
      //   Navigator.pop(context);
      // }
    }
  }

  Future<void> _onSubmit(String pin) async {
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

      unawaited(
        showFloatingFlushBar(
          type: FlushBarType.warning,
          message:
              "Incorrect PIN entered too many times. Please wait $prettyTime",
          context: context,
          iconAsset: Assets.svg.alertCircle,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      _pinTextController.text = '';

      return;
    }

    final String? storedPin;
    if (ref.read(pDuress)) {
      storedPin = await _secureStore.read(key: kDuressPinKey);
    } else {
      storedPin = await _secureStore.read(key: kPinKey);
    }

    if (mounted) {
      if (storedPin == pin) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        unawaited(_onUnlock());
      } else {
        unawaited(_shakeController.shake());
        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.warning,
            message: "Incorrect PIN. Please try again",
            context: context,
            iconAsset: Assets.svg.alertCircle,
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 100));

        _pinTextController.text = '';
      }
    }
  }

  @override
  void initState() {
    _shakeController = ShakeController();

    _secureStore = ref.read(secureStoreProvider);
    biometrics = widget.biometrics;
    _attempts = 0;
    _timeout = Duration.zero;
    _autoPin = ref.read(prefsChangeNotifierProvider).autoPin;
    if (_autoPin) {
      _pinTextController.addListener(_onPinChangedAutologinCheck);
    }

    _checkUseBiometrics();
    super.initState();
  }

  @override
  dispose() {
    // _shakeController.dispose();
    _pinTextController.removeListener(_onPinChangedAutologinCheck);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StackDialogBase(
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
                      style: STextStyles.pageTitleH1(context),
                    ),
                  ),
                  const SizedBox(height: 40),
                  CustomPinPut(
                    fieldsCount: pinCount,
                    eachFieldHeight: 12,
                    eachFieldWidth: 12,
                    textStyle: STextStyles.label(context).copyWith(fontSize: 1),
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
                      fillColor:
                          Theme.of(context).extension<StackColors>()!.popupBG,
                      counterText: "",
                    ),
                    submittedFieldDecoration: _pinPutDecoration,
                    isRandom:
                        ref.read(prefsChangeNotifierProvider).randomizePIN,
                    onSubmit: (pin) {
                      if (!_autoPinCheckLock.isLocked) {
                        _onSubmit(pin);
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
