/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2026 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Adapts async pop approval to [PopScope] and coalesces repeated attempts.
class AsyncPopScope<T> extends StatefulWidget {
  const AsyncPopScope({
    super.key,
    required this.onPopAttempt,
    required this.child,
  });

  final Future<bool> Function() onPopAttempt;
  final Widget child;

  @override
  State<AsyncPopScope<T>> createState() => _AsyncPopScopeState<T>();
}

class _AsyncPopScopeState<T> extends State<AsyncPopScope<T>> {
  bool _handlingPop = false;

  Future<void> _handlePop(T? result) async {
    try {
      final shouldPop = await widget.onPopAttempt();
      if (!shouldPop || !mounted) {
        return;
      }
      final route = ModalRoute.of(context);
      if (route == null || !route.isCurrent) {
        return;
      }
      // `Route.popDisposition` is `bubble` on the first route, so the replaced
      // `WillPopScope` handed an approved back press to the platform (Android
      // backgrounds the app) rather than emptying the navigator.
      if (route.isFirst) {
        await SystemNavigator.pop();
        return;
      }
      Navigator.of(context).pop<T>(result);
    } finally {
      _handlingPop = false;
    }
  }

  void _onPopInvoked(bool didPop, T? result) {
    if (didPop || _handlingPop) {
      return;
    }

    _handlingPop = true;
    unawaited(_handlePop(result));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<T>(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
      child: widget.child,
    );
  }
}
