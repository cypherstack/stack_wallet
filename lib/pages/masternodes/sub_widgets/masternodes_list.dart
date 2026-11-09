import 'package:flutter/material.dart';

import '../../../themes/stack_colors.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/wallet/impl/firo_wallet.dart';
import '../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/dialogs/s_dialog.dart';
import '../../../widgets/rounded_white_container.dart';
import '../masternode_details_view.dart';
import 'masternode_info_widget.dart';

class MasternodesList extends StatelessWidget {
  const MasternodesList({super.key, required this.nodes, this.onUnban});

  final List<MasternodeInfo> nodes;
  final Future<void> Function(MasternodeInfo node)? onUnban;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(Util.isDesktop ? 24 : 16),
      itemCount: nodes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) =>
          _MasternodeCard(node: nodes[index], onUnban: onUnban),
    );
  }
}

class _MasternodeCard extends StatelessWidget {
  const _MasternodeCard({required this.node, required this.onUnban});

  final MasternodeInfo node;
  final Future<void> Function(MasternodeInfo node)? onUnban;

  Future<void> _showDetails(BuildContext context) async {
    if (Util.isDesktop) {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) => SDialog(
          contentCanScroll: false,
          child: SizedBox(
            width: 600,
            child: Column(
              crossAxisAlignment: .stretch,
              mainAxisSize: .min,
              children: [
                Row(
                  mainAxisAlignment: .spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Text(
                        "Masternode details",
                        style: STextStyles.desktopH3(context),
                      ),
                    ),
                    const DesktopDialogCloseButton(),
                  ],
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: MasternodeInfoWidget(info: node),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      await Navigator.of(context)
          .pushNamed(MasternodeDetailsView.routeName, arguments: node);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stack = Theme.of(context).extension<StackColors>()!;
    final status = node.status;

    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(16),
      onPressed: () => _showDetails(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                      style: STextStyles.baseXS(context)
                          .copyWith(color: stack.textSubtitle1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: switch (status) {
                          MasternodeStatus.active => stack.accentColorGreen,
                          MasternodeStatus.banned => stack.accentColorRed,
                        },
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.label,
                        textAlign: TextAlign.center,
                        style: STextStyles.w600_12(context)
                            .copyWith(color: stack.textWhite),
                      ),
                    ),
                    if (status == MasternodeStatus.banned &&
                        node.poseBanHeight != -1 &&
                        node.revocationReason == 0 &&
                        onUnban != null) ...[
                      const SizedBox(height: 8),
                      SecondaryButton(
                        label: "Unban",
                        onPressed: () => onUnban!(node),
                        buttonHeight: Util.isDesktop ? .xs : .xl,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
