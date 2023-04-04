import 'package:decimal/decimal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/models/buy/response_objects/quote.dart';
import 'package:stackwallet/models/contact_address_entry.dart';
import 'package:stackwallet/models/exchange/incomplete_exchange.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/models/paynym/paynym_account_lite.dart';
import 'package:stackwallet/models/send_view_auto_fill_data.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/add_wallet_view.dart';
import 'package:stackwallet/pages/add_wallet_views/create_or_restore_wallet_view/create_or_restore_wallet_view.dart';
import 'package:stackwallet/pages/add_wallet_views/name_your_wallet_view/name_your_wallet_view.dart';
import 'package:stackwallet/pages/add_wallet_views/new_wallet_recovery_phrase_view/new_wallet_recovery_phrase_view.dart';
import 'package:stackwallet/pages/add_wallet_views/new_wallet_recovery_phrase_warning_view/new_wallet_recovery_phrase_warning_view.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/restore_options_view/restore_options_view.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/restore_wallet_view.dart';
import 'package:stackwallet/pages/add_wallet_views/verify_recovery_phrase_view/verify_recovery_phrase_view.dart';
import 'package:stackwallet/pages/address_book_views/address_book_view.dart';
import 'package:stackwallet/pages/address_book_views/subviews/add_address_book_entry_view.dart';
import 'package:stackwallet/pages/address_book_views/subviews/add_new_contact_address_view.dart';
import 'package:stackwallet/pages/address_book_views/subviews/address_book_filter_view.dart';
import 'package:stackwallet/pages/address_book_views/subviews/contact_details_view.dart';
import 'package:stackwallet/pages/address_book_views/subviews/edit_contact_address_view.dart';
import 'package:stackwallet/pages/address_book_views/subviews/edit_contact_name_emoji_view.dart';
import 'package:stackwallet/pages/buy_view/buy_in_wallet_view.dart';
import 'package:stackwallet/pages/buy_view/buy_quote_preview.dart';
import 'package:stackwallet/pages/buy_view/buy_view.dart';
import 'package:stackwallet/pages/coin_control/coin_control_view.dart';
import 'package:stackwallet/pages/coin_control/utxo_details_view.dart';
import 'package:stackwallet/pages/exchange_view/choose_from_stack_view.dart';
import 'package:stackwallet/pages/exchange_view/edit_trade_note_view.dart';
import 'package:stackwallet/pages/exchange_view/exchange_step_views/step_1_view.dart';
import 'package:stackwallet/pages/exchange_view/exchange_step_views/step_2_view.dart';
import 'package:stackwallet/pages/exchange_view/exchange_step_views/step_3_view.dart';
import 'package:stackwallet/pages/exchange_view/exchange_step_views/step_4_view.dart';
import 'package:stackwallet/pages/exchange_view/send_from_view.dart';
import 'package:stackwallet/pages/exchange_view/trade_details_view.dart';
import 'package:stackwallet/pages/exchange_view/wallet_initiated_exchange_view.dart';
import 'package:stackwallet/pages/generic/single_field_edit_view.dart';
import 'package:stackwallet/pages/home_view/home_view.dart';
import 'package:stackwallet/pages/intro_view.dart';
import 'package:stackwallet/pages/manage_favorites_view/manage_favorites_view.dart';
import 'package:stackwallet/pages/notification_views/notifications_view.dart';
import 'package:stackwallet/pages/paynym/add_new_paynym_follow_view.dart';
import 'package:stackwallet/pages/paynym/paynym_claim_view.dart';
import 'package:stackwallet/pages/paynym/paynym_home_view.dart';
import 'package:stackwallet/pages/pinpad_views/create_pin_view.dart';
import 'package:stackwallet/pages/receive_view/addresses/address_details_view.dart';
import 'package:stackwallet/pages/receive_view/addresses/edit_address_label_view.dart';
import 'package:stackwallet/pages/receive_view/addresses/wallet_addresses_view.dart';
import 'package:stackwallet/pages/receive_view/generate_receiving_uri_qr_code_view.dart';
import 'package:stackwallet/pages/receive_view/receive_view.dart';
import 'package:stackwallet/pages/send_view/confirm_transaction_view.dart';
import 'package:stackwallet/pages/send_view/send_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/about_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/advanced_views/advanced_settings_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/advanced_views/debug_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/appearance_settings_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/currency_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/delete_account_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/global_settings_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/hidden_settings.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/language_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/manage_nodes_views/add_edit_node_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/manage_nodes_views/coin_nodes_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/manage_nodes_views/manage_nodes_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/manage_nodes_views/node_details_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/security_views/change_pin_view/change_pin_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/security_views/security_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/auto_backup_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/create_auto_backup_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/create_backup_information_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/create_backup_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/edit_auto_backup_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/restore_from_encrypted_string_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/restore_from_file_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/stack_backup_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/startup_preferences/startup_preferences_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/startup_preferences/startup_wallet_selection_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/support_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/syncing_preferences_views/syncing_options_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/syncing_preferences_views/syncing_preferences_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/syncing_preferences_views/wallet_syncing_options_view.dart';
import 'package:stackwallet/pages/settings_views/wallet_settings_view/wallet_backup_views/wallet_backup_view.dart';
import 'package:stackwallet/pages/settings_views/wallet_settings_view/wallet_network_settings_view/wallet_network_settings_view.dart';
import 'package:stackwallet/pages/settings_views/wallet_settings_view/wallet_settings_view.dart';
import 'package:stackwallet/pages/settings_views/wallet_settings_view/wallet_settings_wallet_settings/delete_wallet_recovery_phrase_view.dart';
import 'package:stackwallet/pages/settings_views/wallet_settings_view/wallet_settings_wallet_settings/delete_wallet_warning_view.dart';
import 'package:stackwallet/pages/settings_views/wallet_settings_view/wallet_settings_wallet_settings/rename_wallet_view.dart';
import 'package:stackwallet/pages/settings_views/wallet_settings_view/wallet_settings_wallet_settings/wallet_settings_wallet_settings_view.dart';
import 'package:stackwallet/pages/stack_privacy_calls.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/all_transactions_view.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/edit_note_view.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_search_filter_view.dart';
import 'package:stackwallet/pages/wallet_view/wallet_view.dart';
import 'package:stackwallet/pages/wallets_view/wallets_view.dart';
import 'package:stackwallet/pages_desktop_specific/address_book_view/desktop_address_book.dart';
import 'package:stackwallet/pages_desktop_specific/addresses/desktop_wallet_addresses_view.dart';
import 'package:stackwallet/pages_desktop_specific/coin_control/desktop_coin_control_view.dart';
// import 'package:stackwallet/pages_desktop_specific/desktop_exchange/desktop_all_buys_view.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_buy/desktop_buy_view.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_exchange/desktop_all_trades_view.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_exchange/desktop_exchange_view.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_home_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/my_stack_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/desktop_wallet_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/delete_wallet_keys_popup.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_attention_delete_wallet.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_delete_wallet_dialog.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/qr_code_desktop_popup_content.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/unlock_wallet_keys_desktop.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/wallet_keys_desktop_popup.dart';
import 'package:stackwallet/pages_desktop_specific/notifications/desktop_notifications_view.dart';
import 'package:stackwallet/pages_desktop_specific/password/create_password_view.dart';
import 'package:stackwallet/pages_desktop_specific/password/delete_password_warning_view.dart';
import 'package:stackwallet/pages_desktop_specific/password/forgot_password_desktop_view.dart';
import 'package:stackwallet/pages_desktop_specific/password/forgotten_passphrase_restore_from_swb.dart';
import 'package:stackwallet/pages_desktop_specific/settings/desktop_settings_view.dart';
import 'package:stackwallet/pages_desktop_specific/settings/settings_menu/advanced_settings/advanced_settings.dart';
import 'package:stackwallet/pages_desktop_specific/settings/settings_menu/appearance_settings.dart';
import 'package:stackwallet/pages_desktop_specific/settings/settings_menu/backup_and_restore/backup_and_restore_settings.dart';
import 'package:stackwallet/pages_desktop_specific/settings/settings_menu/currency_settings/currency_settings.dart';
import 'package:stackwallet/pages_desktop_specific/settings/settings_menu/desktop_about_view.dart';
import 'package:stackwallet/pages_desktop_specific/settings/settings_menu/desktop_support_view.dart';
import 'package:stackwallet/pages_desktop_specific/settings/settings_menu/language_settings/language_settings.dart';
import 'package:stackwallet/pages_desktop_specific/settings/settings_menu/nodes_settings.dart';
import 'package:stackwallet/pages_desktop_specific/settings/settings_menu/security_settings.dart';
import 'package:stackwallet/pages_desktop_specific/settings/settings_menu/syncing_preferences_settings.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/utilities/enums/add_wallet_type_enum.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';
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
        if (args is bool) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => CreatePinView(
              popOnSuccess: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const CreatePinView(),
            settings: RouteSettings(name: settings.name));

      case StackPrivacyCalls.routeName:
        if (args is bool) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => StackPrivacyCalls(isSettings: args),
            settings: RouteSettings(name: settings.name),
          );
        }
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const StackPrivacyCalls(isSettings: false),
            settings: RouteSettings(name: settings.name));

      case WalletsView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const WalletsView(),
            settings: RouteSettings(name: settings.name));

      case AddWalletView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const AddWalletView(),
            settings: RouteSettings(name: settings.name));

      case SingleFieldEditView.routeName:
        if (args is Tuple2<String, String>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => SingleFieldEditView(
              initialValue: args.item1,
              label: args.item2,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case CoinControlView.routeName:
        if (args is Tuple2<String, CoinControlViewType>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => CoinControlView(
              walletId: args.item1,
              type: args.item2,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        } else if (args
            is Tuple4<String, CoinControlViewType, int?, Set<UTXO>?>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => CoinControlView(
              walletId: args.item1,
              type: args.item2,
              requestedTotal: args.item3,
              selectedUTXOs: args.item4,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case UtxoDetailsView.routeName:
        if (args is Tuple2<Id, String>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => UtxoDetailsView(
              walletId: args.item2,
              utxoId: args.item1,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case PaynymClaimView.routeName:
        if (args is String) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => PaynymClaimView(
              walletId: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case PaynymHomeView.routeName:
        if (args is String) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => PaynymHomeView(
              walletId: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case AddNewPaynymFollowView.routeName:
        if (args is String) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => AddNewPaynymFollowView(
              walletId: args,
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

      case StackBackupView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const StackBackupView(),
            settings: RouteSettings(name: settings.name));

      case AutoBackupView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const AutoBackupView(),
            settings: RouteSettings(name: settings.name));

      case EditAutoBackupView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const EditAutoBackupView(),
            settings: RouteSettings(name: settings.name));

      case CreateAutoBackupView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const CreateAutoBackupView(),
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

      case AboutView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const AboutView(),
            settings: RouteSettings(name: settings.name));

      case DebugView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const DebugView(),
            settings: RouteSettings(name: settings.name));

      case AppearanceSettingsView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const AppearanceSettingsView(),
            settings: RouteSettings(name: settings.name));

      case SyncingPreferencesView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const SyncingPreferencesView(),
            settings: RouteSettings(name: settings.name));

      case StartupPreferencesView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const StartupPreferencesView(),
            settings: RouteSettings(name: settings.name));

      case StartupWalletSelectionView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const StartupWalletSelectionView(),
            settings: RouteSettings(name: settings.name));

      case ManageNodesView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const ManageNodesView(),
            settings: RouteSettings(name: settings.name));

      case SyncingOptionsView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const SyncingOptionsView(),
            settings: RouteSettings(name: settings.name));

      case WalletSyncingOptionsView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const WalletSyncingOptionsView(),
            settings: RouteSettings(name: settings.name));

      case AdvancedSettingsView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const AdvancedSettingsView(),
            settings: RouteSettings(name: settings.name));

      case SupportView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const SupportView(),
            settings: RouteSettings(name: settings.name));

      case AddAddressBookEntryView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const AddAddressBookEntryView(),
            settings: RouteSettings(name: settings.name));

      case RestoreFromFileView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const RestoreFromFileView(),
            settings: RouteSettings(name: settings.name));

      case RestoreFromEncryptedStringView.routeName:
        if (args is String) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => RestoreFromEncryptedStringView(
              encrypted: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case CreateBackupInfoView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const CreateBackupInfoView(),
            settings: RouteSettings(name: settings.name));

      case CreateBackupView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const CreateBackupView(),
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

      case EditAddressLabelView.routeName:
        if (args is int) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => EditAddressLabelView(
              addressLabelId: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case EditTradeNoteView.routeName:
        if (args is Tuple2<String, String>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => EditTradeNoteView(
              tradeId: args.item1,
              note: args.item2,
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

      case SystemBrightnessThemeSelectionView.routeName:
        if (args is Tuple2<String, ThemeType>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => SystemBrightnessThemeSelectionView(
              brightness: args.item1,
              current: args.item2,
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
        if (args is String) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => WalletSettingsWalletSettingsView(
              walletId: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case RenameWalletView.routeName:
        if (args is String) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => RenameWalletView(
              walletId: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

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

      case CreateOrRestoreWalletView.routeName:
        if (args is Coin) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => CreateOrRestoreWalletView(
              coin: args,
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

      case NewWalletRecoveryPhraseWarningView.routeName:
        if (args is Tuple2<String, Coin>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => NewWalletRecoveryPhraseWarningView(
              walletName: args.item1,
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
        if (args is Tuple5<String, Coin, int, DateTime, String>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => RestoreWalletView(
                walletName: args.item1,
                coin: args.item2,
                seedWordsLength: args.item3,
                restoreFromDate: args.item4,
                mnemonicPassphrase: args.item5),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case NewWalletRecoveryPhraseView.routeName:
        if (args is Tuple2<Manager, List<String>>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => NewWalletRecoveryPhraseView(
              manager: args.item1,
              mnemonic: args.item2,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case VerifyRecoveryPhraseView.routeName:
        if (args is Tuple2<Manager, List<String>>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => VerifyRecoveryPhraseView(
              manager: args.item1,
              mnemonic: args.item2,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case ManageFavoritesView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const ManageFavoritesView());

      case WalletView.routeName:
        if (args is Tuple2<String, ChangeNotifierProvider<Manager>>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => WalletView(
              walletId: args.item1,
              managerProvider: args.item2,
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

      case WalletAddressesView.routeName:
        if (args is String) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => WalletAddressesView(
              walletId: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case AddressDetailsView.routeName:
        if (args is Tuple2<Id, String>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => AddressDetailsView(
              walletId: args.item2,
              addressId: args.item1,
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
        } else if (args is Tuple3<String, Coin, PaynymAccountLite>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => SendView(
              walletId: args.item1,
              coin: args.item2,
              accountLite: args.item3,
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

      case WalletInitiatedExchangeView.routeName:
        if (args is Tuple2<String, Coin>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => Stack(
              children: [
                WalletInitiatedExchangeView(
                  walletId: args.item1,
                  coin: args.item2,
                ),
                // ExchangeLoadingOverlayView(
                //   unawaitedLoad: args.item3,
                // ),
              ],
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case NotificationsView.routeName:
        if (args is String?) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => NotificationsView(
              walletId: args,
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

      // exchange steps

      case Step1View.routeName:
        if (args is IncompleteExchangeModel) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => Step1View(
              model: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case Step2View.routeName:
        if (args is IncompleteExchangeModel) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => Step2View(
              model: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case Step3View.routeName:
        if (args is IncompleteExchangeModel) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => Step3View(
              model: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case Step4View.routeName:
        if (args is IncompleteExchangeModel) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => Step4View(
              model: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case TradeDetailsView.routeName:
        if (args is Tuple4<String, Transaction?, String?, String?>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => TradeDetailsView(
              tradeId: args.item1,
              transactionIfSentFromStack: args.item2,
              walletId: args.item3,
              walletName: args.item4,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case ChooseFromStackView.routeName:
        if (args is Coin) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => ChooseFromStackView(
              coin: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case SendFromView.routeName:
        if (args is Tuple4<Coin, Decimal, String, Trade>) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => SendFromView(
              coin: args.item1,
              amount: args.item2,
              trade: args.item4,
              address: args.item3,
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

      case BuyQuotePreviewView.routeName:
        if (args is SimplexQuote) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => BuyQuotePreviewView(
              quote: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      // == Desktop specific routes ============================================
      case CreatePasswordView.routeName:
        if (args is bool) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => CreatePasswordView(
              restoreFromSWB: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const CreatePasswordView(),
            settings: RouteSettings(name: settings.name));

      case ForgotPasswordDesktopView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const ForgotPasswordDesktopView(),
            settings: RouteSettings(name: settings.name));

      case ForgottenPassphraseRestoreFromSWB.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const ForgottenPassphraseRestoreFromSWB(),
            settings: RouteSettings(name: settings.name));

      case DeletePasswordWarningView.routeName:
        if (args is bool) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => DeletePasswordWarningView(
              shouldCreateNew: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case DesktopHomeView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const DesktopHomeView(),
            settings: RouteSettings(name: settings.name));

      case DesktopNotificationsView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const DesktopNotificationsView(),
            settings: RouteSettings(name: settings.name));

      case DesktopExchangeView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const DesktopExchangeView(),
            settings: RouteSettings(name: settings.name));

      case BuyView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const BuyView(),
            settings: RouteSettings(name: settings.name));

      case BuyInWalletView.routeName:
        if (args is Coin) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => BuyInWalletView(coin: args),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case DesktopBuyView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const DesktopBuyView(),
            settings: RouteSettings(name: settings.name));

      case DesktopAllTradesView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const DesktopAllTradesView(),
            settings: RouteSettings(name: settings.name));

      case DesktopSettingsView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const DesktopSettingsView(),
            settings: RouteSettings(name: settings.name));

      case MyStackView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const MyStackView(),
            settings: RouteSettings(name: settings.name));

      case DesktopWalletView.routeName:
        if (args is String) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => DesktopWalletView(
              walletId: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case DesktopWalletAddressesView.routeName:
        if (args is String) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => DesktopWalletAddressesView(
              walletId: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case DesktopCoinControlView.routeName:
        if (args is String) {
          return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => DesktopCoinControlView(
              walletId: args,
            ),
            settings: RouteSettings(
              name: settings.name,
            ),
          );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case BackupRestoreSettings.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const BackupRestoreSettings(),
            settings: RouteSettings(name: settings.name));

      case SecuritySettings.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const SecuritySettings(),
            settings: RouteSettings(name: settings.name));

      case CurrencySettings.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const CurrencySettings(),
            settings: RouteSettings(name: settings.name));

      case LanguageOptionSettings.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const LanguageOptionSettings(),
            settings: RouteSettings(name: settings.name));

      case NodesSettings.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const NodesSettings(),
            settings: RouteSettings(name: settings.name));

      case SyncingPreferencesSettings.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const SyncingPreferencesSettings(),
            settings: RouteSettings(name: settings.name));

      case AppearanceOptionSettings.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const AppearanceOptionSettings(),
            settings: RouteSettings(name: settings.name));

      case AdvancedSettings.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const AdvancedSettings(),
            settings: RouteSettings(name: settings.name));

      case DesktopSupportView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const DesktopSupportView(),
            settings: RouteSettings(name: settings.name));

      case DesktopAboutView.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const DesktopAboutView(),
            settings: RouteSettings(name: settings.name));

      case DesktopAddressBook.routeName:
        return getRoute(
            shouldUseMaterialRoute: useMaterialPageRoute,
            builder: (_) => const DesktopAddressBook(),
            settings: RouteSettings(name: settings.name));

      case WalletKeysDesktopPopup.routeName:
        if (args is List<String>) {
          return FadePageRoute(
            WalletKeysDesktopPopup(
              words: args,
            ),
            RouteSettings(
              name: settings.name,
            ),
          );
          // return getRoute(
          //   shouldUseMaterialRoute: useMaterialPageRoute,
          //   builder: (_) => WalletKeysDesktopPopup(
          //     words: args,
          //   ),
          //   settings: RouteSettings(
          //     name: settings.name,
          //   ),
          // );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case UnlockWalletKeysDesktop.routeName:
        if (args is String) {
          return FadePageRoute(
            UnlockWalletKeysDesktop(
              walletId: args,
            ),
            RouteSettings(
              name: settings.name,
            ),
          );
          // return getRoute(
          //   shouldUseMaterialRoute: useMaterialPageRoute,
          //   builder: (_) => WalletKeysDesktopPopup(
          //     words: args,
          //   ),
          //   settings: RouteSettings(
          //     name: settings.name,
          //   ),
          // );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case DesktopDeleteWalletDialog.routeName:
        if (args is String) {
          return FadePageRoute(
            DesktopDeleteWalletDialog(
              walletId: args,
            ),
            RouteSettings(
              name: settings.name,
            ),
          );
          // return getRoute(
          //   shouldUseMaterialRoute: useMaterialPageRoute,
          //   builder: (_) => WalletKeysDesktopPopup(
          //     words: args,
          //   ),
          //   settings: RouteSettings(
          //     name: settings.name,
          //   ),
          // );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case DesktopAttentionDeleteWallet.routeName:
        if (args is String) {
          return FadePageRoute(
            DesktopAttentionDeleteWallet(
              walletId: args,
            ),
            RouteSettings(
              name: settings.name,
            ),
          );
          // return getRoute(
          //   shouldUseMaterialRoute: useMaterialPageRoute,
          //   builder: (_) => WalletKeysDesktopPopup(
          //     words: args,
          //   ),
          //   settings: RouteSettings(
          //     name: settings.name,
          //   ),
          // );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case DeleteWalletKeysPopup.routeName:
        if (args is Tuple2<String, List<String>>) {
          return FadePageRoute(
            DeleteWalletKeysPopup(
              walletId: args.item1,
              words: args.item2,
            ),
            RouteSettings(
              name: settings.name,
            ),
          );
          // return getRoute(
          //   shouldUseMaterialRoute: useMaterialPageRoute,
          //   builder: (_) => WalletKeysDesktopPopup(
          //     words: args,
          //   ),
          //   settings: RouteSettings(
          //     name: settings.name,
          //   ),
          // );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      case QRCodeDesktopPopupContent.routeName:
        if (args is String) {
          return FadePageRoute(
            QRCodeDesktopPopupContent(
              value: args,
            ),
            RouteSettings(
              name: settings.name,
            ),
          );
          // return getRoute(
          //   shouldUseMaterialRoute: useMaterialPageRoute,
          //   builder: (_) => QRCodeDesktopPopupContent(
          //     value: args,
          //   ),
          //   settings: RouteSettings(
          //     name: settings.name,
          //   ),
          // );
        }
        return _routeError("${settings.name} invalid args: ${args.toString()}");

      // == End of desktop specific routes =====================================

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
