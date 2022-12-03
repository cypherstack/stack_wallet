import 'package:epicmobile/models/contact_address_entry.dart';
import 'package:epicmobile/models/paymint/transactions_model.dart';
import 'package:epicmobile/models/send_view_auto_fill_data.dart';
import 'package:epicmobile/pages/add_wallet_views/create_restore_wallet_view.dart';
import 'package:epicmobile/pages/add_wallet_views/name_your_wallet_view.dart';
import 'package:epicmobile/pages/add_wallet_views/restore_wallet_view/restore_options_view/restore_options_view.dart';
import 'package:epicmobile/pages/add_wallet_views/restore_wallet_view/restore_wallet_view.dart';
import 'package:epicmobile/pages/address_book_views/address_book_view.dart';
import 'package:epicmobile/pages/address_book_views/subviews/add_address_book_entry_view.dart';
import 'package:epicmobile/pages/address_book_views/subviews/add_new_contact_address_view.dart';
import 'package:epicmobile/pages/address_book_views/subviews/address_book_filter_view.dart';
import 'package:epicmobile/pages/address_book_views/subviews/contact_details_view.dart';
import 'package:epicmobile/pages/address_book_views/subviews/edit_contact_address_view.dart';
import 'package:epicmobile/pages/address_book_views/subviews/edit_contact_name_emoji_view.dart';
import 'package:epicmobile/pages/help/help_view.dart';
import 'package:epicmobile/pages/home_view/home_view.dart';
import 'package:epicmobile/pages/intro_view.dart';
import 'package:epicmobile/pages/pinpad_views/create_pin_view.dart';
import 'package:epicmobile/pages/receive_view/generate_receiving_uri_qr_code_view.dart';
import 'package:epicmobile/pages/receive_view/receive_view.dart';
import 'package:epicmobile/pages/send_view/confirm_transaction_view.dart';
import 'package:epicmobile/pages/send_view/send_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/advanced_views/advanced_settings_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/advanced_views/debug_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/currency_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/delete_account_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/global_settings_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/hidden_settings.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/language_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/manage_nodes_views/add_edit_node_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/manage_nodes_views/coin_nodes_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/manage_nodes_views/manage_nodes_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/manage_nodes_views/node_details_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/security_views/change_pin_view/change_pin_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/security_views/security_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/wallet_backup_views/wallet_backup_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/wallet_settings_wallet_settings/delete_wallet_recovery_phrase_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/wallet_settings_wallet_settings/delete_wallet_warning_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/wallet_settings_wallet_settings/wallet_settings_wallet_settings_view.dart';
import 'package:epicmobile/pages/settings_views/wallet_settings_view/wallet_network_settings_view/wallet_network_settings_view.dart';
import 'package:epicmobile/pages/settings_views/wallet_settings_view/wallet_settings_view.dart';
import 'package:epicmobile/pages/wallet_view/transaction_views/all_transactions_view.dart';
import 'package:epicmobile/pages/wallet_view/transaction_views/edit_note_view.dart';
import 'package:epicmobile/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:epicmobile/pages/wallet_view/transaction_views/transaction_search_filter_view.dart';
import 'package:epicmobile/pages/wallet_view/wallet_view.dart';
import 'package:epicmobile/services/coins/manager.dart';
import 'package:epicmobile/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:epicmobile/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:epicmobile/utilities/enums/add_wallet_type_enum.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

class RouteGenerator {
  static const bool useMaterialPageRoute = true;

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed into Navigator.pushNamed
    final args = settings.arguments;

    switch (settings.name) {
      case IntroView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const IntroView(),
            settings: RouteSettings(name: settings.name));

      case CreateRestoreWalletView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const CreateRestoreWalletView(),
            settings: RouteSettings(name: settings.name));

      case DeleteAccountView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const DeleteAccountView(),
            settings: RouteSettings(name: settings.name));

      case HomeView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const HomeView(),
            settings: RouteSettings(name: settings.name));

      case CreatePinView.routeName:
        if (args is Tuple2<bool, bool>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => CreatePinView(
              popOnSuccess: args.item1,
              isNewWallet: args.item2,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case GlobalSettingsView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const GlobalSettingsView(),
            settings: RouteSettings(name: settings.name));

      case HelpView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const HelpView(),
            settings: RouteSettings(name: settings.name));

      case AddressBookView.routeName:
        if (args is Coin) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => AddressBookView(
              coin: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const AddressBookView(),
            settings: RouteSettings(name: settings.name));

      case AddressBookFilterView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const AddressBookFilterView(),
            settings: RouteSettings(name: settings.name));

      case SecurityView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const SecurityView(),
            settings: RouteSettings(name: settings.name));

      case ChangePinView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const ChangePinView(),
            settings: RouteSettings(name: settings.name));

      case BaseCurrencySettingsView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const BaseCurrencySettingsView(),
            settings: RouteSettings(name: settings.name));

      case LanguageSettingsView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const LanguageSettingsView(),
            settings: RouteSettings(name: settings.name));

      case DebugView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const DebugView(),
            settings: RouteSettings(name: settings.name));

      case ManageNodesView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const ManageNodesView(),
            settings: RouteSettings(name: settings.name));

      case AdvancedSettingsView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const AdvancedSettingsView(),
            settings: RouteSettings(name: settings.name));

      case AddAddressBookEntryView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const AddAddressBookEntryView(),
            settings: RouteSettings(name: settings.name));

      case HiddenSettings.routeName:
        return getRoute(
            shouldUseMaterialRoute: false,
            builder: (_) => const HiddenSettings(),
            settings: RouteSettings(name: settings.name));

      case CoinNodesView.routeName:
        if (args is Coin) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => CoinNodesView(
              coin: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case NodeDetailsView.routeName:
        if (args is Tuple3<Coin, String, String>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => NodeDetailsView(
              coin: args.item1,
              nodeId: args.item2,
              popRouteName: args.item3,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case EditNoteView.routeName:
        if (args is Tuple3<String, String, String>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => EditNoteView(
              txid: args.item1,
              walletId: args.item2,
              note: args.item3,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case AddEditNodeView.routeName:
        if (args is Tuple4<AddEditNodeViewType, Coin, String?, String>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => AddEditNodeView(
              viewType: args.item1,
              coin: args.item2,
              nodeId: args.item3,
              routeOnSuccessOrDelete: args.item4,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case ContactDetailsView.routeName:
        if (args is String) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => ContactDetailsView(
              contactId: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case AddNewContactAddressView.routeName:
        if (args is String) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => AddNewContactAddressView(
              contactId: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case EditContactNameEmojiView.routeName:
        if (args is String) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => EditContactNameEmojiView(
              contactId: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case EditContactAddressView.routeName:
        if (args is Tuple2<String, ContactAddressEntry>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => EditContactAddressView(
              contactId: args.item1,
              addressEntry: args.item2,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case WalletNetworkSettingsView.routeName:
        if (args is Tuple3<String, WalletSyncStatus, NodeConnectionStatus>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => WalletNetworkSettingsView(
              walletId: args.item1,
              initialSyncStatus: args.item2,
              initialNodeStatus: args.item3,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case WalletBackupView.routeName:
        if (args is Tuple2<String, List<String>>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => WalletBackupView(
              walletId: args.item1,
              mnemonic: args.item2,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case WalletSettingsWalletSettingsView.routeName:
        return getRoute(
          shouldUseMaterialRoute: useMaterialPageRoute,
          builder: (_) => const WalletSettingsWalletSettingsView(),
          settings: RouteSettings(
            name: settings.name,
          ),
        );

      case DeleteWalletWarningView.routeName:
        if (args is String) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => DeleteWalletWarningView(
              walletId: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case NameYourWalletView.routeName:
        if (args is Tuple2<AddWalletType, Coin>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => NameYourWalletView(
              addWalletType: args.item1,
              coin: args.item2,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case RestoreOptionsView.routeName:
        if (args is Tuple2<String, Coin>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => RestoreOptionsView(
              walletName: args.item1,
              coin: args.item2,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case RestoreWalletView.routeName:
        if (args is Tuple4<String, Coin, int, DateTime>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => RestoreWalletView(
              walletName: args.item1,
              coin: args.item2,
              seedWordsLength: args.item3,
              restoreFromDate: args.item4,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case WalletView.routeName:
        if (args is String) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => WalletView(
              walletId: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case TransactionDetailsView.routeName:
        if (args is Tuple3<Transaction, Coin, String>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => TransactionDetailsView(
              transaction: args.item1,
              coin: args.item2,
              walletId: args.item3,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case AllTransactionsView.routeName:
        if (args is String) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => AllTransactionsView(
              walletId: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case TransactionSearchFilterView.routeName:
        if (args is Coin) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => TransactionSearchFilterView(
              coin: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case ReceiveView.routeName:
        if (args is Tuple2<String, Coin>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => ReceiveView(
              walletId: args.item1,
              coin: args.item2,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case SendView.routeName:
        if (args is Tuple2<String, Coin>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => SendView(
              walletId: args.item1,
              coin: args.item2,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        } else if (args is Tuple3<String, Coin, SendViewAutoFillData>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => SendView(
              walletId: args.item1,
              coin: args.item2,
              autoFillData: args.item3,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case ConfirmTransactionView.routeName:
        if (args is Tuple2<Map<String, dynamic>, String>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => ConfirmTransactionView(
              transactionInfo: args.item1,
              walletId: args.item2,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case WalletSettingsView.routeName:
        if (args
            is Tuple4<String, Coin, WalletSyncStatus, NodeConnectionStatus>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => WalletSettingsView(
              walletId: args.item1,
              coin: args.item2,
              initialSyncStatus: args.item3,
              initialNodeStatus: args.item4,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case DeleteWalletRecoveryPhraseView.routeName:
        if (args is Tuple2<Manager, List<String>>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => DeleteWalletRecoveryPhraseView(
              manager: args.item1,
              mnemonic: args.item2,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case GenerateUriQrCodeView.routeName:
        if (args is Tuple2<Coin, String>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => GenerateUriQrCodeView(
              coin: args.item1,
              receivingAddress: args.item2,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      default:
        return _routeError("");
    }
  }

  static Route<dynamic> getRoute({
    bool shouldUseMaterialRoute = useMaterialPageRoute,
    required Widget Function(BuildContext) builder,
    String? title,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    if (shouldUseMaterialRoute) {
      return MaterialPageRoute(
        builder: builder,
        settings: settings,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      );
    } else {
      return CupertinoPageRoute(
        builder: builder,
        settings: settings,
        title: title,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      );
    }
  }

  static Route<dynamic> createSlideTransitionRoute(Widget viewToInsert) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => viewToInsert,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(0.0, 1.0);
        var end = Offset.zero;
        var curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  static Route<dynamic> _routeError(String message) {
    // Replace with robust ErrorView page
    Widget errorView = Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Navigation error'),
      ),
      body: Center(
        child: Text(
            'Error handling route, this is not supposed to happen. Try restarting the app.\n$message'),
      ),
    );

    return getRoute(
        shouldUseMaterialRoute: useMaterialPageRoute,
        builder: (_) => errorView);
  }
}

class FadePageRoute<T> extends PageRoute<T> {
  FadePageRoute(this.child, RouteSettings settings) : _settings = settings;

  final Widget child;
  final RouteSettings _settings;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 100);

  @override
  RouteSettings get settings => _settings;
}
