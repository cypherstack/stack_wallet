import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stackwallet/models/transaction_filter.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/providers/ui/transaction_filter_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class TransactionSearchFilterView extends ConsumerStatefulWidget {
  const TransactionSearchFilterView({
    Key? key,
    required this.coin,
  }) : super(key: key);

  static const String routeName = "/transactionSearchFilter";

  final Coin coin;

  @override
  ConsumerState<TransactionSearchFilterView> createState() =>
      _TransactionSearchViewState();
}

class _TransactionSearchViewState
    extends ConsumerState<TransactionSearchFilterView> {
  final _amountTextEditingController = TextEditingController();
  final _keywordTextEditingController = TextEditingController();

  bool _isActiveReceivedCheckbox = false;
  bool _isActiveSentCheckbox = false;

  String _fromDateString = "";
  String _toDateString = "";

  final keywordTextFieldFocusNode = FocusNode();
  final amountTextFieldFocusNode = FocusNode();

  @override
  initState() {
    final filterState = ref.read(transactionFilterProvider.state).state;
    if (filterState != null) {
      _isActiveReceivedCheckbox = filterState.received;
      _isActiveSentCheckbox = filterState.sent;
      _selectedToDate = filterState.to;
      _selectedFromDate = filterState.from;
      _keywordTextEditingController.text = filterState.keyword;

      // TODO: Fix XMR (modify Format.funcs to take optional Coin parameter)
      // final amt = Format.satoshisToAmount(widget.coin == Coin.monero ? )
      String amount = "";
      if (filterState.amount != null) {
        amount = Format.satoshiAmountToPrettyString(filterState.amount!,
            ref.read(localeServiceChangeNotifierProvider).locale);
      }
      _amountTextEditingController.text = amount;
    }

    super.initState();
  }

  @override
  dispose() {
    _amountTextEditingController.dispose();
    _keywordTextEditingController.dispose();
    keywordTextFieldFocusNode.dispose();
    amountTextFieldFocusNode.dispose();

    super.dispose();
  }

  // The following two getters are not required if the
  // date fields are to remain unclearable.
  Widget get _dateFromText {
    final isDateSelected = _fromDateString.isEmpty;
    return Text(
      isDateSelected ? "From..." : _fromDateString,
      style: STextStyles.fieldLabel.copyWith(
          color: isDateSelected
              ? StackTheme.instance.color.textSubtitle2
              : StackTheme.instance.color.accentColorDark),
    );
  }

  Widget get _dateToText {
    final isDateSelected = _toDateString.isEmpty;
    return Text(
      isDateSelected ? "To..." : _toDateString,
      style: STextStyles.fieldLabel.copyWith(
          color: isDateSelected
              ? StackTheme.instance.color.textSubtitle2
              : StackTheme.instance.color.accentColorDark),
    );
  }

  var _selectedFromDate = DateTime(2007);
  var _selectedToDate = DateTime.now();

  final _datePickerTextStyleBase = GoogleFonts.inter(
    color: StackTheme.instance.color.textSubtitle2,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );

  MaterialRoundedDatePickerStyle _buildDatePickerStyle() {
    return MaterialRoundedDatePickerStyle(
      backgroundPicker: StackTheme.instance.color.popupBG,
      // backgroundHeader: StackTheme.instance.color.textSubtitle2,
      paddingMonthHeader: const EdgeInsets.only(top: 11),
      colorArrowNext: StackTheme.instance.color.textSubtitle1,
      colorArrowPrevious: StackTheme.instance.color.textSubtitle1,
      textStyleButtonNegative: _datePickerTextStyleBase.copyWith(
          fontSize: 16, fontWeight: FontWeight.w600),
      textStyleButtonPositive: _datePickerTextStyleBase.copyWith(
          fontSize: 16, fontWeight: FontWeight.w600),
      textStyleCurrentDayOnCalendar: _datePickerTextStyleBase.copyWith(
          color: StackTheme.instance.color.accentColorDark),
      textStyleDayHeader: _datePickerTextStyleBase.copyWith(
        color: StackTheme.instance.color.accentColorDark,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      textStyleDayOnCalendar: _datePickerTextStyleBase,
      textStyleDayOnCalendarDisabled: _datePickerTextStyleBase.copyWith(
        color: StackTheme.instance.color.textSubtitle3,
      ),
      textStyleDayOnCalendarSelected: _datePickerTextStyleBase.copyWith(
        color: StackTheme.instance.color.textWhite,
      ),
      textStyleMonthYearHeader: _datePickerTextStyleBase.copyWith(
        color: StackTheme.instance.color.textSubtitle1,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      textStyleYearButton: _datePickerTextStyleBase.copyWith(
        color: StackTheme.instance.color.textWhite,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      textStyleButtonAction: GoogleFonts.inter(),
    );
  }

  MaterialRoundedYearPickerStyle _buildYearPickerStyle() {
    return MaterialRoundedYearPickerStyle(
      backgroundPicker: StackTheme.instance.color.popupBG,
      textStyleYear: _datePickerTextStyleBase.copyWith(
        color: StackTheme.instance.color.textSubtitle2,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      textStyleYearSelected: _datePickerTextStyleBase.copyWith(
        color: StackTheme.instance.color.accentColorDark,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
    );
  }

  Widget _buildDateRangePicker() {
    const middleSeparatorPadding = 2.0;
    const middleSeparatorWidth = 12.0;
    final width = (MediaQuery.of(context).size.width -
            (middleSeparatorWidth +
                (2 * middleSeparatorPadding) +
                (2 * Constants.size.standardPadding))) /
        2;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          key: const Key("transactionSearchViewFromDatePickerKey"),
          onTap: () async {
            final height = MediaQuery.of(context).size.height;
            // check and hide keyboard
            if (FocusScope.of(context).hasFocus) {
              FocusScope.of(context).unfocus();
              await Future<void>.delayed(const Duration(milliseconds: 125));
            }

            final date = await showRoundedDatePicker(
              // This doesn't change statusbar color...
              // background: CFColors.starryNight.withOpacity(0.8),
              context: context,
              initialDate: DateTime.now(),
              height: height * 0.5,
              theme: ThemeData(
                primarySwatch: Util.createMaterialColor(
                  StackTheme.instance.color.accentColorDark,
                ),
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
              _selectedFromDate = date;

              // flag to adjust date so from date is always before to date
              final flag = !_selectedFromDate.isBefore(_selectedToDate);
              if (flag) {
                _selectedToDate = DateTime.fromMillisecondsSinceEpoch(
                    _selectedFromDate.millisecondsSinceEpoch);
              }

              setState(() {
                if (flag) {
                  _toDateString = Format.formatDate(_selectedToDate);
                }
                _fromDateString = Format.formatDate(_selectedFromDate);
              });
            }
          },
          child: Container(
            width: width,
            decoration: BoxDecoration(
              color: StackTheme.instance.color.textFieldDefaultBG,
              borderRadius:
                  BorderRadius.circular(Constants.size.circularBorderRadius),
              border: Border.all(
                color: StackTheme.instance.color.textFieldDefaultBG,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SvgPicture.asset(
                    Assets.svg.calendar,
                    height: 20,
                    width: 20,
                    color: StackTheme.instance.color.textSubtitle2,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      child: _dateFromText,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: middleSeparatorPadding),
          child: Container(
            width: middleSeparatorWidth,
            // height: 1,
            // color: CFColors.smoke,
          ),
        ),
        GestureDetector(
          key: const Key("transactionSearchViewToDatePickerKey"),
          onTap: () async {
            final height = MediaQuery.of(context).size.height;
            // check and hide keyboard
            if (FocusScope.of(context).hasFocus) {
              FocusScope.of(context).unfocus();
              await Future<void>.delayed(const Duration(milliseconds: 125));
            }

            final date = await showRoundedDatePicker(
              // This doesn't change statusbar color...
              // background: CFColors.starryNight.withOpacity(0.8),
              context: context,
              height: height * 0.5,
              theme: ThemeData(
                primarySwatch: Util.createMaterialColor(
                  StackTheme.instance.color.accentColorDark,
                ),
              ),
              //TODO pick a better initial date
              // 2007 chosen as that is just before bitcoin launched
              initialDate: DateTime.now(),
              firstDate: DateTime(2007),
              lastDate: DateTime.now(),
              borderRadius: Constants.size.circularBorderRadius * 2,

              textPositiveButton: "SELECT",

              styleDatePicker: _buildDatePickerStyle(),
              styleYearPicker: _buildYearPickerStyle(),
            );
            if (date != null) {
              _selectedToDate = date;

              // flag to adjust date so from date is always before to date
              final flag = !_selectedToDate.isAfter(_selectedFromDate);
              if (flag) {
                _selectedFromDate = DateTime.fromMillisecondsSinceEpoch(
                    _selectedToDate.millisecondsSinceEpoch);
              }

              setState(() {
                if (flag) {
                  _fromDateString = Format.formatDate(_selectedFromDate);
                }
                _toDateString = Format.formatDate(_selectedToDate);
              });
            }
          },
          child: Container(
            width: width,
            decoration: BoxDecoration(
              color: StackTheme.instance.color.textFieldDefaultBG,
              borderRadius:
                  BorderRadius.circular(Constants.size.circularBorderRadius),
              border: Border.all(
                color: StackTheme.instance.color.textFieldDefaultBG,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SvgPicture.asset(
                    Assets.svg.calendar,
                    height: 20,
                    width: 20,
                    color: StackTheme.instance.color.textSubtitle2,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      child: _dateToText,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StackTheme.instance.color.background,
      appBar: AppBar(
        backgroundColor: StackTheme.instance.color.background,
        leading: AppBarBackButton(
          onPressed: () async {
            if (FocusScope.of(context).hasFocus) {
              FocusScope.of(context).unfocus();
              await Future<void>.delayed(const Duration(milliseconds: 75));
            }
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          "Transactions filter",
          style: STextStyles.navBarTitle,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Constants.size.standardPadding,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          child: Text(
                            "Transactions",
                            style: STextStyles.smallMed12,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      RoundedWhiteContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isActiveSentCheckbox =
                                          !_isActiveSentCheckbox;
                                    });
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: Checkbox(
                                            key: const Key(
                                                "transactionSearchViewSentCheckboxKey"),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            value: _isActiveSentCheckbox,
                                            onChanged: (newValue) {
                                              setState(() {
                                                _isActiveSentCheckbox =
                                                    newValue!;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 14,
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: FittedBox(
                                            child: Text(
                                              "Sent",
                                              style: STextStyles.itemSubtitle12,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isActiveReceivedCheckbox =
                                          !_isActiveReceivedCheckbox;
                                    });
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: Checkbox(
                                            key: const Key(
                                                "transactionSearchViewReceivedCheckboxKey"),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            value: _isActiveReceivedCheckbox,
                                            onChanged: (newValue) {
                                              setState(() {
                                                _isActiveReceivedCheckbox =
                                                    newValue!;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 14,
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: FittedBox(
                                            child: Text(
                                              "Received",
                                              style: STextStyles.itemSubtitle12,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          child: Text(
                            "Date",
                            style: STextStyles.smallMed12,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      _buildDateRangePicker(),
                      const SizedBox(
                        height: 24,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          child: Text(
                            "Amount",
                            style: STextStyles.smallMed12,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          Constants.size.circularBorderRadius,
                        ),
                        child: TextField(
                          key: const Key("transactionSearchViewAmountFieldKey"),
                          controller: _amountTextEditingController,
                          focusNode: amountTextFieldFocusNode,
                          onChanged: (_) => setState(() {}),
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: false,
                            decimal: true,
                          ),
                          inputFormatters: [
                            // regex to validate a crypto amount with 8 decimal places
                            TextInputFormatter.withFunction((oldValue,
                                    newValue) =>
                                RegExp(r'^([0-9]*[,.]?[0-9]{0,8}|[,.][0-9]{0,8})$')
                                        .hasMatch(newValue.text)
                                    ? newValue
                                    : oldValue),
                          ],
                          style: STextStyles.field,
                          decoration: standardInputDecoration(
                            "Enter ${widget.coin.ticker} amount...",
                            keywordTextFieldFocusNode,
                          ).copyWith(
                            suffixIcon: _amountTextEditingController
                                    .text.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(right: 0),
                                    child: UnconstrainedBox(
                                      child: Row(
                                        children: [
                                          TextFieldIconButton(
                                            child: const XIcon(),
                                            onTap: () async {
                                              setState(() {
                                                _amountTextEditingController
                                                    .text = "";
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
                      const SizedBox(
                        height: 24,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          child: Text(
                            "Keyword",
                            style: STextStyles.smallMed12,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          Constants.size.circularBorderRadius,
                        ),
                        child: TextField(
                          key:
                              const Key("transactionSearchViewKeywordFieldKey"),
                          controller: _keywordTextEditingController,
                          focusNode: keywordTextFieldFocusNode,
                          style: STextStyles.field,
                          onChanged: (_) => setState(() {}),
                          decoration: standardInputDecoration(
                            "Type keyword...",
                            keywordTextFieldFocusNode,
                          ).copyWith(
                            suffixIcon: _keywordTextEditingController
                                    .text.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(right: 0),
                                    child: UnconstrainedBox(
                                      child: Row(
                                        children: [
                                          TextFieldIconButton(
                                            child: const XIcon(),
                                            onTap: () async {
                                              setState(() {
                                                _keywordTextEditingController
                                                    .text = "";
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
                      const Spacer(),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: TextButton(
                                onPressed: () async {
                                  if (FocusScope.of(context).hasFocus) {
                                    FocusScope.of(context).unfocus();
                                    await Future<void>.delayed(
                                        const Duration(milliseconds: 75));
                                  }
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                                style: StackTheme.instance
                                    .getSecondaryEnabledButtonColor(context),
                                child: Text(
                                  "Cancel",
                                  style: STextStyles.button.copyWith(
                                      color: StackTheme
                                          .instance.color.accentColorDark),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: TextButton(
                                style: StackTheme.instance
                                    .getPrimaryEnabledButtonColor(context),
                                onPressed: () async {
                                  _onApplyPressed();
                                },
                                child: Text(
                                  "Save",
                                  style: STextStyles.button,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onApplyPressed() async {
    final amountText = _amountTextEditingController.text;
    Decimal? amountDecimal;
    if (amountText.isNotEmpty && !(amountText == "," || amountText == ".")) {
      amountDecimal = amountText.contains(",")
          ? Decimal.parse(amountText.replaceFirst(",", "."))
          : Decimal.parse(amountText);
    }
    int? amount;
    if (amountDecimal != null) {
      if (widget.coin == Coin.monero) {
        amount = (amountDecimal * Decimal.fromInt(Constants.satsPerCoinMonero))
            .floor()
            .toBigInt()
            .toInt();
      } else {
        amount = (amountDecimal * Decimal.fromInt(Constants.satsPerCoin))
            .floor()
            .toBigInt()
            .toInt();
      }
    }

    final TransactionFilter filter = TransactionFilter(
      sent: _isActiveSentCheckbox,
      received: _isActiveReceivedCheckbox,
      from: _selectedFromDate,
      to: _selectedToDate,
      amount: amount,
      keyword: _keywordTextEditingController.text,
    );

    ref.read(transactionFilterProvider.state).state = filter;

    Navigator.of(context).pop();
  }
}
