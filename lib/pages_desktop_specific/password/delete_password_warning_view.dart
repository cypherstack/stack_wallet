import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive/hive.dart';
import 'package:stackduo/hive/db.dart';
import 'package:stackduo/notifications/show_flush_bar.dart';
import 'package:stackduo/pages/intro_view.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/logger.dart';
import 'package:stackduo/utilities/stack_file_system.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackduo/widgets/desktop/desktop_app_bar.dart';
import 'package:stackduo/widgets/desktop/desktop_scaffold.dart';
import 'package:stackduo/widgets/desktop/primary_button.dart';
import 'package:stackduo/widgets/desktop/secondary_button.dart';

class DeletePasswordWarningView extends ConsumerStatefulWidget {
  const DeletePasswordWarningView({
    Key? key,
    required this.shouldCreateNew,
  }) : super(key: key);

  static const String routeName = "/deletePasswordWarning";

  final bool shouldCreateNew;

  @override
  ConsumerState<DeletePasswordWarningView> createState() =>
      _ForgotPasswordDesktopViewState();
}

class _ForgotPasswordDesktopViewState
    extends ConsumerState<DeletePasswordWarningView> {
  bool _deleteInProgress = false;

  Future<bool> _deleteStack() async {
    final appRoot = await StackFileSystem.applicationRootDirectory();

    try {
      await Hive.close();
      if (Platform.isWindows || Platform.isLinux) {
        await appRoot.delete(recursive: true);
      } else {
        // macos in ipad mode
        final xmrDir = Directory("${appRoot.path}/wallets");
        if (xmrDir.existsSync()) {
          await xmrDir.delete(recursive: true);
        }
        final epicDir = Directory("${appRoot.path}/epiccash");
        if (epicDir.existsSync()) {
          await epicDir.delete(recursive: true);
        }
        await (await StackFileSystem.applicationHiveDirectory())
            .delete(recursive: true);
        await (await StackFileSystem.applicationIsarDirectory())
            .delete(recursive: true);
      }

      await DB.instance.init();
    } catch (e, s) {
      Logging.instance.log(
        "$e\n$s",
        level: LogLevel.Fatal,
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      appBar: DesktopAppBar(
        leading: AppBarBackButton(
          onPressed: () async {
            if (mounted && !_deleteInProgress) {
              Navigator.of(context).pop();
            }
          },
        ),
        isCompactHeight: false,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  Assets.svg.stackDuoIcon(context),
                  width: 100,
                ),
                const SizedBox(
                  height: 42,
                ),
                Text(
                  "Warning!",
                  style: STextStyles.desktopH1(context),
                ),
                const SizedBox(
                  height: 24,
                ),
                SizedBox(
                  width: 480,
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "To ",
                          style: STextStyles.desktopTextSmall(context),
                        ),
                        TextSpan(
                          text: widget.shouldCreateNew
                              ? "create a new Stack"
                              : "restore from backup",
                          style: STextStyles.desktopTextSmallBold(context),
                        ),
                        TextSpan(
                          text: ", we need to ",
                          style: STextStyles.desktopTextSmall(context),
                        ),
                        TextSpan(
                          text: "delete your old wallets",
                          style: STextStyles.desktopTextSmallBold(context),
                        ),
                        TextSpan(
                          text:
                              ". All wallets will be lost. If you have not written down your recovery phrase for EACH wallet, you may be in danger of losing funds. Continue?",
                          style: STextStyles.desktopTextSmall(context),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 48,
                ),
                PrimaryButton(
                  label: "Delete and continue",
                  enabled: !_deleteInProgress,
                  onPressed: () async {
                    final shouldDelete = !_deleteInProgress;
                    setState(() {
                      _deleteInProgress = true;
                    });

                    if (shouldDelete) {
                      unawaited(
                        showFloatingFlushBar(
                          type: FlushBarType.info,
                          message: "Deleting wallet...",
                          context: context,
                        ),
                      );

                      final success = await _deleteStack();

                      if (success) {
                        await showFloatingFlushBar(
                          type: FlushBarType.success,
                          message: "Wallet deleted",
                          context: context,
                        );
                        if (mounted) {
                          await Navigator.of(context).pushNamedAndRemoveUntil(
                            IntroView.routeName,
                            (_) => false,
                          );
                        }
                      } else {
                        await showFloatingFlushBar(
                          type: FlushBarType.warning,
                          message: "Something broke badly. Contact developer",
                          context: context,
                        );

                        setState(() {
                          _deleteInProgress = false;
                        });
                      }
                    }
                  },
                ),
                const SizedBox(
                  height: 24,
                ),
                SecondaryButton(
                  label: "Take me back!",
                  enabled: !_deleteInProgress,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(
                  height: kDesktopAppBarHeight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
