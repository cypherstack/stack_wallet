/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 */

import 'dart:async';

import 'package:flutter/material.dart';

import '../notifications/show_flush_bar.dart';
import '../themes/stack_colors.dart';
import '../utilities/logger.dart';
import 'custom_loading_overlay.dart';
import 'desktop/secondary_button.dart';

export 'desktop/secondary_button.dart' show ButtonHeight;

class GenerateAddressButton extends StatefulWidget {
  const GenerateAddressButton({
    super.key,
    required this.generateAddress,
    this.onGenerated,
    this.buttonHeight,
  });

  final Future<void> Function() generateAddress;
  final VoidCallback? onGenerated;
  final ButtonHeight? buttonHeight;

  @override
  State<GenerateAddressButton> createState() => _GenerateAddressButtonState();
}

class _GenerateAddressButtonState extends State<GenerateAddressButton> {
  bool _isGenerating = false;

  Future<void> _generate() async {
    if (_isGenerating) {
      return;
    }

    setState(() => _isGenerating = true);

    final dialogContext = Completer<BuildContext>();
    final dialogClosed = showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) {
        if (!dialogContext.isCompleted) {
          dialogContext.complete(context);
        }
        return PopScope(
          canPop: false,
          child: Container(
            color: Theme.of(
              context,
            ).extension<StackColors>()!.overlay.withValues(alpha: 0.5),
            child: const CustomLoadingOverlay(
              message: "Generating address",
              eventBus: null,
            ),
          ),
        );
      },
    );

    Object? failure;
    try {
      await dialogContext.future;
      await widget.generateAddress();
    } catch (error, stackTrace) {
      failure = error;
      Logging.instance.e(
        "Failed to generate a receiving address",
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      final context = await dialogContext.future;
      if (context.mounted) {
        // Close this dialog's own route. A bare pop() would instead drop
        // whatever sits on top of the root navigator, stranding this
        // non dismissible dialog behind anything pushed above it (the idle
        // lockscreen, say) while generation was running.
        final route = ModalRoute.of(context);
        if (route != null) {
          if (route.isCurrent) {
            Navigator.of(context).pop();
          } else if (route.isActive) {
            Navigator.of(context).removeRoute(route);
          }
        }
      }
      await dialogClosed;
    }

    if (!mounted) {
      return;
    }

    setState(() => _isGenerating = false);
    if (failure == null) {
      widget.onGenerated?.call();
    } else {
      unawaited(
        showFloatingFlushBar(
          type: FlushBarType.warning,
          message: "Failed to generate a new address",
          context: context,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => SecondaryButton(
    label: "Generate new address",
    buttonHeight: widget.buttonHeight,
    enabled: !_isGenerating,
    onPressed: _generate,
  );
}
