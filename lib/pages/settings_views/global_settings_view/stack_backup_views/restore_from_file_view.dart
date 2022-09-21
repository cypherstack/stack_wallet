import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/helpers/restore_create_backup.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/helpers/stack_file_system.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/sub_views/stack_restore_progress_view.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:tuple/tuple.dart';

class RestoreFromFileView extends ConsumerStatefulWidget {
  const RestoreFromFileView({Key? key}) : super(key: key);

  static const String routeName = "/restoreFromFile";

  @override
  ConsumerState<RestoreFromFileView> createState() =>
      _RestoreFromFileViewState();
}

class _RestoreFromFileViewState extends ConsumerState<RestoreFromFileView> {
  late final TextEditingController fileLocationController;
  late final TextEditingController passwordController;

  late final FocusNode passwordFocusNode;

  late final StackFileSystem stackFileSystem;

  bool hidePassword = true;

  @override
  void initState() {
    stackFileSystem = StackFileSystem();
    fileLocationController = TextEditingController();
    passwordController = TextEditingController();

    passwordFocusNode = FocusNode();

    super.initState();
  }

  @override
  void dispose() {
    fileLocationController.dispose();
    passwordController.dispose();

    passwordFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StackTheme.instance.color.background,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () async {
            if (FocusScope.of(context).hasFocus) {
              FocusScope.of(context).unfocus();
              await Future<void>.delayed(const Duration(milliseconds: 75));
            }
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          "Restore from file",
          style: STextStyles.navBarTitle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        onTap: () async {
                          try {
                            await stackFileSystem.prepareStorage();
                            // ref
                            //     .read(shouldShowLockscreenOnResumeStateProvider
                            //         .state)
                            //     .state = false;
                            await stackFileSystem.openFile(context);

                            // Future<void>.delayed(
                            //   const Duration(seconds: 2),
                            //   () => ref
                            //       .read(
                            //           shouldShowLockscreenOnResumeStateProvider
                            //               .state)
                            //       .state = true,
                            // );

                            fileLocationController.text =
                                stackFileSystem.filePath ?? "";
                            setState(() {});
                          } catch (e, s) {
                            // ref
                            //     .read(shouldShowLockscreenOnResumeStateProvider
                            //         .state)
                            //     .state = true;
                            Logging.instance
                                .log("$e\n$s", level: LogLevel.Error);
                          }
                        },
                        controller: fileLocationController,
                        style: STextStyles.field,
                        decoration: InputDecoration(
                          hintText: "Choose file...",
                          suffixIcon: UnconstrainedBox(
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                ),
                                SvgPicture.asset(
                                  Assets.svg.folder,
                                  color: CFColors.neutral50,
                                  width: 16,
                                  height: 16,
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                        key: const Key("restoreFromFileLocationTextFieldKey"),
                        readOnly: true,
                        toolbarOptions: const ToolbarOptions(
                          copy: true,
                          cut: false,
                          paste: false,
                          selectAll: false,
                        ),
                        onChanged: (newValue) {},
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          Constants.size.circularBorderRadius,
                        ),
                        child: TextField(
                          key: const Key("restoreFromFilePasswordFieldKey"),
                          focusNode: passwordFocusNode,
                          controller: passwordController,
                          style: STextStyles.field,
                          obscureText: hidePassword,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: standardInputDecoration(
                            "Enter password",
                            passwordFocusNode,
                          ).copyWith(
                            suffixIcon: UnconstrainedBox(
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 16,
                                  ),
                                  GestureDetector(
                                    key: const Key(
                                        "restoreFromFilePasswordFieldShowPasswordButtonKey"),
                                    onTap: () async {
                                      setState(() {
                                        hidePassword = !hidePassword;
                                      });
                                    },
                                    child: SvgPicture.asset(
                                      hidePassword
                                          ? Assets.svg.eye
                                          : Assets.svg.eyeSlash,
                                      color: CFColors.neutral50,
                                      width: 16,
                                      height: 16,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          onChanged: (newValue) {
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      const Spacer(),
                      TextButton(
                        style: passwordController.text.isEmpty ||
                                fileLocationController.text.isEmpty
                            ? StackTheme.instance
                                .getPrimaryEnabledButtonColor(context)
                            : StackTheme.instance
                                .getPrimaryDisabledButtonColor(context),
                        onPressed: passwordController.text.isEmpty ||
                                fileLocationController.text.isEmpty
                            ? null
                            : () async {
                                final String fileToRestore =
                                    fileLocationController.text;
                                final String passphrase =
                                    passwordController.text;

                                if (FocusScope.of(context).hasFocus) {
                                  FocusScope.of(context).unfocus();
                                  await Future<void>.delayed(
                                      const Duration(milliseconds: 75));
                                }

                                if (!(await File(fileToRestore).exists())) {
                                  showFloatingFlushBar(
                                    type: FlushBarType.warning,
                                    message: "Backup file does not exist",
                                    context: context,
                                  );
                                  return;
                                }

                                bool shouldPop = false;
                                showDialog<dynamic>(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (_) => WillPopScope(
                                    onWillPop: () async {
                                      return shouldPop;
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Material(
                                          color: Colors.transparent,
                                          child: Center(
                                            child: Text(
                                              "Decrypting Stack backup file",
                                              style: STextStyles.pageTitleH2
                                                  .copyWith(
                                                color: CFColors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 64,
                                        ),
                                        const Center(
                                          child: LoadingIndicator(
                                            width: 100,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );

                                final String? jsonString = await compute(
                                  SWB.decryptStackWalletWithPassphrase,
                                  Tuple2(fileToRestore, passphrase),
                                  debugLabel: "stack wallet decryption compute",
                                );

                                if (mounted) {
                                  // pop LoadingIndicator
                                  shouldPop = true;
                                  Navigator.of(context).pop();

                                  passwordController.text = "";

                                  if (jsonString == null) {
                                    showFloatingFlushBar(
                                      type: FlushBarType.warning,
                                      message: "Failed to decrypt backup file",
                                      context: context,
                                    );
                                    return;
                                  }

                                  Navigator.of(context).push(
                                    RouteGenerator.getRoute(
                                      builder: (_) => StackRestoreProgressView(
                                        jsonString: jsonString,
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: Text(
                          "Restore",
                          style: STextStyles.button,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
