import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/global/wallets_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../wallets/wallet/wallet_mixin_interfaces/view_only_option_interface.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/custom_tab_view.dart';
import '../../widgets/stack_dialog.dart';
import 'sub_widgets/sign_message_tab.dart';
import 'sub_widgets/verify_message_tab.dart';

class SigningView extends ConsumerStatefulWidget {
  const SigningView({super.key, required this.walletId});

  final String walletId;

  static const String routeName = "/signingView";

  @override
  ConsumerState<SigningView> createState() => _SigningViewState();
}

class _SigningViewState extends ConsumerState<SigningView> {
  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    // keep auto dispose providers alive
    ref.listen(pSignIsValid, (_, __) {});
    ref.listen(pVerifyIsValid, (_, __) {});
    final wallet = ref.watch(pWallets).getWallet(widget.walletId);
    final viewOnly = wallet is ViewOnlyOptionInterface && wallet.isViewOnly;

    return ConditionalParent(
      condition: !Util.isDesktop,
      builder: (child) => Background(
        child: Scaffold(
          backgroundColor: Theme.of(context)
              .extension<StackColors>()!
              .background,
          appBar: AppBar(
            leading: AppBarBackButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            title: Text(
              viewOnly ? "Verify message" : "Sign / Verify",
              style: STextStyles.navBarTitle(context),
            ),
          ),
          body: SafeArea(child: SingleChildScrollView(child: child)),
        ),
      ),
      child: CustomTabView(
        titles: [if (!viewOnly) "Sign message", "Verify message"],
        children: [
          if (!viewOnly)
            SignMessageForm(
              key: const Key("_SignMessageFormKey"),
              walletId: widget.walletId,
            ),
          VerifyMessageForm(
            key: const Key("_VerifyMessageFormKey"),
            walletId: widget.walletId,
          ),
        ],
      ),
    );
  }
}

Future<void> showSignVerifyError(Exception e, {required BuildContext context}) {
  String message = e.toString().trim();
  const exceptionPrefix = "Exception:";
  while (message.startsWith(exceptionPrefix) &&
      message.length > exceptionPrefix.length) {
    message = message.substring(exceptionPrefix.length).trim();
  }
  return showDialog(
    context: context,
    builder: (context) => StackOkDialog(
      title: "Error",
      message: message,
      maxWidth: Util.isDesktop ? 400 : null,
      desktopPopRootNavigator: Util.isDesktop,
    ),
  );
}
