import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class AddressQrPopup extends StatefulWidget {
  const AddressQrPopup({
    Key? key,
    required this.address,
    required this.coin,
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  final Address address;
  final Coin coin;
  final ClipboardInterface clipboard;

  @override
  State<AddressQrPopup> createState() => _AddressQrPopupState();
}

class _AddressQrPopupState extends State<AddressQrPopup> {
  final _qrKey = GlobalKey();
  final isDesktop = Util.isDesktop;

  Future<void> _capturePng(bool shouldSaveInsteadOfShare) async {
    try {
      RenderRepaintBoundary boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      if (shouldSaveInsteadOfShare) {
        if (isDesktop) {
          final dir = Directory("${Platform.environment['HOME']}");
          if (!dir.existsSync()) {
            throw Exception(
                "Home dir not found while trying to open filepicker on QR image save");
          }
          final path = await FilePicker.platform.saveFile(
            fileName: "qrcode.png",
            initialDirectory: dir.path,
          );

          if (path != null) {
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

        await Share.shareFiles(["${tempDir.path}/qrcode.png"],
            text: "Receive URI QR Code");
      }
    } catch (e) {
      //todo: comeback to this
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return StackDialogBase(
      child: Column(
        children: [
          Text(
            "todo: custom label",
            style: STextStyles.pageTitleH2(context),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            widget.address.value,
            style: STextStyles.itemSubtitle(context),
          ),
          const SizedBox(
            height: 16,
          ),
          Center(
            child: RepaintBoundary(
              key: _qrKey,
              child: QrImage(
                data: AddressUtils.buildUriString(
                  widget.coin,
                  widget.address.value,
                  {},
                ),
                size: 220,
                backgroundColor:
                    Theme.of(context).extension<StackColors>()!.popupBG,
                foregroundColor:
                    Theme.of(context).extension<StackColors>()!.accentColorDark,
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  width: 170,
                  buttonHeight: isDesktop ? ButtonHeight.l : null,
                  onPressed: () async {
                    await _capturePng(false);
                  },
                  label: "Share",
                  icon: SvgPicture.asset(
                    Assets.svg.share,
                    width: 20,
                    height: 20,
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .buttonTextSecondary,
                  ),
                ),
              ),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child: PrimaryButton(
                  width: 170,
                  onPressed: () async {
                    await _capturePng(true);
                  },
                  label: "Save",
                  icon: SvgPicture.asset(
                    Assets.svg.arrowDown,
                    width: 20,
                    height: 20,
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .buttonTextPrimary,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
