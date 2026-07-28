import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications/show_flush_bar.dart';
import '../../pages_desktop_specific/desktop_home_view.dart';
import '../../pages_desktop_specific/my_stack_view/exit_to_my_stack_button.dart';
import '../../providers/db/main_db_provider.dart';
import '../../providers/global/node_service_provider.dart';
import '../../providers/global/prefs_provider.dart';
import '../../providers/global/secure_store_provider.dart';
import '../../providers/global/wallets_provider.dart';
import '../../providers/hardware/hardware_wallet_provider.dart';
import '../../providers/hardware/hardware_wallet_scan_controller.dart';
import '../../wallets/hardware/ledger/ledger_bitcoin_service.dart';
import '../../wallets/hardware/ledger/ledger_usb_adapter.dart';
import '../../wallets/hardware/mock_hardware_wallet_service.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/enums/flush_bar_type.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../../wallets/hardware/hardware_session_state.dart';
import '../../wallets/hardware/hardware_wallet_connection_type.dart';
import '../../wallets/hardware/hardware_wallet_device.dart';
import '../../wallets/hardware/hardware_wallet_device_family.dart';
import '../../wallets/isar/models/wallet_info.dart';
import '../../wallets/wallet/wallet.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_app_bar.dart';
import '../../widgets/desktop/desktop_scaffold.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/rounded_white_container.dart';
import '../home_view/home_view.dart';

class HardwareWalletConnectView extends ConsumerStatefulWidget {
  const HardwareWalletConnectView({
    super.key,
    required this.walletName,
    required this.coin,
  });

  static const routeName = '/hardwareWalletConnect';

  final String walletName;
  final CryptoCurrency coin;

  @override
  ConsumerState<HardwareWalletConnectView> createState() =>
      _HardwareWalletConnectViewState();
}

class _HardwareWalletConnectViewState
    extends ConsumerState<HardwareWalletConnectView> {
  static const Duration _autoScanInterval = Duration(seconds: 5);

  late HardwareWalletScanController _scanController;
  late final bool isDesktop;
  bool _isCreating = false;
  Timer? _autoScanTimer;

  @override
  void initState() {
    super.initState();
    isDesktop = Util.isDesktop;
    _scanController = HardwareWalletScanController(ref);
  }

  @override
  void dispose() {
    _autoScanTimer?.cancel();
    _scanController.dispose();
    super.dispose();
  }

  void _startAutoScan() {
    _autoScanTimer?.cancel();
    _autoScanTimer = Timer.periodic(_autoScanInterval, (_) {
      final state = ref.read(hardwareSessionStateProvider);
      final family = ref.read(selectedHardwareFamilyProvider);
      if (family != null &&
          (state == HardwareSessionState.idle ||
              state == HardwareSessionState.timeout)) {
        _scanController.startScan(family);
      }
    });
  }

  void _stopAutoScan() {
    _autoScanTimer?.cancel();
    _autoScanTimer = null;
  }

  void _onFamilySelected(HardwareWalletDeviceFamily family) {
    if (family == HardwareWalletDeviceFamily.foundation) return;
    ref.read(selectedHardwareFamilyProvider.notifier).state = family;
    _startAutoScan();
    _scanController.startScan(family);
  }

  Future<void> _onScanPressed() async {
    final family = ref.read(selectedHardwareFamilyProvider);
    if (family == null) return;
    _startAutoScan();
    await _scanController.startScan(family);
  }

  void _onCancelPressed() {
    _stopAutoScan();
    _scanController.stopScan();
  }

  Future<void> _onRetryPressed() async {
    await _scanController.refresh();
  }

  Future<void> _onConnectDevice(HardwareWalletDevice device) async {
    _stopAutoScan();
    await _scanController.connectToDevice(device);
  }

  Future<void> _onReconnectPressed() async {
    await _scanController.refresh();
  }

  Future<void> _onContinuePressed() async {
    if (_isCreating) return;

    setState(() => _isCreating = true);

    try {
      final device = ref.read(selectedHardwareDeviceProvider);
      if (device == null) {
        throw Exception('No hardware device selected');
      }

      final useMock = ref
          .read(prefsChangeNotifierProvider)
          .enableMockHardwareAutoSigner;

      String derivationPath = '';
      String xpub = '';
      String masterFingerprint = '';

      if (useMock) {
        final mockService = MockHardwareWalletService(
          signingStateController:
              ref.read(hardwareSessionStateProvider.notifier),
          autoApprove: true,
        );
        const path = "m/84'/0'/0'";
        final accounts = await mockService.getAvailableAccounts(
          device: device,
          derivationPath: path,
        );
        if (accounts.isNotEmpty) {
          derivationPath = accounts.first.derivationPath;
          xpub = accounts.first.xpub;
          masterFingerprint = accounts.first.masterFingerprint;
        }
      } else if (device.family == HardwareWalletDeviceFamily.ledger) {
        final adapter = ref.read(
          hardwareAdapterProvider(HardwareWalletDeviceFamily.ledger),
        );
        if (adapter == null || adapter is! LedgerUsbAdapter) {
          throw Exception('Ledger adapter not available');
        }

        final connection = adapter.ledgerConnection;
        if (connection == null) {
          throw Exception('Ledger not connected');
        }
        final service = LedgerBitcoinService(
          connection: connection,
        );

        // TODO [prio=med]: account discovery. This is hardcoded to the first
        // mainnet Bitcoin BIP84 account (m/84'/0'/0') and does not support
        // other coins, account indices, or testnet (coin type 1').
        const path = "m/84'/0'/0'";

        try {
          final accounts = await service.getAvailableAccounts(
            device: device,
            derivationPath: path,
          );

          if (accounts.isNotEmpty) {
            derivationPath = accounts.first.derivationPath;
            xpub = accounts.first.xpub;
            masterFingerprint = accounts.first.masterFingerprint;
          }
        } catch (e) {
          if (mounted) {
            await showFloatingFlushBar(
              type: FlushBarType.warning,
              message:
                  'Could not retrieve account info from Ledger. '
                  'Make sure the Bitcoin app is open on your device.',
              context: context,
            );
          }
          setState(() => _isCreating = false);
          return;
        }
      }

      final otherDataJson = {
        WalletInfoKeys.isHardwareWalletKey: true,
        WalletInfoKeys.hardwareDeviceFamilyKey: device.family.name,
        WalletInfoKeys.hardwareDeviceModelKey: device.model,
        WalletInfoKeys.hardwareDerivationPathKey: derivationPath,
        WalletInfoKeys.hardwareXpubKey: xpub,
        WalletInfoKeys.hardwareMasterFingerprintKey: masterFingerprint,
      };

      final info = WalletInfo.createNew(
        coin: widget.coin,
        name: widget.walletName,
        otherDataJsonString: jsonEncode(otherDataJson),
      );

      final wallet = await Wallet.create(
        walletInfo: info,
        mainDB: ref.read(mainDBProvider),
        secureStorageInterface: ref.read(secureStoreProvider),
        nodeService: ref.read(nodeServiceChangeNotifierProvider),
        prefs: ref.read(prefsChangeNotifierProvider),
      );

      await wallet.info.setMnemonicVerified(
        isar: ref.read(mainDBProvider).isar,
      );

      ref.read(pWallets).addWallet(wallet);

      if (mounted) {
        if (isDesktop) {
          Navigator.of(
            context,
          ).popUntil(ModalRoute.withName(DesktopHomeView.routeName));
        } else {
          unawaited(
            Navigator.of(context).pushNamedAndRemoveUntil(
              HomeView.routeName,
              (route) => false,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        await showFloatingFlushBar(
          type: FlushBarType.warning,
          message: 'Failed to create hardware wallet: $e',
          context: context,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return DesktopScaffold(
        background: Theme.of(context).extension<StackColors>()!.background,
        appBar: const DesktopAppBar(
          isCompactHeight: false,
          leading: AppBarBackButton(),
          trailing: ExitToMyStackButton(),
        ),
        body: SizedBox(width: 480, child: _content()),
      );
    } else {
      return Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: const AppBarBackButton(),
            title: Text(
              "Connect Hardware Wallet",
              style: STextStyles.navBarTitle(context),
            ),
          ),
          body: SafeArea(
            child: Container(
              color: Theme.of(context).extension<StackColors>()!.background,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(child: _content()),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _content() {
    final sessionState = ref.watch(hardwareSessionStateProvider);
    final selectedFamily = ref.watch(selectedHardwareFamilyProvider);
    final devices = ref.watch(hardwareDevicesProvider);

    return Column(
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.center : CrossAxisAlignment.stretch,
      children: [
        if (isDesktop) const Spacer(flex: 10),
        if (!isDesktop) const SizedBox(height: 4),
        Text(
          "Connect Hardware Wallet",
          textAlign: TextAlign.center,
          style: isDesktop
              ? STextStyles.desktopH2(context)
              : STextStyles.pageTitleH1(context),
        ),
        SizedBox(height: isDesktop ? 16 : 8),
        Text(
          "Select your device type, then scan to connect",
          textAlign: TextAlign.center,
          style: isDesktop
              ? STextStyles.desktopSubtitleH2(context)
              : STextStyles.subtitle(context),
        ),
        SizedBox(height: isDesktop ? 32 : 24),
        _buildFamilySelection(selectedFamily),
        SizedBox(height: isDesktop ? 32 : 24),
        _buildStateContent(
          sessionState,
          selectedFamily,
          devices,
        ),
        if (!isDesktop) const Spacer(),
        const SizedBox(height: 16),
        _buildBottomActions(sessionState, selectedFamily),
        if (isDesktop) const Spacer(flex: 15),
        if (!isDesktop) const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFamilySelection(
    HardwareWalletDeviceFamily? selectedFamily,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: HardwareWalletDeviceFamily.values.map((family) {
        final isSelected = selectedFamily == family;
        final isComingSoon = family == HardwareWalletDeviceFamily.foundation;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Opacity(
            opacity: isComingSoon ? 0.5 : 1.0,
            child: RoundedWhiteContainer(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              borderColor: isSelected
                  ? Theme.of(context)
                      .extension<StackColors>()!
                      .textFieldActiveBG
                  : null,
              onPressed: isComingSoon ? null : () => _onFamilySelected(family),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _familyDisplayName(family),
                    style: isDesktop
                        ? STextStyles.desktopTextMedium(context).copyWith(
                            color: isSelected
                                ? Theme.of(context)
                                    .extension<StackColors>()!
                                    .textDark
                                : Theme.of(context)
                                    .extension<StackColors>()!
                                    .textSubtitle1,
                          )
                        : STextStyles.field(context).copyWith(
                            color: isSelected
                                ? Theme.of(context)
                                    .extension<StackColors>()!
                                    .textDark
                                : Theme.of(context)
                                    .extension<StackColors>()!
                                    .textSubtitle1,
                          ),
                  ),
                  if (isComingSoon) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Coming soon",
                      style: isDesktop
                          ? STextStyles.desktopTextExtraExtraSmall(context)
                          : STextStyles.label(context),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStateContent(
    HardwareSessionState state,
    HardwareWalletDeviceFamily? selectedFamily,
    List<HardwareWalletDevice> devices,
  ) {
    switch (state) {
      case HardwareSessionState.idle:
        return Center(
          child: Text(
            "Connect a device to begin",
            textAlign: TextAlign.center,
            style: isDesktop
                ? STextStyles.desktopSubtitleH2(context)
                : STextStyles.subtitle(context),
          ),
        );
      case HardwareSessionState.scanning:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .accentColorDark,
              ),
              const SizedBox(height: 16),
              Text(
                "Scanning for devices...",
                style: isDesktop
                    ? STextStyles.desktopSubtitleH2(context)
                    : STextStyles.subtitle(context),
              ),
            ],
          ),
        );
      case HardwareSessionState.deviceFound:
        return _buildDeviceList(devices);
      case HardwareSessionState.connecting:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .accentColorDark,
              ),
              const SizedBox(height: 16),
              Text(
                "Connecting to device...",
                style: isDesktop
                    ? STextStyles.desktopSubtitleH2(context)
                    : STextStyles.subtitle(context),
              ),
            ],
          ),
        );
      case HardwareSessionState.connected:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .accentColorGreen,
                size: isDesktop ? 48 : 40,
              ),
              const SizedBox(height: 16),
              Text(
                "Device connected",
                style: isDesktop
                    ? STextStyles.desktopH3(context)
                    : STextStyles.pageTitleH2(context),
              ),
              const SizedBox(height: 8),
              Text(
                "Tap continue to set up your wallet",
                textAlign: TextAlign.center,
                style: isDesktop
                    ? STextStyles.desktopSubtitleH2(context)
                    : STextStyles.subtitle(context),
              ),
            ],
          ),
        );
      case HardwareSessionState.timeout:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "No devices found",
                style: isDesktop
                    ? STextStyles.desktopH3(context)
                    : STextStyles.pageTitleH2(context),
              ),
              const SizedBox(height: 8),
              Text(
                "Check that your device is unlocked and connected via USB",
                textAlign: TextAlign.center,
                style: isDesktop
                    ? STextStyles.desktopSubtitleH2(context)
                    : STextStyles.subtitle(context),
              ),
            ],
          ),
        );
      case HardwareSessionState.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Connection error",
                style: isDesktop
                    ? STextStyles.desktopH3(context)
                    : STextStyles.pageTitleH2(context),
              ),
              const SizedBox(height: 8),
              Text(
                _errorHelpText(selectedFamily),
                textAlign: TextAlign.center,
                style: isDesktop
                    ? STextStyles.desktopSubtitleH2(context)
                    : STextStyles.subtitle(context),
              ),
            ],
          ),
        );
      case HardwareSessionState.disconnected:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Device disconnected",
                style: isDesktop
                    ? STextStyles.desktopH3(context)
                    : STextStyles.pageTitleH2(context),
              ),
              const SizedBox(height: 8),
              Text(
                "Reconnect your device to continue",
                textAlign: TextAlign.center,
                style: isDesktop
                    ? STextStyles.desktopSubtitleH2(context)
                    : STextStyles.subtitle(context),
              ),
            ],
          ),
        );
      case HardwareSessionState.approvalPending:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .accentColorDark,
              ),
              const SizedBox(height: 16),
              Text(
                "Waiting for approval on device...",
                style: isDesktop
                    ? STextStyles.desktopSubtitleH2(context)
                    : STextStyles.subtitle(context),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildDeviceList(List<HardwareWalletDevice> devices) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: devices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final device = devices[index];
        return RoundedWhiteContainer(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: isDesktop
                          ? STextStyles.desktopTextMedium(context)
                          : STextStyles.itemSubtitle12(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${device.model} - ${device.connectionType == HardwareWalletConnectionType.usb ? 'USB' : 'BLE'}',
                      style: isDesktop
                          ? STextStyles.desktopTextExtraSmall(context)
                          : STextStyles.label(context),
                    ),
                  ],
                ),
              ),
              PrimaryButton(
                width: isDesktop ? 120 : 100,
                label: "Connect",
                onPressed: () => _onConnectDevice(device),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomActions(
    HardwareSessionState state,
    HardwareWalletDeviceFamily? selectedFamily,
  ) {
    switch (state) {
      case HardwareSessionState.idle:
        return PrimaryButton(
          label: "Scan for devices",
          enabled: selectedFamily != null,
          onPressed: selectedFamily != null ? _onScanPressed : null,
        );
      case HardwareSessionState.scanning:
        return SecondaryButton(
          label: "Cancel",
          onPressed: _onCancelPressed,
        );
      case HardwareSessionState.deviceFound:
        return SecondaryButton(
          label: "Refresh",
          onPressed: _onRetryPressed,
        );
      case HardwareSessionState.connecting:
      case HardwareSessionState.approvalPending:
        return const SizedBox.shrink();
      case HardwareSessionState.connected:
        return PrimaryButton(
          label: _isCreating ? "Creating wallet..." : "Continue",
          enabled: !_isCreating,
          onPressed: _isCreating ? null : _onContinuePressed,
        );
      case HardwareSessionState.timeout:
      case HardwareSessionState.error:
        return PrimaryButton(
          label: "Retry",
          onPressed: _onRetryPressed,
        );
      case HardwareSessionState.disconnected:
        return PrimaryButton(
          label: "Reconnect",
          onPressed: _onReconnectPressed,
        );
    }
  }

  String _familyDisplayName(HardwareWalletDeviceFamily family) {
    switch (family) {
      case HardwareWalletDeviceFamily.ledger:
        return "Ledger";
      case HardwareWalletDeviceFamily.trezor:
        return "Trezor";
      case HardwareWalletDeviceFamily.foundation:
        return "Foundation";
    }
  }

  String _errorHelpText(HardwareWalletDeviceFamily? family) {
    switch (family) {
      case HardwareWalletDeviceFamily.ledger:
        return "Make sure your Ledger is unlocked and the Bitcoin app is open";
      case HardwareWalletDeviceFamily.trezor:
        return "Trezor support is not yet available";
      case HardwareWalletDeviceFamily.foundation:
        return "Foundation support is coming soon";
      case null:
        return "An unexpected error occurred";
    }
  }
}
