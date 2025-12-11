import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/isar/models/isar_models.dart';
import '../../../providers/global/wallets_provider.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/constants.dart';
import '../../../utilities/if_not_already.dart';
import '../../../utilities/show_loading.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/wallet/wallet_mixin_interfaces/sign_verify_interface.dart';
import '../../../widgets/conditional_parent.dart';
import '../../../widgets/custom_buttons/blue_text_button.dart';
import '../../../widgets/custom_buttons/simple_copy_button.dart';
import '../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/detail_item.dart';
import '../../../widgets/dialogs/s_dialog.dart';
import '../../../widgets/rounded_container.dart';
import '../../../widgets/textfields/adaptive_text_field.dart';
import '../signing_view.dart';
import 'address_list.dart';

final class _SignState {
  final String message, signature;
  final Address? address;

  _SignState({
    required this.address,
    required this.message,
    required this.signature,
  });

  bool get isValid => message.isNotEmpty && address != null;

  _SignState copyWith({String? message, String? signature}) {
    return _SignState(
      address: address,
      message: message ?? this.message,
      signature: signature ?? this.signature,
    );
  }

  _SignState copyWithAddress(Address? address) {
    return _SignState(address: address, message: message, signature: signature);
  }

  @override
  String toString() =>
      "_SignState(address: $address, message: $message, signature: $signature)";
}

final _pSignState = StateProvider.autoDispose((ref) {
  return _SignState(address: null, message: "", signature: "");
});

final pSignIsValid = Provider.autoDispose(
  (ref) => ref.watch(_pSignState).isValid,
);

class SignMessageForm extends ConsumerStatefulWidget {
  const SignMessageForm({super.key, required this.walletId});

  final String walletId;

  @override
  ConsumerState<SignMessageForm> createState() => _SignMessageFormState();
}

class _SignMessageFormState extends ConsumerState<SignMessageForm> {
  final messageController = TextEditingController();

  late final VoidCallback _chooseAddress;
  late final VoidCallback _sign;

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

    messageController.text = ref.read(_pSignState).message;

    _chooseAddress = IfNotAlreadyAsync<void>(() async {
      final Address? address;

      if (Util.isDesktop) {
        address = await showDialog<Address>(
          context: context,
          builder: (context) {
            return SDialog(
              contentCanScroll: false,
              child: ConditionalParent(
                condition: Util.isDesktop,
                builder: (child) => SizedBox(width: 600, child: child),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (Util.isDesktop)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              "Choose address",
                              style: STextStyles.desktopH3(context),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const DesktopDialogCloseButton(),
                        ],
                      ),
                    Expanded(
                      child: ConditionalParent(
                        condition: Util.isDesktop,
                        builder: (child) => Padding(
                          padding: const EdgeInsets.only(
                            top: 10,
                            left: 32,
                            right: 32,
                            bottom: 32,
                          ),
                          child: RoundedContainer(
                            padding: EdgeInsets.zero,
                            color: Colors.transparent,
                            borderColor: Theme.of(
                              context,
                            ).extension<StackColors>()!.textFieldDefaultBG,
                            child: child,
                          ),
                        ),

                        child: AddressList(walletId: widget.walletId),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        address = await Navigator.of(context).pushNamed<Address>(
          CompactAddressListView.routeName,
          arguments: widget.walletId,
        );
      }

      if (address != null &&
          address.value != ref.read(_pSignState).address?.value &&
          mounted) {
        ref.read(_pSignState.notifier).state = ref
            .read(_pSignState)
            .copyWithAddress(address)
            .copyWith(signature: "");
      }
    }).execute;

    _sign = IfNotAlreadyAsync<void>(() async {
      Exception? ex;

      final state = ref.read(_pSignState);
      final signature = await showLoading(
        whileFuture:
            (ref.read(pWallets).getWallet(widget.walletId)
                    as SignVerifyInterface)
                .signMessage(state.message, address: state.address!),
        context: context,
        message: "Signing...",
        delay: const Duration(seconds: 1),
        onException: (e) => ex = e,
      );

      if (mounted && ex != null) {
        await showSignVerifyError(ex!, context: context);
      } else if (signature != null && mounted) {
        ref.read(_pSignState.notifier).state = state.copyWith(
          signature: signature,
        );
      }
    }).execute;
  }

  @override
  void dispose() {
    messageController.dispose();
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
                ref.read(_pSignState.notifier).state = ref
                    .read(_pSignState)
                    .copyWith(message: messageController.text, signature: "");
              }
            },
          ),
          SizedBox(height: Util.isDesktop ? 20 : 12),

          DetailItem(
            title: "Address",
            titleStyle: _getStyle(context),
            detail:
                ref.watch(_pSignState.select((s) => s.address))?.value ?? "",
            showEmptyDetail: true,
            detailPlaceholder: "n/a",
            noPadding: Util.isDesktop,
            button: CustomTextButton(
              text: "Choose address",
              onTap: _chooseAddress,
            ),
          ),
          SizedBox(height: Util.isDesktop ? 20 : 12),

          DetailItem(
            title: "Signature",
            titleStyle: _getStyle(context),
            detail: ref.watch(_pSignState.select((s) => s.signature)),
            showEmptyDetail: true,
            detailPlaceholder: "n/a",
            noPadding: Util.isDesktop,
            button: ref.watch(_pSignState.select((s) => s.signature)).isEmpty
                ? null
                : SimpleCopyButton(data: ref.read(_pSignState).signature),
          ),

          const SizedBox(height: 32),

          PrimaryButton(
            buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
            label: "Sign",
            enabled: ref.watch(pSignIsValid),
            onPressed: ref.watch(pSignIsValid) ? _sign : null,
          ),
        ],
      ),
    );
  }
}
