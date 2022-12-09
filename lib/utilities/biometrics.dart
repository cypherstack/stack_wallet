import 'dart:io';

import 'package:epicpay/utilities/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:local_auth/auth_strings.dart';
import 'package:local_auth/local_auth.dart';

class Biometrics {
  static const integrationTestFlag =
      bool.fromEnvironment("IS_INTEGRATION_TEST");

  const Biometrics();

  static Future<bool> get hasBiometrics async {
    final LocalAuthentication localAuth = LocalAuthentication();

    final results = await Future.wait<bool>([
      localAuth.canCheckBiometrics,
      localAuth.isDeviceSupported(),
    ]);

    return results.first && results.last;
  }

  Future<bool> authenticate({
    required String cancelButtonText,
    required String localizedReason,
    required String title,
  }) async {
    if (!(Platform.isIOS || Platform.isAndroid)) {
      Logging.instance.log(
          "Tried to use Biometrics.authenticate() on a platform that is not Android or iOS! ...returning false.",
          level: LogLevel.Error);
      return false;
    }
    if (integrationTestFlag) {
      Logging.instance.log(
          "Tried to use Biometrics.authenticate() during integration testing. Returning false.",
          level: LogLevel.Warning);
      return false;
    }

    final LocalAuthentication localAuth = LocalAuthentication();

    final canCheckBiometrics = await localAuth.canCheckBiometrics;
    final isDeviceSupported = await localAuth.isDeviceSupported();

    debugPrint("canCheckBiometrics: $canCheckBiometrics");
    debugPrint("isDeviceSupported: $isDeviceSupported");

    if (canCheckBiometrics && isDeviceSupported) {
      List<BiometricType> availableSystems =
          await localAuth.getAvailableBiometrics();

      debugPrint("availableSystems: $availableSystems");

      //TODO properly handle caught exceptions
      if (Platform.isIOS) {
        if (availableSystems.contains(BiometricType.face)) {
          try {
            bool didAuthenticate = await localAuth.authenticate(
              biometricOnly: true,
              localizedReason: localizedReason,
              stickyAuth: true,
              iOSAuthStrings: const IOSAuthMessages(),
            );

            if (didAuthenticate) {
              return true;
            }
          } catch (e) {
            Logging.instance.log(
                "local_auth exception caught in Biometrics.authenticate(), e: $e",
                level: LogLevel.Error);
          }
        } else if (availableSystems.contains(BiometricType.fingerprint)) {
          try {
            bool didAuthenticate = await localAuth.authenticate(
              biometricOnly: true,
              localizedReason: localizedReason,
              stickyAuth: true,
              iOSAuthStrings: const IOSAuthMessages(),
            );

            if (didAuthenticate) {
              return true;
            }
          } catch (e) {
            Logging.instance.log(
                "local_auth exception caught in Biometrics.authenticate(), e: $e",
                level: LogLevel.Error);
          }
        }
      } else if (Platform.isAndroid) {
        if (availableSystems.contains(BiometricType.fingerprint)) {
          try {
            bool didAuthenticate = await localAuth.authenticate(
              biometricOnly: true,
              localizedReason: localizedReason,
              stickyAuth: true,
              androidAuthStrings: AndroidAuthMessages(
                biometricHint: "",
                cancelButton: cancelButtonText,
                signInTitle: title,
              ),
            );

            if (didAuthenticate) {
              return true;
            }
          } catch (e) {
            Logging.instance.log(
                "local_auth exception caught in Biometrics.authenticate(), e: $e",
                level: LogLevel.Error);
          }
        }
      }
    }

    // authentication failed
    return false;
  }
}
