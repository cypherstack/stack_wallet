import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";

import "../../db/drift/shared_db/shared_database.dart";
import "../../models/shopinbit/shopinbit_enums.dart";
import "../../providers/global/shopin_bit_service_provider.dart";
import "../../services/shopinbit/src/models/car_research.dart";
import "../../themes/stack_colors.dart";
import "../../utilities/assets.dart";
import "../../utilities/logger.dart";
import "../../utilities/text_styles.dart";
import "../../utilities/util.dart";
import "../../widgets/background.dart";
import "../../widgets/conditional_parent.dart";
import "../../widgets/custom_buttons/app_bar_icon_button.dart";
import "../../widgets/desktop/desktop_dialog_close_button.dart";
import "../../widgets/dialogs/s_dialog.dart";
import "../../widgets/loading_indicator.dart";
import "../../widgets/refresh_control.dart";
import "../../widgets/rounded_container.dart";
import "../../widgets/stack_dialog.dart";
import "shopinbit_car_research_payment_view.dart";
import "shopinbit_ticket_detail.dart";

class ShopInBitTicketsView extends ConsumerStatefulWidget {
  const ShopInBitTicketsView({super.key});

  static const String routeName = "/shopInBitTickets";

  @override
  ConsumerState<ShopInBitTicketsView> createState() =>
      _ShopInBitTicketsViewState();
}

class _ShopInBitTicketsViewState extends ConsumerState<ShopInBitTicketsView> {
  bool _refreshing = false;
  bool _resuming = false;

  // Some unfinished car research fee invoices recovered from the server, if any.
  // The fee is paid before any ticket exists, so this is the only way to let
  // the user resume it — there is no local "pending" row anymore.
  List<CarResearchCurrentInvoice>? _resumableInvoices;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    if (mounted) setState(() => _refreshing = true);
    try {
      await Future.wait([
        ref.read(pShopinBitService).refreshAll(),
        _loadResumableInvoice(),
      ]);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  bool _needsReplacement(CarResearchCurrentInvoice invoice) {
    return !carResearchIsFinalized(invoice.status, invoice.additional) &&
        const {
          'expired',
          'underpaid_expired',
        }.contains(invoice.status.toLowerCase().trim());
  }

  /// Pull still-payable car research invoices from
  /// `GET /car-research/invoices/current` so they can be resumed.
  Future<void> _loadResumableInvoice() async {
    final resumable = <CarResearchCurrentInvoice>[];
    try {
      final customerKey = await ref.read(pShopinBitService).ensureCustomerKey();
      final resp = await ref
          .read(pShopinBitService)
          .client
          .getCurrentCarResearchInvoices(customerKey: customerKey);
      final invoices = resp.value;
      if (invoices != null) {
        for (final inv in invoices) {
          final finalized = carResearchIsFinalized(inv.status, inv.additional);
          final payable =
              inv.expiresAt != null &&
              (finalized ||
                  (inv.expiresAt!
                          .add(const Duration(hours: 24))
                          .isAfter(DateTime.now()) &&
                      (_needsReplacement(inv)
                          ? inv.hasRequestPayload
                          : inv.paymentLinks.isNotEmpty)));
          if (payable) {
            resumable.add(inv);
          }
        }
      }
      resumable.sort((a, b) {
        final aNeedsReplacement = _needsReplacement(a);
        final bNeedsReplacement = _needsReplacement(b);
        if (aNeedsReplacement != bNeedsReplacement) {
          return aNeedsReplacement ? 1 : -1;
        }
        final oldest = DateTime.fromMillisecondsSinceEpoch(0);
        return (b.createdAt ?? oldest).compareTo(a.createdAt ?? oldest);
      });
    } catch (e, s) {
      Logging.instance.e(
        "_loadResumableInvoice failed",
        error: e,
        stackTrace: s,
      );
      // Leave _resumableInvoice unchanged on failure.
      return;
    }
    if (mounted) {
      setState(() => _resumableInvoices = resumable.isEmpty ? null : resumable);
    }
  }

  Future<void> _resumeFlow(CarResearchCurrentInvoice currentInvoice) async {
    if (_resuming) return;
    setState(() => _resuming = true);
    try {
      final customerKey = await ref.read(pShopinBitService).ensureCustomerKey();
      CarResearchInvoice invoice;
      if (_needsReplacement(currentInvoice)) {
        final resp = await ref
            .read(pShopinBitService)
            .client
            .retryCarResearchInvoice(
              invoiceId: currentInvoice.invoiceId,
              customerKey: customerKey,
            );
        invoice = resp.valueOrThrow;
      } else {
        invoice = CarResearchInvoice(
          btcpayInvoice: currentInvoice.invoiceId,
          expiresAt: currentInvoice.expiresAt!,
          paymentLinks: currentInvoice.paymentLinks,
        );
      }

      if (mounted) {
        await Navigator.of(context).pushNamed(
          ShopInBitCarResearchPaymentView.routeName,
          arguments: (invoice: invoice, customerKey: customerKey),
        );
        if (mounted) {
          await _loadResumableInvoice();
        }
      }
    } catch (e, s) {
      Logging.instance.e("_resumeFlow failed", error: e, stackTrace: s);
      if (mounted) {
        await showDialog<void>(
          context: context,
          useRootNavigator: Util.isDesktop,
          builder: (context) => StackOkDialog(
            title: "Failed to resume payment",
            maxWidth: Util.isDesktop ? 500 : null,
            message: e.toString(),
            desktopPopRootNavigator: Util.isDesktop,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _resuming = false);
    }
  }

  List<Widget> _buildListChildren({
    required BuildContext context,
    required bool isDesktop,
    required List<ShopInBitTicket> tickets,
    required List<CarResearchCurrentInvoice>? resumable,
  }) {
    if (resumable == null && tickets.isEmpty) {
      return [
        const SizedBox(height: 80),
        Center(
          child: Text(
            _refreshing ? "Loading requests..." : "No requests yet",
            style: isDesktop
                ? STextStyles.desktopTextSmall(context)
                : STextStyles.itemSubtitle(context),
          ),
        ),
      ];
    }

    final children = <Widget>[];
    if (resumable != null) {
      for (var i = 0; i < resumable.length; i++) {
        if (i > 0) children.add(SizedBox(height: isDesktop ? 16 : 12));
        final invoice = resumable[i];
        children.add(
          RoundedContainer(
            color: Theme.of(context).extension<StackColors>()!.popupBG,
            onPressed: _resuming ? null : () => unawaited(_resumeFlow(invoice)),
            child: _RequestRow(
              title: "Car Research (In Progress)",
              subtitle: _resuming
                  ? "Opening your car research payment..."
                  : "${invoice.status} • Invoice ${invoice.invoiceId}",
              badgeText: "Resume",
              badgeColor: Theme.of(
                context,
              ).extension<StackColors>()!.accentColorYellow,
              loading: _resuming,
            ),
          ),
        );
      }
      if (tickets.isNotEmpty) {
        children.add(SizedBox(height: isDesktop ? 16 : 12));
      }
    }
    for (var i = 0; i < tickets.length; i++) {
      final ticket = tickets[i];
      if (i > 0) children.add(SizedBox(height: isDesktop ? 16 : 12));
      children.add(
        RoundedContainer(
          padding: EdgeInsets.all(isDesktop ? 16 : 12),
          borderColor: isDesktop
              ? Theme.of(context).extension<StackColors>()!.textFieldDefaultBG
              : null,
          color: Theme.of(context).extension<StackColors>()!.popupBG,
          onPressed: () => Navigator.of(context).pushNamed(
            ShopInBitTicketDetail.routeName,
            arguments: ticket.apiTicketId,
          ),
          child: _RequestRow(
            title: ticket.ticketNumber,
            subtitle:
                "${ticket.category.label} • "
                "${ticket.requestDescription}",
            badgeText: ticket.status.label,
            badgeColor: ticket.status.getColor(
              Theme.of(context).extension<StackColors>()!,
            ),
          ),
        ),
      );
    }
    return children;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final tickets =
        ref.watch(pShopInBitTickets).asData?.value ?? const <ShopInBitTicket>[];
    final resumables = _resumableInvoices;

    return ConditionalParent(
      condition: isDesktop,
      builder: (child) => SDialog(
        child: SizedBox(
          width: 580,
          child: Column(
            mainAxisSize: .min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const .only(left: 32),
                    child: Text(
                      "My requests",
                      style: STextStyles.desktopH3(context),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RefreshButton(
                        isRefreshing: _refreshing,
                        onPressed: _refresh,
                      ),
                      const SizedBox(width: 8),
                      const DesktopDialogCloseButton(),
                    ],
                  ),
                ],
              ),
              Flexible(
                child: Padding(
                  padding: const .only(
                    left: 32,
                    right: 32,
                    bottom: 32,
                    top: 16,
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
      child: ConditionalParent(
        condition: !isDesktop,
        builder: (child) => Background(
          child: Scaffold(
            backgroundColor: Theme.of(
              context,
            ).extension<StackColors>()!.background,
            appBar: AppBar(
              leading: AppBarBackButton(
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                "My requests",
                style: STextStyles.navBarTitle(context),
              ),
            ),
            body: SafeArea(
              child: Padding(padding: const .all(16), child: child),
            ),
          ),
        ),
        child: RefreshControl(
          onRefresh: _refresh,
          child: ListView(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            primary: isDesktop ? false : null,
            children: [
              ..._buildListChildren(
                context: context,
                isDesktop: isDesktop,
                tickets: tickets,
                resumable: resumables,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    this.loading = false,
  });

  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final stackColors = Theme.of(context).extension<StackColors>()!;

    final titleStyle = isDesktop
        ? STextStyles.desktopTextSmall(context)
        : STextStyles.titleBold12(context);

    final subtitleStyle = isDesktop
        ? STextStyles.desktopTextExtraExtraSmall(context)
        : STextStyles.itemSubtitle12(
            context,
          ).copyWith(color: stackColors.textSubtitle1);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: titleStyle),
                  _StatusBadge(text: badgeText, color: badgeColor),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: subtitleStyle,
              ),
            ],
          ),
        ),
        SizedBox(width: isDesktop ? 16 : 8),
        loading
            ? const SizedBox(width: 20, height: 20, child: LoadingIndicator())
            : SvgPicture.asset(
                Assets.svg.chevronRight,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  stackColors.textSubtitle1,
                  .srcIn,
                ),
              ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final style =
        (isDesktop
                ? STextStyles.desktopTextExtraExtraSmall(context)
                : STextStyles.itemSubtitle12(context))
            .copyWith(color: color);

    return Container(
      padding: const .symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.2),
      ),
      child: Text(text, style: style),
    );
  }
}
