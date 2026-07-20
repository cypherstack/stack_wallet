import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../notifications/show_flush_bar.dart';
import '../../../../providers/db/main_db_provider.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/constants.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../utilities/util.dart';
import '../../../../wallets/crypto_currency/intermediate/bip39_hd_currency.dart';
import '../../../../wallets/isar/providers/wallet_info_provider.dart';
import '../../../../widgets/background.dart';
import '../../../../widgets/conditional_parent.dart';
import '../../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../../widgets/desktop/desktop_dialog.dart';
import '../../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../../widgets/desktop/primary_button.dart';
import '../../../../widgets/icon_widgets/x_icon.dart';
import '../../../../widgets/stack_text_field.dart';
import '../../../../widgets/textfield_icon_button.dart';

/// Per-wallet address-scanning gap limit editor (UTXO/ElectrumX wallets).
///
/// The gap limit is how many consecutive unused addresses a recovery scan will
/// check before it stops. Raising it makes recovery more thorough (but slower);
/// it can only be raised above the coin's safe default, never below — a smaller
/// gap could stop scanning before a funded address and hide balances.
class AddressGapLimitView extends ConsumerStatefulWidget {
  const AddressGapLimitView({super.key, required this.walletId});

  static const String routeName = "/addressGapLimitView";

  // Upper bound to avoid pathologically long scans.
  static const int maxGapLimit = 10000;

  final String walletId;

  @override
  ConsumerState<AddressGapLimitView> createState() =>
      _AddressGapLimitViewState();
}

class _AddressGapLimitViewState extends ConsumerState<AddressGapLimitView> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();

  late final int _coinDefault;

  bool _saveLock = false;

  void _save() async {
    if (_saveLock) return;
    _saveLock = true;
    try {
      String? errMessage;
      try {
        final value = int.tryParse(_controller.text.trim());
        if (value == null) {
          errMessage = "Invalid number: ${_controller.text}";
        } else if (value < _coinDefault) {
          errMessage =
              "Gap limit must be at least $_coinDefault "
              "(the safe minimum for this coin).";
        } else if (value > AddressGapLimitView.maxGapLimit) {
          errMessage =
              "Gap limit must be at most ${AddressGapLimitView.maxGapLimit}.";
        } else {
          await ref
              .read(pWalletInfo(widget.walletId))
              .setAddressGapLimit(
                newValue: value,
                isar: ref.read(mainDBProvider).isar,
              );
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
              message: "Address gap limit updated. Rescan the wallet to apply.",
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
    _controller = TextEditingController();

    final info = ref.read(pWalletInfo(widget.walletId));
    final coin = info.coin;
    _coinDefault = coin is Bip39HDCurrency ? coin.maxUnusedAddressGap : 20;
    _controller.text = (info.customAddressGapLimit ?? _coinDefault).toString();
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
                    onPressedOverride: Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pop,
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
              backgroundColor: Theme.of(
                context,
              ).extension<StackColors>()!.background,
              appBar: AppBar(
                leading: AppBarBackButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                title: Text(
                  "Address gap limit",
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
            Text(
              "How many consecutive unused addresses to scan before stopping "
              "(default $_coinDefault). Increase this if a restored wallet is "
              "missing funds, then rescan. Higher values make recovery slower.",
              style: Util.isDesktop
                  ? STextStyles.desktopTextExtraExtraSmall(context)
                  : STextStyles.smallMed12(context),
            ),
            SizedBox(height: Util.isDesktop ? 16 : 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius,
              ),
              child: TextField(
                key: const Key("addressGapLimitFieldKey"),
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: const TextInputType.numberWithOptions(),
                style: Util.isDesktop
                    ? STextStyles.desktopTextMedium(context).copyWith(height: 2)
                    : STextStyles.field(context),
                enableSuggestions: false,
                autocorrect: false,
                autofocus: true,
                onSubmitted: (_) => _save(),
                onChanged: (_) => setState(() {}),
                decoration:
                    standardInputDecoration(
                      "Address gap limit",
                      _focusNode,
                      context,
                    ).copyWith(
                      suffixIcon: _controller.text.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(right: 0),
                              child: UnconstrainedBox(
                                child: ConditionalParent(
                                  condition: Util.isDesktop,
                                  builder: (child) =>
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
