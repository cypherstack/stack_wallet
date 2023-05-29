import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/advanced_views/manage_coin_units/choose_unit_sheet.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class EditCoinUnitsView extends ConsumerStatefulWidget {
  const EditCoinUnitsView({
    Key? key,
    required this.coin,
  }) : super(key: key);

  final Coin coin;

  static const String routeName = "/editCoinUnitsView";

  @override
  ConsumerState<EditCoinUnitsView> createState() => _EditCoinUnitsViewState();
}

class _EditCoinUnitsViewState extends ConsumerState<EditCoinUnitsView> {
  late final TextEditingController _decimalsController;
  late final FocusNode _decimalsFocusNode;

  late AmountUnit _currentUnit;

  void onSave() {
    final maxDecimals = int.tryParse(_decimalsController.text);

    if (maxDecimals == null) {
      // TODO show dialog error thing
      return;
    }

    ref.read(prefsChangeNotifierProvider).updateAmountUnit(
          coin: widget.coin,
          amountUnit: _currentUnit,
        );
    ref.read(prefsChangeNotifierProvider).updateMaxDecimals(
          coin: widget.coin,
          maxDecimals: maxDecimals,
        );

    Navigator.of(context).pop();
  }

  Future<void> chooseUnit() async {
    final chosenUnit = await showModalBottomSheet<AmountUnit?>(
      backgroundColor: Colors.transparent,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return ChooseUnitSheet(
          coin: widget.coin,
        );
      },
    );

    if (chosenUnit != null) {
      setState(() {
        _currentUnit = chosenUnit;
      });
    }
  }

  @override
  void initState() {
    _decimalsFocusNode = FocusNode();
    _decimalsController = TextEditingController()
      ..text = ref.read(pMaxDecimals(widget.coin)).toString();
    _currentUnit = ref.read(pAmountUnit(widget.coin));
    super.initState();
  }

  @override
  void dispose() {
    _decimalsFocusNode.dispose();
    _decimalsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: Util.isDesktop,
      builder: (child) => DesktopDialog(
          child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Edit ${widget.coin.prettyName} Units",
                style: STextStyles.desktopH3(context),
              ),
              const DesktopDialogCloseButton(),
            ],
          )
        ],
      )),
      child: ConditionalParent(
        condition: !Util.isDesktop,
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
              title: Text(
                "Edit ${widget.coin.prettyName} units",
                style: STextStyles.navBarTitle(context),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                TextField(
                  autocorrect: Util.isDesktop ? false : true,
                  enableSuggestions: Util.isDesktop ? false : true,
                  // controller: _lengthController,
                  readOnly: true,
                  textInputAction: TextInputAction.none,
                ),
                Positioned.fill(
                  child: RawMaterialButton(
                    splashColor:
                        Theme.of(context).extension<StackColors>()!.highlight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Constants.size.circularBorderRadius,
                      ),
                    ),
                    onPressed: chooseUnit,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 17,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _currentUnit.unitForCoin(widget.coin),
                            style: STextStyles.itemSubtitle12(context),
                          ),
                          SvgPicture.asset(
                            Assets.svg.chevronDown,
                            width: 14,
                            height: 6,
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textFieldActiveSearchIconRight,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 8,
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius,
              ),
              child: TextField(
                autocorrect: Util.isDesktop ? false : true,
                enableSuggestions: Util.isDesktop ? false : true,
                key: const Key("addCustomNodeNodeNameFieldKey"),
                controller: _decimalsController,
                focusNode: _decimalsFocusNode,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: false,
                  decimal: false,
                ),
                style: STextStyles.field(context),
                decoration: standardInputDecoration(
                  "Maximum precision",
                  _decimalsFocusNode,
                  context,
                ).copyWith(
                  suffixIcon: _decimalsController.text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(right: 0),
                          child: UnconstrainedBox(
                            child: Row(
                              children: [
                                TextFieldIconButton(
                                  child: const XIcon(),
                                  onTap: () async {
                                    _decimalsController.text = "";
                                    setState(() {});
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
            const SizedBox(
              height: 24,
            ),
            if (!Util.isDesktop) const Spacer(),
            PrimaryButton(
              label: "Save",
              buttonHeight: ButtonHeight.xl,
              onPressed: onSave,
            ),
          ],
        ),
      ),
    );
  }
}
