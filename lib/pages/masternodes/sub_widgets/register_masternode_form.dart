import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/global/locale_provider.dart';
import '../../../providers/global/wallets_provider.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/amount/amount_field_relocalization.dart';
import '../../../utilities/amount/amount_input_formatter.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/if_not_already.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/show_loading.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/wallet/impl/firo_wallet.dart';
import '../../../widgets/conditional_parent.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/rounded_container.dart';
import '../../../widgets/stack_dialog.dart';
import '../../../widgets/textfields/adaptive_text_field.dart';

class RegisterMasternodeForm extends ConsumerStatefulWidget {
  const RegisterMasternodeForm({
    super.key,
    required this.firoWalletId,
    required this.collateralTxid,
    required this.collateralVout,
    required this.collateralAddress,
    required this.onRegistrationSuccess,
  });

  final String firoWalletId;
  final String collateralTxid;
  final int collateralVout;
  final String collateralAddress;

  final void Function(String) onRegistrationSuccess;

  @override
  ConsumerState<RegisterMasternodeForm> createState() =>
      _RegisterMasternodeFormState();
}

class _RegisterMasternodeFormState
    extends ConsumerState<RegisterMasternodeForm> {
  final _ipAndPortController = TextEditingController();
  final _operatorPubKeyController = TextEditingController();
  final _votingAddressController = TextEditingController();
  final _operatorRewardController = TextEditingController(text: "0");
  final _payoutAddressController = TextEditingController();

  TextStyle _getStyle(BuildContext context) {
    return Util.isDesktop
        ? STextStyles.desktopTextExtraExtraSmall(context).copyWith(
            color: Theme.of(
              context,
            ).extension<StackColors>()!.textFieldActiveSearchIconRight,
          )
        : STextStyles.smallMed12(context);
  }

  late final VoidCallback _register;

  bool _enableCreateButton = false;

  // Parse as a 2-decimal Amount so pasted overprecision ("0.001") is
  // rejected instead of silently rounding to zero basis points.
  Decimal? get _operatorRewardPercent => Amount.tryParseEditableAmount(
    _operatorRewardController.text,
    locale: ref.read(localeServiceChangeNotifierProvider).locale,
    fractionDigits: 2,
  )?.decimal;

  void _validate() {
    if (mounted) {
      final percent = _operatorRewardPercent;
      setState(() {
        _enableCreateButton = [
          _ipAndPortController.text
                  .trim()
                  .split(":")
                  .where((e) => e.isNotEmpty)
                  .length ==
              2,
          _operatorPubKeyController.text.trim().isNotEmpty,
          percent != null && percent <= Decimal.fromInt(100),
          _payoutAddressController.text.trim().isNotEmpty,
        ].every((e) => e);
      });
    }
  }

  Future<String> _registerMasternode() async {
    final parts = _ipAndPortController.text.trim().split(':');
    final ip = parts[0];
    final port = int.parse(parts[1]);
    final operatorPubKey = _operatorPubKeyController.text.trim();
    final votingAddress = _votingAddressController.text.trim();
    final payoutAddress = _payoutAddressController.text.trim();

    // according to https://github.com/cypherstack/stack_wallet/blob/c898a70f808ed5490b8dd23571f5f162d9e38158/lib/wallets/wallet/impl/firo_wallet.dart#L1064
    // this should be a percent of 10000
    final operatorPercent = _operatorRewardPercent;
    if (operatorPercent == null) {
      throw Exception("Invalid operator reward");
    }
    final operatorReward = (operatorPercent * Decimal.fromInt(100))
        .round()
        .toBigInt()
        .toInt()
        .clamp(0, 10000);

    final wallet =
        ref.read(pWallets).getWallet(widget.firoWalletId) as FiroWallet;

    final txId = await wallet.registerMasternode(
      ip,
      port,
      operatorPubKey,
      votingAddress,
      operatorReward,
      payoutAddress,
      collateralTxid: widget.collateralTxid,
      collateralVout: widget.collateralVout,
      collateralAddress: widget.collateralAddress,
    );

    Logging.instance.i('Masternode registration submitted: $txId');

    return txId;
  }

  @override
  void initState() {
    super.initState();

    _register = IfNotAlreadyAsync<void>(() async {
      Exception? ex;

      final txId = await showLoading(
        whileFutureAlt: _registerMasternode,
        context: context,
        rootNavigator: Util.isDesktop,
        message: "Creating and submitting masternode registration...",
        delay: const Duration(seconds: 1),
        onException: (e) => ex = e,
      );

      if (mounted) {
        if (ex != null || txId == null) {
          String message = ex?.toString().trim() ?? "Unknown error: txId=$txId";
          const exceptionPrefix = "Exception:";
          while (message.startsWith(exceptionPrefix) &&
              message.length > exceptionPrefix.length) {
            message = message.substring(exceptionPrefix.length).trim();
          }
          await showDialog<void>(
            context: context,
            builder: (_) => StackOkDialog(
              title: "Registration failed",
              message: message,
              desktopPopRootNavigator: Util.isDesktop,
              maxWidth: Util.isDesktop ? 400 : null,
            ),
          );
        } else {
          widget.onRegistrationSuccess.call(txId);
        }
      }
    }).execute;
  }

  @override
  void dispose() {
    _ipAndPortController.dispose();
    _operatorPubKeyController.dispose();
    _votingAddressController.dispose();
    _operatorRewardController.dispose();
    _payoutAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stack = Theme.of(context).extension<StackColors>()!;

    listenForAmountRelocalization(
      ref.listen,
      controllers: [_operatorRewardController],
      onRelocalized: _validate,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: RoundedContainer(
                color: stack.textFieldDefaultBG,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Masternode collateral",
                        style: STextStyles.w500_12(
                          context,
                        ).copyWith(color: stack.textSubtitle1),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        widget.collateralAddress,
                        style: STextStyles.w500_14(
                          context,
                        ).copyWith(color: stack.textDark),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        "${widget.collateralTxid}:${widget.collateralVout}",
                        style: STextStyles.w500_12(
                          context,
                        ).copyWith(color: stack.textSubtitle1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: Util.isDesktop ? 24 : 16),

        SelectableText("IP:Port", style: _getStyle(context)),
        SizedBox(height: Util.isDesktop ? 10 : 8),
        AdaptiveTextField(
          controller: _ipAndPortController,
          showPasteClearButton: true,
          maxLines: 1,
          onChangedComprehensive: (_) => _validate(),
        ),
        SizedBox(height: Util.isDesktop ? 24 : 16),

        SelectableText("Operator public key (BLS)", style: _getStyle(context)),
        SizedBox(height: Util.isDesktop ? 10 : 8),
        AdaptiveTextField(
          controller: _operatorPubKeyController,
          showPasteClearButton: true,
          maxLines: 1,
          onChangedComprehensive: (_) => _validate(),
        ),
        SizedBox(height: Util.isDesktop ? 24 : 16),

        SelectableText("Voting address (optional)", style: _getStyle(context)),
        SizedBox(height: Util.isDesktop ? 10 : 8),
        AdaptiveTextField(
          controller: _votingAddressController,
          showPasteClearButton: true,
          maxLines: 1,
          labelText: "Defaults to owner address",
          onChangedComprehensive: (_) => _validate(),
        ),
        SizedBox(height: Util.isDesktop ? 24 : 16),

        SelectableText("Operator reward (%)", style: _getStyle(context)),
        SizedBox(height: Util.isDesktop ? 10 : 8),
        AdaptiveTextField(
          controller: _operatorRewardController,
          showPasteClearButton: true,
          maxLines: 1,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            AmountInputFormatter(
              controller: _operatorRewardController,
              decimals: 2,
              locale: ref.watch(
                localeServiceChangeNotifierProvider.select(
                  (value) => value.locale,
                ),
              ),
            ),
          ],
          onChangedComprehensive: (_) => _validate(),
        ),
        SizedBox(height: Util.isDesktop ? 24 : 16),

        SelectableText("Payout address", style: _getStyle(context)),
        SizedBox(height: Util.isDesktop ? 10 : 8),
        AdaptiveTextField(
          controller: _payoutAddressController,
          showPasteClearButton: true,
          maxLines: 1,
          onChangedComprehensive: (_) => _validate(),
        ),

        Util.isDesktop
            ? const SizedBox(height: 32)
            : const SizedBox(height: 16),
        if (!Util.isDesktop) const Spacer(),

        ConditionalParent(
          condition: Util.isDesktop,
          builder: (child) => Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: "Cancel",
                  onPressed: Navigator.of(context).pop,
                  buttonHeight: .l,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(child: child),
            ],
          ),
          child: PrimaryButton(
            label: "Create",
            enabled: _enableCreateButton,
            onPressed: _enableCreateButton ? _register : null,
            buttonHeight: Util.isDesktop ? .l : null,
          ),
        ),
      ],
    );
  }
}
