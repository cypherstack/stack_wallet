import 'dart:io';

import 'package:socks5_proxy/exceptions.dart';

import 'logger.dart';

// TODO: remove once socks5_proxy handles failures inside its ConnectionTask
// cancel callbacks (https://github.com/LacticWhale/socks_dart/issues/19) and
// the dependency is bumped past 2.1.1.
//
// socks5_proxy 2.x passes `async` closures as the cancel callbacks of the
// ConnectionTasks it hands to HttpClient.  cancel() takes a void Function(),
// so the closure's future is dropped.  HttpClient cancels on connectionTimeout
// and on close() while a connect is pending; if the SOCKS or TLS connect then
// fails, the closure rethrows into nothing and the error reaches the root
// isolate's unhandled-error hook.  The request itself has already failed with
// a normal, caught exception by then, so this duplicate is pure noise.  Only
// proxied (Tor) HttpClients that get closed mid-connect are affected, which
// today means the Stellar wallet's node/Tor preference changes.
//
// Handled here instead of at the call sites because a try/catch around the
// request cannot see it.

/// Returns true if [error] is the late, duplicate failure of a cancelled
/// socks5_proxy connection, logging it as a warning.
bool handleSocks5ProxyCancelLeak(Object error, StackTrace stack) {
  final fromSocks5Proxy =
      error is SocksClientException ||
      (error is HandshakeException &&
          stack.toString().contains("socks5_proxy"));
  if (!fromSocks5Proxy) {
    return false;
  }

  Logging.instance.w(
    "Ignoring late failure of a cancelled socks5_proxy connection",
    error: error,
    stackTrace: stack,
  );
  return true;
}
