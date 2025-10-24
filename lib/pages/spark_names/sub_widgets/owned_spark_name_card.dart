import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../db/drift/database.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/isar/providers/wallet_info_provider.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/dialogs/s_dialog.dart';
import '../../../widgets/rounded_white_container.dart';
import 'spark_name_details.dart';

class OwnedSparkNameCard extends ConsumerStatefulWidget {
  const OwnedSparkNameCard({
    super.key,
    required this.name,
    required this.walletId,
  });

  final SparkName name;
  final String walletId;

  @override
  ConsumerState<OwnedSparkNameCard> createState() => _OwnedSparkNameCardState();
}

class _OwnedSparkNameCardState extends ConsumerState<OwnedSparkNameCard> {
  (String, Color) _getExpiry(int currentChainHeight, StackColors theme) {
    final String message;
    final Color color;

    final remaining = widget.name.validUntil - currentChainHeight;

    if (widget.name.validUntil == -99999) {
      color = theme.accentColorYellow;
      message = "Pending";
    } else if (remaining <= 0) {
      color = theme.accentColorRed;
      message = "Expired";
    } else {
      message = "Expires in $remaining blocks";
      if (remaining < 1000) {
        // todo change arbitrary 1000 to something else?
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
          builder:
              (context) => SDialog(
                child: SparkNameDetailsView(
                  name: widget.name,
                  walletId: widget.walletId,
                ),
              ),
        );
      } else {
        await Navigator.of(context).pushNamed(
          SparkNameDetailsView.routeName,
          arguments: (name: widget.name, walletId: widget.walletId),
        );
      }
    } finally {
      _lock = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final (message, color) = _getExpiry(
      ref.watch(pWalletChainHeight(widget.walletId)),
      Theme.of(context).extension<StackColors>()!,
    );

    return RoundedWhiteContainer(
      padding:
          Util.isDesktop ? const EdgeInsets.all(16) : const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(widget.name.name),
              const SizedBox(height: 8),
              SelectableText(
                message,
                style: STextStyles.w500_12(context).copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(width: 12),
          PrimaryButton(
            label: "Details",
            width: Util.isDesktop ? 90 : null,
            buttonHeight: Util.isDesktop ? ButtonHeight.xs : ButtonHeight.l,
            onPressed: _showDetails,
          ),
        ],
      ),
    );
  }
}
