import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/restore_options_view/sub_widgets/mobile_mnemonic_length_selector.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/restore_options_view/sub_widgets/restore_from_date_picker.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/restore_options_view/sub_widgets/restore_options_next_button.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/restore_options_view/sub_widgets/restore_options_platform_layout.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/restore_wallet_view.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/sub_widgets/mnemonic_word_count_select_sheet.dart';
import 'package:stackwallet/pages_desktop_specific/home/my_stack_view/exit_to_my_stack_button.dart';
import 'package:stackwallet/providers/ui/color_theme_provider.dart';
import 'package:stackwallet/providers/ui/verify_recovery_phrase/mnemonic_word_count_state_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
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
  late final bool isDesktop;

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
    isDesktop = Util.isDesktop;

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
      paddingMonthHeader: const EdgeInsets.only(top: 11),
      colorArrowNext: Theme.of(context).extension<StackColors>()!.textSubtitle1,
      colorArrowPrevious:
          Theme.of(context).extension<StackColors>()!.textSubtitle1,
      textStyleButtonNegative: STextStyles.datePicker600(context).copyWith(
        color: baseColor,
      ),
      textStyleButtonPositive: STextStyles.datePicker600(context).copyWith(
        color: baseColor,
      ),
      textStyleCurrentDayOnCalendar: STextStyles.datePicker400(context),
      textStyleDayHeader: STextStyles.datePicker600(context),
      textStyleDayOnCalendar: STextStyles.datePicker400(context).copyWith(
        color: baseColor,
      ),
      textStyleDayOnCalendarDisabled:
          STextStyles.datePicker400(context).copyWith(
        color: Theme.of(context).extension<StackColors>()!.textSubtitle3,
      ),
      textStyleDayOnCalendarSelected:
          STextStyles.datePicker400(context).copyWith(
        color: Theme.of(context).extension<StackColors>()!.popupBG,
      ),
      textStyleMonthYearHeader: STextStyles.datePicker600(context).copyWith(
        color: Theme.of(context).extension<StackColors>()!.textSubtitle1,
      ),
      textStyleYearButton: STextStyles.datePicker600(context).copyWith(
        color: Theme.of(context).extension<StackColors>()!.textWhite,
      ),
      textStyleButtonAction: GoogleFonts.inter(),
    );
  }

  MaterialRoundedYearPickerStyle _buildYearPickerStyle() {
    return MaterialRoundedYearPickerStyle(
      textStyleYear: STextStyles.datePicker600(context).copyWith(
        color: Theme.of(context).extension<StackColors>()!.textSubtitle2,
      ),
      textStyleYearSelected: STextStyles.datePicker600(context).copyWith(
        fontSize: 18,
      ),
    );
  }

  Future<void> nextPressed() async {
    if (!isDesktop) {
      // hide keyboard if has focus
      if (FocusScope.of(context).hasFocus) {
        FocusScope.of(context).unfocus();
        await Future<void>.delayed(const Duration(milliseconds: 75));
      }
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

    final lengths = Constants.possibleLengthsForCoin(coin).toList();

    return MasterScaffold(
      isDesktop: isDesktop,
      appBar: isDesktop
          ? const DesktopAppBar(
              isCompactHeight: false,
              leading: AppBarBackButton(),
              trailing: ExitToMyStackButton(),
            )
          : AppBar(
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
        isDesktop: isDesktop,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 480 : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Spacer(
                flex: isDesktop ? 10 : 1,
              ),
              if (!isDesktop)
                Image(
                  image: AssetImage(
                    Assets.png.imageFor(coin: coin),
                  ),
                  height: 100,
                ),
              SizedBox(
                height: isDesktop ? 0 : 16,
              ),
              Text(
                "Restore options",
                textAlign: TextAlign.center,
                style: isDesktop
                    ? STextStyles.desktopH2(context)
                    : STextStyles.pageTitleH1(context),
              ),
              SizedBox(
                height: isDesktop ? 40 : 24,
              ),
              if (coin == Coin.monero || coin == Coin.moneroTestNet || coin == Coin.moneroStageNet || coin == Coin.epicCash)
                Text(
                  "Choose start date",
                  style: isDesktop
                      ? STextStyles.desktopTextExtraSmall(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textDark3,
                        )
                      : STextStyles.smallMed12(context),
                  textAlign: TextAlign.left,
                ),
              if (coin == Coin.monero || coin == Coin.moneroTestNet || coin == Coin.moneroStageNet || coin == Coin.epicCash)
                SizedBox(
                  height: isDesktop ? 16 : 8,
                ),
              if (coin == Coin.monero || coin == Coin.moneroTestNet || coin == Coin.moneroStageNet || coin == Coin.epicCash)

                // if (!isDesktop)
                RestoreFromDatePicker(
                  onTap: chooseDate,
                  controller: _dateController,
                ),

              // if (isDesktop)
              //   // TODO desktop date picker
              if (coin == Coin.monero || coin == Coin.moneroTestNet || coin == Coin.moneroStageNet || coin == Coin.epicCash)
                const SizedBox(
                  height: 8,
                ),
              if (coin == Coin.monero || coin == Coin.moneroTestNet || coin == Coin.moneroStageNet || coin == Coin.epicCash)
                RoundedWhiteContainer(
                  child: Center(
                    child: Text(
                      "Choose the date you made the wallet (approximate is fine)",
                      style: isDesktop
                          ? STextStyles.desktopTextExtraSmall(context).copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textSubtitle1,
                            )
                          : STextStyles.smallMed12(context).copyWith(
                              fontSize: 10,
                            ),
                    ),
                  ),
                ),
              if (coin == Coin.monero || coin == Coin.moneroTestNet || coin == Coin.moneroStageNet || coin == Coin.epicCash)
                SizedBox(
                  height: isDesktop ? 24 : 16,
                ),
              Text(
                "Choose recovery phrase length",
                style: isDesktop
                    ? STextStyles.desktopTextExtraSmall(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textDark3,
                      )
                    : STextStyles.smallMed12(context),
                textAlign: TextAlign.left,
              ),
              SizedBox(
                height: isDesktop ? 16 : 8,
              ),
              if (isDesktop)
                DropdownButtonHideUnderline(
                  child: DropdownButton2<int>(
                    value:
                        ref.watch(mnemonicWordCountStateProvider.state).state,
                    items: [
                      ...lengths.map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            "$e words",
                            style: STextStyles.desktopTextMedium(context),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value is int) {
                        ref.read(mnemonicWordCountStateProvider.state).state =
                            value;
                      }
                    },
                    isExpanded: true,
                    icon: SvgPicture.asset(
                      Assets.svg.chevronDown,
                      width: 12,
                      height: 6,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textFieldActiveSearchIconRight,
                    ),
                    buttonPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    buttonDecoration: BoxDecoration(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textFieldDefaultBG,
                      borderRadius: BorderRadius.circular(
                        Constants.size.circularBorderRadius,
                      ),
                    ),
                    dropdownDecoration: BoxDecoration(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textFieldDefaultBG,
                      borderRadius: BorderRadius.circular(
                        Constants.size.circularBorderRadius,
                      ),
                    ),
                  ),
                ),
              if (!isDesktop)
                MobileMnemonicLengthSelector(
                  chooseMnemonicLength: chooseMnemonicLength,
                ),
              if (!isDesktop)
                const Spacer(
                  flex: 3,
                ),
              if (isDesktop)
                const SizedBox(
                  height: 32,
                ),
              RestoreOptionsNextButton(
                isDesktop: isDesktop,
                onPressed: _nextEnabled ? nextPressed : null,
              ),

              if (isDesktop)
                const Spacer(
                  flex: 15,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
