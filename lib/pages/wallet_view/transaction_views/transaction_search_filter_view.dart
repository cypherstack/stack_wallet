import 'package:decimal/decimal.dart';
import 'package:epicmobile/models/transaction_filter.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/providers/ui/color_theme_provider.dart';
import 'package:epicmobile/providers/ui/transaction_filter_provider.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/format.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/utilities/util.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/desktop/desktop_dialog.dart';
import 'package:epicmobile/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:epicmobile/widgets/desktop/primary_button.dart';
import 'package:epicmobile/widgets/desktop/secondary_button.dart';
import 'package:epicmobile/widgets/icon_widgets/x_icon.dart';
import 'package:epicmobile/widgets/rounded_white_container.dart';
import 'package:epicmobile/widgets/stack_text_field.dart';
import 'package:epicmobile/widgets/textfield_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:flutter_svg/svg.dart';

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
  bool _isActiveTradeCheckbox = false;

  String _fromDateString = "";
  String _toDateString = "";

  final keywordTextFieldFocusNode = FocusNode();
  final amountTextFieldFocusNode = FocusNode();

  late Color baseColor;

  @override
  initState() {
    baseColor = ref.read(colorThemeProvider.state).state.textSubtitle2;
    final filterState = ref.read(transactionFilterProvider.state).state;
    if (filterState != null) {
      _isActiveReceivedCheckbox = filterState.received;
      _isActiveSentCheckbox = filterState.sent;
      _selectedToDate = filterState.to;
      _selectedFromDate = filterState.from;
      _keywordTextEditingController.text = filterState.keyword;

      _fromDateString = _selectedFromDate == null
          ? ""
          : Format.formatDate(_selectedFromDate!);
      _toDateString =
          _selectedToDate == null ? "" : Format.formatDate(_selectedToDate!);

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
      style: STextStyles.fieldLabel(context).copyWith(
          color: isDateSelected
              ? Theme.of(context).extension<StackColors>()!.textSubtitle2
              : Theme.of(context).extension<StackColors>()!.accentColorDark),
    );
  }

  Widget get _dateToText {
    final isDateSelected = _toDateString.isEmpty;
    return Text(
      isDateSelected ? "To..." : _toDateString,
      style: STextStyles.fieldLabel(context).copyWith(
          color: isDateSelected
              ? Theme.of(context).extension<StackColors>()!.textSubtitle2
              : Theme.of(context).extension<StackColors>()!.accentColorDark),
    );
  }

  DateTime? _selectedFromDate = DateTime(2007);
  DateTime? _selectedToDate = DateTime.now();

  MaterialRoundedDatePickerStyle _buildDatePickerStyle() {
    return MaterialRoundedDatePickerStyle(
      backgroundPicker: Theme.of(context).extension<StackColors>()!.popupBG,
      // backgroundHeader: Theme.of(context).extension<StackColors>()!.textSubtitle2,
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
        color: Theme.of(context).extension<StackColors>()!.coal,
      ),
      textStyleMonthYearHeader: STextStyles.datePicker600(context).copyWith(
        color: Theme.of(context).extension<StackColors>()!.textSubtitle1,
      ),
      textStyleYearButton: STextStyles.datePicker600(context).copyWith(
        color: Theme.of(context).extension<StackColors>()!.coal,
      ),
      // textStyleButtonAction: GoogleFonts.poppins(),
    );
  }

  MaterialRoundedYearPickerStyle _buildYearPickerStyle() {
    return MaterialRoundedYearPickerStyle(
      backgroundPicker: Theme.of(context).extension<StackColors>()!.popupBG,
      textStyleYear: STextStyles.datePicker600(context).copyWith(
        color: Theme.of(context).extension<StackColors>()!.textSubtitle2,
        fontSize: 16,
      ),
      textStyleYearSelected: STextStyles.datePicker600(context).copyWith(
        fontSize: 18,
      ),
    );
  }

  Widget _buildDateRangePicker() {
    const middleSeparatorPadding = 2.0;
    const middleSeparatorWidth = 12.0;
    final isDesktop = Util.isDesktop;

    final width = isDesktop
        ? null
        : (MediaQuery.of(context).size.width -
                (middleSeparatorWidth +
                    (2 * middleSeparatorPadding) +
                    (2 * Constants.size.standardPadding))) /
            2;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            key: const Key("transactionSearchViewFromDatePickerKey"),
            onTap: () async {
              final color =
                  Theme.of(context).extension<StackColors>()!.accentColorDark;
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
                    color,
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
                final flag = _selectedToDate != null &&
                    !_selectedFromDate!.isBefore(_selectedToDate!);
                if (flag) {
                  _selectedToDate = DateTime.fromMillisecondsSinceEpoch(
                      _selectedFromDate!.millisecondsSinceEpoch);
                }

                setState(() {
                  if (flag) {
                    _toDateString = _selectedToDate == null
                        ? ""
                        : Format.formatDate(_selectedToDate!);
                  }
                  _fromDateString = _selectedFromDate == null
                      ? ""
                      : Format.formatDate(_selectedFromDate!);
                });
              }
            },
            child: Container(
              width: width,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldDefaultBG,
                borderRadius:
                    BorderRadius.circular(Constants.size.circularBorderRadius),
                border: Border.all(
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .textFieldDefaultBG,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: isDesktop ? 17 : 12,
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      Assets.svg.calendar,
                      height: 20,
                      width: 20,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textSubtitle2,
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
        Expanded(
          child: GestureDetector(
            key: const Key("transactionSearchViewToDatePickerKey"),
            onTap: () async {
              final color =
                  Theme.of(context).extension<StackColors>()!.accentColorDark;
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
                    color,
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
                final flag = _selectedFromDate != null &&
                    !_selectedToDate!.isAfter(_selectedFromDate!);
                if (flag) {
                  _selectedFromDate = DateTime.fromMillisecondsSinceEpoch(
                      _selectedToDate!.millisecondsSinceEpoch);
                }

                setState(() {
                  if (flag) {
                    _fromDateString = _selectedFromDate == null
                        ? ""
                        : Format.formatDate(_selectedFromDate!);
                  }
                  _toDateString = _selectedToDate == null
                      ? ""
                      : Format.formatDate(_selectedToDate!);
                });
              }
            },
            child: Container(
              width: width,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldDefaultBG,
                borderRadius:
                    BorderRadius.circular(Constants.size.circularBorderRadius),
                border: Border.all(
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .textFieldDefaultBG,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: isDesktop ? 17 : 12,
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      Assets.svg.calendar,
                      height: 20,
                      width: 20,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textSubtitle2,
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
        ),
        if (isDesktop)
          const SizedBox(
            width: 24,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Util.isDesktop) {
      return DesktopDialog(
        maxWidth: 576,
        maxHeight: double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 32,
            bottom: 32,
          ),
          child: _buildContent(context),
        ),
      );
    } else {
      return Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.background,
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
              style: STextStyles.titleH4(context),
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
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: _buildContent(context),
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

  Widget _buildContent(BuildContext context) {
    final isDesktop = Util.isDesktop;

    return Column(
      children: [
        if (isDesktop)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Transaction filter",
                style: STextStyles.desktopH3(context),
                textAlign: TextAlign.center,
              ),
              const DesktopDialogCloseButton(),
            ],
          ),
        SizedBox(
          height: isDesktop ? 14 : 10,
        ),
        if (!isDesktop)
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              child: Text(
                "Transactions",
                style: STextStyles.smallMed12(context),
              ),
            ),
          ),
        if (!isDesktop)
          const SizedBox(
            height: 12,
          ),
        RoundedWhiteContainer(
          padding: EdgeInsets.all(isDesktop ? 0 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isActiveSentCheckbox = !_isActiveSentCheckbox;
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
                                  MaterialTapTargetSize.shrinkWrap,
                              value: _isActiveSentCheckbox,
                              onChanged: (newValue) {
                                setState(() {
                                  _isActiveSentCheckbox = newValue!;
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
                              child: Column(
                                children: [
                                  Text(
                                    "Sent",
                                    style: isDesktop
                                        ? STextStyles.desktopTextSmall(context)
                                        : STextStyles.itemSubtitle12(context),
                                  ),
                                  if (isDesktop)
                                    const SizedBox(
                                      height: 4,
                                    ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: isDesktop ? 4 : 10,
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isActiveReceivedCheckbox = !_isActiveReceivedCheckbox;
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
                                  MaterialTapTargetSize.shrinkWrap,
                              value: _isActiveReceivedCheckbox,
                              onChanged: (newValue) {
                                setState(() {
                                  _isActiveReceivedCheckbox = newValue!;
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
                              child: Column(
                                children: [
                                  Text(
                                    "Received",
                                    style: isDesktop
                                        ? STextStyles.desktopTextSmall(context)
                                        : STextStyles.itemSubtitle12(context),
                                  ),
                                  if (isDesktop)
                                    const SizedBox(
                                      height: 4,
                                    ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: isDesktop ? 4 : 10,
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isActiveTradeCheckbox = !_isActiveTradeCheckbox;
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
                                  MaterialTapTargetSize.shrinkWrap,
                              value: _isActiveTradeCheckbox,
                              onChanged: (newValue) {
                                setState(() {
                                  _isActiveTradeCheckbox = newValue!;
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
                              child: Column(
                                children: [
                                  Text(
                                    "Trades",
                                    style: isDesktop
                                        ? STextStyles.desktopTextSmall(context)
                                        : STextStyles.itemSubtitle12(context),
                                  ),
                                  if (isDesktop)
                                    const SizedBox(
                                      height: 4,
                                    ),
                                ],
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
        SizedBox(
          height: isDesktop ? 32 : 24,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            child: Text(
              "Date",
              style: isDesktop
                  ? STextStyles.labelExtraExtraSmall(context)
                  : STextStyles.smallMed12(context),
            ),
          ),
        ),
        SizedBox(
          height: isDesktop ? 10 : 8,
        ),
        _buildDateRangePicker(),
        SizedBox(
          height: isDesktop ? 32 : 24,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            child: Text(
              "Amount",
              style: isDesktop
                  ? STextStyles.labelExtraExtraSmall(context)
                  : STextStyles.smallMed12(context),
            ),
          ),
        ),
        SizedBox(
          height: isDesktop ? 10 : 8,
        ),
        Padding(
          padding: EdgeInsets.only(right: isDesktop ? 32 : 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
            child: TextField(
              autocorrect: Util.isDesktop ? false : true,
              enableSuggestions: Util.isDesktop ? false : true,
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
                TextInputFormatter.withFunction((oldValue, newValue) =>
                    RegExp(r'^([0-9]*[,.]?[0-9]{0,8}|[,.][0-9]{0,8})$')
                            .hasMatch(newValue.text)
                        ? newValue
                        : oldValue),
              ],
              style: isDesktop
                  ? STextStyles.desktopTextExtraSmall(context).copyWith(
                      color:
                          Theme.of(context).extension<StackColors>()!.textLight,
                      height: 1.8,
                    )
                  : STextStyles.field(context),
              decoration: standardInputDecoration(
                "Enter ${widget.coin.ticker} amount...",
                keywordTextFieldFocusNode,
                context,
                desktopMed: isDesktop,
              ).copyWith(
                contentPadding: isDesktop
                    ? const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      )
                    : null,
                suffixIcon: _amountTextEditingController.text.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 0),
                        child: UnconstrainedBox(
                          child: Row(
                            children: [
                              TextFieldIconButton(
                                child: const XIcon(),
                                onTap: () async {
                                  setState(() {
                                    _amountTextEditingController.text = "";
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
        SizedBox(
          height: isDesktop ? 32 : 24,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            child: Text(
              "Keyword",
              style: isDesktop
                  ? STextStyles.labelExtraExtraSmall(context)
                  : STextStyles.smallMed12(context),
            ),
          ),
        ),
        SizedBox(
          height: isDesktop ? 10 : 8,
        ),
        Padding(
          padding: EdgeInsets.only(right: isDesktop ? 32 : 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
            child: TextField(
              autocorrect: Util.isDesktop ? false : true,
              enableSuggestions: Util.isDesktop ? false : true,
              key: const Key("transactionSearchViewKeywordFieldKey"),
              controller: _keywordTextEditingController,
              focusNode: keywordTextFieldFocusNode,
              style: isDesktop
                  ? STextStyles.desktopTextExtraSmall(context).copyWith(
                      color:
                          Theme.of(context).extension<StackColors>()!.textLight,
                      height: 1.8,
                    )
                  : STextStyles.field(context),
              onChanged: (_) => setState(() {}),
              decoration: standardInputDecoration(
                "Type keyword...",
                keywordTextFieldFocusNode,
                context,
                desktopMed: isDesktop,
              ).copyWith(
                contentPadding: isDesktop
                    ? const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      )
                    : null,
                suffixIcon: _keywordTextEditingController.text.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 0),
                        child: UnconstrainedBox(
                          child: Row(
                            children: [
                              TextFieldIconButton(
                                child: const XIcon(),
                                onTap: () async {
                                  setState(() {
                                    _keywordTextEditingController.text = "";
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
        if (!isDesktop) const Spacer(),
        SizedBox(
          height: isDesktop ? 32 : 20,
        ),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: "Cancel",
                onPressed: () async {
                  if (!isDesktop) {
                    if (FocusScope.of(context).hasFocus) {
                      FocusScope.of(context).unfocus();
                      await Future<void>.delayed(
                        const Duration(
                          milliseconds: 75,
                        ),
                      );
                    }
                  }
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            // Expanded(
            //   child: SizedBox(
            //     height: 48,
            //     child: TextButton(
            //       onPressed: () async {
            //         if (FocusScope.of(context).hasFocus) {
            //           FocusScope.of(context).unfocus();
            //           await Future<void>.delayed(
            //               const Duration(milliseconds: 75));
            //         }
            //         if (mounted) {
            //           Navigator.of(context).pop();
            //         }
            //       },
            //       style: Theme.of(context)
            //           .extension<StackColors>()!
            //           .getSecondaryEnabledButtonColor(context),
            //       child: Text(
            //         "Cancel",
            //         style: STextStyles.button(context).copyWith(
            //             color: Theme.of(context)
            //                 .extension<StackColors>()!
            //                 .accentColorDark),
            //       ),
            //     ),
            //   ),
            // ),
            const SizedBox(
              width: 16,
            ),
            Expanded(
              child: PrimaryButton(
                onPressed: () async {
                  await _onApplyPressed();
                },
                label: "Save",
              ),
            ),
            // Expanded(
            //   child: SizedBox(
            //     height: 48,
            //     child: TextButton(
            //       style: Theme.of(context)
            //           .extension<StackColors>()!
            //           .getPrimaryEnabledButtonColor(context),
            //       onPressed: () async {
            //         await _onApplyPressed();
            //       },
            //       child: Text(
            //         "Save",
            //         style: STextStyles.button(context),
            //       ),
            //     ),
            //   ),
            // ),
            if (isDesktop)
              const SizedBox(
                width: 32,
              ),
          ],
        ),
        if (!isDesktop)
          const SizedBox(
            height: 20,
          ),
      ],
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
      amount = Format.decimalAmountToSatoshis(amountDecimal);
    }

    final TransactionFilter filter = TransactionFilter(
      sent: _isActiveSentCheckbox,
      received: _isActiveReceivedCheckbox,
      trade: _isActiveTradeCheckbox,
      from: _selectedFromDate,
      to: _selectedToDate,
      amount: amount,
      keyword: _keywordTextEditingController.text,
    );

    ref.read(transactionFilterProvider.state).state = filter;

    Navigator.of(context).pop();
  }
}
