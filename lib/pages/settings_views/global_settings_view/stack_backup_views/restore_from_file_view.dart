import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/helpers/restore_create_backup.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/helpers/stack_file_system.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/sub_views/stack_restore_progress_view.dart';
// import 'package:stackwallet/pages_desktop_specific/home/settings_menu/backup_and_restore/restore_backup_dialog.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
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

  Future<void> restoreBackupPopup(BuildContext context) async {
    // await showDialog<dynamic>(
    //   context: context,
    //   useSafeArea: false,
    //   barrierDismissible: true,
    //   builder: (context) {
    //     return const RestoreBackupDialog();
    //   },
    // );
  }

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
    final isDesktop = Util.isDesktop;

    return ConditionalParent(
        condition: !isDesktop,
        builder: (child) {
          return Scaffold(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.background,
            appBar: AppBar(
              leading: AppBarBackButton(
                onPressed: () async {
                  if (FocusScope.of(context).hasFocus) {
                    FocusScope.of(context).unfocus();
                    await Future<void>.delayed(
                        const Duration(milliseconds: 75));
                  }
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              title: Text(
                "Restore from file",
                style: STextStyles.navBarTitle(context),
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
                        child: child,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
        child: ConditionalParent(
          condition: isDesktop,
          builder: (child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    "Choose file location",
                    style: STextStyles.desktopTextExtraExtraSmall(context)
                        .copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark3),
                    textAlign: TextAlign.left,
                  ),
                ),
                child,
              ],
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                autocorrect: Util.isDesktop ? false : true,
                enableSuggestions: Util.isDesktop ? false : true,
                onTap: () async {
                  try {
                    await stackFileSystem.prepareStorage();
                    if (mounted) {
                      await stackFileSystem.openFile(context);
                    }

                    if (mounted) {
                      setState(() {
                        fileLocationController.text =
                            stackFileSystem.filePath ?? "";
                      });
                    }
                  } catch (e, s) {
                    Logging.instance.log("$e\n$s", level: LogLevel.Error);
                  }
                },
                controller: fileLocationController,
                style: STextStyles.field(context),
                decoration: InputDecoration(
                  hintText: "Choose file...",
                  hintStyle: STextStyles.fieldLabel(context),
                  suffixIcon: UnconstrainedBox(
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                        ),
                        SvgPicture.asset(
                          Assets.svg.folder,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textDark3,
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
              SizedBox(
                height: !isDesktop ? 8 : 24,
              ),
              if (isDesktop)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    "Enter passphrase",
                    style: STextStyles.desktopTextExtraExtraSmall(context)
                        .copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark3),
                    textAlign: TextAlign.left,
                  ),
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
                child: TextField(
                  key: const Key("restoreFromFilePasswordFieldKey"),
                  focusNode: passwordFocusNode,
                  controller: passwordController,
                  style: STextStyles.field(context),
                  obscureText: hidePassword,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: standardInputDecoration(
                    "Enter password",
                    passwordFocusNode,
                    context,
                  ).copyWith(
                    labelStyle:
                        isDesktop ? STextStyles.fieldLabel(context) : null,
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
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textDark3,
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
              if (!isDesktop) const Spacer(),
              !isDesktop
                  ? TextButton(
                      style: passwordController.text.isEmpty ||
                              fileLocationController.text.isEmpty
                          ? Theme.of(context)
                              .extension<StackColors>()!
                              .getPrimaryDisabledButtonColor(context)
                          : Theme.of(context)
                              .extension<StackColors>()!
                              .getPrimaryEnabledButtonColor(context),
                      onPressed: passwordController.text.isEmpty ||
                              fileLocationController.text.isEmpty
                          ? null
                          : () async {
                              final String fileToRestore =
                                  fileLocationController.text;
                              final String passphrase = passwordController.text;

                              if (FocusScope.of(context).hasFocus) {
                                FocusScope.of(context).unfocus();
                                await Future<void>.delayed(
                                    const Duration(milliseconds: 75));
                              }

                              if (!(await File(fileToRestore).exists())) {
                                await showFloatingFlushBar(
                                  type: FlushBarType.warning,
                                  message: "Backup file does not exist",
                                  context: context,
                                );
                                return;
                              }

                              bool shouldPop = false;
                              unawaited(
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
                                              style: STextStyles.pageTitleH2(
                                                      context)
                                                  .copyWith(
                                                color: Theme.of(context)
                                                    .extension<StackColors>()!
                                                    .textWhite,
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
                                  await showFloatingFlushBar(
                                    type: FlushBarType.warning,
                                    message: "Failed to decrypt backup file",
                                    context: context,
                                  );
                                  return;
                                }

                                await Navigator.of(context).push(
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
                        style: STextStyles.button(context),
                      ),
                    )
                  : Row(
                      children: [
                        PrimaryButton(
                          width: 183,
                          desktopMed: true,
                          label: "Restore",
                          enabled: !(passwordController.text.isEmpty ||
                              fileLocationController.text.isEmpty),
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
                                    await showFloatingFlushBar(
                                      type: FlushBarType.warning,
                                      message: "Backup file does not exist",
                                      context: context,
                                    );
                                    return;
                                  }

                                  bool shouldPop = false;
                                  unawaited(
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
                                                  style:
                                                      STextStyles.pageTitleH2(
                                                              context)
                                                          .copyWith(
                                                    color: Theme.of(context)
                                                        .extension<
                                                            StackColors>()!
                                                        .textWhite,
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
                                    ),
                                  );

                                  final String? jsonString = await compute(
                                    SWB.decryptStackWalletWithPassphrase,
                                    Tuple2(fileToRestore, passphrase),
                                    debugLabel:
                                        "stack wallet decryption compute",
                                  );

                                  if (mounted) {
                                    // pop LoadingIndicator
                                    shouldPop = true;
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop();

                                    passwordController.text = "";

                                    if (jsonString == null) {
                                      await showFloatingFlushBar(
                                        type: FlushBarType.warning,
                                        message:
                                            "Failed to decrypt backup file",
                                        context: context,
                                      );
                                      return;
                                    }

                                    await showDialog<dynamic>(
                                        context: context,
                                        useSafeArea: false,
                                        barrierDismissible: true,
                                        builder: (context) {
                                          return DesktopDialog(
                                            maxHeight: 750,
                                            maxWidth: 600,
                                            child: LayoutBuilder(
                                              builder: (context, constraints) {
                                                return SingleChildScrollView(
                                                  child: ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                      minHeight:
                                                          constraints.maxHeight,
                                                    ),
                                                    child: IntrinsicHeight(
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(32),
                                                                child: Text(
                                                                  "Restoring Stack Wallet",
                                                                  style: STextStyles
                                                                      .desktopH3(
                                                                          context),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                ),
                                                              ),
                                                              const DesktopDialogCloseButton(),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 30,
                                                          ),
                                                          Padding(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    horizontal:
                                                                        32),
                                                            child:
                                                                StackRestoreProgressView(
                                                              jsonString:
                                                                  jsonString,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        });
                                  }
                                },
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        SecondaryButton(
                          width: 183,
                          desktopMed: true,
                          label: "Cancel",
                          onPressed: () {},
                        ),
                      ],
                    ),
            ],
          ),
        ));
  }
}
