import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../utilities/logger.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_app_bar.dart';
import '../../widgets/desktop/desktop_scaffold.dart';
import '../../widgets/stack_dialog.dart';
import '../../providers/global/wallets_provider.dart';
import '../../wallets/wallet/impl/firo_wallet.dart';

class MasternodesHomeView extends ConsumerStatefulWidget {
  const MasternodesHomeView({super.key, required this.walletId});

  final String walletId;

  static const String routeName = "/masternodesHomeView";

  @override
  ConsumerState<MasternodesHomeView> createState() =>
      _MasternodesHomeViewState();
}

class _MasternodesHomeViewState extends ConsumerState<MasternodesHomeView> {
  late Future<List<MasternodeInfo>> _masternodesFuture;

  FiroWallet get _wallet =>
      ref.read(pWallets).getWallet(widget.walletId) as FiroWallet;

  @override
  void initState() {
    super.initState();
    _masternodesFuture = _wallet.getMyMasternodes();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    return MasterScaffold(
      isDesktop: isDesktop,
      appBar: isDesktop
          ? DesktopAppBar(
              isCompactHeight: true,
              background: Theme.of(context).extension<StackColors>()!.popupBG,
              leading: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 20),
                    child: AppBarIconButton(
                      size: 32,
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.textFieldDefaultBG,
                      shadows: const [],
                      icon: SvgPicture.asset(
                        Assets.svg.arrowLeft,
                        width: 18,
                        height: 18,
                        colorFilter: ColorFilter.mode(
                          Theme.of(
                            context,
                          ).extension<StackColors>()!.topNavIconPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                      onPressed: Navigator.of(context).pop,
                    ),
                  ),
                  SvgPicture.asset(
                    Assets.svg.robotHead,
                    width: 32,
                    height: 32,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).extension<StackColors>()!.textDark,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text("Masternodes", style: STextStyles.desktopH3(context)),
                ],
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(right: 24),
                child: ElevatedButton.icon(
                  onPressed: _showCreateMasternodeDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).extension<StackColors>()!.buttonBackPrimary,
                    foregroundColor: Theme.of(
                      context,
                    ).extension<StackColors>()!.buttonTextPrimary,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Masternode'),
                ),
              ),
            )
          : AppBar(
              leading: AppBarBackButton(
                onPressed: () => Navigator.of(context).pop(),
              ),
              titleSpacing: 0,
              title: Text(
                "Masternodes",
                style: STextStyles.navBarTitle(context),
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: IconButton(
                    onPressed: _showCreateMasternodeDialog,
                    icon: const Icon(Icons.add),
                    tooltip: 'Create Masternode',
                  ),
                ),
              ],
            ),
      body: _buildMasternodesTable(context),
    );
  }

  Widget _buildMasternodesTable(BuildContext context) {
    return FutureBuilder<List<MasternodeInfo>>(
      future: _masternodesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Failed to load masternodes",
              style: STextStyles.w600_14(context),
            ),
          );
        }
        final nodes = snapshot.data ?? const <MasternodeInfo>[];
        if (nodes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "No masternodes found",
                  style: STextStyles.w600_14(context),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showCreateMasternodeDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).extension<StackColors>()!.buttonBackPrimary,
                    foregroundColor: Theme.of(
                      context,
                    ).extension<StackColors>()!.buttonTextPrimary,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Your First Masternode'),
                ),
              ],
            ),
          );
        }

        final isDesktop = Util.isDesktop;
        final stack = Theme.of(context).extension<StackColors>()!;

        if (isDesktop) {
          return _buildDesktopTable(nodes, stack);
        } else {
          return _buildMobileTable(nodes, stack);
        }
      },
    );
  }

  Widget _buildDesktopTable(List<MasternodeInfo> nodes, StackColors stack) {
    return Container(
      color: stack.textFieldDefaultBG,
      child: Column(
        children: [
          // Fixed header
          Container(
            height: 56,
            color: stack.textFieldDefaultBG,
            child: Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('IP'),
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Last Paid Height'),
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Status'),
                    ),
                  ),
                ),
                Expanded(flex: 3, child: Container()),
              ],
            ),
          ),
          // Scrollable content
          Expanded(
            child: Container(
              width: double.infinity,
              color: stack.textFieldDefaultBG,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  children: nodes.map((node) {
                    final status = node.revocationReason == 0
                        ? 'Active'
                        : 'Revoked';
                    return SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  node.serviceAddr,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  node.lastPaidHeight.toString(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: status.toLowerCase() == 'active'
                                        ? stack.accentColorGreen
                                        : stack.accentColorRed,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: STextStyles.w600_12(
                                      context,
                                    ).copyWith(color: stack.textWhite),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          _showMasternodeInfoDialog(node),
                                      icon: const Icon(Icons.info_outline),
                                      tooltip: 'View Details',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTable(List<MasternodeInfo> nodes, StackColors stack) {
    return Container(
      color: stack.textFieldDefaultBG,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: nodes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 1),
        itemBuilder: (context, index) {
          final node = nodes[index];
          final status = node.revocationReason == 0 ? 'Active' : 'Revoked';

          return Container(
            width: double.infinity,
            color: stack.textFieldDefaultBG,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'IP: ${node.serviceAddr}',
                          style: STextStyles.w600_14(context),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status.toLowerCase() == 'active'
                            ? stack.accentColorGreen
                            : stack.accentColorRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: STextStyles.w600_12(
                          context,
                        ).copyWith(color: stack.textWhite),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildMobileRow(
                  'Last Paid Height',
                  node.lastPaidHeight.toString(),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showMasternodeInfoDialog(node),
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Details'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: stack.textFieldDefaultBG,
                        foregroundColor: stack.buttonTextSecondary,
                        side: BorderSide(
                          color: stack.buttonBackBorderSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$label:',
                style: STextStyles.w500_12(context).copyWith(
                  color: Theme.of(
                    context,
                  ).extension<StackColors>()!.textSubtitle1,
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(value, style: STextStyles.w500_12(context)),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateMasternodeDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _CreateMasternodeDialog(wallet: _wallet),
    );
  }

  void _showMasternodeInfoDialog(MasternodeInfo node) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _MasternodeInfoDialog(node: node),
    );
  }
}

class _CreateMasternodeDialog extends StatefulWidget {
  const _CreateMasternodeDialog({required this.wallet});

  final FiroWallet wallet;

  @override
  State<_CreateMasternodeDialog> createState() =>
      _CreateMasternodeDialogState();
}

class _CreateMasternodeDialogState extends State<_CreateMasternodeDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _ipAndPortController = TextEditingController();
  final TextEditingController _operatorPubKeyController =
      TextEditingController();
  final TextEditingController _votingAddressController =
      TextEditingController();
  final TextEditingController _operatorRewardController = TextEditingController(
    text: "0",
  );
  final TextEditingController _payoutAddressController =
      TextEditingController();
  bool _isRegistering = false;
  String? _errorMessage;

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
    final spendable = widget.wallet.info.cachedBalance.spendable;
    final spendableFiro = spendable.decimal;
    final threshold = Decimal.fromInt(1000);
    final canRegister = spendableFiro >= threshold;
    final availableCount = (spendableFiro ~/ threshold).toInt();

    return AlertDialog(
      backgroundColor: stack.popupBG,
      title: const Text('Create Masternode'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!canRegister)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: stack.textFieldErrorBG,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Insufficient funds to register a masternode. You need at least 1000 public FIRO.',
                    style: STextStyles.w600_14(
                      context,
                    ).copyWith(color: stack.textDark),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: stack.textFieldSuccessBG,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'You can register $availableCount masternode(s).',
                    style: STextStyles.w600_14(
                      context,
                    ).copyWith(color: stack.textDark),
                  ),
                ),
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: stack.textFieldErrorBG,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Registration failed: $_errorMessage',
                    style: STextStyles.w600_14(
                      context,
                    ).copyWith(color: stack.textDark),
                  ),
                ),
              TextFormField(
                controller: _ipAndPortController,
                decoration: const InputDecoration(
                  labelText: 'IP:Port',
                  hintText: '123.45.67.89:8168',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final parts = v.split(':');
                  if (parts.length != 2) return 'Format must be ip:port';
                  if (int.tryParse(parts[1]) == null) return 'Invalid port';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _operatorPubKeyController,
                decoration: const InputDecoration(
                  labelText: 'Operator public key (BLS)',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _votingAddressController,
                decoration: const InputDecoration(
                  labelText: 'Voting address (optional)',
                  hintText: 'Defaults to owner address',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _operatorRewardController,
                decoration: const InputDecoration(
                  labelText: 'Operator reward (%)',
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _payoutAddressController,
                decoration: const InputDecoration(labelText: 'Payout address'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isRegistering ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isRegistering || !canRegister
              ? null
              : _registerMasternode,
          style: FilledButton.styleFrom(
            backgroundColor: stack.buttonBackPrimary,
            foregroundColor: stack.buttonTextPrimary,
          ),
          child: _isRegistering
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _registerMasternode() async {
    setState(() {
      _isRegistering = true;
      _errorMessage = null; // Clear any previous error
    });

    try {
      final parts = _ipAndPortController.text.trim().split(':');
      final ip = parts[0];
      final port = int.parse(parts[1]);
      final operatorPubKey = _operatorPubKeyController.text.trim();
      final votingAddress = _votingAddressController.text.trim();
      final operatorReward = _operatorRewardController.text.trim().isNotEmpty
          ? (double.parse(_operatorRewardController.text.trim()) * 100).floor()
          : 0;
      final payoutAddress = _payoutAddressController.text.trim();

      final txId = await widget.wallet.registerMasternode(
        ip,
        port,
        operatorPubKey,
        votingAddress,
        operatorReward,
        payoutAddress,
      );

      if (!mounted) return;

      // Get the parent navigator context before popping
      final navigator = Navigator.of(context, rootNavigator: Util.isDesktop);
      navigator.pop();

      Logging.instance.i('Masternode registration submitted: $txId');

      // Show success dialog after frame is complete to ensure navigation stack is correct
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          barrierDismissible: true,
          useRootNavigator: Util.isDesktop,
          builder: (_) => StackOkDialog(
            title: 'Masternode Registration Submitted',
            message:
                'Masternode registration submitted, your masternode will appear in the list after the tx is confirmed.\n\nTransaction ID: $txId',
            desktopPopRootNavigator: Util.isDesktop,
          ),
        );
      });
    } catch (e, s) {
      Logging.instance.e(
        "Masternode registration failed",
        error: e,
        stackTrace: s,
      );

      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isRegistering = false;
      });
    }
  }
}

class _MasternodeInfoDialog extends StatelessWidget {
  const _MasternodeInfoDialog({required this.node});

  final MasternodeInfo node;

  @override
  Widget build(BuildContext context) {
    final stack = Theme.of(context).extension<StackColors>()!;
    final status = node.revocationReason == 0 ? 'Active' : 'Revoked';

    return AlertDialog(
      backgroundColor: stack.popupBG,
      title: const Text('Masternode Information'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow(context, 'ProTx Hash', node.proTxHash),
              _buildInfoRow(
                context,
                'IP:Port',
                '${node.serviceAddr}:${node.servicePort}',
              ),
              _buildInfoRow(context, 'Status', status),
              _buildInfoRow(
                context,
                'Registered Height',
                node.registeredHeight.toString(),
              ),
              _buildInfoRow(
                context,
                'Last Paid Height',
                node.lastPaidHeight.toString(),
              ),
              _buildInfoRow(context, 'Payout Address', node.payoutAddress),
              _buildInfoRow(context, 'Owner Address', node.ownerAddress),
              _buildInfoRow(context, 'Voting Address', node.votingAddress),
              _buildInfoRow(
                context,
                'Operator Public Key',
                node.pubKeyOperator,
              ),
              _buildInfoRow(
                context,
                'Operator Reward',
                '${node.operatorReward / 100} %',
              ),
              _buildInfoRow(context, 'Collateral Hash', node.collateralHash),
              _buildInfoRow(
                context,
                'Collateral Index',
                node.collateralIndex.toString(),
              ),
              _buildInfoRow(
                context,
                'Collateral Address',
                node.collateralAddress,
              ),
              _buildInfoRow(
                context,
                'Pose Penalty',
                node.posePenalty.toString(),
              ),
              _buildInfoRow(
                context,
                'Pose Revived Height',
                node.poseRevivedHeight.toString(),
              ),
              _buildInfoRow(
                context,
                'Pose Ban Height',
                node.poseBanHeight.toString(),
              ),
              _buildInfoRow(
                context,
                'Revocation Reason',
                node.revocationReason.toString(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: stack.buttonBackPrimary,
            foregroundColor: stack.buttonTextPrimary,
          ),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: STextStyles.w600_14(context).copyWith(
              color: Theme.of(context).extension<StackColors>()!.textSubtitle1,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).extension<StackColors>()!.textFieldDefaultBG,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(value, style: STextStyles.w500_12(context)),
          ),
        ],
      ),
    );
  }
}
