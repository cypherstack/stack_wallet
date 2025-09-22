import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../models/mwc_slatepack_models.dart';
import '../../../notifications/show_flush_bar.dart';
import '../../../providers/global/wallets_provider.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/amount/amount_formatter.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/clipboard_interface.dart';
import '../../../utilities/show_loading.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/isar/providers/wallet_info_provider.dart';
import '../../../wallets/wallet/impl/mimblewimblecoin_wallet.dart';
import '../../../widgets/conditional_parent.dart';
import '../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/detail_item.dart';
import '../../../widgets/rounded_white_container.dart';
import '../../../widgets/stack_dialog.dart';

class MwcSlatepackImportDialog extends ConsumerStatefulWidget {
  const MwcSlatepackImportDialog({
    super.key,
    required this.walletId,
    required this.rawSlatepack,
    required this.decoded,
    required this.slatepackType,
    this.clipboard = const ClipboardWrapper(),
  });

  final String walletId;
  final String rawSlatepack;
  final SlatepackDecodeResult decoded;
  final String slatepackType;
  final ClipboardInterface clipboard;

  @override
  ConsumerState<MwcSlatepackImportDialog> createState() =>
      _MwcSlatepackImportDialogState();
}

class _MwcSlatepackImportDialogState
    extends ConsumerState<MwcSlatepackImportDialog> {
  Future<({String responseSlatepack, bool wasEncrypted})>
  _processSlatepack() async {
    // add delay for showloading exception catching hack fix
    await Future<void>.delayed(const Duration(seconds: 1));

    final wallet =
        ref.read(pWallets).getWallet(widget.walletId) as MimblewimblecoinWallet;

    // Determine action based on slatepack type.
    if (widget.slatepackType.contains("S1")) {
      // This is an initial slatepack - receive it and create response.
      final result = await wallet.receiveSlatepack(widget.rawSlatepack);

      if (result.success && result.responseSlatepack != null) {
        return (
          responseSlatepack: result.responseSlatepack!,
          wasEncrypted: result.wasEncrypted ?? false,
        );
      } else {
        throw Exception(result.error ?? 'Failed to process slatepack');
      }
    } else {
      throw Exception('Unsupported slatepack type: ${widget.slatepackType}');
    }
  }

  Future<void> _processPressed() async {
    Exception? ex;
    final result = await showLoading(
      whileFuture: _processSlatepack(),
      context: context,
      message: "Processing slatepack...",
      onException: (e) => ex = e,
    );

    if (result == null || ex != null) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          useRootNavigator: true,
          builder:
              (context) => StackOkDialog(
                desktopPopRootNavigator: true,
                maxWidth: Util.isDesktop ? 400 : null,
                title: "Slatepack receive error",
                message:
                    ex?.toString() ?? "Unexpected result without exception",
              ),
        );
      }
      return;
    }

    if (mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => _SlatepackResponseDialog(
              responseSlatepack: result.responseSlatepack,
              wasEncrypted: result.wasEncrypted,
              clipboard: widget.clipboard,
            ),
      );
    }
  }

  late final Amount? _amount;

  // late final Amount? _fee;

  @override
  void initState() {
    final map = jsonDecode(widget.decoded.slateJson!) as Map;

    final rawAmount = BigInt.tryParse(map["amount"].toString());
    _amount =
        rawAmount == null
            ? null
            : Amount(
              rawValue: rawAmount,
              fractionDigits:
                  ref.read(pWalletCoin(widget.walletId)).fractionDigits,
            );

    // final rawFee = BigInt.tryParse(map["fee"].toString());
    // _fee =
    //     rawFee == null
    //         ? null
    //         : Amount(
    //           rawValue: rawFee,
    //           fractionDigits:
    //               ref.read(pWalletCoin(widget.walletId)).fractionDigits,
    //         );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDesktop)
          // Header with title and close button.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(
                  "Import Slatepack",
                  style: STextStyles.pageTitleH2(context),
                ),
              ),
              const DesktopDialogCloseButton(),
            ],
          ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConditionalParent(
                condition: isDesktop,
                builder:
                    (child) => RoundedWhiteContainer(
                      borderColor:
                          isDesktop
                              ? Theme.of(
                                context,
                              ).extension<StackColors>()!.backgroundAppBar
                              : null,
                      padding: const EdgeInsets.all(0),
                      child: child,
                    ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isDesktop)
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 24),
                        child: Text(
                          "Import slatepack",
                          style: STextStyles.pageTitleH2(context),
                        ),
                      ),

                    // DetailItem(title: "Type", detail: widget.slatepackType),
                    // const DetailDivider(),
                    // DetailItem(
                    //   title: "Encrypted",
                    //   detail: (widget.decoded.wasEncrypted ?? false).toString(),
                    // ),
                    // if (widget.decoded.senderAddress != null)
                    //   const DetailDivider(),
                    // if (widget.decoded.senderAddress != null)
                    //   DetailItem(
                    //     title: "From",
                    //     detail: widget.decoded.senderAddress!,
                    //   ),
                    // if (widget.decoded.recipientAddress != null)
                    //   const DetailDivider(),
                    // if (widget.decoded.recipientAddress != null)
                    //   DetailItem(
                    //     title: "To",
                    //     detail: widget.decoded.recipientAddress!,
                    //   ),
                    // if (_amount != null) const DetailDivider(),
                    if (_amount != null)
                      DetailItem(
                        title: "Amount",
                        detail: ref
                            .watch(
                              pAmountFormatter(
                                ref.watch(pWalletCoin(widget.walletId)),
                              ),
                            )
                            .format(_amount),
                      ),
                    // if (_fee != null) const DetailDivider(),
                    // if (_fee != null)
                    //   DetailItem(
                    //     title: "Fee",
                    //     detail: ref
                    //         .watch(
                    //           pAmountFormatter(
                    //             ref.watch(pWalletCoin(widget.walletId)),
                    //           ),
                    //         )
                    //         .format(_fee),
                    //   ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ConditionalParent(
                condition: isDesktop,
                builder:
                    (child) => Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [child],
                    ),
                child: PrimaryButton(
                  width: isDesktop ? 220 : null,

                  buttonHeight: isDesktop ? ButtonHeight.l : null,
                  label: "Process",
                  onPressed: _processPressed,
                ),
              ),
              if (!isDesktop) const SizedBox(height: 12),
              if (!isDesktop)
                SecondaryButton(
                  label: "Cancel",
                  onPressed: Navigator.of(context).pop,
                ),
            ],
          ),
        ),
        isDesktop ? const SizedBox(height: 32) : const SizedBox(height: 16),
      ],
    );
  }
}

class _SlatepackResponseDialog extends StatelessWidget {
  const _SlatepackResponseDialog({
    required this.responseSlatepack,
    required this.wasEncrypted,
    required this.clipboard,
  });

  final String responseSlatepack;
  final bool wasEncrypted;
  final ClipboardInterface clipboard;

  void _copySlatepack(BuildContext context) {
    clipboard.setData(ClipboardData(text: responseSlatepack));
    showFloatingFlushBar(
      type: FlushBarType.info,
      message: "Response slatepack copied to clipboard",
      iconAsset: Assets.svg.copy,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StackDialogBase(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with title and close button.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Response Slatepack",
                style: STextStyles.pageTitleH2(context),
              ),
              AppBarIconButton(
                size: 36,
                color: Theme.of(context).extension<StackColors>()!.background,
                shadows: const [],
                icon: SvgPicture.asset(
                  Assets.svg.x,
                  color:
                      Theme.of(
                        context,
                      ).extension<StackColors>()!.topNavIconPrimary,
                  width: 24,
                  height: 24,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Return this slatepack to the sender to complete the transaction.",
                  style: STextStyles.subtitle(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                if (wasEncrypted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .infoItemIcons
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock,
                          size: 16,
                          color:
                              Theme.of(
                                context,
                              ).extension<StackColors>()!.infoItemIcons,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Encrypted Response",
                          style: STextStyles.label(context),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                RoundedWhiteContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Response Slatepack",
                            style: STextStyles.itemSubtitle(context),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _copySlatepack(context),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  Assets.svg.copy,
                                  width: 10,
                                  height: 10,
                                ),
                                const SizedBox(width: 4),
                                Text("Copy", style: STextStyles.link2(context)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(
                          maxHeight: 200,
                          minHeight: 100,
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            responseSlatepack,
                            style: STextStyles.w400_14(
                              context,
                            ).copyWith(fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                PrimaryButton(
                  label: "Copy Response",
                  onPressed: () => _copySlatepack(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
