import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/home_view/home_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/helpers/restore_create_backup.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/sub_views/stack_restore_progress_view.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:tuple/tuple.dart';

class RestoreFromEncryptedStringView extends ConsumerStatefulWidget {
  const RestoreFromEncryptedStringView({
    Key? key,
    required this.encrypted,
  }) : super(key: key);

  static const String routeName = "/restoreFromEncryptedString";

  final String encrypted;

  @override
  ConsumerState<RestoreFromEncryptedStringView> createState() =>
      _RestoreFromEncryptedStringViewState();
}

class _RestoreFromEncryptedStringViewState
    extends ConsumerState<RestoreFromEncryptedStringView> {
  late final TextEditingController passwordController;
  late final FocusNode passwordFocusNode;

  bool hidePassword = true;

  Future<bool> _onWillPop() async {
    Navigator.of(context).pushReplacementNamed(HomeView.routeName);
    return false;
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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: StackTheme.instance.color.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () async {
              if (FocusScope.of(context).hasFocus) {
                FocusScope.of(context).unfocus();
                await Future<void>.delayed(const Duration(milliseconds: 75));
              }
              if (mounted) {
                _onWillPop();
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                                        color:
                                            StackTheme.instance.color.textDark3,
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
                          style: passwordController.text.isEmpty
                              ? StackTheme.instance
                                  .getPrimaryEnabledButtonColor(context)
                              : StackTheme.instance
                                  .getPrimaryDisabledButtonColor(context),
                          onPressed: passwordController.text.isEmpty
                              ? null
                              : () async {
                                  final String passphrase =
                                      passwordController.text;

                                  if (FocusScope.of(context).hasFocus) {
                                    FocusScope.of(context).unfocus();
                                    await Future<void>.delayed(
                                        const Duration(milliseconds: 75));
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
                                                style: STextStyles.pageTitleH2(
                                                        context)
                                                    .copyWith(
                                                  color: StackTheme
                                                      .instance.color.textWhite,
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
                                    SWB.decryptStackWalletStringWithPassphrase,
                                    Tuple2(widget.encrypted, passphrase),
                                    debugLabel:
                                        "stack wallet decryption compute",
                                  );

                                  if (mounted) {
                                    // pop LoadingIndicator
                                    shouldPop = true;
                                    Navigator.of(context).pop();

                                    passwordController.text = "";

                                    if (jsonString == null) {
                                      showFloatingFlushBar(
                                        type: FlushBarType.warning,
                                        message:
                                            "Failed to decrypt backup file",
                                        context: context,
                                      );
                                      return;
                                    }

                                    Navigator.of(context).push(
                                      RouteGenerator.getRoute(
                                        builder: (_) =>
                                            StackRestoreProgressView(
                                          jsonString: jsonString,
                                          fromFile: true,
                                        ),
                                      ),
                                    );
                                  }
                                },
                          child: Text(
                            "Restore",
                            style: STextStyles.button(context),
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
      ),
    );
  }
}
