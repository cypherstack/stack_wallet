import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../db/drift/shared_db/shared_database.dart';
import '../../models/shopinbit/shopinbit_enums.dart';
import '../../notifications/show_flush_bar.dart';
import '../../providers/db/drift_provider.dart';
import '../../providers/global/shopin_bit_service_provider.dart';
import '../../services/shopinbit/shopinbit_service.dart';
import '../../services/shopinbit/src/api_response.dart';
import '../../services/shopinbit/src/client.dart';
import '../../services/shopinbit/src/models/message.dart';
import '../../services/shopinbit/src/models/ticket.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/logger.dart';
import '../../utilities/show_loading.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/custom_buttons/blue_text_button.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/detail_item.dart';
import '../../widgets/dialogs/s_dialog.dart';
import '../../widgets/loading_indicator.dart';
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
  late final ShopInBitService _shopinBitService;

  static const Duration _kBasePollInterval = Duration(seconds: 5);
  static const Duration _kMaxPollInterval = Duration(seconds: 120);
  Duration _pollInterval = _kBasePollInterval;

  // True while a `_poll` is awaiting a refresh. `_startPolling` bails when a
  // poll is already running so app-resume/lifecycle events can't start a second
  // loop on top of the first.
  bool _pollInFlight = false;

  // True while the app is backgrounded. A poll already in flight when we get
  // backgrounded checks this before re-arming its timer, so polling actually
  // stops instead of quietly continuing in the background.
  bool _paused = false;

  // Optimistically-shown messages the user just sent, kept until the next
  // refresh folds them into the persisted ticket row.
  final List<TicketMessage> _pending = [];

  bool _sending = false;

  int get _id => widget.apiTicketId;

  @override
  void initState() {
    super.initState();

    _shopinBitService = ref.read(pShopinBitService);

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
    // Always continue polling on desktop
    if (Util.isDesktop) return;

    // Don't poll while backgrounded; resume fresh when we come back.
    if (state == AppLifecycleState.resumed) {
      _paused = false;
      _startPolling();
    } else {
      _paused = true;
      _pollingTimer?.cancel();
    }
  }

  Timer? _pollingTimer;
  Future<void> _poll() async {
    _pollInFlight = true;
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
    _pollInFlight = false;
    if (!mounted) return;
    // Backgrounded while this poll was awaiting its refresh: don't re-arm.
    // Resume will restart polling (`_pollInFlight` is already cleared above, so
    // `_startPolling` won't be blocked).
    if (_paused) return;

    final ticket = ref.read(pShopInBitTicket(_id)).asData?.value;
    final isTerminal =
        ticket != null && TicketState.fromString(ticket.statusRaw).isTerminal;
    // Just check terminal tickets less often.  Was hitting limits in testing.
    final baseInterval = isTerminal ? _kMaxPollInterval : _kBasePollInterval;

    // Back off on failure (e.g. a 429), reset to the base interval on success.
    _pollInterval = ok
        ? baseInterval
        : ShopInBitClient.nextPollBackoff(_pollInterval, _kMaxPollInterval);
    _pollingTimer = Timer(_pollInterval, _poll);
  }

  void _startPolling() {
    // A poll is already running and will re-arm itself; don't start a second
    // loop on top of it.
    if (_pollInFlight) return;
    _pollingTimer?.cancel();
    _pollInterval = _kBasePollInterval;
    unawaited(_poll());
  }

  Future<void> _refresh() => _shopinBitService.refreshOne(_id);

  List<File>? _currentSelectedAttachments;

  /// Pick files and validate them with the same rules the client enforces at
  /// send time (type whitelist, per-category size caps, 50 MB combined), so
  /// a doomed selection is rejected here with a specific reason instead of
  /// failing later behind a generic "Message failed to send".
  Future<void> _pickAttachments() async {
    if (_sending) return;

    // TODO verify this works on android and ios
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: .custom,
      allowedExtensions: kAllowedAttachmentExtensions,
      lockParentWindow: true,
    );
    if (result == null || !mounted) return;

    final accepted = [...?_currentSelectedAttachments];
    int combinedBytes = 0;
    for (final file in accepted) {
      combinedBytes += await file.length();
    }

    String? rejection;
    for (final picked in result.files) {
      final path = picked.path;
      if (path == null || accepted.any((f) => f.path == path)) continue;

      final file = File(path);
      final fileName = file.uri.pathSegments.last;
      final resolved = resolveAttachmentType(fileName);
      if (resolved == null) {
        rejection = "$fileName is not a supported file type";
        continue;
      }

      final sizeBytes = await file.length();
      if (sizeBytes > resolved.category.maxBytes) {
        rejection =
            "$fileName is larger than the "
            "${resolved.category.maxBytes ~/ 1000000} MB "
            "${resolved.category.name} limit";
        continue;
      }
      if (combinedBytes + sizeBytes > kCombinedAttachmentMaxBytes) {
        rejection =
            "Combined attachment size exceeds the "
            "${kCombinedAttachmentMaxBytes ~/ 1000000} MB limit";
        continue;
      }

      combinedBytes += sizeBytes;
      accepted.add(file);
    }

    if (!mounted) return;
    setState(() {
      _currentSelectedAttachments = accepted.isEmpty ? null : accepted;
    });
    if (rejection != null) {
      unawaited(
        showFloatingFlushBar(
          type: FlushBarType.warning,
          message: rejection,
          context: context,
        ),
      );
    }
  }

  void _removeAttachment(File file) {
    final current = _currentSelectedAttachments;
    if (current == null) return;
    setState(() {
      current.remove(file);
      if (current.isEmpty) _currentSelectedAttachments = null;
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    // Capture the selection now: the field is cleared optimistically below,
    // so a re-pick while this send is in flight can't be lost or orphaned.
    final attachmentsToSend = _currentSelectedAttachments;
    if ((text.isEmpty && attachmentsToSend == null) || _sending) return;

    // The server's copy will carry real attachment links after processing;
    // until then the optimistic bubble just notes the count.
    final optimisticContent = switch ((text, attachmentsToSend?.length)) {
      (final t, null) => t,
      ("", final int n) => "$n attachment(s)",
      (final t, final int n) => "$t ($n attachment(s))",
    };

    final optimistic = TicketMessage(
      timestamp: DateTime.now(),
      fromAgent: false,
      content: optimisticContent,
    );
    setState(() {
      _sending = true;
      _pending.add(optimistic);
      _currentSelectedAttachments = null;
    });
    _messageController.clear();

    var sent = false;
    try {
      final thisTicket = await ref
          .read(pSharedDrift)
          .shopInBitTicketsDao
          .getByApiId(_id);
      final customerKey = thisTicket?.customerKey;
      if (customerKey != null) {
        sent = await ref
            .read(pShopinBitService)
            .sendMessage(
              _id,
              text,
              customerKey,
              attachments: attachmentsToSend,
            );
      }
    } catch (_) {
      sent = false;
    }

    if (sent) {
      // Delivered. sendMessage already scheduled its own refresh and the poll
      // loop reconciles regardless, so a failure pulling the server's copy in
      // here must not roll the (already sent) message back. Fold it in if we
      // can; otherwise leave the optimistic bubble for the next refresh.
      try {
        await _refresh();
      } catch (_) {}
      if (mounted) setState(() => _pending.remove(optimistic));
    } else {
      // The send didn't go through: roll the optimistic message back, restore
      // the text and attachments so nothing is lost, and let the user know.
      _pending.remove(optimistic);
      if (mounted) {
        if (_messageController.text.isEmpty) _messageController.text = text;
        // Don't clear a selection the user made while this send was
        // in flight; only restore into an empty slot.
        _currentSelectedAttachments ??= attachmentsToSend;
        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.warning,
            message: 'Message failed to send',
            context: context,
          ),
        );
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final ShopInBitTicket? ticket = ref
        .watch(pShopInBitTicket(_id))
        .asData
        ?.value;

    final ticketNumber = ticket?.ticketNumber ?? "Request";
    final customerKey = ticket?.customerKey;
    final status = ticket?.status ?? ShopInBitOrderStatus.pending;
    final isCarResearch = ticket?.category == ShopInBitCategory.car;
    final messages = <TicketMessage>[...?ticket?.messages, ..._pending];

    final trackingLinks = splitTrackingLinks(ticket?.trackingLink).toList();

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

    Future<void> _pushOfferView() async {
      if (_id != 0) {
        await showLoading(
          whileFutureAlt: _refresh,
          context: context,
          message: "Checking offer...",
          rootNavigator: Util.isDesktop,
          delay: const Duration(seconds: 1),
          onException: (e) {
            Logging.instance.w(
              "Failed to refresh ShopInBit offer $_id, "
              "using cached data",
              error: e,
            );
          },
        );
      }
      if (context.mounted) {
        await Navigator.of(
          context,
        ).pushNamed(ShopInBitOfferView.routeName, arguments: _id);
      }
    }

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
                      onPressed: _pushOfferView,
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
                      "${ticket?.offerPrice ?? '0'} EUR (incl. VAT)",
                      style: isDesktop
                          ? STextStyles.desktopTextExtraExtraSmall(context)
                          : STextStyles.itemSubtitle12(context),
                    ),
                    if (!Util.isDesktop) const SizedBox(height: 12),
                    if (!Util.isDesktop)
                      PrimaryButton(
                        label: "Review offer",
                        buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
                        onPressed: _pushOfferView,
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
        return _ChatBubble(
          // Stable per-message identity so the list (which grows/shrinks as
          // optimistic and polled messages come and go) keeps each bubble's
          // state (e.g. a proxy image's fetched URL) with the right message.
          // Value-stable across polls (objects are rebuilt each poll) but a
          // cheap hash, so we don't allocate/compare the whole content (which
          // can be a multi-MB inline image) on every itemBuilder call.
          key: ValueKey(
            Object.hash(
              message.fromAgent,
              message.timestamp.microsecondsSinceEpoch,
              message.content.hashCode,
            ),
          ),
          message: message,
          isDesktop: isDesktop,
          customerKey: customerKey,
        );
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
          IconButton(
            onPressed: _sending ? null : _pickAttachments,
            tooltip: "Attach files",
            icon: SvgPicture.asset(
              Assets.svg.file,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                Theme.of(context).extension<StackColors>()!.textSubtitle1,
                .srcIn,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
        if (trackingLinks.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: isDesktop ? 12 : 8),
            child: _TrackingLinks(trackingLinks: trackingLinks),
          ),
        chatArea,
        if (_currentSelectedAttachments != null) ...[
          SizedBox(height: isDesktop ? 8 : 6),
          _SelectedAttachmentChips(
            files: _currentSelectedAttachments!,
            enabled: !_sending,
            onRemove: _removeAttachment,
          ),
        ],
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

// Chat bubble / attachment layout dimensions.
const double _kBubbleMaxWidthDesktop = 380;
const double _kBubbleMaxWidthMobile = 260;
const double _kAttachmentMaxHeight = 220;
// Decode images down to ~2x the display height to cap decode/memory cost.
const int _kAttachmentDecodeHeight = 440;
const double _kAttachmentLoaderHeight = 80;
const double _kAttachmentLoaderWidth = 40;
// Selected-attachment chip layout.
const double _kChipIconSize = 12;
const double _kChipMaxNameWidth = 140;

/// Chips for attachments that are selected but not yet sent, each removable
/// until the send starts.
class _SelectedAttachmentChips extends StatelessWidget {
  const _SelectedAttachmentChips({
    required this.files,
    required this.enabled,
    required this.onRemove,
  });

  final List<File> files;
  final bool enabled;
  final void Function(File) onRemove;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final File file in files)
            _AttachmentChip(
              file: file,
              enabled: enabled,
              onRemove: () => onRemove(file),
            ),
        ],
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({
    required this.file,
    required this.enabled,
    required this.onRemove,
  });

  final File file;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<StackColors>()!;
    final String fileName = file.uri.pathSegments.last;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.textFieldDefaultBG,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          SvgPicture.asset(
            Assets.svg.file,
            width: _kChipIconSize,
            height: _kChipIconSize,
            colorFilter: ColorFilter.mode(colors.textSubtitle1, .srcIn),
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kChipMaxNameWidth),
            child: Text(
              fileName,
              style: STextStyles.itemSubtitle12(context),
              maxLines: 1,
              overflow: .ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: enabled ? onRemove : null,
              child: SvgPicture.asset(
                Assets.svg.x,
                width: _kChipIconSize,
                height: _kChipIconSize,
                colorFilter: ColorFilter.mode(colors.textSubtitle1, .srcIn),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders an authenticated `/attachment-proxy/` image.
///
/// The signed URL future is built once in [initState] (and only rebuilt when
/// [proxyPath] or [customerKey] actually change) so the surrounding 30s poll
/// can't re-fire `getAttachmentUrl`/re-fetch the image on every rebuild.
class _ProxyImage extends StatefulWidget {
  const _ProxyImage({
    required this.client,
    required this.proxyPath,
    required this.customerKey,
    required this.fallback,
  });

  final ShopInBitClient client;
  final String proxyPath;
  final String customerKey;
  final Widget Function() fallback;

  @override
  State<_ProxyImage> createState() => _ProxyImageState();
}

class _ProxyImageState extends State<_ProxyImage> {
  late Future<ApiResponse<Uri>> _urlFuture;

  Future<ApiResponse<Uri>> _buildFuture() => widget.client.getAttachmentUrl(
    widget.proxyPath,
    useQueryAuth: true,
    customerKey: widget.customerKey,
  );

  @override
  void initState() {
    super.initState();
    _urlFuture = _buildFuture();
  }

  @override
  void didUpdateWidget(covariant _ProxyImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.proxyPath != widget.proxyPath ||
        oldWidget.customerKey != widget.customerKey) {
      _urlFuture = _buildFuture();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: _kAttachmentMaxHeight),
          child: FutureBuilder<ApiResponse<Uri>>(
            future: _urlFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: _kAttachmentLoaderHeight,
                  child: LoadingIndicator(width: _kAttachmentLoaderWidth),
                );
              }
              final resp = snapshot.data!;
              if (resp.hasError || resp.value == null) {
                return widget.fallback();
              }
              return Image.network(
                resp.value!.toString(),
                fit: BoxFit.contain,
                cacheHeight: _kAttachmentDecodeHeight,
                semanticLabel: "Image attachment",
                errorBuilder: (_, _, _) => widget.fallback(),
              );
            },
          ),
        ),
      ),
    );
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

/// A single chat message bubble: the message body plus its timestamp.
class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    super.key,
    required this.message,
    required this.isDesktop,
    required this.customerKey,
  });

  final TicketMessage message;
  final bool isDesktop;
  final String? customerKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<StackColors>()!;
    final isFromUser = !message.fromAgent;
    final textColor = isFromUser
        ? colors.buttonTextPrimary
        : colors.buttonTextSecondary;

    return Align(
      alignment: isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isDesktop
              ? _kBubbleMaxWidthDesktop
              : _kBubbleMaxWidthMobile,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isFromUser
              ? colors.buttonBackPrimary
              : colors.buttonBackSecondary,
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
            _MessageBody(
              message: message,
              isDesktop: isDesktop,
              textColor: textColor,
              customerKey: customerKey,
            ),
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
                            ? colors.buttonTextPrimary.withOpacity(0.7)
                            : colors.textSubtitle1.withOpacity(0.7),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders a ticket message's HTML [TicketMessage.content] as a column of text,
/// inline base64 images, proxy images, and file links.
class _MessageBody extends ConsumerWidget {
  const _MessageBody({
    required this.message,
    required this.isDesktop,
    required this.textColor,
    required this.customerKey,
  });

  final TicketMessage message;
  final bool isDesktop;
  final Color? textColor;
  final String? customerKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textStyle =
        (isDesktop
                ? STextStyles.desktopTextExtraExtraSmall(context)
                : STextStyles.itemSubtitle12(context))
            .copyWith(color: textColor);

    final widgets = <Widget>[];

    // Render segments in document order. Proxy images and file links need the
    // customer key to fetch; a loaded ticket always has one, so when it's null
    // (e.g. an optimistic message) those segments are simply skipped.
    final key = customerKey;
    final client = key == null ? null : ref.read(pShopinBitService).client;

    for (final segment in message.contentSegments) {
      switch (segment) {
        case MessageTextSegment(:final text):
          widgets.add(Text(text, style: textStyle));
        case MessageImageSegment(:final bytes):
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: _kAttachmentMaxHeight,
                  ),
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    cacheHeight: _kAttachmentDecodeHeight,
                    semanticLabel: "Image",
                    // The decoded bytes are cached and reused across polls, so
                    // the provider stays equal; keep the last frame if it ever
                    // does reload (e.g. cache eviction) instead of flashing.
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
          );
        case MessageProxyImageSegment(:final proxyPath, :final filename):
          if (key != null && client != null) {
            widgets.add(
              _ProxyImage(
                client: client,
                proxyPath: proxyPath,
                customerKey: key,
                fallback: () => _AttachmentImageFallback(filename: filename),
              ),
            );
          }
        case MessageFileLinkSegment(:final proxyPath, :final filename):
          if (key != null) {
            widgets.add(
              _AttachmentFileLink(
                proxyPath: proxyPath,
                customerKey: key,
                filename: filename,
                textStyle: textStyle,
              ),
            );
          }
      }
    }

    if (widgets.isEmpty) {
      widgets.add(Text('', style: textStyle));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }
}

/// A tappable `/attachment-proxy/` file link, opened in the browser.
class _AttachmentFileLink extends ConsumerWidget {
  const _AttachmentFileLink({
    required this.proxyPath,
    required this.customerKey,
    required this.filename,
    required this.textStyle,
  });

  final String proxyPath;
  final String customerKey;
  final String? filename;
  final TextStyle textStyle;

  Future<void> _open(BuildContext context, ShopInBitService service) async {
    // Resolving the signed URL hits the token manager (and possibly the
    // network), so show the loading overlay and surface any failure rather than
    // doing nothing.
    await showLoading<void>(
      whileFuture: _resolveAndLaunch(service),
      context: context,
      message: "Opening attachment",
      rootNavigator: Util.isDesktop,
      onException: (e) {
        Logging.instance.w("ShopInBit open attachment failed", error: e);
        showFloatingFlushBar(
          type: FlushBarType.warning,
          message: "Could not open attachment",
          context: context,
        );
      },
    );
  }

  Future<void> _resolveAndLaunch(ShopInBitService service) async {
    final resp = await service.client.getAttachmentUrl(
      proxyPath,
      useQueryAuth: true,
      customerKey: customerKey,
    );
    if (resp.hasError || resp.value == null) {
      throw resp.exception ?? Exception("Could not resolve attachment URL");
    }
    final launched = await launchUrl(
      resp.value!,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) throw Exception("Could not open attachment");
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkStyle = textStyle.copyWith(
      decoration: TextDecoration.underline,
      decorationColor: textStyle.color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        // TODO: Make sure we warn about browsing.
        child: Semantics(
          button: true,
          label: filename ?? 'attachment',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => _open(context, ref.read(pShopinBitService)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  Assets.svg.file,
                  width: 16,
                  height: 16,
                  color: textStyle.color,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    filename ?? 'attachment',
                    style: linkStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown in place of a proxy image that failed to load.
class _AttachmentImageFallback extends StatelessWidget {
  const _AttachmentImageFallback({required this.filename});

  final String? filename;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<StackColors>()!;
    return Container(
      padding: const EdgeInsets.all(8),
      color: colors.textFieldDefaultBG,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            Assets.svg.alertCircle,
            width: 16,
            height: 16,
            color: colors.textSubtitle1,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              filename ?? 'image',
              style: STextStyles.itemSubtitle12(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingLinks extends StatelessWidget {
  const _TrackingLinks({super.key, required this.trackingLinks});

  final List<String> trackingLinks;

  @override
  Widget build(BuildContext context) {
    return DetailItemBase(
      horizontal: true,
      expandDetail: true,
      crossAxisAlignment: .start,
      title: Text(
        "Tracking link(s)",
        style: Util.isDesktop
            ? STextStyles.desktopTextSmall(context)
            : STextStyles.titleBold12(context),
      ),
      detail: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          ...trackingLinks.map(
            (e) => CustomTextButton(
              text: e,
              overflow: .ellipsis,
              onTap: () async {
                try {
                  await launchUrl(
                    Uri.parse(e),
                    mode: LaunchMode.externalApplication,
                  );
                } catch (e, s) {
                  Logging.instance.e(
                    "Failed to open shipping tracking link",
                    error: e,
                    stackTrace: s,
                  );
                }
              },
            ),
          ),
        ],
      ),
      borderColor: Util.isDesktop
          ? Theme.of(context).extension<StackColors>()!.textFieldDefaultBG
          : null,
    );
  }
}
