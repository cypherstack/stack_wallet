import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/shopinbit/shopinbit_order_model.dart';
import '../../notifications/show_flush_bar.dart';
import '../../providers/db/drift_provider.dart';
import '../../providers/global/shopin_bit_orders_provider.dart';
import '../../providers/global/shopin_bit_service_provider.dart';
import '../../services/shopinbit/shopinbit_orders_service.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/dialogs/s_dialog.dart';
import '../../widgets/refresh_control.dart';
import '../../widgets/rounded_container.dart';
import '../../widgets/rounded_white_container.dart';
import 'shopinbit_offer_view.dart';

class ShopInBitTicketDetail extends ConsumerStatefulWidget {
  const ShopInBitTicketDetail({super.key, required this.model});

  static const String routeName = "/shopInBitTicketDetail";

  final ShopInBitOrderModel model;

  @override
  ConsumerState<ShopInBitTicketDetail> createState() =>
      _ShopInBitTicketDetailState();
}

class _ShopInBitTicketDetailState extends ConsumerState<ShopInBitTicketDetail> {
  late final TextEditingController _messageController;
  late final ShopInBitOrdersService _ordersService;
  late final ShopInBitOrderModel _model;
  bool _polling = false;

  bool _sending = false;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _ordersService = ref.read(pShopInBitOrdersService);
    _model = _ordersService.upsert(widget.model);
    if (_model.apiTicketId != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _polling = true;
        _ordersService.startPolling(
          _model.apiTicketId,
          pollInBackground: !_isCarResearch,
        );
      });
    }
  }

  @override
  void dispose() {
    if (_polling) {
      _ordersService.stopPolling(_model.apiTicketId);
    }
    _messageController.dispose();
    super.dispose();
  }

  bool get _isCarResearch => _model.category == ShopInBitCategory.car;

  Future<void> _refresh() => _ordersService.refreshOne(_model.apiTicketId);

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _messageController.clear();

    // Add optimistic local message
    _model.addMessage(
      ShopInBitMessage(text: text, timestamp: DateTime.now(), isFromUser: true),
    );
    setState(() {});

    try {
      if (_model.apiTicketId != 0) {
        await ref
            .read(pShopinBitService)
            .client
            .sendMessage(_model.apiTicketId, text);
        // Pull fresh state from the API via the service so the watcher updates.
        await _refresh();
      }
      final db = ref.read(pSharedDrift);
      unawaited(
        db
            .into(db.shopInBitTickets)
            .insertOnConflictUpdate(_model.toCompanion()),
      );
    } catch (_) {
      // Keep optimistic local message
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _retryCreateRequest() async {
    if (_retrying) return;
    setState(() => _retrying = true);

    try {
      final model = _model;
      final customerKey = await ref.read(pShopinBitService).ensureCustomerKey();
      final comment =
          "${model.requestDescription}\n\n"
          "The Client paid the car research fee (#${model.feeTicketNumber})";

      final reqResp = await ref
          .read(pShopinBitService)
          .client
          .createRequest(
            customerPseudonym: model.displayName,
            externalCustomerKey: customerKey,
            serviceType: "car_research",
            comment: comment,
            deliveryCountry: model.deliveryCountry,
          );

      if (reqResp.hasError || reqResp.value == null) {
        if (mounted) {
          setState(() => _retrying = false);
          unawaited(
            showFloatingFlushBar(
              type: FlushBarType.warning,
              message: reqResp.exception?.message ?? "Failed to create request",
              context: context,
            ),
          );
        }
        return;
      }

      final requestRef = reqResp.value!;
      final requestModel = ShopInBitOrderModel()
        ..ticketId = requestRef.number
        ..apiTicketId = requestRef.id
        ..category = ShopInBitCategory.car
        ..status = ShopInBitOrderStatus.pending
        ..displayName = model.displayName
        ..requestDescription = model.requestDescription
        ..deliveryCountry = model.deliveryCountry;
      final db = ref.read(pSharedDrift);
      await db
          .into(db.shopInBitTickets)
          .insertOnConflictUpdate(requestModel.toCompanion());

      model.needsCreateRequest = false;
      await db
          .into(db.shopInBitTickets)
          .insertOnConflictUpdate(model.toCompanion());

      if (!mounted) return;
      setState(() => _retrying = false);

      unawaited(
        showFloatingFlushBar(
          type: FlushBarType.success,
          message: "Car research request submitted successfully!",
          context: context,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _retrying = false);
        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.warning,
            message: e.toString(),
            context: context,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final hm = "$hour:$minute";
    final now = DateTime.now();
    final isToday =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    return isToday ? hm : "${DateFormat('MMM d').format(local)} $hm";
  }

  static final _imgTagRegex = RegExp(
    r'<img[^>]+src="data:image/[^;]+;base64,([^"]+)"[^>]*/?>',
    caseSensitive: false,
  );

  List<Widget> _buildMessageContent(
    String html,
    bool isDesktop,
    Color? textColor,
  ) {
    final textStyle =
        (isDesktop
                ? STextStyles.desktopTextExtraExtraSmall(context)
                : STextStyles.itemSubtitle12(context))
            .copyWith(color: textColor);

    final widgets = <Widget>[];
    var lastEnd = 0;

    for (final match in _imgTagRegex.allMatches(html)) {
      // Add any text before this <img>
      if (match.start > lastEnd) {
        final textChunk = html
            .substring(lastEnd, match.start)
            .replaceAll(RegExp(r'</?div>'), '')
            .replaceAll(RegExp(r'<br\s*/?>'), '\n')
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .trim();
        if (textChunk.isNotEmpty) {
          widgets.add(Text(textChunk, style: textStyle));
        }
      }

      // Decode and render the image
      try {
        final bytes = base64Decode(match.group(1)!);
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Image.memory(bytes),
          ),
        );
      } catch (_) {
        // Skip malformed images
      }

      lastEnd = match.end;
    }

    // Add any remaining text after the last <img>
    if (lastEnd < html.length) {
      final textChunk = html
          .substring(lastEnd)
          .replaceAll(RegExp(r'</?div>'), '')
          .replaceAll(RegExp(r'<br\s*/?>'), '\n')
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .trim();
      if (textChunk.isNotEmpty) {
        widgets.add(Text(textChunk, style: textStyle));
      }
    }

    if (widgets.isEmpty) {
      widgets.add(Text('', style: textStyle));
    }

    return widgets;
  }

  Widget _chatBubble(ShopInBitMessage message, bool isDesktop) {
    final textColor = message.isFromUser
        ? Theme.of(context).extension<StackColors>()!.buttonTextPrimary
        : Theme.of(context).extension<StackColors>()!.buttonTextSecondary;

    return Align(
      alignment: message.isFromUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: isDesktop ? 380 : 260),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: message.isFromUser
              ? Theme.of(context).extension<StackColors>()!.buttonBackPrimary
              : Theme.of(context).extension<StackColors>()!.buttonBackSecondary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: message.isFromUser
                ? const Radius.circular(12)
                : Radius.zero,
            bottomRight: message.isFromUser
                ? Radius.zero
                : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.isFromUser)
              Text(
                message.text,
                style:
                    (isDesktop
                            ? STextStyles.desktopTextExtraExtraSmall(context)
                            : STextStyles.itemSubtitle12(context))
                        .copyWith(color: textColor),
              )
            else
              ..._buildMessageContent(message.text, isDesktop, textColor),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style:
                  (isDesktop
                          ? STextStyles.desktopTextExtraExtraSmall(context)
                          : STextStyles.itemSubtitle12(context))
                      .copyWith(
                        fontSize: 10,
                        color: message.isFromUser
                            ? Colors.white.withOpacity(0.7)
                            : Theme.of(context)
                                  .extension<StackColors>()!
                                  .textSubtitle1
                                  .withOpacity(0.7),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final service = ref.watch(pShopInBitOrdersService);
    final model = service.get(_model.apiTicketId) ?? _model;
    final isRefreshing = service.isRefreshing(_model.apiTicketId);

    final statusBar = Padding(
      padding: .only(bottom: isDesktop ? 12 : 8),
      child: RoundedWhiteContainer(
        borderColor: isDesktop
            ? Theme.of(context).extension<StackColors>()!.textFieldDefaultBG
            : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SelectableText(
              model.ticketId ?? "Request",
              style: isDesktop
                  ? STextStyles.desktopTextSmall(context)
                  : STextStyles.titleBold12(context),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: model.status
                    .getColor(Theme.of(context).extension<StackColors>()!)
                    .withOpacity(0.2),
              ),
              child: Text(
                model.status.label,
                style:
                    (isDesktop
                            ? STextStyles.desktopTextExtraExtraSmall(context)
                            : STextStyles.itemSubtitle12(context))
                        .copyWith(
                          color: model.status.getColor(
                            Theme.of(context).extension<StackColors>()!,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );

    final offerBanner = model.status == ShopInBitOrderStatus.offerAvailable
        ? Padding(
            padding: .only(bottom: isDesktop ? 12 : 8),
            child: RoundedWhiteContainer(
              borderColor: isDesktop
                  ? Theme.of(
                      context,
                    ).extension<StackColors>()!.textFieldDefaultBG
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Offer available",
                    style: isDesktop
                        ? STextStyles.desktopTextSmall(context)
                        : STextStyles.titleBold12(context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${model.offerProductName ?? 'Item'} \u2014 "
                    "${model.offerPrice ?? '0'} EUR",
                    style: isDesktop
                        ? STextStyles.desktopTextExtraExtraSmall(context)
                        : STextStyles.itemSubtitle12(context),
                  ),
                  SizedBox(height: isDesktop ? 12 : 8),
                  PrimaryButton(
                    label: "Review offer",
                    onPressed: () {
                      if (isDesktop) {
                        Navigator.of(context, rootNavigator: true).pop();
                        showDialog<void>(
                          context: context,

                          builder: (_) => ShopInBitOfferView(model: model),
                        );
                      } else {
                        Navigator.of(context).pushNamed(
                          ShopInBitOfferView.routeName,
                          arguments: model,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();

    final chatList = ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(8),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: model.messages.length,
      itemBuilder: (context, index) {
        final message = model.messages[model.messages.length - 1 - index];
        return _chatBubble(message, isDesktop);
      },
    );

    final chatArea = Expanded(
      child: ConditionalParent(
        condition: Util.isDesktop,
        builder: (child) => RoundedContainer(
          padding: .zero,
          color: Theme.of(context).extension<StackColors>()!.textFieldActiveBG,
          child: child,
        ),
        child: RefreshControl(onRefresh: _refresh, child: chatList),
      ),
    );

    final inputBar = RoundedContainer(
      padding: Util.isDesktop ? .zero : const .all(8),
      color: Theme.of(context).extension<StackColors>()!.popupBG,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style:
                  (isDesktop
                          ? STextStyles.desktopTextExtraSmall(context)
                          : STextStyles.field(context))
                      .copyWith(
                        color: Theme.of(
                          context,
                        ).extension<StackColors>()!.textDark,
                      ),
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: isDesktop
                    ? STextStyles.desktopTextExtraExtraSmall(context)
                    : STextStyles.fieldLabel(context),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          if (!Util.isDesktop) const SizedBox(width: 8),
          if (!Util.isDesktop)
            IconButton(
              onPressed: _sendMessage,
              icon: Icon(
                Icons.send,
                color: Theme.of(
                  context,
                ).extension<StackColors>()!.accentColorBlue,
              ),
            ),
        ],
      ),
    );

    final requestDetailsSection =
        _isCarResearch && model.requestDescription.isNotEmpty
        ? Padding(
            padding: EdgeInsets.only(bottom: isDesktop ? 12 : 8),
            child: RoundedWhiteContainer(
              borderColor: isDesktop
                  ? Theme.of(
                      context,
                    ).extension<StackColors>()!.textFieldDefaultBG
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Request details",
                    style: isDesktop
                        ? STextStyles.desktopTextSmall(context)
                        : STextStyles.titleBold12(context),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    model.requestDescription,
                    style: isDesktop
                        ? STextStyles.desktopTextExtraExtraSmall(context)
                        : STextStyles.itemSubtitle12(context),
                  ),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();

    final retryButton =
        model.needsCreateRequest && model.category == ShopInBitCategory.car
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: PrimaryButton(
              label: _retrying ? "Submitting..." : "Complete Request",
              enabled: !_retrying,
              onPressed: _retrying
                  ? null
                  : () => unawaited(_retryCreateRequest()),
            ),
          )
        : const SizedBox.shrink();

    final body = Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        statusBar,
        retryButton,
        offerBanner,
        requestDetailsSection,
        chatArea,
        SizedBox(height: isDesktop ? 12 : 8),
        inputBar,
      ],
    );

    return ConditionalParent(
      condition: isDesktop,
      builder: (child) => SDialog(
        contentCanScroll: false,
        child: SizedBox(
          width: 600,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Text(
                      "Request",
                      style: STextStyles.desktopH3(context),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RefreshButton(
                        isRefreshing: isRefreshing,
                        onPressed: _refresh,
                      ),
                      const SizedBox(width: 8),
                      const DesktopDialogCloseButton(),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 32,
                    right: 32,
                    bottom: 32,
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
                model.ticketId ?? "Request",
                style: STextStyles.navBarTitle(context),
              ),
            ),
            body: SafeArea(
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            ),
          ),
        ),
        child: body,
      ),
    );
  }
}
