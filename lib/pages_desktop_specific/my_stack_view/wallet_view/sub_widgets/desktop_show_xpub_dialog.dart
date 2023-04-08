import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/mixins/xpubable.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class DesktopShowXpubDialog extends ConsumerStatefulWidget {
  const DesktopShowXpubDialog({
    Key? key,
    required this.walletId,
    this.clipboardInterface = const ClipboardWrapper(),
  }) : super(key: key);

  final String walletId;

  final ClipboardInterface clipboardInterface;

  static const String routeName = "/desktopShowXpubDialog";

  @override
  ConsumerState<DesktopShowXpubDialog> createState() =>
      _DesktopShowXpubDialog();
}

class _DesktopShowXpubDialog extends ConsumerState<DesktopShowXpubDialog> {
  late ClipboardInterface _clipboardInterface;
  late final Manager manager;

  String? xpub;

  @override
  void initState() {
    _clipboardInterface = widget.clipboardInterface;
    manager =
        ref.read(walletsChangeNotifierProvider).getManager(widget.walletId);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _copy() async {
    await _clipboardInterface.setData(ClipboardData(text: xpub!));
    if (mounted) {
      unawaited(showFloatingFlushBar(
        type: FlushBarType.info,
        message: "Copied to clipboard",
        iconAsset: Assets.svg.copy,
        context: context,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      maxWidth: 600,
      maxHeight: double.infinity,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 32,
                ),
                child: Text(
                  "${manager.walletName} xPub",
                  style: STextStyles.desktopH2(context),
                ),
              ),
              DesktopDialogCloseButton(
                onPressedOverride: Navigator.of(
                  context,
                  rootNavigator: true,
                ).pop,
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Column(
                children: [
                  const SizedBox(height: 44),
                  FutureBuilder(
                    future: (manager.wallet as XPubAble).xpub,
                    builder: (context, AsyncSnapshot<String> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        xpub = snapshot.data!;
                      }

                      return Column(
                        children: [
                          xpub == null
                              ? const SizedBox(
                                  height: 300,
                                  child: LoadingIndicator(),
                                )
                              : QrImage(
                                  data: xpub!,
                                  size: 280,
                                  foregroundColor: Theme.of(context)
                                      .extension<StackColors>()!
                                      .accentColorDark,
                                ),
                          const SizedBox(height: 25),
                          RoundedWhiteContainer(
                            padding: const EdgeInsets.all(16),
                            borderColor: xpub == null
                                ? null
                                : Theme.of(context)
                                    .extension<StackColors>()!
                                    .backgroundAppBar,
                            child: SelectableText(
                              xpub ?? "",
                              style: STextStyles.largeMedium14(context),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: SecondaryButton(
                                  buttonHeight: ButtonHeight.xl,
                                  label: "Cancel",
                                  onPressed: Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: PrimaryButton(
                                  buttonHeight: ButtonHeight.xl,
                                  label: "Copy",
                                  enabled: xpub != null,
                                  onPressed: _copy,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
