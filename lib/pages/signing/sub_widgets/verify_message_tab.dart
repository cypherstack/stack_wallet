import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/global/wallets_provider.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/constants.dart';
import '../../../utilities/if_not_already.dart';
import '../../../utilities/show_loading.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/wallet/wallet_mixin_interfaces/sign_verify_interface.dart';
import '../../../widgets/conditional_parent.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/stack_dialog.dart';
import '../../../widgets/textfields/adaptive_text_field.dart';
import '../signing_view.dart';

final class _VerifyState {
  final String address, message, signature;

  _VerifyState({
    required this.address,
    required this.message,
    required this.signature,
  });

  bool get isValid =>
      message.isNotEmpty && signature.isNotEmpty && address.isNotEmpty;

  _VerifyState copyWith({String? address, String? message, String? signature}) {
    return _VerifyState(
      address: address ?? this.address,
      message: message ?? this.message,
      signature: signature ?? this.signature,
    );
  }

  @override
  String toString() =>
      "_VerifyState(address: $address, message: $message, signature: $signature)";
}

final _pVerifyState = StateProvider.autoDispose((ref) {
  return _VerifyState(address: "", message: "", signature: "");
});

final pVerifyIsValid = Provider.autoDispose(
  (ref) => ref.watch(_pVerifyState).isValid,
);

class VerifyMessageForm extends ConsumerStatefulWidget {
  const VerifyMessageForm({super.key, required this.walletId});

  final String walletId;

  @override
  ConsumerState<VerifyMessageForm> createState() => _VerifyMessageFormState();
}

class _VerifyMessageFormState extends ConsumerState<VerifyMessageForm> {
  final messageController = TextEditingController();
  final addressController = TextEditingController();
  final signatureController = TextEditingController();

  late final VoidCallback _verify;

  TextStyle _getStyle(BuildContext context) {
    return Util.isDesktop
        ? STextStyles.desktopTextExtraExtraSmall(context).copyWith(
            color: Theme.of(
              context,
            ).extension<StackColors>()!.textFieldActiveSearchIconRight,
          )
        : STextStyles.smallMed12(context);
  }

  @override
  void initState() {
    super.initState();

    addressController.text = ref.read(_pVerifyState).address;
    messageController.text = ref.read(_pVerifyState).message;
    signatureController.text = ref.read(_pVerifyState).signature;

    _verify = IfNotAlreadyAsync<void>(() async {
      Exception? ex;

      final verified = await showLoading(
        whileFuture:
            (ref.read(pWallets).getWallet(widget.walletId)
                    as SignVerifyInterface)
                .verifyMessage(
                  messageController.text,
                  address: addressController.text,
                  signature: signatureController.text,
                ),
        context: context,
        message: "Verifying...",
        delay: const Duration(seconds: 1),
        onException: (e) => ex = e,
      );

      if (mounted) {
        if (ex != null) {
          await showSignVerifyError(ex!, context: context);
        } else {
          await showDialog<void>(
            context: context,
            builder: (context) => StackOkDialog(
              title: verified == true
                  ? "Verification succeeded"
                  : "Verification failed",
              maxWidth: Util.isDesktop ? 400 : null,
              desktopPopRootNavigator: Util.isDesktop,
            ),
          );
        }
      }
    }).execute;
  }

  @override
  void dispose() {
    messageController.dispose();
    addressController.dispose();
    signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: !Util.isDesktop,
      builder: (child) => Padding(
        padding: EdgeInsets.all(Constants.size.standardPadding),
        child: child,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: Util.isDesktop ? 20 : 12),

          SelectableText("Message", style: _getStyle(context)),
          SizedBox(height: Util.isDesktop ? 10 : 8),
          AdaptiveTextField(
            controller: messageController,
            showPasteClearButton: true,
            maxLines: 1,
            onChangedComprehensive: (_) {
              if (mounted) {
                ref.read(_pVerifyState.notifier).state = ref
                    .read(_pVerifyState)
                    .copyWith(message: messageController.text);
              }
            },
          ),
          SizedBox(height: Util.isDesktop ? 20 : 12),

          SelectableText("Address", style: _getStyle(context)),
          SizedBox(height: Util.isDesktop ? 10 : 8),
          AdaptiveTextField(
            controller: addressController,
            showPasteClearButton: true,
            maxLines: 1,
            onChangedComprehensive: (_) {
              if (mounted) {
                ref.read(_pVerifyState.notifier).state = ref
                    .read(_pVerifyState)
                    .copyWith(address: addressController.text);
              }
            },
          ),
          SizedBox(height: Util.isDesktop ? 20 : 12),

          SelectableText("Signature", style: _getStyle(context)),
          SizedBox(height: Util.isDesktop ? 10 : 8),
          AdaptiveTextField(
            controller: signatureController,
            showPasteClearButton: true,
            maxLines: 1,
            onChangedComprehensive: (_) {
              if (mounted) {
                ref.read(_pVerifyState.notifier).state = ref
                    .read(_pVerifyState)
                    .copyWith(signature: signatureController.text);
              }
            },
          ),

          const SizedBox(height: 32),

          PrimaryButton(
            buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
            label: "Verify",
            enabled: ref.watch(pVerifyIsValid),
            onPressed: ref.watch(pVerifyIsValid) ? _verify : null,
          ),
        ],
      ),
    );
  }
}
