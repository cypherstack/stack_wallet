import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> simulateSystemBack() {
  return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        'flutter/navigation',
        const JSONMessageCodec().encodeMessage(<String, dynamic>{
          'method': 'popRoute',
        }),
        (ByteData? _) {},
      );
}

Future<void> startPredictiveBackGesture() {
  return _sendBackGesture(
    const MethodCall('startBackGesture', <String, dynamic>{
      'touchOffset': <double>[5, 300],
      'progress': 0.0,
      'swipeEdge': 0,
    }),
  );
}

Future<void> updatePredictiveBackGesture(double progress) {
  return _sendBackGesture(
    MethodCall('updateBackGestureProgress', <String, dynamic>{
      'x': 5 + (300 * progress),
      'y': 300.0,
      'progress': progress,
      'swipeEdge': 0,
    }),
  );
}

Future<void> commitPredictiveBackGesture() {
  return _sendBackGesture(const MethodCall('commitBackGesture'));
}

Future<void> cancelPredictiveBackGesture() {
  return _sendBackGesture(const MethodCall('cancelBackGesture'));
}

Future<void> _sendBackGesture(MethodCall call) {
  return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        'flutter/backgesture',
        const StandardMethodCodec().encodeMethodCall(call),
        (ByteData? _) {},
      );
}
