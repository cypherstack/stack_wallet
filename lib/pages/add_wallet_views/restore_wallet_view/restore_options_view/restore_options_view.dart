import 'package:epicpay/pages/add_wallet_views/restore_wallet_view/restore_options_view/sub_widgets/restore_from_date_picker.dart';
import 'package:epicpay/pages/add_wallet_views/restore_wallet_view/restore_options_view/sub_widgets/restore_options_platform_layout.dart';
import 'package:epicpay/pages/add_wallet_views/restore_wallet_view/restore_wallet_view.dart';
import 'package:epicpay/pages/add_wallet_views/restore_wallet_view/sub_widgets/mnemonic_word_count_select_sheet.dart';
import 'package:epicpay/providers/ui/color_theme_provider.dart';
import 'package:epicpay/providers/ui/verify_recovery_phrase/mnemonic_word_count_state_provider.dart';
import 'package:epicpay/utilities/constants.dart';
import 'package:epicpay/utilities/enums/coin_enum.dart';
import 'package:epicpay/utilities/format.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/utilities/util.dart';
import 'package:epicpay/widgets/background.dart';
import 'package:epicpay/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicpay/widgets/desktop/primary_button.dart';
import 'package:epicpay/widgets/rounded_white_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:tuple/tuple.dart';

class RestoreOptionsView extends ConsumerStatefulWidget {
  const RestoreOptionsView({
    Key? key,
    required this.walletName,
    required this.coin,
  }) : super(key: key);

  static const routeName = "/restoreOptions";

  final String walletName;
  final Coin coin;

  @override
  ConsumerState<RestoreOptionsView> createState() => _RestoreOptionsViewState();
}

class _RestoreOptionsViewState extends ConsumerState<RestoreOptionsView> {
  late final String walletName;
  late final Coin coin;

  late TextEditingController _dateController;
  late FocusNode textFieldFocusNode;

  final bool _nextEnabled = true;
  DateTime _restoreFromDate = DateTime.fromMillisecondsSinceEpoch(0);
  late final Color baseColor;

  @override
  void initState() {
    baseColor = ref.read(colorThemeProvider.state).state.textSubtitle2;
    walletName = widget.walletName;
    coin = widget.coin;

    _dateController = TextEditingController();
    textFieldFocusNode = FocusNode();

    super.initState();
  }

  @override
  void dispose() {
    _dateController.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  MaterialRoundedDatePickerStyle _buildDatePickerStyle() {
    return MaterialRoundedDatePickerStyle(
      backgroundPicker: Theme.of(context).extension<StackColors>()!.coal,
      // backgroundHeader: Theme.of(context).extension<StackColors>()!.textSubtitle2,
      paddingMonthHeader: const EdgeInsets.only(top: 11),
      colorArrowNext: Theme.of(context).extension<StackColors>()!.textGold,
      colorArrowPrevious: Theme.of(context).extension<StackColors>()!.textGold,
      textStyleButtonNegative: STextStyles.datePicker600(context).copyWith(
        color: Theme.of(context).extension<StackColors>()!.textMedium,
      ),
      textStyleButtonPositive: STextStyles.datePicker600(context).copyWith(
        color: Theme.of(context).extension<StackColors>()!.textGold,
      ),
      textStyleCurrentDayOnCalendar: STextStyles.datePicker400(context),
      textStyleDayHeader: STextStyles.datePicker600(context),
      textStyleDayOnCalendar: STextStyles.datePicker400(context).copyWith(
        color: baseColor,
      ),
      textStyleDayOnCalendarDisabled:
          STextStyles.datePicker400(context).copyWith(
        color: Theme.of(context).extension<StackColors>()!.textDark,
      ),
      textStyleDayOnCalendarSelected:
          STextStyles.datePicker400(context).copyWith(
        color: Theme.of(context).extension<StackColors>()!.coal,
      ),
      textStyleMonthYearHeader: STextStyles.datePicker600(context).copyWith(
        color: Theme.of(context).extension<StackColors>()!.textGold,
      ),
      textStyleYearButton: STextStyles.datePicker600(context).copyWith(
        color: Theme.of(context).extension<StackColors>()!.coal,
      ),
      backgroundHeader: Theme.of(context).extension<StackColors>()!.textGold,
      decorationDateSelected: BoxDecoration(
        color: Theme.of(context).extension<StackColors>()!.textGold,
        shape: BoxShape.circle,
      ),
    );
  }

  MaterialRoundedYearPickerStyle _buildYearPickerStyle() {
    return MaterialRoundedYearPickerStyle(
      backgroundPicker: Theme.of(context).extension<StackColors>()!.coal,
      textStyleYear: STextStyles.datePicker600(context).copyWith(
        color: Theme.of(context).extension<StackColors>()!.textMedium,
        fontSize: 16,
      ),
      textStyleYearSelected: STextStyles.datePicker600(context).copyWith(
        fontSize: 18,
      ),
    );
  }

  Future<void> nextPressed() async {
    // hide keyboard if has focus
    if (FocusScope.of(context).hasFocus) {
      FocusScope.of(context).unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 75));
    }

    if (mounted) {
      await Navigator.of(context).pushNamed(
        RestoreWalletView.routeName,
        arguments: Tuple4(
          walletName,
          coin,
          ref.read(mnemonicWordCountStateProvider.state).state,
          _restoreFromDate,
        ),
      );
    }
  }

  Future<void> chooseDate() async {
    final height = MediaQuery.of(context).size.height;
    final fetchedColor =
        Theme.of(context).extension<StackColors>()!.accentColorDark;
    // check and hide keyboard
    if (FocusScope.of(context).hasFocus) {
      FocusScope.of(context).unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 125));
    }

    final date = await showRoundedDatePicker(
      context: context,
      initialDate: DateTime.now(),
      height: height * 0.5,
      theme: ThemeData(
        primarySwatch: Util.createMaterialColor(fetchedColor),
      ),
      //TODO pick a better initial date
      // 2007 chosen as that is just before bitcoin launched
      firstDate: DateTime(2007),
      lastDate: DateTime.now(),
      borderRadius: Constants.size.circularBorderRadius * 2,

      textPositiveButton: "SELECT",

      styleDatePicker: _buildDatePickerStyle(),
      styleYearPicker: _buildYearPickerStyle(),
    );
    if (date != null) {
      _restoreFromDate = date;
      _dateController.text = Format.formatDate(date);
    }
  }

  Future<void> chooseMnemonicLength() async {
    await showModalBottomSheet<dynamic>(
      backgroundColor: Colors.transparent,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return MnemonicWordCountSelectSheet(
          lengthOptions: Constants.possibleLengthsForCoin(coin),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType with ${coin.name} $walletName");

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              if (textFieldFocusNode.hasFocus) {
                textFieldFocusNode.unfocus();
                Future<void>.delayed(const Duration(milliseconds: 100))
                    .then((value) => Navigator.of(context).pop());
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: RestoreOptionsPlatformLayout(
          isDesktop: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(
                flex: 1,
              ),
              Text(
                "Restore options",
                textAlign: TextAlign.center,
                style: STextStyles.titleH2(context),
              ),
              const SizedBox(
                height: 32,
              ),
              if (coin == Coin.epicCash ||
                  ref.watch(mnemonicWordCountStateProvider.state).state == 25)
                Text(
                  "CHOOSE START DATE",
                  style: STextStyles.bodySmallBold(context).copyWith(
                    color:
                        Theme.of(context).extension<StackColors>()!.textMedium,
                  ),
                  textAlign: TextAlign.left,
                ),
              const SizedBox(
                height: 16,
              ),

              // if (!isDesktop)
              RestoreFromDatePicker(
                onTap: chooseDate,
                controller: _dateController,
              ),

              const SizedBox(
                height: 16,
              ),
              RoundedWhiteContainer(
                child: Center(
                  child: Text(
                    "Choose the date you made the wallet (approximate is fine)",
                    style: STextStyles.smallMed12(context).copyWith(
                      fontSize: 10,
                    ),
                  ),
                ),
              ),

              const Spacer(
                flex: 3,
              ),

              PrimaryButton(
                label: "NEXT",
                enabled: _nextEnabled,
                onPressed: nextPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
