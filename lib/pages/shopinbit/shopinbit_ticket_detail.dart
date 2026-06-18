import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../db/drift/shared_db/shared_database.dart';
import '../../models/shopinbit/shopinbit_enums.dart';
import '../../providers/db/drift_provider.dart';
import '../../providers/global/shopin_bit_service_provider.dart';
import '../../services/shopinbit/src/client.dart';
import '../../services/shopinbit/src/models/message.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/logger.dart';
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
  const ShopInBitTicketDetail({super.key, required this.apiTicketId});

  static const String routeName = "/shopInBitTicketDetail";

  final int apiTicketId;

  @override
  ConsumerState<ShopInBitTicketDetail> createState() =>
      _ShopInBitTicketDetailState();
}

class _ShopInBitTicketDetailState extends ConsumerState<ShopInBitTicketDetail>
    with WidgetsBindingObserver {
  late final TextEditingController _messageController;

  static const Duration _kBasePollInterval = Duration(seconds: 30);
  static const Duration _kMaxPollInterval = Duration(seconds: 120);
  Duration _pollInterval = _kBasePollInterval;

  // Optimistically-shown messages the user just sent, kept until the next
  // refresh folds them into the persisted ticket row.
  final List<TicketMessage> _pending = [];

  bool _sending = false;

  int get _id => widget.apiTicketId;

  @override
  void initState() {
    super.initState();

    _messageController = TextEditingController();
    WidgetsBinding.instance.addObserver(this);

    // start with a refresh right away and then start polling for updates
    unawaited(_refresh().then((_) => _startPolling()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _messageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Don't poll while backgrounded; resume fresh when we come back.
    if (state == AppLifecycleState.resumed) {
      _startPolling();
    } else {
      _pollingTimer?.cancel();
    }
  }

  Timer? _pollingTimer;
  Future<void> _poll() async {
    bool ok = false;
    try {
      await _refresh();
      ok = true;
    } catch (e, s) {
      Logging.instance.w(
        "ShopInBit ticket poll failed",
        error: e,
        stackTrace: s,
      );
    }
    if (!mounted) return;

    // Back off on failure (e.g. a 429), reset on success.
    _pollInterval = ok
        ? _kBasePollInterval
        : ShopInBitClient.nextPollBackoff(_pollInterval, _kMaxPollInterval);
    _pollingTimer = Timer(_pollInterval, _poll);
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollInterval = _kBasePollInterval;
    unawaited(_poll());
  }

  Future<void> _refresh() => ref.read(pShopinBitService).refreshOne(_id);

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _pending.add(
        TicketMessage(
          timestamp: DateTime.now(),
          fromAgent: false,
          content: text,
        ),
      );
    });
    _messageController.clear();

    try {
      final thisTicket = await ref
          .read(pSharedDrift)
          .shopInBitTicketsDao
          .getByApiId(_id);
      final ok = await ref
          .read(pShopinBitService)
          .sendMessage(_id, text, thisTicket!.customerKey);
      if (ok) {
        // Pull the server's copy into the DB row, then drop our optimistic one.
        await _refresh();
        if (mounted) setState(() => _pending.clear());
      }
    } catch (_) {
      // Keep the optimistic message on failure so the text isn't lost.
    } finally {
      if (mounted) setState(() => _sending = false);
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

  Widget _chatBubble(TicketMessage message, bool isDesktop) {
    final isFromUser = !message.fromAgent;
    final textColor = isFromUser
        ? Theme.of(context).extension<StackColors>()!.buttonTextPrimary
        : Theme.of(context).extension<StackColors>()!.buttonTextSecondary;

    return Align(
      alignment: isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: isDesktop ? 380 : 260),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isFromUser
              ? Theme.of(context).extension<StackColors>()!.buttonBackPrimary
              : Theme.of(context).extension<StackColors>()!.buttonBackSecondary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isFromUser ? const Radius.circular(12) : Radius.zero,
            bottomRight: isFromUser ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isFromUser)
              Text(
                message.content,
                style:
                    (isDesktop
                            ? STextStyles.desktopTextExtraExtraSmall(context)
                            : STextStyles.itemSubtitle12(context))
                        .copyWith(color: textColor),
              )
            else
              ..._buildMessageContent(message.content, isDesktop, textColor),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style:
                  (isDesktop
                          ? STextStyles.desktopTextExtraExtraSmall(context)
                          : STextStyles.itemSubtitle12(context))
                      .copyWith(
                        fontSize: 10,
                        color: isFromUser
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
    final ShopInBitTicket? ticket = ref
        .watch(pShopInBitTicket(_id))
        .asData
        ?.value;

    final ticketNumber = ticket?.ticketNumber ?? "Request";
    final status = ticket?.status ?? ShopInBitOrderStatus.pending;
    final isCarResearch = ticket?.category == ShopInBitCategory.car;
    final messages = <TicketMessage>[...?ticket?.messages, ..._pending];

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
              ticketNumber,
              style: isDesktop
                  ? STextStyles.desktopTextSmall(context)
                  : STextStyles.titleBold12(context),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: status
                    .getColor(Theme.of(context).extension<StackColors>()!)
                    .withOpacity(0.2),
              ),
              child: Text(
                status.label,
                style:
                    (isDesktop
                            ? STextStyles.desktopTextExtraExtraSmall(context)
                            : STextStyles.itemSubtitle12(context))
                        .copyWith(
                          color: status.getColor(
                            Theme.of(context).extension<StackColors>()!,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );

    final offerBanner = status == ShopInBitOrderStatus.offerAvailable
        ? Padding(
            padding: .only(bottom: isDesktop ? 12 : 8),
            child: RoundedWhiteContainer(
              borderColor: isDesktop
                  ? Theme.of(
                      context,
                    ).extension<StackColors>()!.textFieldDefaultBG
                  : null,
              child: ConditionalParent(
                condition: Util.isDesktop,
                builder: (child) => Row(
                  children: [
                    Expanded(child: child),
                    PrimaryButton(
                      label: "Review offer",
                      width: 220,
                      buttonHeight: ButtonHeight.l,
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          ShopInBitOfferView.routeName,
                          arguments: _id,
                        );
                      },
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: .start,
                  mainAxisSize: .min,
                  children: [
                    Text(
                      "Offer available",
                      style: isDesktop
                          ? STextStyles.desktopTextSmall(context)
                          : STextStyles.titleBold12(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${ticket?.offerProductName ?? 'Item'} — "
                      "${ticket?.offerPrice ?? '0'} EUR",
                      style: isDesktop
                          ? STextStyles.desktopTextExtraExtraSmall(context)
                          : STextStyles.itemSubtitle12(context),
                    ),
                    if (!Util.isDesktop) const SizedBox(height: 12),
                    if (!Util.isDesktop)
                      PrimaryButton(
                        label: "Review offer",
                        buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            ShopInBitOfferView.routeName,
                            arguments: _id,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    final chatList = ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(8),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
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
              icon: SvgPicture.asset(
                Assets.svg.send,
                width: 24,
                height: 24,
                color: Theme.of(
                  context,
                ).extension<StackColors>()!.accentColorBlue,
              ),
            ),
        ],
      ),
    );

    final requestDetailsSection =
        isCarResearch && (ticket?.requestDescription.isNotEmpty ?? false)
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
                    ticket!.requestDescription,
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
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        statusBar,
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
                      RefreshButton(isRefreshing: false, onPressed: _refresh),
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
                ticketNumber,
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
