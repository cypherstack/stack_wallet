import 'package:flutter/material.dart';

import '../../../themes/stack_colors.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/wallet/impl/firo_wallet.dart';
import '../../../widgets/dialogs/s_dialog.dart';
import '../../../widgets/rounded_white_container.dart';
import '../masternode_details_view.dart';
import 'masternode_info_widget.dart';

class MasternodesList extends StatelessWidget {
  const MasternodesList({super.key, required this.nodes});

  final List<MasternodeInfo> nodes;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(Util.isDesktop ? 24 : 16),
      itemCount: nodes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) => _MasternodeCard(node: nodes[index]),
    );
  }
}

class _MasternodeCard extends StatelessWidget {
  const _MasternodeCard({required this.node});

  final MasternodeInfo node;

  Future<void> _showDetails(BuildContext context) async {
    if (Util.isDesktop) {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => SDialog(
          child: SizedBox(width: 600, child: MasternodeInfoWidget(info: node)),
        ),
      );
    } else {
      await Navigator.of(
        context,
      ).pushNamed(MasternodeDetailsView.routeName, arguments: node);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stack = Theme.of(context).extension<StackColors>()!;
    final isActive = node.revocationReason == 0;

    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(16),
      onPressed: () => _showDetails(context),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              children: [
                Text(
                  "${node.serviceAddr}:${node.servicePort}",
                  style: STextStyles.titleBold12(context),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "Last paid height: ${node.lastPaidHeight}",
                  style: STextStyles.baseXS(
                    context,
                  ).copyWith(color: stack.textSubtitle1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? stack.accentColorGreen : stack.accentColorRed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isActive ? "ACTIVE" : "REVOKED",
              style: STextStyles.w600_12(
                context,
              ).copyWith(color: stack.textWhite),
            ),
          ),
        ],
      ),
    );
  }
}
