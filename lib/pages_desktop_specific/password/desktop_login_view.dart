import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackduo/notifications/show_flush_bar.dart';
import 'package:stackduo/pages_desktop_specific/desktop_home_view.dart';
import 'package:stackduo/pages_desktop_specific/password/forgot_password_desktop_view.dart';
import 'package:stackduo/providers/desktop/storage_crypto_handler_provider.dart';
import 'package:stackduo/providers/global/secure_store_provider.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/constants.dart';
import 'package:stackduo/utilities/flutter_secure_storage_interface.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/utilities/util.dart';
import 'package:stackduo/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackduo/widgets/desktop/desktop_scaffold.dart';
import 'package:stackduo/widgets/desktop/primary_button.dart';
import 'package:stackduo/widgets/loading_indicator.dart';
import 'package:stackduo/widgets/stack_text_field.dart';

import '../../hive/db.dart';
import '../../utilities/db_version_migration.dart';
import '../../utilities/logger.dart';

class DesktopLoginView extends ConsumerStatefulWidget {
  const DesktopLoginView({
    Key? key,
    this.startupWalletId,
    this.load,
  }) : super(key: key);

  static const String routeName = "/desktopLogin";

  final String? startupWalletId;
  final Future<void> Function()? load;

  @override
  ConsumerState<DesktopLoginView> createState() => _DesktopLoginViewState();
}

class _DesktopLoginViewState extends ConsumerState<DesktopLoginView> {
  late final TextEditingController passwordController;

  late final FocusNode passwordFocusNode;

  bool hidePassword = true;
  bool _continueEnabled = false;

  Future<void> _checkDesktopMigrate() async {
    if (Util.isDesktop) {
      int dbVersion = DB.instance.get<dynamic>(
              boxName: DB.boxNameDBInfo, key: "hive_data_version") as int? ??
          0;
      if (dbVersion < Constants.currentHiveDbVersion) {
        try {
          await DbVersionMigrator().migrate(
            dbVersion,
            secureStore: ref.read(secureStoreProvider),
          );
        } catch (e, s) {
          Logging.instance.log("Cannot migrate desktop database\n$e $s",
              level: LogLevel.Error, printFullLength: true);
        }
      }
    }
  }

  Future<void> login() async {
    try {
      unawaited(
        showDialog(
          context: context,
          builder: (context) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              LoadingIndicator(
                width: 200,
                height: 200,
              ),
            ],
          ),
        ),
      );

      await Future<void>.delayed(const Duration(seconds: 1));

      // init security context
      await ref
          .read(storageCryptoHandlerProvider)
          .initFromExisting(passwordController.text);

      // init desktop secure storage
      await (ref.read(secureStoreProvider).store as DesktopSecureStore).init();

      // check and migrate if needed
      await _checkDesktopMigrate();

      // load data
      await widget.load?.call();

      // if no errors passphrase is correct
      if (mounted) {
        // pop loading indicator
        Navigator.of(context).pop();

        unawaited(
          Navigator.of(context).pushNamedAndRemoveUntil(
            DesktopHomeView.routeName,
            (route) => false,
          ),
        );
      }
    } catch (e) {
      // pop loading indicator
      Navigator.of(context).pop();

      await Future<void>.delayed(const Duration(seconds: 1));

      if (mounted) {
        await showFloatingFlushBar(
          type: FlushBarType.warning,
          message: e.toString(),
          context: context,
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    unawaited(Assets.precache(context));

    super.didChangeDependencies();
  }

  @override
  void initState() {
    passwordController = TextEditingController();
    passwordFocusNode = FocusNode();

    super.initState();
  }

  @override
  void dispose() {
    passwordController.dispose();
    passwordFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
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
                  "Stack Duo",
                  style: STextStyles.desktopH1(context),
                ),
                const SizedBox(
                  height: 24,
                ),
                SizedBox(
                  width: 350,
                  child: Text(
                    "Open source multicoin wallet for everyone",
                    textAlign: TextAlign.center,
                    style: STextStyles.desktopSubtitleH1(context),
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                  child: TextField(
                    key: const Key("desktopLoginPasswordFieldKey"),
                    focusNode: passwordFocusNode,
                    controller: passwordController,
                    style: STextStyles.desktopTextMedium(context).copyWith(
                      height: 2,
                    ),
                    obscureText: hidePassword,
                    enableSuggestions: false,
                    autocorrect: false,
                    autofocus: true,
                    onSubmitted: (_) {
                      if (_continueEnabled) {
                        login();
                      }
                    },
                    decoration: standardInputDecoration(
                      "Enter password",
                      passwordFocusNode,
                      context,
                    ).copyWith(
                      suffixIcon: UnconstrainedBox(
                        child: SizedBox(
                          height: 70,
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 24,
                              ),
                              GestureDetector(
                                key: const Key(
                                    "restoreFromFilePasswordFieldShowPasswordButtonKey"),
                                onTap: () async {
                                  setState(() {
                                    hidePassword = !hidePassword;
                                  });
                                },
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: SvgPicture.asset(
                                    hidePassword
                                        ? Assets.svg.eye
                                        : Assets.svg.eyeSlash,
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textDark3,
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    onChanged: (newValue) {
                      setState(() {
                        _continueEnabled = passwordController.text.isNotEmpty;
                      });
                    },
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                PrimaryButton(
                  label: "Continue",
                  enabled: _continueEnabled,
                  onPressed: login,
                ),
                const SizedBox(
                  height: 60,
                ),
                CustomTextButton(
                  text: "Forgot password?",
                  textSize: 20,
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      ForgotPasswordDesktopView.routeName,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
