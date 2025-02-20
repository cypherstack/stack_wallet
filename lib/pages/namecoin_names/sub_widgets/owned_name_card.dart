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
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/dialogs/s_dialog.dart';
import '../../../widgets/rounded_white_container.dart';
import 'name_details.dart';

class OwnedNameCard extends ConsumerStatefulWidget {
  const OwnedNameCard({
    super.key,
    required this.opNameData,
    required this.utxo,
  });

  final OpNameData opNameData;
  final UTXO utxo;

  @override
  ConsumerState<OwnedNameCard> createState() => _OwnedNameCardState();
}

class _OwnedNameCardState extends ConsumerState<OwnedNameCard> {
  String? constructedName, value;

  (String, Color) getExpiry(int currentChainHeight, StackColors theme) {
    final String message;
    final Color color;

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
      message = "$remaining blocks remaining";
      if (semiRemaining == null) {
        color = theme.accentColorYellow;
      } else {
        color = theme.accentColorGreen;
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
          builder: (context) => SDialog(
            child: NameDetailsView(
              utxoId: widget.utxo.id,
              walletId: widget.utxo.walletId,
            ),
          ),
        );
      } else {
        await Navigator.of(context).pushNamed(
          NameDetailsView.routeName,
          arguments: (
            widget.utxo.id,
            widget.utxo.walletId,
          ),
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
            final data = (jsonDecode(onValue) as Map).cast<String, String>();
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

  @override
  Widget build(BuildContext context) {
    final (message, color) = getExpiry(
      ref.watch(pWalletChainHeight(widget.utxo.walletId)),
      Theme.of(context).extension<StackColors>()!,
    );

    return RoundedWhiteContainer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(constructedName ?? ""),
                if (value != null)
                  const SizedBox(
                    height: 8,
                  ),
                if (value != null) SelectableText(value!),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: SelectableText(
              message,
              style: STextStyles.w500_12(context).copyWith(
                color: color,
              ),
            ),
          ),
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
