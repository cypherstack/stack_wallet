import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../db/isar/main_db.dart';
import '../../models/shopinbit/shopinbit_order_model.dart';
import '../../services/shopinbit/shopinbit_service.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/rounded_white_container.dart';
import 'shopinbit_offer_view.dart';

class ShopInBitTicketDetail extends StatefulWidget {
  const ShopInBitTicketDetail({super.key, required this.model});

  static const String routeName = "/shopInBitTicketDetail";

  final ShopInBitOrderModel model;

  @override
  State<ShopInBitTicketDetail> createState() => _ShopInBitTicketDetailState();
}

class _ShopInBitTicketDetailState extends State<ShopInBitTicketDetail> {
  late final TextEditingController _messageController;

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

  bool _sending = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    if (widget.model.apiTicketId != 0) {
      _loadFromApi();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  bool get _isCarResearch => widget.model.category == ShopInBitCategory.car;

  Future<void> _loadFromApi() async {
    setState(() => _loading = true);
    try {
      final client = ShopInBitService.instance.client;
      final id = widget.model.apiTicketId;

      // Car research tickets created via /car-research/log-payment are not
      // accessible via /tickets/:id/* endpoints (API returns 403). Skip
      // those calls for car tickets to avoid log spam. Local data is used.
      if (!_isCarResearch) {
        final messagesResp = await client.getMessages(id);
        final statusResp = await client.getTicketStatus(id);

        if (!messagesResp.hasError && messagesResp.value != null) {
          final apiMessages = messagesResp.value!;
          widget.model.clearMessages();
          for (final m in apiMessages) {
            widget.model.addMessage(
              ShopInBitMessage(
                text: m.content,
                timestamp: m.timestamp,
                isFromUser: !m.fromAgent,
              ),
            );
          }
        }

        if (!statusResp.hasError && statusResp.value != null) {
          widget.model.status = ShopInBitOrderModel.statusFromTicketState(
            statusResp.value!.state,
          );
        }
      }

      unawaited(
        MainDB.instance.putShopInBitTicket(widget.model.toIsarTicket()),
      );
    } catch (_) {
      // Silently fall back to local data
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _messageController.clear();

    // Add optimistic local message
    widget.model.addMessage(
      ShopInBitMessage(text: text, timestamp: DateTime.now(), isFromUser: true),
    );
    setState(() {});

    try {
      if (widget.model.apiTicketId != 0) {
        await ShopInBitService.instance.client.sendMessage(
          widget.model.apiTicketId,
          text,
        );
        // Reload messages from API to get accurate state
        await _loadFromApi();
      }
      unawaited(
        MainDB.instance.putShopInBitTicket(widget.model.toIsarTicket()),
      );
    } catch (_) {
      // Keep optimistic local message
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
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
    final textColor = message.isFromUser ? Colors.white : null;

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
              ? Theme.of(context).extension<StackColors>()!.accentColorBlue
              : Theme.of(context).extension<StackColors>()!.popupBG,
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
    final model = widget.model;

    final statusBar = RoundedWhiteContainer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            model.ticketId ?? "Request",
            style: isDesktop
                ? STextStyles.desktopTextSmall(context)
                : STextStyles.titleBold12(context),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _statusColor(context, model.status).withOpacity(0.2),
            ),
            child: Text(
              _statusLabel(model.status),
              style:
                  (isDesktop
                          ? STextStyles.desktopTextExtraExtraSmall(context)
                          : STextStyles.itemSubtitle12(context))
                      .copyWith(color: _statusColor(context, model.status)),
            ),
          ),
        ],
      ),
    );

    final offerBanner = model.status == ShopInBitOrderStatus.offerAvailable
        ? Padding(
            padding: EdgeInsets.only(bottom: isDesktop ? 16 : 12),
            child: RoundedWhiteContainer(
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

    final chatArea = Expanded(
      child: Stack(
        children: [
          ListView.builder(
            reverse: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: model.messages.length,
            itemBuilder: (context, index) {
              final message = model.messages[model.messages.length - 1 - index];
              return _chatBubble(message, isDesktop);
            },
          ),
          if (_loading)
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );

    final inputBar = Container(
      padding: EdgeInsets.all(isDesktop ? 16 : 8),
      decoration: BoxDecoration(
        color: Theme.of(context).extension<StackColors>()!.popupBG,
        borderRadius: BorderRadius.circular(12),
      ),
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

    final requestDetailsSection = _isCarResearch && model.requestDescription.isNotEmpty
        ? Padding(
            padding: EdgeInsets.only(bottom: isDesktop ? 12 : 8),
            child: RoundedWhiteContainer(
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
                  Text(
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

    final body = Column(
      children: [
        statusBar,
        offerBanner,
        requestDetailsSection,
        chatArea,
        SizedBox(height: isDesktop ? 12 : 8),
        inputBar,
      ],
    );

    if (isDesktop) {
      return DesktopDialog(
        maxWidth: 600,
        maxHeight: 650,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text("Request", style: STextStyles.desktopH3(context)),
                ),
                const DesktopDialogCloseButton(),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 8,
                ),
                child: body,
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
          title: Text(
            model.ticketId ?? "Request",
            style: STextStyles.navBarTitle(context),
          ),
        ),
        body: SafeArea(
          child: Padding(padding: const EdgeInsets.all(16), child: body),
        ),
      ),
    );
  }
}
