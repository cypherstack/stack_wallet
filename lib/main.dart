import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cw_core/node.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libmonero/monero/monero.dart';
import 'package:flutter_libmonero/wownero/wownero.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:isar/isar.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction_status.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/models/models.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/models/notification_model.dart';
import 'package:stackwallet/models/trade_wallet_lookup.dart';
import 'package:stackwallet/pages/home_view/home_view.dart';
import 'package:stackwallet/pages/intro_view.dart';
import 'package:stackwallet/pages/loading_view.dart';
import 'package:stackwallet/pages/pinpad_views/create_pin_view.dart';
import 'package:stackwallet/pages/pinpad_views/lock_screen_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/restore_from_encrypted_string_view.dart';
import 'package:stackwallet/pages_desktop_specific/password/desktop_login_view.dart';
import 'package:stackwallet/providers/desktop/storage_crypto_handler_provider.dart';
import 'package:stackwallet/providers/global/auto_swb_service_provider.dart';
import 'package:stackwallet/providers/global/base_currencies_provider.dart';
// import 'package:stackwallet/providers/global/has_authenticated_start_state_provider.dart';
import 'package:stackwallet/providers/global/trades_service_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/route_generator.dart';
// import 'package:stackwallet/services/buy/buy_data_loading_service.dart';
import 'package:stackwallet/services/debug_service.dart';
import 'package:stackwallet/services/exchange/exchange_data_loading_service.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/notifications_api.dart';
import 'package:stackwallet/services/notifications_service.dart';
import 'package:stackwallet/services/trade_service.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/db_version_migration.dart';
import 'package:stackwallet/utilities/enums/backup_frequency_type.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/crypto_notifications.dart';
import 'package:window_size/window_size.dart';

final openedFromSWBFileStringStateProvider =
    StateProvider<String?>((ref) => null);

// main() is the entry point to the app. It initializes Hive (local database),
// runs the MyApp widget and checks for new users, caching the value in the
// miscellaneous box for later use
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  if (Platform.isIOS) {
    Util.libraryPath = await getLibraryDirectory();
  }
  Screen? screen;
  if (Platform.isLinux || (Util.isDesktop && !Platform.isIOS)) {
    screen = await getCurrentScreen();
    Util.screenWidth = screen?.frame.width;
  }

  if (Util.isDesktop && !Platform.isIOS) {
    setWindowTitle('Stack Wallet');
    setWindowMinSize(const Size(1220, 100));
    setWindowMaxSize(Size.infinite);

    final screenHeight = screen?.frame.height;
    if (screenHeight != null && !kDebugMode) {
      // starting to height be 3/4 screen height or 900, whichever is smaller
      final height = min<double>(screenHeight * 0.75, 900);
      setWindowFrame(
        Rect.fromLTWH(0, 0, 1220, height),
      );
    }
  }

  // FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  if (!(Logging.isArmLinux || Logging.isTestEnv)) {
    final isar = await Isar.open(
      [LogSchema],
      directory: (await StackFileSystem.applicationIsarDirectory()).path,
      inspector: false,
      maxSizeMiB: 512,
    );
    await Logging.instance.init(isar);
    await DebugService.instance.init(isar);

    // clear out all info logs on startup. No need to await and block
    unawaited(DebugService.instance.deleteLogsOlderThan());
  }

  // Registering Transaction Model Adapters
  Hive.registerAdapter(TransactionDataAdapter());
  Hive.registerAdapter(TransactionChunkAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(InputAdapter());
  Hive.registerAdapter(OutputAdapter());

  // Registering Utxo Model Adapters
  Hive.registerAdapter(UtxoDataAdapter());
  Hive.registerAdapter(UtxoObjectAdapter());
  Hive.registerAdapter(StatusAdapter());

  // Registering Lelantus Model Adapters
  Hive.registerAdapter(LelantusCoinAdapter());

  // notification model adapter
  Hive.registerAdapter(NotificationModelAdapter());

  // change now trade adapters
  Hive.registerAdapter(ExchangeTransactionAdapter());
  Hive.registerAdapter(ExchangeTransactionStatusAdapter());

  Hive.registerAdapter(TradeAdapter());

  // reference lookup data adapter
  Hive.registerAdapter(TradeWalletLookupAdapter());

  // node model adapter
  Hive.registerAdapter(NodeModelAdapter());

  Hive.registerAdapter(NodeAdapter());

  if (!Hive.isAdapterRegistered(WalletInfoAdapter().typeId)) {
    Hive.registerAdapter(WalletInfoAdapter());
  }

  Hive.registerAdapter(WalletTypeAdapter());

  Hive.registerAdapter(UnspentCoinsInfoAdapter());
  await Hive.initFlutter(
      (await StackFileSystem.applicationHiveDirectory()).path);

  await Hive.openBox<dynamic>(DB.boxNameDBInfo);
  await Hive.openBox<dynamic>(DB.boxNamePrefs);
  await Prefs.instance.init();

  // Desktop migrate handled elsewhere (currently desktop_login_view.dart)
  if (!Util.isDesktop) {
    int dbVersion = DB.instance.get<dynamic>(
            boxName: DB.boxNameDBInfo, key: "hive_data_version") as int? ??
        0;
    if (dbVersion < Constants.currentDataVersion) {
      try {
        await DbVersionMigrator().migrate(
          dbVersion,
          secureStore: const SecureStorageWrapper(
            store: FlutterSecureStorage(),
            isDesktop: false,
          ),
        );
      } catch (e, s) {
        Logging.instance.log("Cannot migrate mobile database\n$e $s",
            level: LogLevel.Error, printFullLength: true);
      }
    }
  }

  monero.onStartup();
  if (!Platform.isLinux && !Platform.isWindows) {
    wownero.onStartup();
  }

  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
  //     overlays: [SystemUiOverlay.bottom]);
  await NotificationApi.init();

  await MainDB.instance.initMainDB();
  ThemeService.instance.init(MainDB.instance);

  // check and update or install default themes
  await ThemeService.instance.checkDefaultThemesOnStartup();

  runApp(const ProviderScope(child: MyApp()));
}

/// MyApp initialises relevant services with a MultiProvider
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localeService = LocaleService();
    localeService.loadLocale();

    return const KeyboardDismisser(
      child: MaterialAppWithTheme(),
    );
  }
}

// Sidenote: MaterialAppWithTheme and InitView are only separated for clarity. No other reason.

class MaterialAppWithTheme extends ConsumerStatefulWidget {
  const MaterialAppWithTheme({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<MaterialAppWithTheme> createState() =>
      _MaterialAppWithThemeState();
}

class _MaterialAppWithThemeState extends ConsumerState<MaterialAppWithTheme>
    with WidgetsBindingObserver {
  static const platform = MethodChannel("STACK_WALLET_RESTORE");
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // late final Wallets _wallets;
  // late final Prefs _prefs;
  late final NotificationsService _notificationsService;
  late final NodeService _nodeService;
  late final TradesService _tradesService;

  late final Completer<void> loadingCompleter;

  bool didLoad = false;
  bool didLoadShared = false;
  bool _desktopHasPassword = false;

  Future<void> loadShared() async {
    if (didLoadShared) {
      return;
    }
    didLoadShared = true;

    await DB.instance.init();
    await ref.read(prefsChangeNotifierProvider).init();

    final familiarity = ref.read(prefsChangeNotifierProvider).familiarity + 1;
    ref.read(prefsChangeNotifierProvider).familiarity = familiarity;

    Constants.exchangeForExperiencedUsers(familiarity);

    if (Util.isDesktop) {
      _desktopHasPassword =
          await ref.read(storageCryptoHandlerProvider).hasPassword();
    }

    ref
        .read(priceAnd24hChangeNotifierProvider)
        .tokenContractAddressesToCheck
        .addAll(
          await MainDB.instance.getEthContracts().addressProperty().findAll(),
        );
  }

  Future<void> load() async {
    try {
      if (didLoad) {
        return;
      }
      didLoad = true;

      if (!Util.isDesktop) {
        await loadShared();
      }

      ref.read(applicationThemesDirectoryPathProvider.notifier).state =
          (await StackFileSystem.applicationThemesDirectory()).path;

      _notificationsService = ref.read(notificationsProvider);
      _nodeService = ref.read(nodeServiceChangeNotifierProvider);
      _tradesService = ref.read(tradesServiceProvider);

      NotificationApi.prefs = ref.read(prefsChangeNotifierProvider);
      NotificationApi.notificationsService = _notificationsService;

      unawaited(ref.read(baseCurrenciesProvider).update());

      await _nodeService.updateDefaults();
      await _notificationsService.init(
        nodeService: _nodeService,
        tradesService: _tradesService,
        prefs: ref.read(prefsChangeNotifierProvider),
      );
      ref.read(priceAnd24hChangeNotifierProvider).start(true);
      await ref
          .read(walletsChangeNotifierProvider)
          .load(ref.read(prefsChangeNotifierProvider));
      loadingCompleter.complete();
      // TODO: this should probably run unawaited. Keep commented out for now as proper community nodes ui hasn't been implemented yet
      //  unawaited(_nodeService.updateCommunityNodes());

      await ExchangeDataLoadingService.instance.initDB();
      // run without awaiting
      if (ref.read(prefsChangeNotifierProvider).externalCalls &&
          await ref.read(prefsChangeNotifierProvider).isExternalCallsSet()) {
        if (Constants.enableExchange) {
          await ExchangeDataLoadingService.instance.setCurrenciesIfEmpty(
            ref.read(efCurrencyPairProvider),
            ref.read(efRateTypeProvider),
          );
          unawaited(ExchangeDataLoadingService.instance.loadAll());
        }
        // if (Constants.enableBuy) {
        //   unawaited(BuyDataLoadingService().loadAll(ref));
        // }
      }

      if (ref.read(prefsChangeNotifierProvider).isAutoBackupEnabled) {
        switch (ref.read(prefsChangeNotifierProvider).backupFrequencyType) {
          case BackupFrequencyType.everyTenMinutes:
            ref.read(autoSWBServiceProvider).startPeriodicBackupTimer(
                duration: const Duration(minutes: 10));
            break;
          case BackupFrequencyType.everyAppStart:
            unawaited(ref.read(autoSWBServiceProvider).doBackup());
            break;
          case BackupFrequencyType.afterClosingAWallet:
            // ignore this case here
            break;
        }
      }

      // ref
      //     .read(prefsChangeNotifierProvider)
      //     .userID; // Just reading the ref should set it if it's not already set
      // We shouldn't need to do this, instead only generating an ID when (or if) the userID is looked up when creating a quote
    } catch (e, s) {
      Logger.print("$e $s", normalLength: false);
    }
  }

  @override
  void initState() {
    String themeId;
    if (ref.read(prefsChangeNotifierProvider).enableSystemBrightness) {
      final brightness = WidgetsBinding.instance.window.platformBrightness;
      switch (brightness) {
        case Brightness.dark:
          themeId =
              ref.read(prefsChangeNotifierProvider).systemBrightnessDarkThemeId;
          break;
        case Brightness.light:
          themeId = ref
              .read(prefsChangeNotifierProvider)
              .systemBrightnessLightThemeId;
          break;
      }
    } else {
      themeId = ref.read(prefsChangeNotifierProvider).themeId;
    }

    loadingCompleter = Completer();
    WidgetsBinding.instance.addObserver(this);
    // load locale and prefs
    ref
        .read(localeServiceChangeNotifierProvider.notifier)
        .loadLocale(notify: false);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      //Add themes path to provider
      ref.read(applicationThemesDirectoryPathProvider.notifier).state =
          (await StackFileSystem.applicationThemesDirectory()).path;

      ref.read(themeProvider.state).state = ref.read(pThemeService).getTheme(
            themeId: themeId,
          )!;

      if (Platform.isAndroid) {
        // fetch open file if it exists
        await getOpenFile();

        if (ref.read(openedFromSWBFileStringStateProvider.state).state !=
            null) {
          // waiting for loading to complete before going straight to restore if the app was opened via file
          await loadingCompleter.future;

          await goToRestoreSWB(
              ref.read(openedFromSWBFileStringStateProvider.state).state!);
          ref.read(openedFromSWBFileStringStateProvider.state).state = null;
        }
        // ref.read(shouldShowLockscreenOnResumeStateProvider.state).state = false;
      }
    });

    WidgetsBinding.instance.window.onPlatformBrightnessChanged = () {
      String themeId;
      switch (WidgetsBinding.instance.window.platformBrightness) {
        case Brightness.dark:
          themeId =
              ref.read(prefsChangeNotifierProvider).systemBrightnessDarkThemeId;
          break;
        case Brightness.light:
          themeId = ref
              .read(prefsChangeNotifierProvider)
              .systemBrightnessLightThemeId;
          break;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(prefsChangeNotifierProvider).enableSystemBrightness) {
          ref.read(themeProvider.state).state =
              ref.read(pThemeService).getTheme(
                    themeId: themeId,
                  )!;
        }
      });
    };

    super.initState();
  }

  @override
  dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    debugPrint("didChangeAppLifecycleState: ${state.name}");
    if (state == AppLifecycleState.resumed) {}
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.resumed:
        if (Platform.isAndroid) {
          // fetch open file if it exists
          await getOpenFile();
          // go straight to restore if the app was resumed via file
          if (ref.read(openedFromSWBFileStringStateProvider.state).state !=
              null) {
            await goToRestoreSWB(
                ref.read(openedFromSWBFileStringStateProvider.state).state!);
            ref.read(openedFromSWBFileStringStateProvider.state).state = null;
          }
        }
        // if (ref.read(hasAuthenticatedOnStartStateProvider.state).state &&
        //     ref.read(shouldShowLockscreenOnResumeStateProvider.state).state) {
        //   final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
        //
        //   if (now - _prefs.lastUnlocked > _prefs.lastUnlockedTimeout) {
        //     ref.read(shouldShowLockscreenOnResumeStateProvider.state).state =
        //         false;
        //     Navigator.of(navigatorKey.currentContext!).push(
        //       MaterialPageRoute<dynamic>(
        //         builder: (_) => LockscreenView(
        //           routeOnSuccess: "",
        //           popOnSuccess: true,
        //           biometricsAuthenticationTitle: "Unlock Stack",
        //           biometricsLocalizedReason:
        //               "Unlock your stack wallet using biometrics",
        //           biometricsCancelButtonString: "Cancel",
        //           onSuccess: () {
        //             ref
        //                 .read(shouldShowLockscreenOnResumeStateProvider.state)
        //                 .state = true;
        //           },
        //         ),
        //       ),
        //     );
        //   }
        // }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  /// should only be called on android currently
  Future<void> getOpenFile() async {
    // update provider with new file content state
    ref.read(openedFromSWBFileStringStateProvider.state).state =
        await platform.invokeMethod("getOpenFile");

    // call reset to clear cached value
    await resetOpenPath();

    Logging.instance.log(
        "This is the .swb content from intent: ${ref.read(openedFromSWBFileStringStateProvider.state).state}",
        level: LogLevel.Info);
  }

  /// should only be called on android currently
  Future<void> resetOpenPath() async {
    await platform.invokeMethod("resetOpenPath");
  }

  Future<void> goToRestoreSWB(String encrypted) async {
    if (!ref.read(prefsChangeNotifierProvider).hasPin) {
      await Navigator.of(navigatorKey.currentContext!)
          .pushNamed(CreatePinView.routeName, arguments: true)
          .then((value) {
        if (value is! bool || value == false) {
          Navigator.of(navigatorKey.currentContext!).pushNamed(
              RestoreFromEncryptedStringView.routeName,
              arguments: encrypted);
        }
      });
    } else {
      unawaited(Navigator.push(
        navigatorKey.currentContext!,
        RouteGenerator.getRoute(
          shouldUseMaterialRoute: RouteGenerator.useMaterialPageRoute,
          builder: (_) => LockscreenView(
            showBackButton: true,
            routeOnSuccess: RestoreFromEncryptedStringView.routeName,
            routeOnSuccessArguments: encrypted,
            biometricsCancelButtonString: "CANCEL",
            biometricsLocalizedReason:
                "Authenticate to restore Stack Wallet backup",
            biometricsAuthenticationTitle: "Restore Stack backup",
          ),
          settings: const RouteSettings(name: "/swbrestorelockscreen"),
        ),
      ));
    }
  }

  InputBorder _buildOutlineInputBorder(Color color) {
    return OutlineInputBorder(
      borderSide: BorderSide(
        width: 1,
        color: color,
      ),
      borderRadius: BorderRadius.circular(Constants.size.circularBorderRadius),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    // ref.listen(shouldShowLockscreenOnResumeStateProvider, (previous, next) {
    //   Logging.instance.log("shouldShowLockscreenOnResumeStateProvider set to: $next",
    //       addToDebugMessagesDB: false);
    // });

    final colorScheme = ref.watch(colorProvider.state).state;

    return MaterialApp(
      key: GlobalKey(),
      navigatorKey: navigatorKey,
      title: 'Stack Wallet',
      onGenerateRoute: RouteGenerator.generateRoute,
      theme: ThemeData(
        extensions: [colorScheme],
        highlightColor: colorScheme.highlight,
        brightness: colorScheme.brightness,
        fontFamily: GoogleFonts.inter().fontFamily,
        unselectedWidgetColor: colorScheme.radioButtonBorderDisabled,
        // textTheme: GoogleFonts.interTextTheme().copyWith(
        //   button: STextStyles.button(context),
        //   subtitle1: STextStyles.field(context).copyWith(
        //     color: colorScheme.textDark,
        //   ),
        // ),
        radioTheme: const RadioThemeData(
          splashRadius: 0,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        // splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        buttonTheme: ButtonThemeData(
          splashColor: colorScheme.splash,
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            // splashFactory: NoSplash.splashFactory,
            overlayColor: MaterialStateProperty.all(colorScheme.splash),
            minimumSize: MaterialStateProperty.all<Size>(const Size(46, 46)),
            // textStyle: MaterialStateProperty.all<TextStyle>(
            //     STextStyles.button(context)),
            foregroundColor:
                MaterialStateProperty.all(colorScheme.buttonTextSecondary),
            backgroundColor: MaterialStateProperty.all<Color>(
                colorScheme.buttonBackSecondary),
            shape: MaterialStateProperty.all<OutlinedBorder>(
              RoundedRectangleBorder(
                // 1000 to be relatively sure it keeps its pill shape
                borderRadius: BorderRadius.circular(1000),
              ),
            ),
          ),
        ),
        primaryColor: colorScheme.accentColorDark,
        primarySwatch: Util.createMaterialColor(colorScheme.accentColorDark),
        checkboxTheme: CheckboxThemeData(
          splashRadius: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(Constants.size.checkboxBorderRadius),
          ),
          checkColor: MaterialStateColor.resolveWith(
            (state) {
              if (state.contains(MaterialState.selected)) {
                return colorScheme.checkboxIconChecked;
              }
              return colorScheme.checkboxBGChecked;
            },
          ),
          fillColor: MaterialStateColor.resolveWith(
            (states) {
              if (states.contains(MaterialState.selected)) {
                return colorScheme.checkboxBGChecked;
              }
              return colorScheme.checkboxBorderEmpty;
            },
          ),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          color: colorScheme.background,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusColor: colorScheme.textFieldDefaultBG,
          fillColor: colorScheme.textFieldDefaultBG,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 6,
            horizontal: 12,
          ),
          // labelStyle: STextStyles.fieldLabel(context),
          // hintStyle: STextStyles.fieldLabel(context),
          enabledBorder:
              _buildOutlineInputBorder(colorScheme.textFieldDefaultBG),
          focusedBorder:
              _buildOutlineInputBorder(colorScheme.textFieldDefaultBG),
          errorBorder: _buildOutlineInputBorder(colorScheme.textFieldDefaultBG),
          disabledBorder:
              _buildOutlineInputBorder(colorScheme.textFieldDefaultBG),
          focusedErrorBorder:
              _buildOutlineInputBorder(colorScheme.textFieldDefaultBG),
        ),
      ),
      home: CryptoNotifications(
        child: Util.isDesktop
            ? FutureBuilder(
                future: loadShared(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (_desktopHasPassword) {
                      String? startupWalletId;
                      if (ref
                          .read(prefsChangeNotifierProvider)
                          .gotoWalletOnStartup) {
                        startupWalletId = ref
                            .read(prefsChangeNotifierProvider)
                            .startupWalletId;
                      }

                      return DesktopLoginView(
                        startupWalletId: startupWalletId,
                        load: load,
                      );
                    } else {
                      return const IntroView();
                    }
                  } else {
                    return const LoadingView();
                  }
                },
              )
            : FutureBuilder(
                future: load(),
                builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    // FlutterNativeSplash.remove();
                    if (ref.read(walletsChangeNotifierProvider).hasWallets ||
                        ref.read(prefsChangeNotifierProvider).hasPin) {
                      // return HomeView();

                      String? startupWalletId;
                      if (ref
                          .read(prefsChangeNotifierProvider)
                          .gotoWalletOnStartup) {
                        startupWalletId = ref
                            .read(prefsChangeNotifierProvider)
                            .startupWalletId;
                      }

                      return LockscreenView(
                        isInitialAppLogin: true,
                        routeOnSuccess: HomeView.routeName,
                        routeOnSuccessArguments: startupWalletId,
                        biometricsAuthenticationTitle: "Unlock Stack",
                        biometricsLocalizedReason:
                            "Unlock your stack wallet using biometrics",
                        biometricsCancelButtonString: "Cancel",
                      );
                    } else {
                      return const IntroView();
                    }
                  } else {
                    // CURRENTLY DISABLED as cannot be animated
                    // technically not needed as FlutterNativeSplash will overlay
                    // anything returned here until the future completes but
                    // FutureBuilder requires you to return something
                    return const LoadingView();
                  }
                },
              ),
      ),
    );
  }
}
