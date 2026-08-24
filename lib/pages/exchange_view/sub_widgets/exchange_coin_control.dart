/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:tuple/tuple.dart';

import '../../../db/isar/main_db.dart';
import '../../../models/input.dart';
import '../../../models/isar/models/isar_models.dart';
import '../../../providers/providers.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/text_styles.dart';
import '../../../wallets/crypto_currency/coins/firo.dart';
import '../../../wallets/isar/providers/wallet_info_provider.dart';
import '../../../wallets/wallet/impl/namecoin_wallet.dart';
import '../../../wallets/wallet/wallet.dart';
import '../../../wallets/wallet/wallet_mixin_interfaces/coin_control_interface.dart';
import '../../../widgets/custom_buttons/blue_text_button.dart';
import '../../../widgets/rounded_white_container.dart';
import '../../../widgets/stack_dialog.dart';
import '../../coin_control/coin_control_view.dart';

typedef ExchangeUtxoLookup = UTXO? Function(UTXO selected);
typedef ExchangeUtxoConfirmation = bool Function(UTXO utxo);

class ExchangeCoinSelectionException implements Exception {
  const ExchangeCoinSelectionException(
    this.message, {
    required this.clearSelection,
  });

  final String message;
  final bool clearSelection;

  @override
  String toString() => message;
}

bool shouldShowExchangeCoinControl({
  required bool preferenceEnabled,
  required bool walletSupportsCoinControl,
  required bool isFiro,
}) => preferenceEnabled && walletSupportsCoinControl && !isFiro;

Future<Amount> estimateExchangeFundingTotal({
  required Amount amount,
  required Future<Amount> Function(Amount amount) estimateFee,
}) async => amount + await estimateFee(amount);

Set<StandardInput>? validateExchangeCoinSelection({
  required String walletId,
  required Set<UTXO> selected,
  required Amount requiredTotal,
  required ExchangeUtxoLookup lookup,
  required ExchangeUtxoConfirmation isConfirmed,
  bool requireSufficientValue = true,
}) {
  if (selected.isEmpty) {
    return null;
  }

  final current = <UTXO>{};
  for (final prior in selected) {
    final utxo = prior.walletId == walletId ? lookup(prior) : null;
    if (utxo == null ||
        utxo.walletId != walletId ||
        utxo.isBlocked ||
        utxo.used == true ||
        !isConfirmed(utxo)) {
      throw const ExchangeCoinSelectionException(
        "Selected outputs changed. Please select them again.",
        clearSelection: true,
      );
    }
    current.add(utxo);
  }

  final selectedValue = current.fold<BigInt>(
    BigInt.zero,
    (sum, utxo) => sum + BigInt.from(utxo.value),
  );
  if (requireSufficientValue && selectedValue < requiredTotal.raw) {
    throw const ExchangeCoinSelectionException(
      "Selected outputs do not cover the exchange amount and network fee. "
      "Please select more outputs.",
      clearSelection: false,
    );
  }

  return current.map(StandardInput.new).toSet();
}

Future<Amount> estimateExchangeFundingTotalForWallet({
  required Wallet wallet,
  required Amount amount,
}) async {
  final fees = await wallet.fees;
  return estimateExchangeFundingTotal(
    amount: amount,
    estimateFee: (amount) => wallet.estimateFeeFor(amount, fees.medium),
  );
}

Future<({Amount requiredTotal, Set<StandardInput>? inputs})>
prepareExchangeCoinSelection({
  required String walletId,
  required Wallet wallet,
  required int currentChainHeight,
  required Amount amount,
  required Set<UTXO> selected,
  bool requireSufficientValue = true,
}) async {
  final requiredTotal = await estimateExchangeFundingTotalForWallet(
    wallet: wallet,
    amount: amount,
  );

  final inputs = validateExchangeCoinSelection(
    walletId: walletId,
    selected: selected,
    requiredTotal: requiredTotal,
    lookup: (prior) => MainDB.instance.isar.utxos
        .where()
        .txidWalletIdVoutEqualTo(prior.txid, walletId, prior.vout)
        .findFirstSync(),
    isConfirmed: (utxo) => wallet is NamecoinWallet
        ? wallet.checkUtxoConfirmed(utxo, currentChainHeight)
        : utxo.isConfirmed(
            currentChainHeight,
            wallet.cryptoCurrency.minConfirms,
            wallet.cryptoCurrency.minCoinbaseConfirms,
          ),
    requireSufficientValue: requireSufficientValue,
  );
  return (requiredTotal: requiredTotal, inputs: inputs);
}

class ExchangeCoinControlRow extends StatelessWidget {
  const ExchangeCoinControlRow({
    super.key,
    required this.selectedCount,
    required this.onPressed,
    required this.loading,
    required this.padding,
    required this.rounded,
  });

  final int selectedCount;
  final VoidCallback onPressed;
  final bool loading;
  final EdgeInsetsGeometry padding;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Coin control",
          style: STextStyles.w500_14(context).copyWith(
            color: Theme.of(context).extension<StackColors>()!.textSubtitle1,
          ),
        ),
        CustomTextButton(
          enabled: !loading,
          text: loading
              ? "Calculating fee..."
              : selectedCount == 0
              ? "Select coins"
              : "Selected coins ($selectedCount)",
          onTap: loading ? null : onPressed,
        ),
      ],
    );

    return Padding(
      padding: padding,
      child: rounded ? RoundedWhiteContainer(child: row) : row,
    );
  }
}

class ExchangeCoinControlSelector extends ConsumerStatefulWidget {
  const ExchangeCoinControlSelector({
    super.key,
    required this.walletId,
    required this.amount,
    required this.selected,
    required this.onChanged,
    required this.padding,
    this.rounded = false,
  });

  final String walletId;
  final Amount amount;
  final Set<UTXO> selected;
  final ValueChanged<Set<UTXO>> onChanged;
  final EdgeInsetsGeometry padding;
  final bool rounded;

  @override
  ConsumerState<ExchangeCoinControlSelector> createState() =>
      _ExchangeCoinControlSelectorState();
}

class _ExchangeCoinControlSelectorState
    extends ConsumerState<ExchangeCoinControlSelector> {
  bool _opening = false;

  Future<void> _open() async {
    if (_opening) {
      return;
    }
    setState(() => _opening = true);

    try {
      if (FocusScope.of(context).hasFocus) {
        FocusScope.of(context).unfocus();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      final wallet = ref.read(pWallets).getWallet(widget.walletId);
      final preparation = await prepareExchangeCoinSelection(
        walletId: widget.walletId,
        wallet: wallet,
        currentChainHeight: ref.read(pWalletChainHeight(widget.walletId)),
        amount: widget.amount,
        selected: widget.selected,
        requireSufficientValue: false,
      );

      if (!mounted) {
        return;
      }
      final result = await Navigator.of(context).pushNamed(
        CoinControlView.routeName,
        arguments: Tuple4(
          widget.walletId,
          CoinControlViewType.use,
          preparation.requiredTotal,
          preparation.inputs?.map((input) => input.utxo).toSet() ?? const {},
        ),
      );
      if (mounted && result is Set<UTXO>) {
        widget.onChanged(Set.unmodifiable(result));
      }
    } on ExchangeCoinSelectionException catch (e, s) {
      Logging.instance.w(
        "Exchange coin selection changed",
        error: e,
        stackTrace: s,
      );
      if (!mounted) {
        return;
      }
      if (e.clearSelection) {
        widget.onChanged(const {});
      }
      await showDialog<void>(
        context: context,
        builder: (_) =>
            StackOkDialog(title: "Selection changed", message: e.message),
      );
    } catch (e, s) {
      Logging.instance.e(
        "Failed to open exchange coin control",
        error: e,
        stackTrace: s,
      );
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => const StackOkDialog(
            title: "Coin control unavailable",
            message:
                "Unable to estimate the network fee. Check your "
                "connection and try again.",
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _opening = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(pWallets).getWallet(widget.walletId);
    final preferenceEnabled = ref.watch(
      prefsChangeNotifierProvider.select((value) => value.enableCoinControl),
    );
    if (!shouldShowExchangeCoinControl(
      preferenceEnabled: preferenceEnabled,
      walletSupportsCoinControl: wallet is CoinControlInterface,
      isFiro: wallet.info.coin is Firo,
    )) {
      return const SizedBox.shrink();
    }

    return ExchangeCoinControlRow(
      selectedCount: widget.selected.length,
      onPressed: _open,
      loading: _opening,
      padding: widget.padding,
      rounded: widget.rounded,
    );
  }
}
