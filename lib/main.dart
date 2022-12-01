import 'dart:async';
import 'dart:io';

import 'package:epicmobile/hive/db.dart';
import 'package:epicmobile/models/isar/models/log.dart';
import 'package:epicmobile/models/models.dart';
import 'package:epicmobile/models/node_model.dart';
import 'package:epicmobile/models/notification_model.dart';
import 'package:epicmobile/models/trade_wallet_lookup.dart';
import 'package:epicmobile/pages/home_view/home_view.dart';
import 'package:epicmobile/pages/intro_view.dart';
import 'package:epicmobile/pages/loading_view.dart';
import 'package:epicmobile/pages/pinpad_views/lock_screen_view.dart';
import 'package:epicmobile/providers/desktop/storage_crypto_handler_provider.dart';
import 'package:epicmobile/providers/global/base_currencies_provider.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/providers/ui/color_theme_provider.dart';
import 'package:epicmobile/route_generator.dart';
import 'package:epicmobile/services/debug_service.dart';
import 'package:epicmobile/services/locale_service.dart';
import 'package:epicmobile/services/node_service.dart';
import 'package:epicmobile/services/notifications_api.dart';
import 'package:epicmobile/services/notifications_service.dart';
import 'package:epicmobile/services/wallets.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/db_version_migration.dart';
import 'package:epicmobile/utilities/logger.dart';
import 'package:epicmobile/utilities/prefs.dart';
import 'package:epicmobile/utilities/theme/color_theme.dart';
import 'package:epicmobile/utilities/theme/dark_colors.dart';
import 'package:epicmobile/utilities/theme/light_colors.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/utilities/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:isar/isar.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_size/window_size.dart';

// main() is the entry point to the app. It initializes Hive (local database),
// runs the MyApp widget and checks for new users, caching the value in the
// miscellaneous box for later use
void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  if (Platform.isIOS) {
    Util.libraryPath = await getLibraryDirectory();
  }

  if (Util.isDesktop) {
    setWindowTitle('Stack Wallet');
    setWindowMinSize(const Size(1200, 900));
    setWindowMaxSize(Size.infinite);
  }

  Directory appDirectory = (await getApplicationDocumentsDirectory());
  if (Platform.isIOS) {
    appDirectory = (await getLibraryDirectory());
  }
  if (Platform.isLinux || Logging.isArmLinux) {
    appDirectory = Directory("${appDirectory.path}/.epicmobile");
    await appDirectory.create();
  }
  // FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  if (!(Logging.isArmLinux || Logging.isTestEnv)) {
    final isar = await Isar.open(
      [LogSchema],
      directory: appDirectory.path,
      inspector: false,
    );
    await Logging.instance.init(isar);
    await DebugService.instance.init(isar);

    // clear out all info logs on startup. No need to await and block
    unawaited(DebugService.instance.purgeInfoLogs());
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

  // reference lookup data adapter
  Hive.registerAdapter(TradeWalletLookupAdapter());

  // node model adapter
  Hive.registerAdapter(NodeModelAdapter());

  await Hive.initFlutter(appDirectory.path);

  await Hive.openBox<dynamic>(DB.boxNameDBInfo);
  int dbVersion = DB.instance.get<dynamic>(
          boxName: DB.boxNameDBInfo, key: "hive_data_version") as int? ??
      0;
  if (dbVersion < Constants.currentHiveDbVersion) {
    try {
      await DbVersionMigrator().migrate(dbVersion);
    } catch (e, s) {
      Logging.instance.log("Cannot migrate database\n$e $s",
          level: LogLevel.Error, printFullLength: true);
    }
  }

  await Hive.openBox<dynamic>(DB.boxNameTheme);

  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
  //     overlays: [SystemUiOverlay.bottom]);
  await NotificationApi.init();

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

  late final Wallets _wallets;
  late final Prefs _prefs;
  late final NotificationsService _notificationsService;
  late final NodeService _nodeService;

  late final Completer<void> loadingCompleter;

  bool didLoad = false;
  bool _desktopHasPassword = false;

  Future<void> load() async {
    try {
      if (didLoad) {
        return;
      }
      didLoad = true;

      await DB.instance.init();
      await _prefs.init();

      if (Util.isDesktop) {
        _desktopHasPassword =
            await ref.read(storageCryptoHandlerProvider).hasPassword();
      }

      _notificationsService = ref.read(notificationsProvider);
      _nodeService = ref.read(nodeServiceChangeNotifierProvider);

      NotificationApi.prefs = _prefs;
      NotificationApi.notificationsService = _notificationsService;

      unawaited(ref.read(baseCurrenciesProvider).update());

      await _nodeService.updateDefaults();
      await _notificationsService.init(
        nodeService: _nodeService,
        prefs: _prefs,
      );
      ref.read(priceAnd24hChangeNotifierProvider).start(true);
      await _wallets.load(_prefs);
      loadingCompleter.complete();
      // TODO: this should probably run unawaited. Keep commented out for now as proper community nodes ui hasn't been implemented yet
      //  unawaited(_nodeService.updateCommunityNodes());

    } catch (e, s) {
      Logger.print("$e $s", normalLength: false);
    }
  }

  @override
  void initState() {
    final colorScheme = DB.instance
        .get<dynamic>(boxName: DB.boxNameTheme, key: "colorScheme") as String?;

    ThemeType themeType;
    switch (colorScheme) {
      case "dark":
        themeType = ThemeType.dark;
        break;
      case "light":
      default:
        themeType = ThemeType.light;
    }
    loadingCompleter = Completer();
    WidgetsBinding.instance.addObserver(this);
    // load locale and prefs
    ref
        .read(localeServiceChangeNotifierProvider.notifier)
        .loadLocale(notify: false);

    _prefs = ref.read(prefsChangeNotifierProvider);
    _wallets = ref.read(walletsChangeNotifierProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(colorThemeProvider.state).state =
          StackColors.fromStackColorTheme(
              themeType == ThemeType.dark ? DarkColors() : LightColors());
    });

    super.initState();
  }

  @override
  dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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

    final colorScheme = ref.watch(colorThemeProvider.state).state;

    return MaterialApp(
      key: GlobalKey(),
      navigatorKey: navigatorKey,
      title: 'Stack Wallet',
      onGenerateRoute: RouteGenerator.generateRoute,
      theme: ThemeData(
        extensions: [colorScheme],
        highlightColor: colorScheme.highlight,
        brightness: Brightness.light,
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
      home: FutureBuilder(
        future: load(),
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // FlutterNativeSplash.remove();
            if (!Util.isDesktop && (_wallets.hasWallets || _prefs.hasPin)) {
              // return HomeView();

              String? startupWalletId;
              if (ref.read(prefsChangeNotifierProvider).gotoWalletOnStartup) {
                startupWalletId =
                    ref.read(prefsChangeNotifierProvider).startupWalletId;
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
    );
  }
}
