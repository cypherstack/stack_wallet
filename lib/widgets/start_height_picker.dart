/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2026 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../themes/stack_colors.dart';
import '../utilities/constants.dart';
import '../utilities/format.dart';
import '../utilities/logger.dart';
import '../utilities/text_styles.dart';
import '../utilities/util.dart';
import '../wallets/crypto_currency/crypto_currency.dart';
import '../wallets/crypto_currency/intermediate/cryptonote_currency.dart';
import '../wl_gen/interfaces/cs_monero_interface.dart';
import '../wl_gen/interfaces/cs_salvium_interface.dart';
import '../wl_gen/interfaces/cs_wownero_interface.dart';
import 'custom_buttons/blue_text_button.dart';
import 'date_picker/date_picker.dart';
import 'date_picker/restore_from_date_picker.dart';
import 'icon_widgets/x_icon.dart';
import 'rounded_white_container.dart';
import 'stack_text_field.dart';
import 'textfield_icon_button.dart';

/// The selection made in a [StartHeightPicker].
///
/// Use one controller per picker. Sharing a controller between panels leaks the
/// height into panels that show no picker at all.
class StartHeightPickerController extends ChangeNotifier {
  int? _height;
  bool _isUsingDate = true;

  /// The chosen block height, or null while nothing has been chosen yet.
  int? get height => _height;

  bool get isUsingDate => _isUsingDate;

  /// Fills the block height field in and switches to block height mode.
  ///
  /// The field stays editable afterwards; whatever the user leaves in it is
  /// what [height] reports.
  void setHeight(int height) => _update(height: height, isUsingDate: false);

  void _update({required int? height, required bool isUsingDate}) {
    if (_height == height && _isUsingDate == isUsingDate) {
      return;
    }
    _height = height;
    _isUsingDate = isUsingDate;
    notifyListeners();
  }
}

/// Lets the user choose where a wallet scan starts, as either a calendar date
/// or a raw block height, and reports the result through [controller].
class StartHeightPicker extends StatefulWidget {
  const StartHeightPicker({
    super.key,
    required this.coin,
    required this.controller,
  });

  final CryptoCurrency coin;
  final StartHeightPickerController controller;

  /// Whether a chosen start height can actually be applied to [coin]. Coins
  /// that cannot honour one must not be offered the control.
  static bool isSupported(CryptoCurrency coin) =>
      coin is CryptonoteCurrency ||
      coin is Epiccash ||
      coin is Mimblewimblecoin;

  /// The block height [coin] was at on [date], or null if [coin] has no date to
  /// height mapping.
  static int? heightFromDate(CryptoCurrency coin, DateTime date) {
    try {
      final int height;
      if (coin is Monero) {
        height = csMonero.getHeightByDate(date);
      } else if (coin is Wownero) {
        height = csWownero.getHeightByDate(date);
      } else if (coin is Salvium) {
        height = csSalvium.getHeightByDate(date);
      } else if (coin is Epiccash || coin is Mimblewimblecoin) {
        // Epic Cash and Mimblewimblecoin share a genesis timestamp and target
        // block time. Seconds per block is deliberately overestimated so the
        // result scans from slightly too early rather than skipping history.
        const genesisEpochSeconds = 1565370278;
        const overestimatedSecondsPerBlock = 61;
        height =
            (date.millisecondsSinceEpoch ~/ 1000 - genesisEpochSeconds) ~/
            overestimatedSecondsPerBlock;
      } else {
        return null;
      }
      return max(height, 0);
    } catch (e, s) {
      Logging.instance.w(
        "Failed to convert a date to a ${coin.identifier} block height",
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  @override
  State<StartHeightPicker> createState() => _StartHeightPickerState();
}

class _StartHeightPickerState extends State<StartHeightPicker> {
  final _dateController = TextEditingController();
  final _blockHeightController = TextEditingController();
  final _blockHeightFocusNode = FocusNode();

  DateTime? _date;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _syncBlockHeightField();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _dateController.dispose();
    _blockHeightController.dispose();
    _blockHeightFocusNode.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(_syncBlockHeightField);
    }
  }

  void _syncBlockHeightField() {
    if (widget.controller.isUsingDate) {
      return;
    }
    final height = widget.controller.height;
    // Compare parsed values so that typing does not fight the field over
    // leading zeroes.
    if (int.tryParse(_blockHeightController.text) != height) {
      _blockHeightController.text = height?.toString() ?? "";
    }
  }

  /// Pushes the current selection into the controller, optionally switching
  /// between date and block height mode first.
  void _apply({bool? isUsingDate}) {
    final usingDate = isUsingDate ?? widget.controller.isUsingDate;
    widget.controller._update(
      height: usingDate
          ? (_date == null
                ? null
                : StartHeightPicker.heightFromDate(widget.coin, _date!))
          : int.tryParse(_blockHeightController.text),
      isUsingDate: usingDate,
    );
  }

  Future<void> _chooseDate() async {
    if (!Util.isDesktop && FocusScope.of(context).hasFocus) {
      FocusScope.of(context).unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 125));
    }
    if (!mounted) {
      return;
    }

    final date = (await showSWDatePicker(context))?.first;
    if (date == null || !mounted) {
      return;
    }

    setState(() {
      _date = date;
      _dateController.text = Format.formatDate(date);
    });
    _apply();
  }

  @override
  Widget build(BuildContext context) {
    final isUsingDate = widget.controller.isUsingDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isUsingDate ? "Choose start date" : "Block height",
              style: Util.isDesktop
                  ? STextStyles.desktopTextExtraSmall(context).copyWith(
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.textDark3,
                    )
                  : STextStyles.smallMed12(context),
              textAlign: TextAlign.left,
            ),
            CustomTextButton(
              text: isUsingDate ? "Use block height" : "Use date",
              onTap: () => _apply(isUsingDate: !isUsingDate),
            ),
          ],
        ),
        SizedBox(height: Util.isDesktop ? 16 : 8),
        if (isUsingDate)
          RestoreFromDatePicker(onTap: _chooseDate, controller: _dateController)
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
            child: TextField(
              key: const Key("startHeightPickerBlockHeightFieldKey"),
              focusNode: _blockHeightFocusNode,
              controller: _blockHeightController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              style: Util.isDesktop
                  ? STextStyles.desktopTextMedium(context).copyWith(height: 2)
                  : STextStyles.field(context),
              onChanged: (_) {
                setState(_apply);
              },
              decoration:
                  standardInputDecoration(
                    "Start scanning from...",
                    _blockHeightFocusNode,
                    context,
                  ).copyWith(
                    suffixIcon: UnconstrainedBox(
                      child: TextFieldIconButton(
                        child: Semantics(
                          label:
                              "Clear Block Height Field Button. "
                              "Clears the block height field",
                          excludeSemantics: true,
                          child: _blockHeightController.text.isNotEmpty
                              ? XIcon(
                                  width: Util.isDesktop ? 24 : 16,
                                  height: Util.isDesktop ? 24 : 16,
                                )
                              : const SizedBox.shrink(),
                        ),
                        onTap: () {
                          _blockHeightController.text = "";
                          setState(_apply);
                        },
                      ),
                    ),
                  ),
            ),
          ),
        const SizedBox(height: 8),
        RoundedWhiteContainer(
          child: Center(
            child: Text(
              isUsingDate
                  ? "Choose the date you made the wallet (approximate is fine)"
                  : "Enter the initial block height of the wallet",
              style: Util.isDesktop
                  ? STextStyles.desktopTextExtraSmall(context).copyWith(
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.textSubtitle1,
                    )
                  : STextStyles.smallMed12(context).copyWith(fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }
}
