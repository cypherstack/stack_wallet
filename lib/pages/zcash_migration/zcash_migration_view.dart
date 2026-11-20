import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../providers/providers.dart';
import '../../route_generator.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/logger.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../wallets/models/tx_data.dart';
import '../../wallets/wallet/impl/zcash_wallet.dart';
import '../../wallets/wallet/intermediate/zcash_migration.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_app_bar.dart';
import '../../widgets/desktop/desktop_scaffold.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_dialog.dart';
import '../../widgets/textfields/adaptive_text_field.dart';
import '../send_view/confirm_transaction_view.dart';
import '../send_view/sub_widgets/building_transaction_dialog.dart';
import '../send_view/zcash_parameter_acquisition.dart';

class ZcashMigrationView extends ConsumerStatefulWidget {
  const ZcashMigrationView({super.key, required this.walletId});

  static const routeName = '/zcashMigrationView';

  final String walletId;

  @override
  ConsumerState<ZcashMigrationView> createState() => _ZcashMigrationViewState();
}

class _ZcashMigrationViewState extends ConsumerState<ZcashMigrationView> {
  late Future<ZcashMigrationOverview> _overview;
  bool _preparing = false;

  ZcashWallet get _wallet =>
      ref.read(pWallets).getWallet(widget.walletId) as ZcashWallet;

  @override
  void initState() {
    super.initState();
    _overview = _wallet.migrationOverview();
  }

  Future<void> _routePressed(ZcashMigrationRoute route) async {
    if (_preparing) return;
    _preparing = true;
    try {
      final overview = await _overview;
      if (!mounted) return;

      Amount? amount;
      if (route == ZcashMigrationRoute.transparentToIronwood) {
        final approved = await _confirmRoute(
          title: 'Shield transparent funds?',
          message:
              'All mature transparent funds will be swept into this '
              "wallet's Ironwood pool. The exact fee will be shown before "
              'broadcast.',
        );
        if (!approved || !mounted) return;
      } else if (route == ZcashMigrationRoute.saplingToIronwood) {
        amount = await showDialog<Amount>(
          context: context,
          builder: (_) => _ZcashMigrationAmountDialog(
            title: 'Migrate Sapling funds',
            availableZatoshis: overview.saplingSpendableZatoshis,
          ),
        );
        if (amount == null || !mounted) return;
      } else {
        final approved = await _confirmRoute(
          title: 'Move funds to transparent?',
          message:
              'Transparent funds and transaction amounts are publicly visible. '
              'Stack leaves positive Ironwood change; this flow does not '
              'provide a Max action.',
        );
        if (!approved || !mounted) return;
        amount = await showDialog<Amount>(
          context: context,
          builder: (_) => _ZcashMigrationAmountDialog(
            title: 'Move Ironwood funds',
            availableZatoshis: overview.ironwoodSpendableZatoshis,
          ),
        );
        if (amount == null || !mounted) return;
      }

      await _prepare(route, amount);
    } finally {
      _preparing = false;
    }
  }

  Future<bool> _confirmRoute({
    required String title,
    required String message,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StackDialog(
          title: title,
          message: message,
          leftButton: TextButton(
            style: Theme.of(dialogContext)
                .extension<StackColors>()!
                .getSecondaryEnabledButtonStyle(dialogContext),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: STextStyles.button(dialogContext)),
          ),
          rightButton: TextButton(
            style: Theme.of(dialogContext)
                .extension<StackColors>()!
                .getPrimaryEnabledButtonStyle(dialogContext),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Continue', style: STextStyles.button(dialogContext)),
          ),
        ),
      ) ??
      false;

  Future<void> _prepare(ZcashMigrationRoute route, Amount? amount) async {
    var nextBuildingDialogId = 0;
    int? activeBuildingDialogId;
    final buildingDialogContexts = <int, BuildContext>{};
    final closedBuildingDialogs = <int>{};
    var cancelled = false;
    TxData? preparedForReview;

    void closeBuildingDialog() {
      final dialogId = activeBuildingDialogId;
      if (dialogId == null) return;
      activeBuildingDialogId = null;
      closedBuildingDialogs.add(dialogId);
      final dialogContext = buildingDialogContexts[dialogId];
      if (dialogContext?.mounted == true) {
        final route = ModalRoute.of(dialogContext!);
        if (route != null) {
          Navigator.of(dialogContext).removeRoute(route);
        }
      }
    }

    void showBuildingDialog() {
      final dialogId = ++nextBuildingDialogId;
      activeBuildingDialogId = dialogId;
      unawaited(
        showDialog<void>(
          context: context,
          useSafeArea: false,
          barrierDismissible: false,
          builder: (dialogContext) {
            buildingDialogContexts[dialogId] = dialogContext;
            if (closedBuildingDialogs.contains(dialogId)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!dialogContext.mounted) return;
                final route = ModalRoute.of(dialogContext);
                if (route != null) {
                  Navigator.of(dialogContext).removeRoute(route);
                }
              });
            }
            return BuildingTransactionDialog(
              coin: _wallet.cryptoCurrency,
              isSpark: false,
              onCancel: () {
                cancelled = true;
                closeBuildingDialog();
              },
            );
          },
        ).whenComplete(() {
          buildingDialogContexts.remove(dialogId);
          closedBuildingDialogs.remove(dialogId);
          if (activeBuildingDialogId == dialogId) {
            activeBuildingDialogId = null;
          }
        }),
      );
    }

    try {
      showBuildingDialog();
      Future<TxData> prepare() =>
          _wallet.prepareMigration(route: route, amount: amount);
      final TxData? txData;
      if (route == ZcashMigrationRoute.saplingToIronwood) {
        txData = await prepareWithZcashSaplingParameterAcquisition<TxData>(
          context: context,
          prepare: prepare,
          canAcquire: () => !cancelled,
          beforeAcquisition: () async => closeBuildingDialog(),
          afterAcquisition: () async {
            if (mounted && !cancelled) showBuildingDialog();
          },
        );
      } else {
        txData = await prepare();
      }
      closeBuildingDialog();
      if (txData == null || cancelled || !mounted) {
        if (txData != null) await _wallet.cancelSend(txData: txData);
        return;
      }
      final prepared = txData;
      preparedForReview = prepared;
      await Navigator.of(context).push(
        RouteGenerator.getRoute<void>(
          shouldUseMaterialRoute: RouteGenerator.useMaterialPageRoute,
          builder: (_) => ConfirmTransactionView(
            txData: prepared,
            walletId: widget.walletId,
            onSuccess: () {
              if (mounted) {
                setState(() => _overview = _wallet.migrationOverview());
              }
            },
          ),
          settings: const RouteSettings(name: ConfirmTransactionView.routeName),
        ),
      );
    } catch (error, stackTrace) {
      closeBuildingDialog();
      final prepared = preparedForReview;
      if (prepared != null) {
        await _wallet.cancelSend(txData: prepared).catchError((Object error) {
          Logging.instance.e(
            'Failed to release prepared Zcash migration',
            error: error,
          );
        });
      }
      Logging.instance.e(
        'Zcash migration preparation failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted && !cancelled) {
        await showDialog<void>(
          context: context,
          builder: (_) => const StackOkDialog(
            title: 'Unable to prepare migration',
            message:
                'The transaction could not be prepared. Make sure the wallet '
                'is fully synchronized, reduce the amount, and try again.',
          ),
        );
      }
    }
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
                    child: AppBarBackButton(
                      size: 32,
                      onPressed: Navigator.of(context).pop,
                    ),
                  ),
                  Text('Migrate Zcash', style: STextStyles.desktopH3(context)),
                ],
              ),
            )
          : AppBar(
              leading: AppBarBackButton(onPressed: Navigator.of(context).pop),
              titleSpacing: 0,
              title: Text(
                'Migrate Zcash',
                style: STextStyles.navBarTitle(context),
              ),
            ),
      body: ConditionalParent(
        condition: !isDesktop,
        builder: (child) => SafeArea(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: FutureBuilder<ZcashMigrationOverview>(
              future: _overview,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load Zcash pool balances. Make sure the '
                      'wallet is synchronized and try again.',
                      textAlign: TextAlign.center,
                      style: STextStyles.smallMed14(context),
                    ),
                  );
                }
                final overview = snapshot.data;
                if (overview == null) return const LoadingIndicator();
                return ZcashMigrationPanel(
                  overview: overview,
                  formatZatoshis: (value) {
                    final amount = Amount(
                      rawValue: BigInt.from(value),
                      fractionDigits: 8,
                    );
                    return '${amount.decimal} ZEC';
                  },
                  onRoutePressed: (route) => unawaited(_routePressed(route)),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ZcashMigrationPanel extends StatelessWidget {
  const ZcashMigrationPanel({
    super.key,
    required this.overview,
    required this.formatZatoshis,
    required this.onRoutePressed,
  });

  final ZcashMigrationOverview overview;
  final String Function(int zatoshis) formatZatoshis;
  final ValueChanged<ZcashMigrationRoute> onRoutePressed;

  @override
  Widget build(BuildContext context) {
    final routes = overview.availableRoutes;
    return ListView(
      padding: Util.isDesktop ? const EdgeInsets.all(24) : EdgeInsets.zero,
      children: [
        Text(
          'Move wallet-owned funds between supported Zcash pools. Every '
          'transaction is reviewed before broadcast.',
          style: STextStyles.smallMed14(context),
        ),
        const SizedBox(height: 16),
        if (routes.contains(ZcashMigrationRoute.transparentToIronwood))
          _MigrationActionCard(
            title: 'Transparent → Ironwood',
            detail: 'Shield all mature transparent outputs in one exact sweep.',
            balance: formatZatoshis(overview.transparentSpendableZatoshis),
            buttonKey: const Key('zcash_migrate_transparent'),
            buttonLabel: 'Shield funds',
            onPressed: () =>
                onRoutePressed(ZcashMigrationRoute.transparentToIronwood),
          ),
        if (routes.contains(ZcashMigrationRoute.saplingToIronwood))
          _MigrationActionCard(
            title: 'Sapling → Ironwood',
            detail:
                'Choose an amount. Sapling proving data is downloaded only '
                'when needed.',
            balance: formatZatoshis(overview.saplingSpendableZatoshis),
            buttonKey: const Key('zcash_migrate_sapling'),
            buttonLabel: 'Migrate funds',
            onPressed: () =>
                onRoutePressed(ZcashMigrationRoute.saplingToIronwood),
          ),
        if (routes.contains(ZcashMigrationRoute.ironwoodToTransparent))
          _MigrationActionCard(
            title: 'Ironwood → Transparent',
            detail:
                'Choose an amount to make public. Positive Ironwood change is '
                'always retained.',
            balance: formatZatoshis(overview.ironwoodSpendableZatoshis),
            buttonKey: const Key('zcash_migrate_ironwood'),
            buttonLabel: 'Move funds',
            onPressed: () =>
                onRoutePressed(ZcashMigrationRoute.ironwoodToTransparent),
          ),
        _MigrationActionCard(
          title: 'Orchard migration is scheduled only',
          detail: overview.orchardIsScheduledOnly
              ? 'This wallet has migratable Orchard funds. ZIP 318 requires '
                    'a randomized persistent schedule; an immediate migration '
                    'is intentionally unavailable.'
              : 'No migratable Orchard funds are currently detected.',
          balance: formatZatoshis(overview.orchardMigratableZatoshis),
        ),
      ],
    );
  }
}

class _MigrationActionCard extends StatelessWidget {
  const _MigrationActionCard({
    required this.title,
    required this.detail,
    required this.balance,
    this.buttonKey,
    this.buttonLabel,
    this.onPressed,
  });

  final String title;
  final String detail;
  final String balance;
  final Key? buttonKey;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: RoundedWhiteContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: STextStyles.w600_16(context)),
          const SizedBox(height: 4),
          Text(detail, style: STextStyles.smallMed12(context)),
          const SizedBox(height: 12),
          Text('Available: $balance', style: STextStyles.w500_14(context)),
          if (onPressed != null) ...[
            const SizedBox(height: 12),
            PrimaryButton(
              key: buttonKey,
              buttonHeight: ButtonHeight.l,
              label: buttonLabel,
              onPressed: onPressed,
            ),
          ],
        ],
      ),
    ),
  );
}

class _ZcashMigrationAmountDialog extends StatefulWidget {
  const _ZcashMigrationAmountDialog({
    required this.title,
    required this.availableZatoshis,
  });

  final String title;
  final int availableZatoshis;

  @override
  State<_ZcashMigrationAmountDialog> createState() =>
      _ZcashMigrationAmountDialogState();
}

class _ZcashMigrationAmountDialogState
    extends State<_ZcashMigrationAmountDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    final amount = Amount.tryParseEditableAmount(
      _controller.text,
      locale: Localizations.localeOf(context).toString(),
      fractionDigits: 8,
    );
    if (amount == null ||
        amount.raw <= BigInt.zero ||
        amount.raw >= BigInt.from(widget.availableZatoshis)) {
      setState(() {
        _error =
            'Enter a positive amount below the available balance to '
            'leave room for the network fee and required change.';
      });
      return;
    }
    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) => StackDialogBase(
    width: Util.isDesktop ? 480 : null,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: STextStyles.pageTitleH2(context)),
        const SizedBox(height: 8),
        Text(
          'Enter an amount below the available balance. The exact fee and '
          'destination are shown on the next screen.',
          style: STextStyles.smallMed14(context),
        ),
        const SizedBox(height: 16),
        AdaptiveTextField(
          textFieldKey: const Key('zcash_migration_amount'),
          controller: _controller,
          labelText: 'Amount (ZEC)',
          hintText: '0',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          errorText: _error,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextButton(
                style: Theme.of(context)
                    .extension<StackColors>()!
                    .getSecondaryEnabledButtonStyle(context),
                onPressed: Navigator.of(context).pop,
                child: Text('Cancel', style: STextStyles.button(context)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton(
                style: Theme.of(context)
                    .extension<StackColors>()!
                    .getPrimaryEnabledButtonStyle(context),
                onPressed: _continue,
                child: Text('Continue', style: STextStyles.button(context)),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
