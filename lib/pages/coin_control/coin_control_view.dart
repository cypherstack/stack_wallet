import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/pages/coin_control/utxo_card.dart';
import 'package:stackwallet/pages/coin_control/utxo_details_view.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/mixins/coin_control_interface.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/app_bar_field.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/toggle.dart';
import 'package:tuple/tuple.dart';

enum CoinControlViewType {
  manage,
  use;
}

class CoinControlView extends ConsumerStatefulWidget {
  const CoinControlView({
    Key? key,
    required this.walletId,
    required this.type,
    this.requestedTotal,
    this.selectedUTXOs,
  }) : super(key: key);

  static const routeName = "/coinControl";

  final String walletId;
  final CoinControlViewType type;
  final int? requestedTotal;
  final Set<UTXO>? selectedUTXOs;

  @override
  ConsumerState<CoinControlView> createState() => _CoinControlViewState();
}

class _CoinControlViewState extends ConsumerState<CoinControlView> {
  final searchController = TextEditingController();
  final searchFocus = FocusNode();

  bool _isSearching = false;
  bool _showBlocked = false;

  CCSortDescriptor _sort = CCSortDescriptor.age;

  final Set<UTXO> _selectedAvailable = {};
  final Set<UTXO> _selectedBlocked = {};

  Future<void> _refreshBalance() async {
    final coinControlInterface = ref
        .read(walletsChangeNotifierProvider)
        .getManager(widget.walletId)
        .wallet as CoinControlInterface;
    await coinControlInterface.refreshBalance(notify: true);
  }

  @override
  void initState() {
    if (widget.selectedUTXOs != null) {
      _selectedAvailable.addAll(widget.selectedUTXOs!);
    }
    searchController.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        setState(() {});
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final coin = ref.watch(
      walletsChangeNotifierProvider.select(
        (value) => value
            .getManager(
              widget.walletId,
            )
            .coin,
      ),
    );

    final currentChainHeight = ref.watch(
      walletsChangeNotifierProvider.select(
        (value) => value
            .getManager(
              widget.walletId,
            )
            .currentHeight,
      ),
    );

    final ids = MainDB.instance.queryUTXOsSync(
      walletId: widget.walletId,
      filter: _isSearching
          ? CCFilter.all
          : _showBlocked
              ? CCFilter.frozen
              : CCFilter.available,
      sort: _sort,
      searchTerm: _isSearching ? searchController.text : "",
      coin: coin,
    );

    return WillPopScope(
      onWillPop: () async {
        unawaited(_refreshBalance());
        Navigator.of(context).pop(
            widget.type == CoinControlViewType.use ? _selectedAvailable : null);
        return false;
      },
      child: Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: _isSearching
                ? null
                : widget.type == CoinControlViewType.use &&
                        _selectedAvailable.isNotEmpty
                    ? AppBarIconButton(
                        icon: XIcon(
                          width: 24,
                          height: 24,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .topNavIconPrimary,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedAvailable.clear();
                          });
                        },
                      )
                    : AppBarBackButton(
                        onPressed: () {
                          unawaited(_refreshBalance());
                          Navigator.of(context).pop(
                              widget.type == CoinControlViewType.use
                                  ? _selectedAvailable
                                  : null);
                        },
                      ),
            title: _isSearching
                ? AppBarSearchField(
                    controller: searchController,
                    focusNode: searchFocus,
                  )
                : Text(
                    "Coin control",
                    style: STextStyles.navBarTitle(context),
                  ),
            titleSpacing: 0,
            actions: _isSearching
                ? [
                    AspectRatio(
                      aspectRatio: 1,
                      child: AppBarIconButton(
                        size: 36,
                        icon: SvgPicture.asset(
                          Assets.svg.x,
                          width: 20,
                          height: 20,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .topNavIconPrimary,
                        ),
                        onPressed: () {
                          // show search
                          setState(() {
                            _isSearching = false;
                          });
                        },
                      ),
                    ),
                  ]
                : [
                    AspectRatio(
                      aspectRatio: 1,
                      child: AppBarIconButton(
                        size: 36,
                        icon: SvgPicture.asset(
                          Assets.svg.search,
                          width: 20,
                          height: 20,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .topNavIconPrimary,
                        ),
                        onPressed: () {
                          // show search
                          setState(() {
                            _isSearching = true;
                          });
                        },
                      ),
                    ),
                    AspectRatio(
                      aspectRatio: 1,
                      child: AppBarIconButton(
                        size: 36,
                        icon: SvgPicture.asset(
                          Assets.svg.verticalEllipsis,
                          width: 20,
                          height: 20,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .topNavIconPrimary,
                        ),
                        onPressed: () {
                          // show search
                          setState(() {
                            _isSearching = true;
                          });
                        },
                      ),
                    ),
                  ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        if (!_isSearching)
                          RoundedWhiteContainer(
                            child: Text(
                              "This option allows you to control, freeze, and utilize "
                              "outputs at your discretion. Tap the output circle to "
                              "select.",
                              style: STextStyles.w500_14(context).copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textSubtitle1,
                              ),
                            ),
                          ),
                        if (!_isSearching)
                          const SizedBox(
                            height: 10,
                          ),
                        if (!_isSearching)
                          SizedBox(
                            height: 48,
                            child: Toggle(
                              key: UniqueKey(),
                              onColor: Theme.of(context)
                                  .extension<StackColors>()!
                                  .popupBG,
                              onText: "Available outputs",
                              offColor: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textFieldDefaultBG,
                              offText: "Frozen outputs",
                              isOn: _showBlocked,
                              onValueChanged: (value) {
                                setState(() {
                                  _showBlocked = value;
                                });
                              },
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  Constants.size.circularBorderRadius,
                                ),
                              ),
                            ),
                          ),
                        if (!_isSearching)
                          const SizedBox(
                            height: 10,
                          ),
                        if (_isSearching)
                          Expanded(
                            child: ListView.separated(
                              itemCount: ids.length,
                              separatorBuilder: (context, _) => const SizedBox(
                                height: 10,
                              ),
                              itemBuilder: (context, index) {
                                final utxo = MainDB.instance.isar.utxos
                                    .where()
                                    .idEqualTo(ids[index])
                                    .findFirstSync()!;

                                final isSelected =
                                    _selectedBlocked.contains(utxo) ||
                                        _selectedAvailable.contains(utxo);

                                return UtxoCard(
                                  key: Key(
                                      "${utxo.walletId}_${utxo.id}_$isSelected"),
                                  walletId: widget.walletId,
                                  utxo: utxo,
                                  canSelect: widget.type ==
                                          CoinControlViewType.manage ||
                                      (widget.type == CoinControlViewType.use &&
                                          !utxo.isBlocked &&
                                          utxo.isConfirmed(
                                            currentChainHeight,
                                            coin.requiredConfirmations,
                                          )),
                                  initialSelectedState: isSelected,
                                  onSelectedChanged: (value) {
                                    if (value) {
                                      utxo.isBlocked
                                          ? _selectedBlocked.add(utxo)
                                          : _selectedAvailable.add(utxo);
                                    } else {
                                      utxo.isBlocked
                                          ? _selectedBlocked.remove(utxo)
                                          : _selectedAvailable.remove(utxo);
                                    }
                                    setState(() {});
                                  },
                                  onPressed: () async {
                                    final result =
                                        await Navigator.of(context).pushNamed(
                                      UtxoDetailsView.routeName,
                                      arguments: Tuple2(
                                        utxo.id,
                                        widget.walletId,
                                      ),
                                    );
                                    if (mounted && result == "refresh") {
                                      setState(() {});
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        if (!_isSearching)
                          Expanded(
                            child: ListView.separated(
                              itemCount: ids.length,
                              separatorBuilder: (context, _) => const SizedBox(
                                height: 10,
                              ),
                              itemBuilder: (context, index) {
                                final utxo = MainDB.instance.isar.utxos
                                    .where()
                                    .idEqualTo(ids[index])
                                    .findFirstSync()!;

                                final isSelected = _showBlocked
                                    ? _selectedBlocked.contains(utxo)
                                    : _selectedAvailable.contains(utxo);

                                return UtxoCard(
                                  key: Key(
                                      "${utxo.walletId}_${utxo.id}_$isSelected"),
                                  walletId: widget.walletId,
                                  utxo: utxo,
                                  canSelect: widget.type ==
                                          CoinControlViewType.manage ||
                                      (widget.type == CoinControlViewType.use &&
                                          !_showBlocked &&
                                          utxo.isConfirmed(
                                            currentChainHeight,
                                            coin.requiredConfirmations,
                                          )),
                                  initialSelectedState: isSelected,
                                  onSelectedChanged: (value) {
                                    if (value) {
                                      _showBlocked
                                          ? _selectedBlocked.add(utxo)
                                          : _selectedAvailable.add(utxo);
                                    } else {
                                      _showBlocked
                                          ? _selectedBlocked.remove(utxo)
                                          : _selectedAvailable.remove(utxo);
                                    }
                                    setState(() {});
                                  },
                                  onPressed: () async {
                                    final result =
                                        await Navigator.of(context).pushNamed(
                                      UtxoDetailsView.routeName,
                                      arguments: Tuple2(
                                        utxo.id,
                                        widget.walletId,
                                      ),
                                    );
                                    if (mounted && result == "refresh") {
                                      setState(() {});
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (((_showBlocked && _selectedBlocked.isNotEmpty) ||
                        (!_showBlocked && _selectedAvailable.isNotEmpty)) &&
                    widget.type == CoinControlViewType.manage)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .backgroundAppBar,
                      boxShadow: [
                        Theme.of(context)
                            .extension<StackColors>()!
                            .standardBoxShadow,
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SecondaryButton(
                        label: _showBlocked ? "Unfreeze" : "Freeze",
                        onPressed: () async {
                          if (_showBlocked) {
                            await MainDB.instance.putUTXOs(_selectedBlocked
                                .map(
                                  (e) => e.copyWith(
                                    isBlocked: false,
                                  ),
                                )
                                .toList());
                            _selectedBlocked.clear();
                          } else {
                            await MainDB.instance.putUTXOs(_selectedAvailable
                                .map(
                                  (e) => e.copyWith(
                                    isBlocked: true,
                                  ),
                                )
                                .toList());
                            _selectedAvailable.clear();
                          }
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                if (!_showBlocked && widget.type == CoinControlViewType.use)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .backgroundAppBar,
                      boxShadow: [
                        Theme.of(context)
                            .extension<StackColors>()!
                            .standardBoxShadow,
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          RoundedWhiteContainer(
                            padding: const EdgeInsets.all(0),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Selected amount",
                                        style: STextStyles.w600_14(context),
                                      ),
                                      Builder(
                                        builder: (context) {
                                          int selectedSum =
                                              _selectedAvailable.isEmpty
                                                  ? 0
                                                  : _selectedAvailable
                                                      .map((e) => e.value)
                                                      .reduce(
                                                        (value, element) =>
                                                            value += element,
                                                      );
                                          return Text(
                                            "${Format.satoshisToAmount(
                                              selectedSum,
                                              coin: coin,
                                            ).toStringAsFixed(
                                              coin.decimals,
                                            )} ${coin.ticker}",
                                            style: widget.requestedTotal == null
                                                ? STextStyles.w600_14(context)
                                                : STextStyles.w600_14(context).copyWith(
                                                    color: selectedSum >=
                                                            widget
                                                                .requestedTotal!
                                                        ? Theme.of(context)
                                                            .extension<
                                                                StackColors>()!
                                                            .accentColorGreen
                                                        : Theme.of(context)
                                                            .extension<
                                                                StackColors>()!
                                                            .accentColorRed),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                if (widget.requestedTotal != null)
                                  Container(
                                    width: double.infinity,
                                    height: 1.5,
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .backgroundAppBar,
                                  ),
                                if (widget.requestedTotal != null)
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Amount to send",
                                          style: STextStyles.w600_14(context),
                                        ),
                                        Text(
                                          "${Format.satoshisToAmount(
                                            widget.requestedTotal!,
                                            coin: coin,
                                          ).toStringAsFixed(
                                            coin.decimals,
                                          )} ${coin.ticker}",
                                          style: STextStyles.w600_14(context),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          PrimaryButton(
                            label: "Use coins",
                            enabled: _selectedAvailable.isNotEmpty,
                            onPressed: () async {
                              if (searchFocus.hasFocus) {
                                searchFocus.unfocus();
                              }
                              Navigator.of(context).pop(
                                _selectedAvailable,
                              );
                            },
                          ),
                        ],
                      ),
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
