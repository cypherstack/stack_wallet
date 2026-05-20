import "dart:async";
import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";

import "../../db/drift/shared_db/shared_database.dart";
import "../../models/shopinbit/shopinbit_order_model.dart";
import "../../providers/db/drift_provider.dart";
import "../../providers/global/shopin_bit_service_provider.dart";
import "../../services/shopinbit/src/models/car_research.dart";
import "../../themes/stack_colors.dart";
import "../../utilities/assets.dart";
import "../../utilities/show_loading.dart";
import "../../utilities/text_styles.dart";
import "../../utilities/util.dart";
import "../../widgets/background.dart";
import "../../widgets/conditional_parent.dart";
import "../../widgets/custom_buttons/app_bar_icon_button.dart";
import "../../widgets/desktop/desktop_dialog_close_button.dart";
import "../../widgets/dialogs/s_dialog.dart";
import "../../widgets/rounded_container.dart";
import "shopinbit_car_fee_view.dart";
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
  List<ShopInBitOrderModel> _tickets = [];
  ShopInBitTicket? _pendingTicket;
  StreamSubscription<List<ShopInBitTicket>>? _ticketsSub;

  @override
  void initState() {
    super.initState();
    final db = ref.read(pSharedDrift);
    _ticketsSub = db.select(db.shopInBitTickets).watch().listen((rows) {
      if (!mounted) return;
      setState(() {
        _pendingTicket = rows.where((t) => t.isPendingPayment).firstOrNull;
        _tickets = rows
            .where((t) => !t.isPendingPayment)
            .map(ShopInBitOrderModel.fromDriftRow)
            .toList();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromApi());
  }

  @override
  void dispose() {
    _ticketsSub?.cancel();
    super.dispose();
  }

  void _resumeFlow(ShopInBitTicket pending) {
    final model = ShopInBitOrderModel.fromDriftRow(pending);
    final expiresAt = pending.carResearchExpiresAt;
    final linksJson = pending.carResearchPaymentLinks;
    final isDesktop = Util.isDesktop;

    if (expiresAt != null &&
        expiresAt.isAfter(DateTime.now()) &&
        linksJson != null) {
      // Invoice still live: navigate directly to payment view.
      final links = (jsonDecode(linksJson) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as String),
      );
      final invoice = CarResearchInvoice(
        btcpayInvoice: pending.carResearchInvoiceId!,
        expiresAt: expiresAt,
        paymentLinks: links,
      );
      if (isDesktop) {
        Navigator.of(context, rootNavigator: true).pop();
        showDialog<void>(
          context: context,
          builder: (_) =>
              ShopInBitCarResearchPaymentView(model: model, invoice: invoice),
        );
      } else {
        Navigator.of(context).pushNamed(
          ShopInBitCarResearchPaymentView.routeName,
          arguments: (model, invoice),
        );
      }
    } else {
      // Invoice expired: navigate to fee view.
      if (isDesktop) {
        Navigator.of(context, rootNavigator: true).pop();
        showDialog<void>(
          context: context,
          builder: (_) => ShopInBitCarFeeView(model: model),
        );
      } else {
        Navigator.of(
          context,
        ).pushNamed(ShopInBitCarFeeView.routeName, arguments: model);
      }
    }
  }

  Future<void> _syncFromApi() async {
    await showLoading(
      context: context,
      message: "Loading requests...",
      whileFutureAlt: _syncFromApiHelper,
      rootNavigator: Util.isDesktop,
    );
  }

  Future<void> _syncFromApiHelper() async {
    try {
      final service = ref.read(pShopinBitService);
      final customerKey = await service.ensureCustomerKey();
      final resp = await service.client.getTicketsByCustomer(customerKey);

      if (resp.hasError || resp.value == null) return;

      for (final ticketRef in resp.value!) {
        final localIdx = _tickets.indexWhere(
          (t) => t.apiTicketId == ticketRef.id,
        );
        if (localIdx < 0) continue;

        // Car research tickets return 403 on /tickets/:id/* endpoints.
        // if (_tickets[localIdx].category == ShopInBitCategory.car) continue;

        final statusResp = await service.client.getTicketStatus(ticketRef.id);
        if (statusResp.hasError || statusResp.value == null) continue;

        _tickets[localIdx].status = ShopInBitOrderModel.statusFromTicketState(
          statusResp.value!.state,
        );

        if (_tickets[localIdx].status == ShopInBitOrderStatus.offerAvailable &&
            (_tickets[localIdx].offerProductName == null ||
                _tickets[localIdx].offerPrice == null)) {
          final offerResp = await service.client.getTicketFull(ticketRef.id);
          if (!offerResp.hasError && offerResp.value != null) {
            _tickets[localIdx].setOffer(
              productName: offerResp.value!.productName,
              price: offerResp.value!.customerPrice,
            );
          }
        }

        final msgsResp = await service.client.getMessages(ticketRef.id);
        if (!msgsResp.hasError && msgsResp.value != null) {
          _tickets[localIdx].clearMessages();
          for (final m in msgsResp.value!) {
            _tickets[localIdx].addMessage(
              ShopInBitMessage(
                text: m.content,
                timestamp: m.timestamp,
                isFromUser: !m.fromAgent,
              ),
            );
          }
        }

        final db = ref.read(pSharedDrift);
        await db
            .into(db.shopInBitTickets)
            .insertOnConflictUpdate(_tickets[localIdx].toCompanion());
      }
    } catch (_) {
      // Fall back to local data — stream listener still has whatever was last persisted.
    }
  }

  static String _categoryLabel(ShopInBitCategory? category) =>
      switch (category) {
        ShopInBitCategory.concierge => "Concierge",
        ShopInBitCategory.travel => "Travel",
        ShopInBitCategory.car => "Car",
        null => "",
      };

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final pending = _pendingTicket;
    final hasTickets = _tickets.isNotEmpty;

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
                  const DesktopDialogCloseButton(),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: .min,
          children: [
            if (pending == null && !hasTickets)
              Center(
                child: Text(
                  "No requests yet",
                  style: Util.isDesktop
                      ? STextStyles.desktopTextSmall(context)
                      : STextStyles.itemSubtitle(context),
                ),
              )
            else ...[
              if (pending != null) ...[
                RoundedContainer(
                  color: Theme.of(context).extension<StackColors>()!.popupBG,
                  onPressed: () => _resumeFlow(pending),
                  child: _RequestRow(
                    title: "Car Research (In Progress)",
                    subtitle: "Tap to continue your car research payment",
                    badgeText: "Resume",
                    badgeColor: Theme.of(
                      context,
                    ).extension<StackColors>()!.accentColorYellow,
                  ),
                ),
                if (hasTickets) SizedBox(height: isDesktop ? 16 : 12),
              ],
              if (hasTickets)
                ListView.separated(
                  shrinkWrap: true,
                  primary: isDesktop ? false : null,
                  itemCount: _tickets.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(height: isDesktop ? 16 : 12),
                  itemBuilder: (context, index) {
                    final ticket = _tickets[index];

                    return RoundedContainer(
                      padding: .all(Util.isDesktop ? 16 : 12),
                      borderColor: Util.isDesktop
                          ? Theme.of(
                              context,
                            ).extension<StackColors>()!.textFieldDefaultBG
                          : null,
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.popupBG,
                      onPressed: () => Navigator.of(context).pushNamed(
                        ShopInBitTicketDetail.routeName,
                        arguments: ticket,
                      ),
                      child: _RequestRow(
                        title: ticket.ticketId ?? "N/A",
                        subtitle:
                            "${_categoryLabel(ticket.category)} \u2022 ${ticket.requestDescription}",
                        badgeText: ticket.status.label,
                        badgeColor: ticket.status.getColor(
                          Theme.of(context).extension<StackColors>()!,
                        ),
                      ),
                    );
                  },
                ),

              // // TODO: fix loading from locking everything up
              // if (_syncing) const LoadingIndicator(width: 24, height: 24),
            ],
          ],
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
  });

  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;

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
        SvgPicture.asset(
          Assets.svg.chevronRight,
          width: 14,
          colorFilter: ColorFilter.mode(stackColors.textSubtitle1, .srcIn),
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
        color: color.withOpacity(0.2),
      ),
      child: Text(text, style: style),
    );
  }
}
