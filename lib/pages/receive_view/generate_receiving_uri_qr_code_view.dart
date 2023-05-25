import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

// import 'package:document_file_save_plus/document_file_save_plus.dart';
import 'package:decimal/decimal.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class GenerateUriQrCodeView extends StatefulWidget {
  const GenerateUriQrCodeView({
    Key? key,
    required this.coin,
    required this.receivingAddress,
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  static const String routeName = "/generateUriQrCodeView";

  final Coin coin;
  final String receivingAddress;
  final ClipboardInterface clipboard;

  @override
  State<GenerateUriQrCodeView> createState() => _GenerateUriQrCodeViewState();
}

class _GenerateUriQrCodeViewState extends State<GenerateUriQrCodeView> {
  final _qrKey = GlobalKey();

  late TextEditingController amountController;
  late TextEditingController noteController;

  late final bool isDesktop;
  late String _uriString;
  bool didGenerate = false;

  final _amountFocusNode = FocusNode();
  final _noteFocusNode = FocusNode();

  Future<void> _capturePng(bool shouldSaveInsteadOfShare) async {
    try {
      RenderRepaintBoundary boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      if (shouldSaveInsteadOfShare) {
        if (Util.isDesktop) {
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

  String? _generateURI() {
    final amountString = amountController.text;
    final noteString = noteController.text;

    if (amountString.isNotEmpty && Decimal.tryParse(amountString) == null) {
      showFloatingFlushBar(
        type: FlushBarType.warning,
        message: "Invalid amount",
        context: context,
      );
      return null;
    }

    Map<String, String> queryParams = {};

    if (amountString.isNotEmpty) {
      queryParams["amount"] = amountString;
    }
    if (noteString.isNotEmpty) {
      queryParams["message"] = noteString;
    }

    String receivingAddress = widget.receivingAddress;
    if ((widget.coin == Coin.bitcoincash ||
            widget.coin == Coin.eCash ||
            widget.coin == Coin.bitcoincashTestnet) &&
        receivingAddress.contains(":")) {
      // remove cash addr prefix
      receivingAddress = receivingAddress.split(":").sublist(1).join();
    }

    final uriString = AddressUtils.buildUriString(
      widget.coin,
      receivingAddress,
      queryParams,
    );

    Logging.instance.log("Generated receiving QR code for: $uriString",
        level: LogLevel.Info);

    return uriString;
  }

  void onGeneratePressed() {
    final uriString = _generateURI();

    if (uriString == null) {
      return;
    }

    showDialog<dynamic>(
      context: context,
      useSafeArea: false,
      barrierDismissible: true,
      builder: (_) {
        final width = MediaQuery.of(context).size.width / 2;
        return StackDialogBase(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  "New QR code",
                  style: STextStyles.pageTitleH2(context),
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              Center(
                child: RepaintBoundary(
                  key: _qrKey,
                  child: SizedBox(
                    width: width + 20,
                    height: width + 20,
                    child: QrImage(
                        data: uriString,
                        size: width,
                        backgroundColor:
                            Theme.of(context).extension<StackColors>()!.popupBG,
                        foregroundColor: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorDark),
                  ),
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              Center(
                child: SizedBox(
                  width: width,
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
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    isDesktop = Util.isDesktop;

    String receivingAddress = widget.receivingAddress;
    if ((widget.coin == Coin.bitcoincash ||
            widget.coin == Coin.eCash ||
            widget.coin == Coin.bitcoincashTestnet) &&
        receivingAddress.contains(":")) {
      // remove cash addr prefix
      receivingAddress = receivingAddress.split(":").sublist(1).join();
    }

    _uriString = AddressUtils.buildUriString(
      widget.coin,
      receivingAddress,
      {},
    );

    amountController = TextEditingController();
    noteController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();

    _amountFocusNode.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) => Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: AppBarBackButton(
              onPressed: () async {
                if (FocusScope.of(context).hasFocus) {
                  FocusScope.of(context).unfocus();
                  await Future<void>.delayed(const Duration(milliseconds: 70));
                }
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            title: Text(
              "Generate QR code",
              style: STextStyles.navBarTitle(context),
            ),
          ),
          body: LayoutBuilder(
            builder: (buildContext, constraints) {
              return Padding(
                padding: const EdgeInsets.only(
                  left: 12,
                  top: 12,
                  right: 12,
                ),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 24,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: child,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      child: Padding(
        padding: isDesktop
            ? const EdgeInsets.only(
                top: 12,
                left: 32,
                right: 32,
                bottom: 32,
              )
            : const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: isDesktop ? MainAxisSize.min : MainAxisSize.max,
          children: [
            if (!isDesktop)
              RoundedWhiteContainer(
                child: Text(
                  "The new QR code with your address, amount and note will appear in the pop up window.",
                  style: STextStyles.itemSubtitle(context),
                ),
              ),
            if (!isDesktop)
              const SizedBox(
                height: 12,
              ),
            Text(
              "Amount (Optional)",
              style: isDesktop
                  ? STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textFieldActiveSearchIconRight,
                    )
                  : STextStyles.smallMed12(context),
              textAlign: TextAlign.left,
            ),
            SizedBox(
              height: isDesktop ? 10 : 8,
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius,
              ),
              child: TextField(
                autocorrect: Util.isDesktop ? false : true,
                enableSuggestions: Util.isDesktop ? false : true,
                controller: amountController,
                focusNode: _amountFocusNode,
                style: isDesktop
                    ? STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textFieldDefaultText,
                        height: 1.8,
                      )
                    : STextStyles.field(context),
                keyboardType: Util.isDesktop
                    ? null
                    : const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: standardInputDecoration(
                  "Amount",
                  _amountFocusNode,
                  context,
                ).copyWith(
                  contentPadding: isDesktop
                      ? const EdgeInsets.only(
                          left: 16,
                          top: 11,
                          bottom: 12,
                          right: 5,
                        )
                      : null,
                  suffixIcon: amountController.text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(right: 0),
                          child: UnconstrainedBox(
                            child: Row(
                              children: [
                                TextFieldIconButton(
                                  child: const XIcon(),
                                  onTap: () async {
                                    setState(() {
                                      amountController.text = "";
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
            SizedBox(
              height: isDesktop ? 20 : 12,
            ),
            Text(
              "Note (Optional)",
              style: isDesktop
                  ? STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textFieldActiveSearchIconRight,
                    )
                  : STextStyles.smallMed12(context),
              textAlign: TextAlign.left,
            ),
            SizedBox(
              height: isDesktop ? 10 : 8,
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius,
              ),
              child: TextField(
                autocorrect: Util.isDesktop ? false : true,
                enableSuggestions: Util.isDesktop ? false : true,
                controller: noteController,
                focusNode: _noteFocusNode,
                style: isDesktop
                    ? STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textFieldDefaultText,
                        height: 1.8,
                      )
                    : STextStyles.field(context),
                onChanged: (_) => setState(() {}),
                decoration: standardInputDecoration(
                  "Note",
                  _noteFocusNode,
                  context,
                ).copyWith(
                  contentPadding: isDesktop
                      ? const EdgeInsets.only(
                          left: 16,
                          top: 11,
                          bottom: 12,
                          right: 5,
                        )
                      : null,
                  suffixIcon: noteController.text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(right: 0),
                          child: UnconstrainedBox(
                            child: Row(
                              children: [
                                TextFieldIconButton(
                                  child: const XIcon(),
                                  onTap: () async {
                                    setState(() {
                                      noteController.text = "";
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
            SizedBox(
              height: isDesktop ? 20 : 8,
            ),
            PrimaryButton(
              label: "Generate QR code",
              onPressed: isDesktop
                  ? () {
                      final uriString = _generateURI();
                      if (uriString == null) {
                        return;
                      }

                      setState(() {
                        didGenerate = true;
                        _uriString = uriString;
                      });
                    }
                  : onGeneratePressed,
              buttonHeight: isDesktop ? ButtonHeight.l : null,
            ),
            if (isDesktop && didGenerate)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        height: 20,
                      ),
                      RoundedWhiteContainer(
                        borderColor: Theme.of(context)
                            .extension<StackColors>()!
                            .background,
                        width: isDesktop ? 370 : null,
                        child: Column(
                          children: [
                            Text(
                              "New QR Code",
                              style: STextStyles.desktopTextMedium(context),
                            ),
                            const SizedBox(
                              height: 16,
                            ),
                            Center(
                              child: RepaintBoundary(
                                key: _qrKey,
                                child: SizedBox(
                                  width: 234,
                                  height: 234,
                                  child: QrImage(
                                      data: _uriString,
                                      size: 220,
                                      backgroundColor: Theme.of(context)
                                          .extension<StackColors>()!
                                          .popupBG,
                                      foregroundColor: Theme.of(context)
                                          .extension<StackColors>()!
                                          .accentColorDark),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            Row(
                              mainAxisAlignment: isDesktop
                                  ? MainAxisAlignment.center
                                  : MainAxisAlignment.start,
                              children: [
                                if (!isDesktop)
                                  SecondaryButton(
                                    width: 170,
                                    buttonHeight:
                                        isDesktop ? ButtonHeight.l : null,
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
                                if (!isDesktop)
                                  const SizedBox(
                                    width: 16,
                                  ),
                                PrimaryButton(
                                  width: 170,
                                  buttonHeight:
                                      isDesktop ? ButtonHeight.l : null,
                                  onPressed: () async {
                                    // TODO: add save functionality instead of share
                                    // save works on linux at the moment
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
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
