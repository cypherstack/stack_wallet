import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/shopinbit/shopinbit_order_model.dart';
import '../../notifications/show_flush_bar.dart';
import '../../providers/db/drift_provider.dart';
import '../../providers/global/shopin_bit_service_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/dialogs/s_dialog.dart';
import '../../widgets/loading_indicator.dart';
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

  bool _sending = false;
  bool _loading = false;
  bool _retrying = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    if (widget.model.apiTicketId != 0) {
      _loadFromApi();
      if (!_isCarResearch) {
        _pollTimer = Timer.periodic(
          const Duration(seconds: 30),
          (_) => _loadFromApi(),
        );
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  bool get _isCarResearch => widget.model.category == ShopInBitCategory.car;

  Future<void> _loadFromApi() async {
    setState(() => _loading = true);
    try {
      final client = ref.read(pShopinBitService).client;
      final id = widget.model.apiTicketId;

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

      if (widget.model.status == ShopInBitOrderStatus.offerAvailable &&
          (widget.model.offerProductName == null ||
              widget.model.offerPrice == null)) {
        final offerResp = await client.getTicketFull(id);
        if (!offerResp.hasError && offerResp.value != null) {
          final t = offerResp.value!;
          widget.model.setOffer(
            productName: t.productName,
            price: t.customerPrice,
          );
        }
      }

      final db = ref.read(pSharedDrift);
      unawaited(
        db
            .into(db.shopInBitTickets)
            .insertOnConflictUpdate(widget.model.toCompanion()),
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
        await ref
            .read(pShopinBitService)
            .client
            .sendMessage(widget.model.apiTicketId, text);
        // Reload messages from API to get accurate state
        await _loadFromApi();
      }
      final db = ref.read(pSharedDrift);
      unawaited(
        db
            .into(db.shopInBitTickets)
            .insertOnConflictUpdate(widget.model.toCompanion()),
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
      final model = widget.model;
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
    // TODO: local time is a start but this is still far from ideal...
    if (dt.isUtc) {
      dt = dt.toLocal();
    }

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
      child: ConditionalParent(
        condition: Util.isDesktop,
        builder: (child) => RoundedContainer(
          padding: .zero,
          color: Theme.of(context).extension<StackColors>()!.textFieldActiveBG,
          child: child,
        ),
        child: Stack(
          children: [
            ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(8),
              itemCount: model.messages.length,
              itemBuilder: (context, index) {
                final message =
                    model.messages[model.messages.length - 1 - index];
                return _chatBubble(message, isDesktop);
              },
            ),
            // TODO: fix loading from locking everything up
            if (_loading) const LoadingIndicator(width: 24, height: 24),
          ],
        ),
      ),
    );

    final inputBar = Container(
      padding: Util.isDesktop ? null : const EdgeInsets.all(8),
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

    final retryButton =
        widget.model.needsCreateRequest &&
            widget.model.category == ShopInBitCategory.car
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
                  const DesktopDialogCloseButton(),
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
