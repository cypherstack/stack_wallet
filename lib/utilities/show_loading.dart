import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/widgets/custom_loading_overlay.dart';

Future<T> showLoading<T>({
  required Future<T> whileFuture,
  required BuildContext context,
  required String message,
  String? subMessage,
  bool isDesktop = false,
  bool opaqueBG = false,
}) async {
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: Container(
          color: Theme.of(context)
              .extension<StackColors>()!
              .overlay
              .withOpacity(opaqueBG ? 1.0 : 0.6),
          child: CustomLoadingOverlay(
            message: message,
            subMessage: subMessage,
            eventBus: null,
          ),
        ),
      ),
    ),
  );

  final result = await whileFuture;

  if (context.mounted) {
    Navigator.of(context, rootNavigator: isDesktop).pop();
  }

  return result;
}
