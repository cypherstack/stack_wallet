import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/models/add_wallet_list_entity/sub_classes/coin_entity.dart';
import 'package:stackwallet/models/add_wallet_list_entity/sub_classes/eth_token_entity.dart';
import 'package:stackwallet/pages/add_wallet_views/add_token_view/edit_wallet_tokens_view.dart';
import 'package:stackwallet/pages/add_wallet_views/create_or_restore_wallet_view/create_or_restore_wallet_view.dart';
import 'package:stackwallet/pages/add_wallet_views/verify_recovery_phrase_view/verify_recovery_phrase_view.dart';
import 'package:stackwallet/providers/global/wallets_service_provider.dart';
import 'package:stackwallet/services/wallets_service.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/eth_wallet_radio.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/wallet_info_row/wallet_info_row.dart';
import 'package:tuple/tuple.dart';

final newEthWalletTriggerTempUntilHiveCompletelyDeleted =
    StateProvider((ref) => false);

class SelectWalletForTokenView extends ConsumerStatefulWidget {
  const SelectWalletForTokenView({
    Key? key,
    required this.entity,
  }) : super(key: key);

  static const String routeName = "/selectWalletForTokenView";

  final EthTokenEntity entity;

  @override
  ConsumerState<SelectWalletForTokenView> createState() =>
      _SelectWalletForTokenViewState();
}

class _SelectWalletForTokenViewState
    extends ConsumerState<SelectWalletForTokenView> {
  final isDesktop = Util.isDesktop;
  late final List<String> ethWalletIds;
  bool _hasEthWallets = false;

  String? _selectedWalletId;

  void _onContinue() {
    Navigator.of(context).pushNamed(
      EditWalletTokensView.routeName,
      arguments: Tuple2(
        _selectedWalletId!,
        [widget.entity.token.address],
      ),
    );
  }

  void _onAddNewEthWallet() {
    ref.read(createSpecialEthWalletRoutingFlag.notifier).state = true;
    Navigator.of(context).pushNamed(
      CreateOrRestoreWalletView.routeName,
      arguments: CoinEntity(widget.entity.coin),
    );
  }

  late int _cachedWalletCount;

  void _updateWalletsList(Map<String, WalletInfo> walletsData) {
    _cachedWalletCount = walletsData.length;

    walletsData.removeWhere((key, value) => value.coin != widget.entity.coin);
    ethWalletIds.clear();

    _hasEthWallets = walletsData.isNotEmpty;

    // TODO: proper wallet data class instead of this Hive silliness
    for (final walletId in walletsData.values.map((e) => e.walletId).toList()) {
      final walletContracts = DB.instance.get<dynamic>(
            boxName: walletId,
            key: DBKeys.ethTokenContracts,
          ) as List<String>? ??
          [];
      if (!walletContracts.contains(widget.entity.token.address)) {
        ethWalletIds.add(walletId);
      }
    }
  }

  @override
  void initState() {
    ethWalletIds = [];

    final walletsData =
        ref.read(walletsServiceChangeNotifierProvider).fetchWalletsData();
    _updateWalletsList(walletsData);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // dumb hack
    ref.watch(newEthWalletTriggerTempUntilHiveCompletelyDeleted);
    final walletsData =
        ref.read(walletsServiceChangeNotifierProvider).fetchWalletsData();
    if (walletsData.length != _cachedWalletCount) {
      _updateWalletsList(walletsData);
    }

    return WillPopScope(
      onWillPop: () async {
        ref.read(createSpecialEthWalletRoutingFlag.notifier).state = false;
        return true;
      },
      child: ConditionalParent(
        condition: !isDesktop,
        builder: (child) => Background(
          child: Scaffold(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.background,
            appBar: AppBar(
              leading: AppBarBackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: child,
              ),

              // child: LayoutBuilder(
              //   builder: (ctx, constraints) {
              //     return SingleChildScrollView(
              //       child: ConstrainedBox(
              //         constraints:
              //             BoxConstraints(minHeight: constraints.maxHeight),
              //         child: IntrinsicHeight(
              //           child: child,
              //         ),
              //       ),
              //     );
              //   },
              // ),
            ),
          ),
        ),
        child: ConditionalParent(
          condition: isDesktop,
          builder: (child) => DesktopScaffold(
            appBar: const DesktopAppBar(
              isCompactHeight: false,
              leading: AppBarBackButton(),
            ),
            body: SizedBox(
              width: 500,
              child: child,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isDesktop)
                const SizedBox(
                  height: 24,
                ),
              Text(
                "Select Ethereum wallet",
                textAlign: TextAlign.center,
                style: isDesktop
                    ? STextStyles.desktopH2(context)
                    : STextStyles.pageTitleH1(context),
              ),
              SizedBox(
                height: isDesktop ? 16 : 8,
              ),
              Text(
                "You are adding an ETH token.",
                textAlign: TextAlign.center,
                style: isDesktop
                    ? STextStyles.desktopSubtitleH2(context)
                    : STextStyles.subtitle(context),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                "You must choose an Ethereum wallet in order to use ${widget.entity.name}",
                textAlign: TextAlign.center,
                style: isDesktop
                    ? STextStyles.desktopSubtitleH2(context)
                    : STextStyles.subtitle(context),
              ),
              SizedBox(
                height: isDesktop ? 60 : 16,
              ),
              ethWalletIds.isEmpty
                  ? RoundedWhiteContainer(
                      padding: EdgeInsets.all(isDesktop ? 16 : 12),
                      child: Text(
                        _hasEthWallets
                            ? "All current Ethereum wallets already have ${widget.entity.name}"
                            : "You do not have any Ethereum wallets",
                        style: isDesktop
                            ? STextStyles.desktopSubtitleH2(context)
                            : STextStyles.label(context),
                      ),
                    )
                  : ConditionalParent(
                      condition: !isDesktop,
                      builder: (child) => Expanded(
                        child: Column(
                          children: [
                            RoundedWhiteContainer(
                              padding: const EdgeInsets.all(8),
                              child: child,
                            ),
                          ],
                        ),
                      ),
                      child: ListView.separated(
                        itemCount: ethWalletIds.length,
                        shrinkWrap: true,
                        separatorBuilder: (_, __) => SizedBox(
                          height: isDesktop ? 12 : 6,
                        ),
                        itemBuilder: (_, index) {
                          return RoundedContainer(
                            padding: EdgeInsets.all(isDesktop ? 16 : 8),
                            onPressed: () {
                              setState(() {
                                _selectedWalletId = ethWalletIds[index];
                              });
                            },
                            color: isDesktop
                                ? Theme.of(context)
                                    .extension<StackColors>()!
                                    .popupBG
                                : _selectedWalletId == ethWalletIds[index]
                                    ? Theme.of(context)
                                        .extension<StackColors>()!
                                        .highlight
                                    : Colors.transparent,
                            child: isDesktop
                                ? EthWalletRadio(
                                    walletId: ethWalletIds[index],
                                    selectedWalletId: _selectedWalletId,
                                  )
                                : WalletInfoRow(
                                    walletId: ethWalletIds[index],
                                  ),
                          );
                        },
                      ),
                    ),
              if (ethWalletIds.isEmpty || isDesktop)
                const SizedBox(
                  height: 16,
                ),
              if (isDesktop)
                const SizedBox(
                  height: 16,
                ),
              ethWalletIds.isEmpty
                  ? PrimaryButton(
                      label: "Add new Ethereum wallet",
                      onPressed: _onAddNewEthWallet,
                    )
                  : PrimaryButton(
                      label: "Continue",
                      enabled: _selectedWalletId != null,
                      onPressed: _onContinue,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
