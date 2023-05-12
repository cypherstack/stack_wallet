import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/show_loading.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/desktop/outline_blue_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

class DesktopInstallTheme extends ConsumerStatefulWidget {
  const DesktopInstallTheme({Key? key}) : super(key: key);

  @override
  ConsumerState<DesktopInstallTheme> createState() =>
      _DesktopInstallThemeState();
}

class _DesktopInstallThemeState extends ConsumerState<DesktopInstallTheme> {
  final _boxKey = GlobalKey(debugLabel: "selectThemeFileBoxKey");

  XFile? _selectedFile;
  bool? _installedState;
  Size? _size;
  bool _dragging = false;

  Future<bool> _install() async {
    try {
      final timedFuture = Future<void>.delayed(const Duration(seconds: 2));
      final installFuture = _selectedFile!.readAsBytes().then(
            (fileBytes) => ref.read(pThemeService).install(
                  themeArchive: ByteData.view(
                    fileBytes.buffer,
                  ),
                ),
          );

      // wait for at least 2 seconds to prevent annoying screen flashing
      await Future.wait([
        installFuture,
        timedFuture,
      ]);
      return true;
    } catch (e, s) {
      Logging.instance.log(
        "Failed to install theme: $e\n$s",
        level: LogLevel.Warning,
      );
      return false;
    }
  }

  Future<void> _chooseFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: "Choose theme file",
        type: FileType.custom,
        allowedExtensions: ["zip"],
        lockParentWindow: true, // windows only
      );

      if (result != null && mounted) {
        if (result.paths.isNotEmpty && result.paths.first != null) {
          setState(() {
            _selectedFile = XFile(result.paths.first!);
          });
        }
      }
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Error);
    }
  }

  void setBoxSize() {
    if (_size == null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        setState(() {
          _size = _boxKey.currentContext?.size;
        });
      });
    }
  }

  @override
  void initState() {
    setBoxSize();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              "Install theme file",
              style: STextStyles.desktopTextExtraExtraSmall(context),
            ),
          ],
        ),
        const SizedBox(
          height: 12,
        ),
        DropTarget(
          onDragDone: (detail) {
            setState(() {
              if (detail.files.isNotEmpty) {
                _selectedFile = detail.files.first;
              }
            });
          },
          onDragEntered: (detail) {
            setState(() {
              _dragging = true;
            });
          },
          onDragExited: (detail) {
            setState(() {
              _dragging = false;
            });
          },
          child: RoundedContainer(
            key: _boxKey,
            height: _size?.height,
            color: _dragging
                ? Theme.of(context).extension<StackColors>()!.textSubtitle6
                : Theme.of(context).extension<StackColors>()!.popupBG,
            borderColor:
                Theme.of(context).extension<StackColors>()!.textSubtitle6,
            child: _selectedFile == null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        height: 12,
                      ),
                      SvgPicture.asset(
                        Assets.svg.fileUpload,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textSubtitle2,
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Text(
                        "Drag and drop your file here",
                        style: STextStyles.fieldLabel(context),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      OutlineBlueButton(
                        label: "Browse",
                        buttonHeight: ButtonHeight.s,
                        width: 140,
                        onPressed: _chooseFile,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RoundedContainer(
                        padding: EdgeInsets.zero,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textFieldActiveBG,
                        width: 300,
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 10,
                            ),
                            SvgPicture.asset(
                              Assets.svg.file,
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textDark,
                              width: 16,
                              height: 16,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: Text(
                                _selectedFile!.name,
                                style: STextStyles.w500_14(context),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _selectedFile = null;
                                });
                              },
                              icon: SvgPicture.asset(
                                Assets.svg.circleX,
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textSubtitle2,
                                width: 16,
                                height: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
          ),
        ),
        if (_selectedFile != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 20),
                child: PrimaryButton(
                  label: "Install",
                  buttonHeight: ButtonHeight.s,
                  width: 140,
                  enabled: _installedState == null,
                  onPressed: () async {
                    final result = await showLoading(
                      whileFuture: _install(),
                      context: context,
                      message: "Installing ${_selectedFile!.name}...",
                    );
                    if (mounted) {
                      setState(() {
                        _installedState = result;
                      });

                      await Future<void>.delayed(
                        const Duration(milliseconds: 2000),
                      ).then((_) {
                        if (mounted) {
                          setState(() {
                            _selectedFile = null;
                            _installedState = null;
                          });
                        }
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        if (_installedState == true)
          RoundedContainer(
            color:
                Theme.of(context).extension<StackColors>()!.snackBarBackSuccess,
            child: Row(
              children: [
                SvgPicture.asset(
                  Assets.svg.circleX,
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .snackBarTextSuccess,
                  width: 16,
                  height: 16,
                ),
                const SizedBox(
                  width: 10,
                ),
                Text(
                  "${_selectedFile?.name} theme installed",
                  style:
                      STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .snackBarTextSuccess,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        if (_installedState == false)
          RoundedContainer(
            color:
                Theme.of(context).extension<StackColors>()!.snackBarBackError,
            child: Row(
              children: [
                SvgPicture.asset(
                  Assets.svg.circleX,
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .snackBarTextError,
                  width: 16,
                  height: 16,
                ),
                const SizedBox(
                  width: 10,
                ),
                Text(
                  "Failed to install ${_selectedFile?.name} theme",
                  style:
                      STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .snackBarTextError,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
