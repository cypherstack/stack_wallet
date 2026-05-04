import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../db/isar/main_db.dart';
import '../../models/isar/models/shopinbit_ticket.dart';
import '../../models/shopinbit/shopinbit_order_model.dart';
import '../../services/shopinbit/shopinbit_service.dart';
import '../../services/shopinbit/src/models/car_research.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/rounded_white_container.dart';
import 'shopinbit_car_fee_view.dart';
import 'shopinbit_car_research_payment_view.dart';
import 'shopinbit_ticket_detail.dart';

class ShopInBitTicketsView extends StatefulWidget {
  const ShopInBitTicketsView({super.key});

  static const String routeName = "/shopInBitTickets";

  @override
  State<ShopInBitTicketsView> createState() => _ShopInBitTicketsViewState();
}

class _ShopInBitTicketsViewState extends State<ShopInBitTicketsView> {
  List<ShopInBitOrderModel> _tickets = [];
  bool _syncing = false;
  ShopInBitTicket? _pendingTicket;
  StreamSubscription<void>? _isarSub;

  @override
  void initState() {
    super.initState();
    _loadLocal();
    _syncFromApi();
    // Refresh on ticket writes.
    _isarSub = MainDB.instance.isar.shopInBitTickets.watchLazy().listen((_) {
      if (mounted) setState(_loadLocal);
    });
  }

  @override
  void dispose() {
    _isarSub?.cancel();
    super.dispose();
  }

  void _loadLocal() {
    final allTickets = MainDB.instance.getShopInBitTickets();
    _pendingTicket = allTickets.where((t) => t.isPendingPayment).firstOrNull;
    _tickets = allTickets
        .where((t) => !t.isPendingPayment)
        .map(ShopInBitOrderModel.fromIsarTicket)
        .toList();
  }

  void _resumeFlow(ShopInBitTicket pending) {
    final model = ShopInBitOrderModel.fromIsarTicket(pending);
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
    setState(() => _syncing = true);
    try {
      final service = ShopInBitService.instance;
      final customerKey = await service.ensureCustomerKey();
      final resp = await service.client.getTicketsByCustomer(customerKey);

      if (resp.hasError || resp.value == null) return;

      for (final ref in resp.value!) {
        final localIdx = _tickets.indexWhere((t) => t.apiTicketId == ref.id);
        if (localIdx < 0) continue;

        // Car research tickets return 403 on /tickets/:id/* endpoints.
        if (_tickets[localIdx].category == ShopInBitCategory.car) continue;

        final statusResp = await service.client.getTicketStatus(ref.id);
        if (statusResp.hasError || statusResp.value == null) continue;

        final mapped = ShopInBitOrderModel.statusFromTicketState(
          statusResp.value!.state,
        );
        _tickets[localIdx].statusRaw = statusResp.value!.stateRaw;
        if (mapped != null) _tickets[localIdx].status = mapped;

        if (_tickets[localIdx].status == ShopInBitOrderStatus.offerAvailable &&
            (_tickets[localIdx].offerProductName == null ||
                _tickets[localIdx].offerPrice == null)) {
          final offerResp = await service.client.getTicketFull(ref.id);
          if (!offerResp.hasError && offerResp.value != null) {
            _tickets[localIdx].setOffer(
              productName: offerResp.value!.productName,
              price: offerResp.value!.customerPrice,
            );
          }
        }

        final msgsResp = await service.client.getMessages(ref.id);
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

        await MainDB.instance.putShopInBitTicket(
          _tickets[localIdx].toIsarTicket(),
        );
      }
    } catch (_) {
      // Fall back to local data
    } finally {
      if (mounted) {
        _loadLocal();
        setState(() => _syncing = false);
      }
    }
  }

  String _statusLabel(ShopInBitOrderStatus status) {
    switch (status) {
      case ShopInBitOrderStatus.pending:
        return "Pending";
      case ShopInBitOrderStatus.reviewing:
        return "Under review";
      case ShopInBitOrderStatus.offerAvailable:
        return "Offer available";
      case ShopInBitOrderStatus.accepted:
        return "Accepted";
      case ShopInBitOrderStatus.paymentPending:
        return "Awaiting payment";
      case ShopInBitOrderStatus.paid:
        return "Paid";
      case ShopInBitOrderStatus.shipping:
        return "Shipping";
      case ShopInBitOrderStatus.delivered:
        return "Delivered";
      case ShopInBitOrderStatus.closed:
        return "Closed";
      case ShopInBitOrderStatus.cancelled:
        return "Cancelled";
      case ShopInBitOrderStatus.refunded:
        return "Refunded";
    }
  }

  Color _statusColor(BuildContext context, ShopInBitOrderStatus status) {
    switch (status) {
      case ShopInBitOrderStatus.delivered:
        return Theme.of(context).extension<StackColors>()!.accentColorGreen;
      case ShopInBitOrderStatus.offerAvailable:
        return Theme.of(context).extension<StackColors>()!.accentColorBlue;
      case ShopInBitOrderStatus.pending:
      case ShopInBitOrderStatus.reviewing:
        return Theme.of(context).extension<StackColors>()!.accentColorYellow;
      case ShopInBitOrderStatus.closed:
      case ShopInBitOrderStatus.cancelled:
      case ShopInBitOrderStatus.refunded:
        return Theme.of(context).extension<StackColors>()!.textSubtitle1;
      default:
        return Theme.of(context).extension<StackColors>()!.accentColorDark;
    }
  }

  String _categoryLabel(ShopInBitCategory? category) {
    switch (category) {
      case ShopInBitCategory.concierge:
        return "Concierge";
      case ShopInBitCategory.travel:
        return "Travel";
      case ShopInBitCategory.car:
        return "Car";
      case null:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    final resumeCard = _pendingTicket != null
        ? GestureDetector(
            onTap: () => _resumeFlow(_pendingTicket!),
            child: RoundedWhiteContainer(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Car Research (In Progress)",
                              style: isDesktop
                                  ? STextStyles.desktopTextSmall(context)
                                  : STextStyles.titleBold12(context),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .accentColorYellow
                                    .withOpacity(0.2),
                              ),
                              child: Text(
                                "Resume",
                                style:
                                    (isDesktop
                                            ? STextStyles.desktopTextExtraExtraSmall(
                                                context,
                                              )
                                            : STextStyles.itemSubtitle12(
                                                context,
                                              ))
                                        .copyWith(
                                          color: Theme.of(context)
                                              .extension<StackColors>()!
                                              .accentColorYellow,
                                        ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Tap to continue your car research payment",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: isDesktop
                              ? STextStyles.desktopTextExtraExtraSmall(context)
                              : STextStyles.itemSubtitle12(context).copyWith(
                                  color: Theme.of(
                                    context,
                                  ).extension<StackColors>()!.textSubtitle1,
                                ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isDesktop ? 16 : 8),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.textSubtitle1,
                  ),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();

    final ticketList = _tickets.isEmpty
        ? null
        : ListView.separated(
            shrinkWrap: true,
            itemCount: _tickets.length,
            separatorBuilder: (_, __) => SizedBox(height: isDesktop ? 16 : 12),
            itemBuilder: (context, index) {
              final ticket = _tickets[index];
              return GestureDetector(
                onTap: () {
                  if (isDesktop) {
                    Navigator.of(context, rootNavigator: true).pop();
                    showDialog<void>(
                      context: context,
                      builder: (_) => ShopInBitTicketDetail(model: ticket),
                    );
                  } else {
                    Navigator.of(context).pushNamed(
                      ShopInBitTicketDetail.routeName,
                      arguments: ticket,
                    );
                  }
                },
                child: RoundedWhiteContainer(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  ticket.ticketId ?? "N/A",
                                  style: isDesktop
                                      ? STextStyles.desktopTextSmall(context)
                                      : STextStyles.titleBold12(context),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: _statusColor(
                                      context,
                                      ticket.status,
                                    ).withOpacity(0.2),
                                  ),
                                  child: Text(
                                    _statusLabel(ticket.status),
                                    style:
                                        (isDesktop
                                                ? STextStyles.desktopTextExtraExtraSmall(
                                                    context,
                                                  )
                                                : STextStyles.itemSubtitle12(
                                                    context,
                                                  ))
                                            .copyWith(
                                              color: _statusColor(
                                                context,
                                                ticket.status,
                                              ),
                                            ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${_categoryLabel(ticket.category)} \u2022 "
                              "${ticket.requestDescription}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: isDesktop
                                  ? STextStyles.desktopTextExtraExtraSmall(
                                      context,
                                    )
                                  : STextStyles.itemSubtitle12(
                                      context,
                                    ).copyWith(
                                      color: Theme.of(
                                        context,
                                      ).extension<StackColors>()!.textSubtitle1,
                                    ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isDesktop ? 16 : 8),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(
                          context,
                        ).extension<StackColors>()!.textSubtitle1,
                      ),
                    ],
                  ),
                ),
              );
            },
          );

    final Widget list;
    if (_pendingTicket == null && _tickets.isEmpty) {
      list = Center(
        child: Text(
          _syncing ? "Loading requests..." : "No requests yet",
          style: isDesktop
              ? STextStyles.desktopTextSmall(context)
              : STextStyles.itemSubtitle(context),
        ),
      );
    } else if (ticketList == null) {
      list = resumeCard;
    } else {
      list = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_pendingTicket != null) ...[
            resumeCard,
            SizedBox(height: isDesktop ? 16 : 12),
          ],
          ticketList,
        ],
      );
    }

    final content = Stack(
      children: [
        list,
        if (_syncing)
          const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );

    if (isDesktop) {
      return DesktopDialog(
        maxWidth: 580,
        maxHeight: 550,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    "My requests",
                    style: STextStyles.desktopH3(context),
                  ),
                ),
                const DesktopDialogCloseButton(),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                child: content,
              ),
            ),
          ],
        ),
      );
    }

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text("My requests", style: STextStyles.navBarTitle(context)),
        ),
        body: SafeArea(
          child: Padding(padding: const EdgeInsets.all(16), child: content),
        ),
      ),
    );
  }
}
