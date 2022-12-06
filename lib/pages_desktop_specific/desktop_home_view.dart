import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages_desktop_specific/address_book_view/desktop_address_book.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_exchange/desktop_exchange_view.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_menu.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/my_stack_view.dart';
import 'package:stackwallet/pages_desktop_specific/notifications/desktop_notifications_view.dart';
import 'package:stackwallet/pages_desktop_specific/settings/desktop_settings_view.dart';
import 'package:stackwallet/pages_desktop_specific/settings/settings_menu/desktop_about_view.dart';
import 'package:stackwallet/pages_desktop_specific/settings/settings_menu/desktop_support_view.dart';
import 'package:stackwallet/providers/desktop/current_desktop_menu_item.dart';
import 'package:stackwallet/providers/global/auto_swb_service_provider.dart';
import 'package:stackwallet/providers/global/notifications_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/providers/ui/transaction_filter_provider.dart';
import 'package:stackwallet/providers/ui/unread_notifications_provider.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/utilities/enums/backup_frequency_type.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/background.dart';

final currentWalletIdProvider = StateProvider<String?>((_) => null);

class DesktopHomeView extends ConsumerStatefulWidget {
  const DesktopHomeView({Key? key}) : super(key: key);

  static const String routeName = "/desktopHome";

  @override
  ConsumerState<DesktopHomeView> createState() => _DesktopHomeViewState();
}

class _DesktopHomeViewState extends ConsumerState<DesktopHomeView> {
  final GlobalKey myStackViewNavKey = GlobalKey<NavigatorState>();
  late final Navigator myStackViewNav;

  @override
  void initState() {
    myStackViewNav = Navigator(
      key: myStackViewNavKey,
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: MyStackView.routeName,
    );
    super.initState();
  }

  final Map<DesktopMenuItemId, Widget> contentViews = {
    DesktopMenuItemId.myStack: Container(
        // key: Key("desktopStackHomeKey"),
        // onGenerateRoute: RouteGenerator.generateRoute,
        // initialRoute: MyStackView.routeName,
        ),
    DesktopMenuItemId.exchange: const Navigator(
      key: Key("desktopExchangeHomeKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: DesktopExchangeView.routeName,
    ),
    DesktopMenuItemId.notifications: const Navigator(
      key: Key("desktopNotificationsHomeKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: DesktopNotificationsView.routeName,
    ),
    DesktopMenuItemId.addressBook: const Navigator(
      key: Key("desktopAddressBookHomeKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: DesktopAddressBook.routeName,
    ),
    DesktopMenuItemId.settings: const Navigator(
      key: Key("desktopSettingHomeKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: DesktopSettingsView.routeName,
    ),
    DesktopMenuItemId.support: const Navigator(
      key: Key("desktopSupportHomeKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: DesktopSupportView.routeName,
    ),
    DesktopMenuItemId.about: const Navigator(
      key: Key("desktopAboutHomeKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: DesktopAboutView.routeName,
    ),
  };

  DesktopMenuItemId prev = DesktopMenuItemId.myStack;

  void onMenuSelectionWillChange(DesktopMenuItemId newKey) {
    if (prev == DesktopMenuItemId.myStack && prev == newKey) {
      Navigator.of(myStackViewNavKey.currentContext!)
          .popUntil(ModalRoute.withName(MyStackView.routeName));
      if (ref.read(currentWalletIdProvider.state).state != null) {
        final managerProvider = ref
            .read(walletsChangeNotifierProvider)
            .getManagerProvider(ref.read(currentWalletIdProvider.state).state!);
        if (ref.read(managerProvider).shouldAutoSync) {
          ref.read(managerProvider).shouldAutoSync = false;
        }
        ref.read(transactionFilterProvider.state).state = null;
        if (ref.read(prefsChangeNotifierProvider).isAutoBackupEnabled &&
            ref.read(prefsChangeNotifierProvider).backupFrequencyType ==
                BackupFrequencyType.afterClosingAWallet) {
          ref.read(autoSWBServiceProvider).doBackup();
        }
        ref.read(managerProvider.notifier).isActiveWallet = false;
      }
    }
    prev = newKey;

    // check for unread notifications and refresh provider before
    // showing notifications view
    if (newKey == DesktopMenuItemId.notifications) {
      ref.refresh(unreadNotificationsStateProvider);
    }
    // mark notifications as read if leaving notifications view
    if (ref.read(currentDesktopMenuItemProvider.state).state ==
            DesktopMenuItemId.notifications &&
        newKey != DesktopMenuItemId.notifications) {
      final Set<int> unreadNotificationIds =
          ref.read(unreadNotificationsStateProvider.state).state;

      if (unreadNotificationIds.isNotEmpty) {
        List<Future<void>> futures = [];
        for (int i = 0; i < unreadNotificationIds.length - 1; i++) {
          futures.add(ref
              .read(notificationsProvider)
              .markAsRead(unreadNotificationIds.elementAt(i), false));
        }

        // wait for multiple to update if any
        Future.wait(futures).then((_) {
          // only notify listeners once
          ref
              .read(notificationsProvider)
              .markAsRead(unreadNotificationIds.last, true);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).extension<StackColors>()!.background,
      child: Background(
        child: Row(
          children: [
            DesktopMenu(
              // onSelectionChanged: onMenuSelectionChanged,
              onSelectionWillChange: onMenuSelectionWillChange,
            ),
            Container(
              width: 1,
              color: Theme.of(context).extension<StackColors>()!.background,
            ),
            Expanded(
              child: IndexedStack(
                index: ref
                            .watch(currentDesktopMenuItemProvider.state)
                            .state
                            .index >
                        0
                    ? 1
                    : 0,
                children: [
                  myStackViewNav,
                  contentViews[
                      ref.watch(currentDesktopMenuItemProvider.state).state]!,
                ],
              ),
            ),
            // Expanded(
            //   child: contentViews[
            //       ref.watch(currentDesktopMenuItemProvider.state).state]!,
            // ),
          ],
        ),
      ),
    );
  }
}
