import 'dart:async';

import 'package:flutter/foundation.dart';

import 'open_alias.dart';
import 'send_recipient.dart';

class ResolvedSendRecipient {
  final String destination;
  final OpenAliasRecipient? alias;

  const ResolvedSendRecipient(this.destination, [this.alias]);
}

// One instance per send screen, never shared between wallets. Invalidating an
// attempt prevents late lookup/preparation results from reaching confirmation.
class SendPreview extends ChangeNotifier {
  SendPreviewAttempt? _active;
  bool _disposed = false;

  bool get busy => _active != null;

  Future<void> run({
    required String walletId,
    required String source,
    required bool Function() isCurrent,
    required Future<void> Function(SendPreviewAttempt) work,
    required void Function(Object, StackTrace) onError,
  }) async {
    if (_disposed || busy || !isCurrent()) return;
    final attempt = SendPreviewAttempt._(this, walletId, source, isCurrent);
    _active = attempt;
    notifyListeners();
    try {
      await work(attempt);
    } on _StalePreview {
      // A new edit, cancellation, wallet, or screen owns the user's intent.
    } catch (error, stack) {
      if (attempt.isCurrent) onError(error, stack);
    } finally {
      attempt._close();
      if (identical(_active, attempt)) {
        _active = null;
        if (!_disposed) notifyListeners();
      }
    }
  }

  void invalidate() {
    final attempt = _active;
    _active = null;
    attempt?._close();
    if (attempt != null && !_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    invalidate();
    super.dispose();
  }
}

class SendPreviewAttempt {
  final SendPreview _owner;
  final String walletId;
  final String source;
  final bool Function() _isCurrent;
  final _cleanup = <VoidCallback>[];

  SendPreviewAttempt._(
    this._owner,
    this.walletId,
    this.source,
    this._isCurrent,
  );

  bool get isCurrent =>
      !_owner._disposed && identical(_owner._active, this) && _isCurrent();

  void checkCurrent() {
    if (!isCurrent) throw const _StalePreview();
  }

  void cancel() {
    if (identical(_owner._active, this)) _owner.invalidate();
  }

  void onClose(VoidCallback cleanup) {
    checkCurrent();
    _cleanup.add(cleanup);
  }

  void _close() {
    for (final cleanup in _cleanup) {
      cleanup();
    }
    _cleanup.clear();
  }

  Future<ResolvedSendRecipient> resolve({
    required bool supportsOpenAlias,
    required bool Function(String) validateAddress,
    required Future<OpenAliasRecipient> Function(String) lookup,
  }) async {
    checkCurrent();
    // Non-Monero destinations retain their existing coin-specific handling
    // (including Spark, PayNym and slatepack).
    if (!supportsOpenAlias) return ResolvedSendRecipient(source);
    final input = SendRecipient.classify(
      source,
      supportsOpenAlias: true,
      validateAddress: validateAddress,
    );
    if (input.kind == SendRecipientKind.literal) {
      return ResolvedSendRecipient(input.destination);
    }
    if (!input.isAlias) {
      throw const OpenAliasException('Enter a valid address or OpenAlias.');
    }
    final recipient = await lookup(input.destination);
    checkCurrent();
    if (!validateAddress(recipient.address) ||
        recipient.domain != input.destination) {
      throw const OpenAliasException(
        'OpenAlias did not return a valid recipient for this wallet.',
      );
    }
    return ResolvedSendRecipient(recipient.address, recipient);
  }
}

class _StalePreview implements Exception {
  const _StalePreview();
}
