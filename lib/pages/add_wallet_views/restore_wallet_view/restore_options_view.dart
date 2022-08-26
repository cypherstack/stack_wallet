import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/restore_wallet_view.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/sub_widgets/mnemonic_word_count_select_sheet.dart';
import 'package:stackwallet/providers/ui/verify_recovery_phrase/mnemonic_word_count_state_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
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

  late TextEditingController _dateController;
  late TextEditingController _lengthController;
  late FocusNode textFieldFocusNode;

  final bool _nextEnabled = true;
  DateTime _restoreFromDate = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    walletName = widget.walletName;
    coin = widget.coin;

    _dateController = TextEditingController();
    _lengthController = TextEditingController();
    textFieldFocusNode = FocusNode();

    super.initState();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _lengthController.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  final _datePickerTextStyleBase = GoogleFonts.inter(
    color: CFColors.gray3,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );
  MaterialRoundedDatePickerStyle _buildDatePickerStyle() {
    return MaterialRoundedDatePickerStyle(
      paddingMonthHeader: const EdgeInsets.only(top: 11),
      colorArrowNext: CFColors.neutral60,
      colorArrowPrevious: CFColors.neutral60,
      textStyleButtonNegative: _datePickerTextStyleBase.copyWith(
          fontSize: 16, fontWeight: FontWeight.w600),
      textStyleButtonPositive: _datePickerTextStyleBase.copyWith(
          fontSize: 16, fontWeight: FontWeight.w600),
      textStyleCurrentDayOnCalendar: _datePickerTextStyleBase.copyWith(
        color: CFColors.stackAccent,
      ),
      textStyleDayHeader: _datePickerTextStyleBase.copyWith(
        color: CFColors.stackAccent,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      textStyleDayOnCalendar: _datePickerTextStyleBase,
      textStyleDayOnCalendarDisabled: _datePickerTextStyleBase.copyWith(
        color: CFColors.neutral80,
      ),
      textStyleDayOnCalendarSelected: _datePickerTextStyleBase.copyWith(
        color: CFColors.white,
      ),
      textStyleMonthYearHeader: _datePickerTextStyleBase.copyWith(
        color: CFColors.neutral60,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      textStyleYearButton: _datePickerTextStyleBase.copyWith(
        color: CFColors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      textStyleButtonAction: GoogleFonts.inter(),
    );
  }

  MaterialRoundedYearPickerStyle _buildYearPickerStyle() {
    return MaterialRoundedYearPickerStyle(
      textStyleYear: _datePickerTextStyleBase.copyWith(
        color: CFColors.gray3,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      textStyleYearSelected: _datePickerTextStyleBase.copyWith(
        color: CFColors.stackAccent,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType with ${coin.name} $walletName");

    return Scaffold(
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
      body: Container(
        color: CFColors.almostWhite,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(
                          flex: 1,
                        ),
                        Image(
                          image: AssetImage(
                            Assets.png.imageFor(coin: coin),
                          ),
                          height: 100,
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Text(
                          "Restore options",
                          textAlign: TextAlign.center,
                          style: STextStyles.pageTitleH1,
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        if (coin == Coin.monero || coin == Coin.epicCash)
                          Text(
                            "Choose start date",
                            style: STextStyles.smallMed12,
                            textAlign: TextAlign.left,
                          ),
                        if (coin == Coin.monero || coin == Coin.epicCash)
                          const SizedBox(
                            height: 8,
                          ),
                        if (coin == Coin.monero || coin == Coin.epicCash)
                          Container(
                            color: Colors.transparent,
                            child: TextField(
                              onTap: () async {
                                final height =
                                    MediaQuery.of(context).size.height;
                                // check and hide keyboard
                                if (FocusScope.of(context).hasFocus) {
                                  FocusScope.of(context).unfocus();
                                  await Future<void>.delayed(
                                      const Duration(milliseconds: 125));
                                }

                                final date = await showRoundedDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  height: height * 0.5,
                                  theme: ThemeData(
                                    primarySwatch: CFColors.createMaterialColor(
                                        CFColors.stackAccent),
                                  ),
                                  //TODO pick a better initial date
                                  // 2007 chosen as that is just before bitcoin launched
                                  firstDate: DateTime(2007),
                                  lastDate: DateTime.now(),
                                  borderRadius:
                                      Constants.size.circularBorderRadius * 2,

                                  textPositiveButton: "SELECT",

                                  styleDatePicker: _buildDatePickerStyle(),
                                  styleYearPicker: _buildYearPickerStyle(),
                                );
                                if (date != null) {
                                  _restoreFromDate = date;
                                  _dateController.text =
                                      Format.formatDate(date);
                                }
                              },
                              controller: _dateController,
                              style: STextStyles.field,
                              decoration: InputDecoration(
                                hintText: "Restore from...",
                                suffixIcon: UnconstrainedBox(
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                        width: 16,
                                      ),
                                      SvgPicture.asset(
                                        Assets.svg.calendar,
                                        color: CFColors.neutral50,
                                        width: 16,
                                        height: 16,
                                      ),
                                      const SizedBox(
                                        width: 12,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              key: const Key("restoreOptionsViewDatePickerKey"),
                              readOnly: true,
                              toolbarOptions: const ToolbarOptions(
                                copy: true,
                                cut: false,
                                paste: false,
                                selectAll: false,
                              ),
                              onChanged: (newValue) {},
                            ),
                          ),
                        if (coin == Coin.monero || coin == Coin.epicCash)
                          const SizedBox(
                            height: 8,
                          ),
                        if (coin == Coin.monero || coin == Coin.epicCash)
                          RoundedWhiteContainer(
                            child: Center(
                              child: Text(
                                "Choose the date you made the wallet (approximate is fine)",
                                style: STextStyles.smallMed12.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        if (coin == Coin.monero || coin == Coin.epicCash)
                          const SizedBox(
                            height: 16,
                          ),
                        Text(
                          "Choose recovery phrase length",
                          style: STextStyles.smallMed12,
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Stack(
                          children: [
                            TextField(
                              controller: _lengthController,
                              readOnly: true,
                              textInputAction: TextInputAction.none,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: RawMaterialButton(
                                splashColor: CFColors.splashLight,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    Constants.size.circularBorderRadius,
                                  ),
                                ),
                                onPressed: () {
                                  showModalBottomSheet<dynamic>(
                                    backgroundColor: Colors.transparent,
                                    context: context,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    builder: (_) {
                                      return MnemonicWordCountSelectSheet(
                                        lengthOptions:
                                            Constants.possibleLengthsForCoin(
                                                coin),
                                      );
                                    },
                                  );
                                },
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${ref.watch(mnemonicWordCountStateProvider.state).state} words",
                                      style: STextStyles.itemSubtitle12,
                                    ),
                                    SvgPicture.asset(
                                      Assets.svg.chevronDown,
                                      width: 8,
                                      height: 4,
                                      color: CFColors.gray3,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                        const Spacer(
                          flex: 3,
                        ),
                        TextButton(
                          onPressed: _nextEnabled
                              ? () async {
                                  // hide keyboard if has focus
                                  if (FocusScope.of(context).hasFocus) {
                                    FocusScope.of(context).unfocus();
                                    await Future<void>.delayed(
                                        const Duration(milliseconds: 75));
                                  }

                                  if (mounted) {
                                    Navigator.of(context).pushNamed(
                                      RestoreWalletView.routeName,
                                      arguments: Tuple4(
                                        walletName,
                                        coin,
                                        ref
                                            .read(mnemonicWordCountStateProvider
                                                .state)
                                            .state,
                                        _restoreFromDate,
                                      ),
                                    );
                                  }
                                }
                              : null,
                          style: _nextEnabled
                              ? Theme.of(context)
                                  .textButtonTheme
                                  .style
                                  ?.copyWith(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      CFColors.stackAccent,
                                    ),
                                  )
                              : Theme.of(context)
                                  .textButtonTheme
                                  .style
                                  ?.copyWith(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      CFColors.stackAccent.withOpacity(
                                        0.25,
                                      ),
                                    ),
                                  ),
                          child: Text(
                            "Next",
                            style: STextStyles.button,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
