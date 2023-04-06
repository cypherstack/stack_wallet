import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class XPubView extends ConsumerStatefulWidget {
  const XPubView({
    Key? key,
    this.xpub,
    this.clipboardInterface = const ClipboardWrapper(),
  }) : super(key: key);

  final String? xpub;
  final ClipboardInterface clipboardInterface;

  static const String routeName = "/xpub";

  @override
  ConsumerState<XPubView> createState() => _XPubViewState();
}

class _XPubViewState extends ConsumerState<XPubView> {
  late ClipboardInterface _clipboardInterface;

  @override
  void initState() {
    _clipboardInterface = widget.clipboardInterface;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _copy() async {
    await _clipboardInterface.setData(ClipboardData(text: widget.xpub));
    unawaited(showFloatingFlushBar(
      type: FlushBarType.info,
      message: "Copied to clipboard",
      iconAsset: Assets.svg.copy,
      context: context,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
            leading: AppBarBackButton(
              onPressed: () async {
                Navigator.of(context).pop();
              },
            ),
            title: Text(
              "Wallet xPub",
              style: STextStyles.navBarTitle(context),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AppBarIconButton(
                    color:
                        Theme.of(context).extension<StackColors>()!.background,
                    shadows: const [],
                    icon: SvgPicture.asset(
                      Assets.svg.copy,
                      width: 24,
                      height: 24,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .topNavIconPrimary,
                    ),
                    onPressed: () async {
                      await _copy();
                    },
                  ),
                ),
              ),
            ]),
        body: Padding(
          padding: const EdgeInsets.only(
            top: 12,
            left: 16,
            right: 16,
          ),
          child: Column(children: [
            if (widget.xpub != null)
              RoundedWhiteContainer(
                padding: const EdgeInsets.all(12),
                child: QrImage(data: widget.xpub!),
                onPressed: () => _copy(),
              ),
            if (widget.xpub != null)
              const SizedBox(
                height: 8,
              ),
            if (widget.xpub != null)
              RoundedWhiteContainer(
                padding: const EdgeInsets.all(12),
                child: Text(widget.xpub!,
                    style: STextStyles.largeMedium14(context)),
                onPressed: () => _copy(),
              )
          ]),
        ),
      ),
    );
  }
}
