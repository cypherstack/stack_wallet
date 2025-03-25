import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:namecoin/namecoin.dart';

import '../../../models/isar/models/isar_models.dart';
import '../../../providers/global/secure_store_provider.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/isar/providers/wallet_info_provider.dart';
import '../../../wallets/wallet/impl/namecoin_wallet.dart';
import '../../../widgets/conditional_parent.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/dialogs/s_dialog.dart';
import '../../../widgets/rounded_white_container.dart';
import 'spark_name_details.dart';

class OwnedSparkNameCard extends ConsumerStatefulWidget {
  const OwnedSparkNameCard({
    super.key,
    required this.opNameData,
    required this.utxo,
    this.firstColWidth,
    this.calculatedFirstColWidth,
  });

  final OpNameData opNameData;
  final UTXO utxo;

  final double? firstColWidth;
  final void Function(double)? calculatedFirstColWidth;

  @override
  ConsumerState<OwnedSparkNameCard> createState() => _OwnedSparkNameCardState();
}

class _OwnedSparkNameCardState extends ConsumerState<OwnedSparkNameCard> {
  String? constructedName, value;

  (String, Color) _getExpiry(int currentChainHeight, StackColors theme) {
    final String message;
    final Color color;

    if (widget.utxo.blockHash == null) {
      message = "Expires in $blocksNameExpiration+ blocks";
      color = theme.accentColorGreen;
    } else {
      final remaining = widget.opNameData.expiredBlockLeft(
        currentChainHeight,
        false,
      );
      final semiRemaining = widget.opNameData.expiredBlockLeft(
        currentChainHeight,
        true,
      );

      if (remaining == null) {
        color = theme.accentColorRed;
        message = "Expired";
      } else {
        message = "Expires in $remaining blocks";
        if (semiRemaining == null) {
          color = theme.accentColorYellow;
        } else {
          color = theme.accentColorGreen;
        }
      }
    }

    return (message, color);
  }

  bool _lock = false;

  Future<void> _showDetails() async {
    if (_lock) return;
    _lock = true;
    try {
      if (Util.isDesktop) {
        await showDialog<void>(
          context: context,
          builder:
              (context) => SDialog(
                child: SparkNameDetailsView(
                  utxoId: widget.utxo.id,
                  walletId: widget.utxo.walletId,
                ),
              ),
        );
      } else {
        await Navigator.of(context).pushNamed(
          SparkNameDetailsView.routeName,
          arguments: (widget.utxo.id, widget.utxo.walletId),
        );
      }
    } finally {
      _lock = false;
    }
  }

  void _setName() {
    try {
      constructedName = widget.opNameData.constructedName;
      value = widget.opNameData.value;
    } catch (_) {
      if (widget.opNameData.op == OpName.nameNew) {
        ref
            .read(secureStoreProvider)
            .read(
              key: nameSaltKeyBuilder(
                widget.utxo.txid,
                widget.utxo.walletId,
                widget.utxo.vout,
              ),
            )
            .then((onValue) {
              if (onValue != null) {
                final data =
                    (jsonDecode(onValue) as Map).cast<String, String>();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  constructedName = data["name"]!;
                  value = data["value"]!;
                  if (mounted) {
                    setState(() {});
                  }
                });
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  constructedName = "UNKNOWN";
                  value = "";
                  if (mounted) {
                    setState(() {});
                  }
                });
              }
            });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _setName();
  }

  double _callbackWidth = 0;

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final (message, color) = _getExpiry(
      ref.watch(pWalletChainHeight(widget.utxo.walletId)),
      Theme.of(context).extension<StackColors>()!,
    );

    return RoundedWhiteContainer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ConditionalParent(
            condition: widget.firstColWidth != null && Util.isDesktop,
            builder:
                (child) => ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: widget.firstColWidth!),
                  child: child,
                ),
            child: ConditionalParent(
              condition: widget.firstColWidth == null && Util.isDesktop,
              builder:
                  (child) => LayoutBuilder(
                    builder: (context, constraints) {
                      if (widget.firstColWidth == null &&
                          _callbackWidth != constraints.maxWidth) {
                        _callbackWidth = constraints.maxWidth;
                        widget.calculatedFirstColWidth?.call(_callbackWidth);
                      }
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth,
                        ),
                        child: child,
                      );
                    },
                  ),
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(constructedName ?? ""),
                    const SizedBox(height: 8),
                    SelectableText(
                      message,
                      style: STextStyles.w500_12(
                        context,
                      ).copyWith(color: color),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (Util.isDesktop)
            Expanded(
              child: SelectableText(
                value ?? "",
                style: STextStyles.w500_12(context),
              ),
            ),
          if (Util.isDesktop) const SizedBox(width: 12),
          PrimaryButton(
            label: "Details",
            buttonHeight: Util.isDesktop ? ButtonHeight.xs : ButtonHeight.l,
            onPressed: _showDetails,
          ),
        ],
      ),
    );
  }
}
