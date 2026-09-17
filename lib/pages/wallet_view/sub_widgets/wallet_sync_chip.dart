import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/global/wallets_provider.dart';
import '../../../services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import '../../../services/event_bus/global_event_bus.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/hero_ink.dart';
import '../../../utilities/text_styles.dart';

/// Live sync-status pill shown on the balance card ("Synced" / "Syncing" /
/// "Offline"). Tapping it triggers a wallet refresh, replacing the old
/// spinning-arrows refresh button.
class WalletSyncChip extends ConsumerStatefulWidget {
  const WalletSyncChip({
    super.key,
    required this.walletId,
    required this.initialSyncStatus,
  });

  final String walletId;
  final WalletSyncStatus initialSyncStatus;

  @override
  ConsumerState<WalletSyncChip> createState() => _WalletSyncChipState();
}

class _WalletSyncChipState extends ConsumerState<WalletSyncChip> {
  late WalletSyncStatus _status;
  late final StreamSubscription<dynamic> _subscription;

  @override
  void initState() {
    _status = widget.initialSyncStatus;
    _subscription =
        GlobalEventBus.instance.on<WalletSyncStatusChangedEvent>().listen((
          event,
        ) {
          if (event.walletId == widget.walletId && mounted) {
            setState(() => _status = event.newStatus);
          }
        });
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _refresh() {
    final wallet = ref.read(pWallets).getWallet(widget.walletId);
    if (!wallet.refreshMutex.isLocked) {
      unawaited(wallet.refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Balance block now sits on the page background (no gradient card), so the
    // chip reads against the themed surface rather than on-card white.
    // This chip only ever renders inside the hero (its sole call site is
    // wallet_summary_info), so its ink comes from the hero, not the page.
    // textDark is near-black in the light theme and was unreadable on blue;
    // hardcoded white then failed the other way on the light-orange heroes.
    // The hero is one neutral for every coin now, so this reads the surface
    // it actually sits on rather than the coin's colour.
    const hero = kHeroSurface;
    final favText = heroInk(hero);

    final String label = switch (_status) {
      WalletSyncStatus.synced => "Synced",
      WalletSyncStatus.syncing => "Syncing",
      WalletSyncStatus.unableToSync => "Offline",
    };

    // Offline escalates from a dot to the whole pill: it is the one state that
    // needs to be noticed rather than merely reported, and a red dot alone was
    // too quiet to do it.
    final alarm = _status == WalletSyncStatus.unableToSync;
    final colors = Theme.of(context).extension<StackColors>()!;
    final alarmFill = colors.accentColorRed;

    final pillFill = alarm ? alarmFill : favText.withOpacity(0.16);
    final pillInk = alarm ? readableInk(Colors.white, alarmFill) : favText;

    // The dot carries the state in colour; the word beside it stays hero ink so
    // the pill still reads as one object. Green when synced, amber while it
    // works, both from the theme.
    //
    // These used to be hero ink too, because the hero was the coin's colour and
    // a green dot measured 1.05:1 on Pepecoin's green. The hero is one fixed
    // brand fill now, so a status colour has a single known ground to clear,
    // and onHeroSignal is what maps the theme's state onto a tint authored for
    // that ground.
    final dotColor = switch (_status) {
      WalletSyncStatus.synced => onHeroSignal(colors.accentColorGreen),
      WalletSyncStatus.syncing => onHeroSignal(colors.accentColorYellow),
      WalletSyncStatus.unableToSync => pillInk,
    };

    return GestureDetector(
      onTap: _refresh,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: pillFill,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_status == WalletSyncStatus.syncing)
              SizedBox(
                width: 8,
                height: 8,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: dotColor,
                ),
              )
            else
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            const SizedBox(width: 5),
            Text(
              label,
              style: STextStyles.subtitle500(context).copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: pillInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
