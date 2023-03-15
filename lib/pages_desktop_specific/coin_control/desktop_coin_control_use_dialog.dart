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
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';
import 'package:stackwallet/widgets/toggle.dart';

final desktopUseUTXOs = StateProvider.autoDispose((ref) => <UTXO>{});

class DesktopCoinControlUseDialog extends ConsumerStatefulWidget {
  const DesktopCoinControlUseDialog({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  @override
  ConsumerState<DesktopCoinControlUseDialog> createState() =>
      _DesktopCoinControlUseDialogState();
}

class _DesktopCoinControlUseDialogState
    extends ConsumerState<DesktopCoinControlUseDialog> {
  late final TextEditingController _searchController;
  late final Coin coin;
  final searchFieldFocusNode = FocusNode();

  final Set<UtxoRowData> _selectedUTXOs = {};

  String _searchString = "";

  CCFilter _filter = CCFilter.available;
  CCSortDescriptor _sort = CCSortDescriptor.age;

  @override
  void initState() {
    _searchController = TextEditingController();
    coin = ref
        .read(walletsChangeNotifierProvider)
        .getManager(widget.walletId)
        .coin;
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
    final ids = MainDB.instance.queryUTXOsSync(
      walletId: widget.walletId,
      filter: _filter,
      sort: _sort,
      searchTerm: _searchString,
      coin: coin,
    );

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
                      SizedBox(
                        height: 56,
                        width: 56,
                        child: TextButton(
                          style: Theme.of(context)
                              .extension<StackColors>()!
                              .getSecondaryEnabledButtonStyle(context)
                              ?.copyWith(
                                shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .buttonBackBorderSecondary,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      Constants.size.circularBorderRadius,
                                    ),
                                  ),
                                ),
                              ),
                          onPressed: () {},
                          child: SvgPicture.asset(
                            Assets.svg.list,
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      primary: false,
                      itemCount: ids.length,
                      separatorBuilder: (context, _) => const SizedBox(
                        height: 10,
                      ),
                      itemBuilder: (context, index) {
                        final utxo = MainDB.instance.isar.utxos
                            .where()
                            .idEqualTo(ids[index])
                            .findFirstSync()!;
                        final data = UtxoRowData(utxo.id, false);
                        data.selected = _selectedUTXOs.contains(data);

                        return UtxoRow(
                          key: Key(
                              "${utxo.walletId}_${utxo.id}_${utxo.isBlocked}"),
                          data: data,
                          compact: true,
                          walletId: widget.walletId,
                          onSelectionChanged: (value) {
                            setState(() {
                              if (data.selected) {
                                _selectedUTXOs.add(value);
                              } else {
                                _selectedUTXOs.remove(value);
                              }
                            });
                          },
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
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Selected amount",
                          style: STextStyles.desktopTextExtraExtraSmall(context)
                              .copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark,
                          ),
                        ),
                        Text(
                          "LOL",
                          style: STextStyles.desktopTextExtraExtraSmall(context)
                              .copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark,
                          ),
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
                        child: SecondaryButton(
                          enabled: _selectedUTXOs.isNotEmpty,
                          buttonHeight: ButtonHeight.l,
                          label: _selectedUTXOs.isEmpty
                              ? "Clear selection"
                              : "Clear selection (${_selectedUTXOs.length})",
                          onPressed: () => setState(() {
                            _selectedUTXOs.clear();
                          }),
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      Expanded(
                        child: PrimaryButton(
                          enabled: _selectedUTXOs.isNotEmpty,
                          buttonHeight: ButtonHeight.l,
                          label: "Use coins",
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
