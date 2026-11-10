import 'package:flutter/material.dart';

import '../../utilities/native_library_check.dart';
import '../../utilities/util.dart';
import '../stack_dialog.dart';

String nativeLibraryWarningTitle(List<NativeLibraryFailure> failures) =>
    failures.length == 1
    ? "A required file could not be loaded"
    : "Some required files could not be loaded";

String nativeLibraryWarningMessage(List<NativeLibraryFailure> failures) => [
  for (final f in failures) nativeLibraryErrorMessage(f.displayName, f.result),
].join("\n\n");

/// Shows what the startup check found, once, the first time a home view
/// appears after launch. Only the message changes hands: wallets open as
/// they always have, so a broken library never locks anyone out of a seed
/// they can still reach through wallet settings.
Future<void> showNativeLibraryWarningIfRequired(BuildContext context) {
  // Taken only once there is a live context to show them in, so a home
  // view replaced within its first frame leaves them for the next one.
  if (!context.mounted) return Future.value();
  final failures = takeNativeLibraryFailures();
  if (failures.isEmpty) return Future.value();

  return showDialog<void>(
    context: context,
    builder: (_) => StackOkDialog(
      title: nativeLibraryWarningTitle(failures),
      message: nativeLibraryWarningMessage(failures),
      desktopPopRootNavigator: true,
      maxWidth: Util.isDesktop ? 500 : null,
    ),
  );
}
