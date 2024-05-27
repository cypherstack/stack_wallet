import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../notifications/show_flush_bar.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../conditional_parent.dart';
import '../../desktop/secondary_button.dart';
import '../../rounded_container.dart';
import '../../rounded_white_container.dart';
import '../simple_mobile_dialog.dart';

class FrostStepQrDialog extends StatefulWidget {
  const FrostStepQrDialog({
    super.key,
    required this.myName,
    required this.title,
    required this.data,
  });

  final String myName;
  final String title;
  final String data;

  @override
  State<FrostStepQrDialog> createState() => _FrostStepQrDialogState();
}

class _FrostStepQrDialogState extends State<FrostStepQrDialog> {
  final _qrKey = GlobalKey();

  Future<void> _capturePng(bool shouldSaveInsteadOfShare) async {
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      if (shouldSaveInsteadOfShare) {
        if (Util.isDesktop) {
          final dir = Directory("${Platform.environment['HOME']}");
          if (!dir.existsSync()) {
            throw Exception(
              "Home dir not found while trying to open filepicker on QR image save",
            );
          }
          final path = await FilePicker.platform.saveFile(
            fileName: "qrcode.png",
            initialDirectory: dir.path,
          );

          if (path != null && context.mounted) {
            final file = File(path);
            if (file.existsSync()) {
              unawaited(
                showFloatingFlushBar(
                  type: FlushBarType.warning,
                  message: "$path already exists!",
                  context: context,
                ),
              );
            } else {
              await file.writeAsBytes(pngBytes);
              unawaited(
                showFloatingFlushBar(
                  type: FlushBarType.success,
                  message: "$path saved!",
                  context: context,
                ),
              );
            }
          }
        } else {
          //   await DocumentFileSavePlus.saveFile(
          //       pngBytes,
          //       "receive_qr_code_${DateTime.now().toLocal().toIso8601String()}.png",
          //       "image/png");
        }
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = await File("${tempDir.path}/qrcode.png").create();
        await file.writeAsBytes(pngBytes);

        await Share.shareFiles(
          ["${tempDir.path}/qrcode.png"],
          text: "Receive URI QR Code",
        );
      }
    } catch (e) {
      //todo: comeback to this
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleMobileDialog(
      showCloseButton: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            key: _qrKey,
            child: RoundedWhiteContainer(
              boxShadow: [
                Theme.of(context).extension<StackColors>()!.standardBoxShadow,
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.myName,
                    style: STextStyles.w600_16(context).copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .customTextButtonEnabledText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.title,
                    style: STextStyles.w600_12(context),
                  ),
                  const SizedBox(height: 8),
                  RoundedContainer(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textFieldDefaultBG,
                    radiusMultiplier: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ConditionalParent(
                          condition: Util.isDesktop,
                          builder: (child) => ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 360,
                            ),
                            child: child,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: QrImageView(
                                data: widget.data,
                                padding: EdgeInsets.zero,
                                foregroundColor: Theme.of(context)
                                    .extension<StackColors>()!
                                    .accentColorDark,
                                // dataModuleStyle: QrDataModuleStyle(
                                //   dataModuleShape: QrDataModuleShape.square,
                                //   color: Theme.of(context)
                                //       .extension<StackColors>()!
                                //       .accentColorDark,
                                // ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          widget.data,
                          style: STextStyles.w500_10(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!Util.isDesktop)
            const SizedBox(
              height: 16,
            ),
          if (!Util.isDesktop)
            Row(
              children: [
                const Spacer(),
                const SizedBox(width: 16),
                Expanded(
                  child: SecondaryButton(
                    label: "Share",
                    icon: SvgPicture.asset(
                      Assets.svg.share,
                      width: 14,
                      height: 14,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .buttonTextSecondary,
                    ),
                    onPressed: () async {
                      await _capturePng(false);
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
