import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/pages_desktop_specific/coin_control/utxo_row.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/themes/coin_icon_provider.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/animated_widgets/rotate_icon.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/dropdown_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/expandable2.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';
import 'package:stackwallet/widgets/toggle.dart';

final desktopUseUTXOs = StateProvider((ref) => <UTXO>{});

class DesktopCoinControlUseDialog extends ConsumerStatefulWidget {
  const DesktopCoinControlUseDialog({
    Key? key,
    required this.walletId,
    this.amountToSend,
  }) : super(key: key);

  final String walletId;
  final Amount? amountToSend;

  @override
  ConsumerState<DesktopCoinControlUseDialog> createState() =>
      _DesktopCoinControlUseDialogState();
}

class _DesktopCoinControlUseDialogState
    extends ConsumerState<DesktopCoinControlUseDialog> {
  late final TextEditingController _searchController;
  late final Coin coin;
  final searchFieldFocusNode = FocusNode();

  final Set<UtxoRowData> _selectedUTXOsData = {};
  final Set<UTXO> _selectedUTXOs = {};

  Map<String, List<Id>>? _map;
  List<Id>? _list;

  String _searchString = "";

  CCFilter _filter = CCFilter.available;
  CCSortDescriptor _sort = CCSortDescriptor.age;

  bool selectedChanged(Set<UTXO> newSelected) {
    if (ref.read(desktopUseUTXOs).length != newSelected.length) return true;
    return !ref.read(desktopUseUTXOs).containsAll(newSelected);
  }

  @override
  void initState() {
    _searchController = TextEditingController();
    coin = ref
        .read(walletsChangeNotifierProvider)
        .getManager(widget.walletId)
        .coin;

    for (final utxo in ref.read(desktopUseUTXOs)) {
      final data = UtxoRowData(utxo.id, true);
      _selectedUTXOs.add(utxo);
      _selectedUTXOsData.add(data);
    }

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

    if (_sort == CCSortDescriptor.address) {
      _list = null;
      _map = MainDB.instance.queryUTXOsGroupedByAddressSync(
        walletId: widget.walletId,
        filter: _filter,
        sort: _sort,
        searchTerm: _searchString,
        coin: coin,
      );
    } else {
      _map = null;
      _list = MainDB.instance.queryUTXOsSync(
        walletId: widget.walletId,
        filter: _filter,
        sort: _sort,
        searchTerm: _searchString,
        coin: coin,
      );
    }

    final Amount selectedSum = _selectedUTXOs.map((e) => e.value).fold(
          Amount(
            rawValue: BigInt.zero,
            fractionDigits: coin.decimals,
          ),
          (value, element) => value += Amount(
            rawValue: BigInt.from(element),
            fractionDigits: coin.decimals,
          ),
        );

    final enableApply = widget.amountToSend == null
        ? selectedChanged(_selectedUTXOs)
        : selectedChanged(_selectedUTXOs) &&
            widget.amountToSend! <= selectedSum;

    return DesktopDialog(
      maxWidth: 700,
      maxHeight: MediaQuery.of(context).size.height - 128,
      child: Column(
        children: [
          Row(
            children: [
              const AppBarBackButton(
                size: 40,
                iconSize: 24,
              ),
              Text(
                "Coin control",
                style: STextStyles.desktopH3(context),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  RoundedContainer(
                    color: Colors.transparent,
                    borderColor: Theme.of(context)
                        .extension<StackColors>()!
                        .textFieldDefaultBG,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "This option allows you to control, freeze, and utilize "
                          "outputs at your discretion.",
                          style:
                              STextStyles.desktopTextExtraExtraSmall(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Row(
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
                            style: STextStyles.desktopTextExtraSmall(context)
                                .copyWith(
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
                        width: 16,
                      ),
                      SizedBox(
                        height: 56,
                        width: 240,
                        child: Toggle(
                          isOn: _filter == CCFilter.frozen,
                          onColor: Theme.of(context)
                              .extension<StackColors>()!
                              .rateTypeToggleDesktopColorOn,
                          offColor: Theme.of(context)
                              .extension<StackColors>()!
                              .rateTypeToggleDesktopColorOff,
                          onIcon: Assets.svg.coinControl.unBlocked,
                          onText: "Available",
                          offIcon: Assets.svg.coinControl.blocked,
                          offText: "Frozen",
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              Constants.size.circularBorderRadius,
                            ),
                          ),
                          onValueChanged: (value) {
                            setState(() {
                              if (value) {
                                _filter = CCFilter.frozen;
                              } else {
                                _filter = CCFilter.available;
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      JDropdownIconButton(
                        redrawOnScreenSizeChanged: true,
                        groupValue: _sort,
                        items: CCSortDescriptor.values.toSet(),
                        onSelectionChanged: (CCSortDescriptor? newValue) {
                          if (newValue != null && newValue != _sort) {
                            setState(() {
                              _sort = newValue;
                            });
                          }
                        },
                        displayPrefix: "Sort by",
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Expanded(
                    child: _list != null
                        ? ListView.separated(
                            shrinkWrap: true,
                            primary: false,
                            itemCount: _list!.length,
                            separatorBuilder: (context, _) => const SizedBox(
                              height: 10,
                            ),
                            itemBuilder: (context, index) {
                              final utxo = MainDB.instance.isar.utxos
                                  .where()
                                  .idEqualTo(_list![index])
                                  .findFirstSync()!;
                              final data = UtxoRowData(utxo.id, false);
                              data.selected = _selectedUTXOsData.contains(data);

                              return UtxoRow(
                                key: Key(
                                    "${utxo.walletId}_${utxo.id}_${utxo.isBlocked}"),
                                data: data,
                                compact: true,
                                walletId: widget.walletId,
                                onSelectionChanged: (value) {
                                  setState(() {
                                    if (data.selected) {
                                      _selectedUTXOsData.add(value);
                                      _selectedUTXOs.add(utxo);
                                    } else {
                                      _selectedUTXOsData.remove(value);
                                      _selectedUTXOs.remove(utxo);
                                    }
                                  });
                                },
                              );
                            },
                          )
                        : ListView.separated(
                            itemCount: _map!.entries.length,
                            separatorBuilder: (context, _) => const SizedBox(
                              height: 10,
                            ),
                            itemBuilder: (context, index) {
                              final entry = _map!.entries.elementAt(index);
                              final _controller = RotateIconController();

                              return Expandable2(
                                border: Theme.of(context)
                                    .extension<StackColors>()!
                                    .backgroundAppBar,
                                background: Theme.of(context)
                                    .extension<StackColors>()!
                                    .popupBG,
                                animationDurationMultiplier:
                                    0.2 * entry.value.length,
                                onExpandWillChange: (state) {
                                  if (state == Expandable2State.expanded) {
                                    _controller.forward?.call();
                                  } else {
                                    _controller.reverse?.call();
                                  }
                                },
                                header: RoundedContainer(
                                  padding: const EdgeInsets.all(20),
                                  color: Colors.transparent,
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                        ref.watch(coinIconProvider(coin)),
                                        width: 24,
                                        height: 24,
                                      ),
                                      const SizedBox(
                                        width: 12,
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          entry.key,
                                          style: STextStyles.w600_14(context),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          "${entry.value.length} "
                                          "output${entry.value.length > 1 ? "s" : ""}",
                                          style: STextStyles
                                              .desktopTextExtraExtraSmall(
                                                  context),
                                        ),
                                      ),
                                      RotateIcon(
                                        animationDurationMultiplier:
                                            0.2 * entry.value.length,
                                        icon: SvgPicture.asset(
                                          Assets.svg.chevronDown,
                                          width: 14,
                                          color: Theme.of(context)
                                              .extension<StackColors>()!
                                              .textSubtitle1,
                                        ),
                                        curve: Curves.easeInOut,
                                        controller: _controller,
                                      ),
                                    ],
                                  ),
                                ),
                                children: entry.value.map(
                                  (id) {
                                    final utxo = MainDB.instance.isar.utxos
                                        .where()
                                        .idEqualTo(id)
                                        .findFirstSync()!;
                                    final data = UtxoRowData(utxo.id, false);
                                    data.selected =
                                        _selectedUTXOsData.contains(data);

                                    return UtxoRow(
                                      key: Key(
                                          "${utxo.walletId}_${utxo.id}_${utxo.isBlocked}"),
                                      data: data,
                                      compact: true,
                                      compactWithBorder: false,
                                      raiseOnSelected: false,
                                      walletId: widget.walletId,
                                      onSelectionChanged: (value) {
                                        setState(() {
                                          if (data.selected) {
                                            _selectedUTXOsData.add(value);
                                            _selectedUTXOs.add(utxo);
                                          } else {
                                            _selectedUTXOsData.remove(value);
                                            _selectedUTXOs.remove(utxo);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ).toList(),
                              );
                            },
                          ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  RoundedContainer(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textFieldDefaultBG,
                    padding: EdgeInsets.zero,
                    child: ConditionalParent(
                      condition: widget.amountToSend != null,
                      builder: (child) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            child,
                            Container(
                              height: 1.2,
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .popupBG,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Amount to send",
                                    style:
                                        STextStyles.desktopTextExtraExtraSmall(
                                                context)
                                            .copyWith(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .textDark,
                                    ),
                                  ),
                                  Text(
                                    "${widget.amountToSend!.decimal.toStringAsFixed(
                                      coin.decimals,
                                    )}"
                                    " ${coin.ticker}",
                                    style:
                                        STextStyles.desktopTextExtraExtraSmall(
                                      context,
                                    ).copyWith(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Selected amount",
                              style: STextStyles.desktopTextExtraExtraSmall(
                                      context)
                                  .copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textDark,
                              ),
                            ),
                            Text(
                              "${selectedSum.decimal.toStringAsFixed(
                                coin.decimals,
                              )} ${coin.ticker}",
                              style: STextStyles.desktopTextExtraExtraSmall(
                                      context)
                                  .copyWith(
                                color: widget.amountToSend == null
                                    ? Theme.of(context)
                                        .extension<StackColors>()!
                                        .textDark
                                    : selectedSum < widget.amountToSend!
                                        ? Theme.of(context)
                                            .extension<StackColors>()!
                                            .accentColorRed
                                        : Theme.of(context)
                                            .extension<StackColors>()!
                                            .accentColorGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          enabled: _selectedUTXOsData.isNotEmpty,
                          buttonHeight: ButtonHeight.l,
                          label: _selectedUTXOsData.isEmpty
                              ? "Clear selection"
                              : "Clear selection (${_selectedUTXOsData.length})",
                          onPressed: () {
                            setState(() {
                              _selectedUTXOsData.clear();
                              _selectedUTXOs.clear();
                            });
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      Expanded(
                        child: PrimaryButton(
                          enabled: enableApply,
                          buttonHeight: ButtonHeight.l,
                          label: "Apply",
                          onPressed: () {
                            ref.read(desktopUseUTXOs.state).state =
                                _selectedUTXOs;

                            Navigator.of(context, rootNavigator: true).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
