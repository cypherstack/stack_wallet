import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/pages_desktop_specific/coin_control/utxo_row.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

enum CCFilter {
  frozen,
  available,
  all;
}

enum CCSortDescriptor {
  address,
  age,
  value;
}

class DesktopCoinControlView extends ConsumerStatefulWidget {
  const DesktopCoinControlView({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  static const String routeName = "/desktopCoinControl";

  final String walletId;

  @override
  ConsumerState<DesktopCoinControlView> createState() =>
      _DesktopCoinControlViewState();
}

class _DesktopCoinControlViewState
    extends ConsumerState<DesktopCoinControlView> {
  late final TextEditingController _searchController;
  final searchFieldFocusNode = FocusNode();

  String _searchString = "";
  CCFilter _filter = CCFilter.all;
  CCSortDescriptor _sort = CCSortDescriptor.age;

  @override
  void initState() {
    _searchController = TextEditingController();

    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    searchFieldFocusNode.dispose();
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

    final ids = MainDB.instance
        .getUTXOs(widget.walletId)
        .filter()
        .group((q) {
          final qq = q.group(
            (q) => q.usedIsNull().or().usedEqualTo(false),
          );
          switch (_filter) {
            case CCFilter.frozen:
              return qq.and().isBlockedEqualTo(true);
            case CCFilter.available:
              return qq.and().isBlockedEqualTo(false);
            case CCFilter.all:
              return qq;
          }
        })
        .idProperty()
        .findAllSync();

    return DesktopScaffold(
      appBar: DesktopAppBar(
        background: Theme.of(context).extension<StackColors>()!.popupBG,
        leading: Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                width: 32,
              ),
              AppBarIconButton(
                size: 32,
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldDefaultBG,
                shadows: const [],
                icon: SvgPicture.asset(
                  Assets.svg.arrowLeft,
                  width: 18,
                  height: 18,
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .topNavIconPrimary,
                ),
                onPressed: Navigator.of(context).pop,
              ),
              const SizedBox(
                width: 18,
              ),
              SvgPicture.asset(
                Assets.svg.coinControl.gamePad,
                width: 32,
                height: 32,
                color:
                    Theme.of(context).extension<StackColors>()!.textSubtitle1,
              ),
              const SizedBox(
                width: 12,
              ),
              Text(
                "Coin control",
                style: STextStyles.desktopH3(context),
              ),
            ],
          ),
        ),
        useSpacers: false,
        isCompactHeight: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                    child: TextField(
                      autocorrect: false,
                      enableSuggestions: false,
                      controller: _searchController,
                      focusNode: searchFieldFocusNode,
                      onChanged: (value) {
                        setState(() {
                          _searchString = value;
                        });
                      },
                      style:
                          STextStyles.desktopTextExtraSmall(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textFieldActiveText,
                        height: 1.8,
                      ),
                      decoration: standardInputDecoration(
                        "Search...",
                        searchFieldFocusNode,
                        context,
                        desktopMed: true,
                      ).copyWith(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 18,
                          ),
                          child: SvgPicture.asset(
                            Assets.svg.search,
                            width: 20,
                            height: 20,
                          ),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(right: 0),
                                child: UnconstrainedBox(
                                  child: Row(
                                    children: [
                                      TextFieldIconButton(
                                        child: const XIcon(),
                                        onTap: () async {
                                          setState(() {
                                            _searchController.text = "";
                                            _searchString = "";
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 24,
                ),
                SecondaryButton(
                  buttonHeight: ButtonHeight.l,
                  width: 200,
                  label: "Show all outputs",
                  onPressed: () {
                    //
                  },
                ),
                const SizedBox(
                  width: 24,
                ),
                SecondaryButton(
                  buttonHeight: ButtonHeight.l,
                  width: 200,
                  label: "Sort by",
                  onPressed: () {
                    //
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
              ),
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

                  // final isSelected = _showBlocked
                  //     ? _selectedBlocked.contains(utxo)
                  //     : _selectedAvailable.contains(utxo);

                  return UtxoRow(
                    key: Key("${utxo.walletId}_${utxo.id}_${utxo.isBlocked}"),
                    utxo: utxo,
                    walletId: widget.walletId,
                    onSelectedChanged: (value) {
                      // if (value) {
                      //   _showBlocked
                      //       ? _selectedBlocked.add(utxo)
                      //       : _selectedAvailable.add(utxo);
                      // } else {
                      //   _showBlocked
                      //       ? _selectedBlocked.remove(utxo)
                      //       : _selectedAvailable.remove(utxo);
                      // }
                      // setState(() {});
                    },
                    initialSelectedState: false,
                  );

                  // return UtxoCard(
                  //   key: Key("${utxo.walletId}_${utxo.id}_$isSelected"),
                  //   walletId: widget.walletId,
                  //   utxo: utxo,
                  //   canSelect: widget.type == CoinControlViewType.manage ||
                  //       (widget.type == CoinControlViewType.use &&
                  //           !_showBlocked &&
                  //           utxo.isConfirmed(
                  //             currentChainHeight,
                  //             coin.requiredConfirmations,
                  //           )),
                  //   initialSelectedState: isSelected,
                  //   onSelectedChanged: (value) {
                  //     if (value) {
                  //       _showBlocked
                  //           ? _selectedBlocked.add(utxo)
                  //           : _selectedAvailable.add(utxo);
                  //     } else {
                  //       _showBlocked
                  //           ? _selectedBlocked.remove(utxo)
                  //           : _selectedAvailable.remove(utxo);
                  //     }
                  //     setState(() {});
                  //   },
                  //   onPressed: () async {
                  //     final result = await Navigator.of(context).pushNamed(
                  //       UtxoDetailsView.routeName,
                  //       arguments: Tuple2(
                  //         utxo.id,
                  //         widget.walletId,
                  //       ),
                  //     );
                  //     if (mounted && result == "refresh") {
                  //       setState(() {});
                  //     }
                  //   },
                  // );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
