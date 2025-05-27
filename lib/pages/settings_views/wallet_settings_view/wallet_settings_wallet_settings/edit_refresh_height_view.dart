import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../notifications/show_flush_bar.dart';
import '../../../../providers/db/main_db_provider.dart';
import '../../../../providers/global/wallets_provider.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/constants.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../utilities/util.dart';
import '../../../../wallets/wallet/intermediate/lib_monero_wallet.dart';
import '../../../../widgets/background.dart';
import '../../../../widgets/conditional_parent.dart';
import '../../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../../widgets/desktop/desktop_dialog.dart';
import '../../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../../widgets/desktop/primary_button.dart';
import '../../../../widgets/icon_widgets/x_icon.dart';
import '../../../../widgets/stack_text_field.dart';
import '../../../../widgets/textfield_icon_button.dart';

class EditRefreshHeightView extends ConsumerStatefulWidget {
  const EditRefreshHeightView({super.key, required this.walletId});

  static const String routeName = "/editRefreshHeightView";

  final String walletId;

  @override
  ConsumerState<EditRefreshHeightView> createState() =>
      _EditRefreshHeightViewState();
}

class _EditRefreshHeightViewState extends ConsumerState<EditRefreshHeightView> {
  late final LibMoneroWallet _wallet;
  late final TextEditingController _controller;
  final _focusNode = FocusNode();

  bool _saveLock = false;

  void _save() async {
    if (_saveLock) return;
    _saveLock = true;
    try {
      String? errMessage;
      try {
        final newHeight = int.tryParse(_controller.text);
        if (newHeight != null && newHeight >= 0) {
          await _wallet.info.updateRestoreHeight(
            newRestoreHeight: newHeight,
            isar: ref.read(mainDBProvider).isar,
          );
          _wallet.libMoneroWallet!.setRefreshFromBlockHeight(newHeight);
        } else {
          errMessage = "Invalid height: ${_controller.text}";
        }
      } catch (e) {
        errMessage = e.toString();
      }

      if (mounted) {
        if (errMessage == null) {
          Navigator.of(context).pop();
          unawaited(
            showFloatingFlushBar(
              type: FlushBarType.success,
              message: "Refresh height updated",
              context: context,
            ),
          );
        } else {
          unawaited(
            showFloatingFlushBar(
              type: FlushBarType.warning,
              message: errMessage,
              context: context,
            ),
          );
        }
      }
    } finally {
      _saveLock = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _wallet = ref.read(pWallets).getWallet(widget.walletId) as LibMoneroWallet;
    _controller =
        TextEditingController()
          ..text =
              _wallet.libMoneroWallet!.getRefreshFromBlockHeight().toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: Util.isDesktop,
      builder: (child) {
        return DesktopDialog(
          maxWidth: 500,
          maxHeight: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DesktopDialogCloseButton(
                    onPressedOverride:
                        Navigator.of(context, rootNavigator: true).pop,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: child,
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
      child: ConditionalParent(
        condition: !Util.isDesktop,
        builder: (child) {
          return Background(
            child: Scaffold(
              backgroundColor:
                  Theme.of(context).extension<StackColors>()!.background,
              appBar: AppBar(
                leading: AppBarBackButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                title: Text(
                  "Restore height",
                  style: STextStyles.navBarTitle(context),
                ),
              ),
              body: SafeArea(
                child: Padding(padding: const EdgeInsets.all(16), child: child),
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius,
              ),
              child: TextField(
                key: const Key("restoreHeightFieldKey"),
                controller: _controller,
                focusNode: _focusNode,
                style:
                    Util.isDesktop
                        ? STextStyles.desktopTextMedium(
                          context,
                        ).copyWith(height: 2)
                        : STextStyles.field(context),
                enableSuggestions: false,
                autocorrect: false,
                autofocus: true,
                onSubmitted: (_) => _save(),
                onChanged: (_) => setState(() {}),
                decoration: standardInputDecoration(
                  "Restore height",
                  _focusNode,
                  context,
                ).copyWith(
                  suffixIcon:
                      _controller.text.isNotEmpty
                          ? Padding(
                            padding: const EdgeInsets.only(right: 0),
                            child: UnconstrainedBox(
                              child: ConditionalParent(
                                condition: Util.isDesktop,
                                builder:
                                    (child) =>
                                        SizedBox(height: 70, child: child),
                                child: Row(
                                  children: [
                                    TextFieldIconButton(
                                      child: const XIcon(),
                                      onTap: () async {
                                        setState(() {
                                          _controller.text = "";
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          : Util.isDesktop
                          ? const SizedBox(height: 70)
                          : null,
                ),
              ),
            ),
            Util.isDesktop ? const SizedBox(height: 32) : const Spacer(),
            PrimaryButton(label: "Save", onPressed: _save),
          ],
        ),
      ),
    );
  }
}
