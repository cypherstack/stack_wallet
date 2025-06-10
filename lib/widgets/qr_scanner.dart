import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../themes/stack_colors.dart';
import '../utilities/logger.dart';
import '../utilities/text_styles.dart';
import 'background.dart';
import 'custom_buttons/app_bar_icon_button.dart';

class QrScanner extends ConsumerWidget {
  const QrScanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.backgroundAppBar,
          leading: const AppBarBackButton(),
          title: Text("Scan QR code", style: STextStyles.navBarTitle(context)),
        ),
        body: MobileScanner(
          onDetect: (capture) {
            final data =
                ((capture.raw as Map?)?["data"] as List?)?.firstOrNull as Map?;

            final value =
                data?["rawValue"] as String? ??
                data?["displayValue"] as String?;

            Navigator.of(context).pop(value);
          },
          onDetectError: (error, stackTrace) {
            Logging.instance.w(
              "Mobile scanner",
              error: error,
              stackTrace: stackTrace,
            );
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
