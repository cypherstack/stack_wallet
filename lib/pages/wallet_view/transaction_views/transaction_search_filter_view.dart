import 'package:decimal/decimal.dart';
import 'package:epicpay/models/transaction_filter.dart';
import 'package:epicpay/providers/providers.dart';
import 'package:epicpay/providers/ui/color_theme_provider.dart';
import 'package:epicpay/providers/ui/transaction_filter_provider.dart';
import 'package:epicpay/utilities/assets.dart';
import 'package:epicpay/utilities/constants.dart';
import 'package:epicpay/utilities/enums/coin_enum.dart';
import 'package:epicpay/utilities/format.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/utilities/util.dart';
import 'package:epicpay/widgets/background.dart';
import 'package:epicpay/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicpay/widgets/desktop/primary_button.dart';
import 'package:epicpay/widgets/desktop/secondary_button.dart';
import 'package:epicpay/widgets/expandable.dart';
import 'package:epicpay/widgets/icon_widgets/search_icon.dart';
import 'package:epicpay/widgets/icon_widgets/x_icon.dart';
import 'package:epicpay/widgets/rounded_container.dart';
import 'package:epicpay/widgets/textfield_icon_button.dart';
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
  String header = "";
  final List<String> options = [
    "All transactions",
    "Incoming",
    "Outgoing",
  ];
  ExpandableState _expandableState = ExpandableState.collapsed;
  late final ExpandableController _expandableController;

  final _amountTextEditingController = TextEditingController();
  final _keywordTextEditingController = TextEditingController();

  String _fromDateString = "";
  String _toDateString = "";

  final keywordTextFieldFocusNode = FocusNode();
  final amountTextFieldFocusNode = FocusNode();

  late Color baseColor;

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
      sent: header == options[0] || header == options[2],
      received: header == options[0] || header == options[1],
      from: _selectedFromDate,
      to: _selectedToDate,
      amount: amount,
      keyword: _keywordTextEditingController.text,
    );

    ref.read(transactionFilterProvider.state).state = filter;

    Navigator.of(context).pop();
  }

  DateTime? _selectedFromDate = DateTime(2007);
  DateTime? _selectedToDate = DateTime.now();

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

  Widget _buildDateRangePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              AppBarIconButton(
                color: Theme.of(context).extension<StackColors>()!.coal,
                size: 48,
                icon: SvgPicture.asset(
                  Assets.svg.calendar,
                  width: 24,
                  height: 24,
                  color: Theme.of(context).extension<StackColors>()!.textMedium,
                ),
                onPressed: () async {
                  final color = Theme.of(context)
                      .extension<StackColors>()!
                      .accentColorDark;
                  final height = MediaQuery.of(context).size.height;
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
              ),
              const SizedBox(
                width: 12,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "FROM",
                    style: STextStyles.overLineBold(context).copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textMedium,
                    ),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    _selectedFromDate == null
                        ? "n/a"
                        : Format.extractDateFrom(
                            _selectedFromDate!.millisecondsSinceEpoch ~/ 1000,
                            simple: true),
                    style: STextStyles.bodySmall(context),
                  ),
                ],
              )
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              AppBarIconButton(
                color: Theme.of(context).extension<StackColors>()!.coal,
                size: 48,
                icon: SvgPicture.asset(
                  Assets.svg.calendar,
                  width: 24,
                  height: 24,
                  color: Theme.of(context).extension<StackColors>()!.textMedium,
                ),
                onPressed: () async {
                  final color = Theme.of(context)
                      .extension<StackColors>()!
                      .accentColorDark;
                  final height = MediaQuery.of(context).size.height;
                  // check and hide keyboard
                  if (FocusScope.of(context).hasFocus) {
                    FocusScope.of(context).unfocus();
                    await Future<void>.delayed(
                        const Duration(milliseconds: 125));
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
              ),
              const SizedBox(
                width: 12,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "TO",
                    style: STextStyles.overLineBold(context).copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textMedium,
                    ),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    _selectedToDate == null
                        ? "n/a"
                        : Format.extractDateFrom(
                            _selectedToDate!.millisecondsSinceEpoch ~/ 1000,
                            simple: true),
                    style: STextStyles.bodySmall(context),
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  @override
  initState() {
    _expandableController = ExpandableController();
    baseColor = ref.read(colorThemeProvider.state).state.textLight;
    final filterState = ref.read(transactionFilterProvider.state).state;

    header = options[0];

    if (filterState != null) {
      if (filterState.received && !filterState.sent) {
        header = options[1];
      } else if (!filterState.received && filterState.sent) {
        header = options[2];
      } else {
        header = options[0];
      }

      _selectedToDate = filterState.to;
      _selectedFromDate = filterState.from;
      _keywordTextEditingController.text = filterState.keyword;

      _fromDateString = _selectedFromDate == null
          ? ""
          : Format.formatDate(_selectedFromDate!);
      _toDateString =
          _selectedToDate == null ? "" : Format.formatDate(_selectedToDate!);

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

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          automaticallyImplyLeading: false,
          centerTitle: true,
          actions: [
            AspectRatio(
              aspectRatio: 1,
              child: AppBarIconButton(
                icon: const XIcon(),
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
              ),
            ),
          ],
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
                        Text(
                          "Filter transactions",
                          style: STextStyles.titleH4(context),
                        ),
                        const SizedBox(
                          height: 36,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            child: Text(
                              "TRANSACTION TYPE",
                              style: STextStyles.overLineBold(context),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        RoundedContainer(
                          padding: const EdgeInsets.all(0),
                          color:
                              Theme.of(context).extension<StackColors>()!.coal,
                          child: Expandable(
                            controller: _expandableController,
                            onExpandChanged: (expanded) {
                              setState(() {
                                _expandableState = expanded;
                              });
                            },
                            header: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    header,
                                    style: STextStyles.body(context).copyWith(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .textMedium,
                                    ),
                                  ),
                                  SvgPicture.asset(
                                    Assets.svg.chevronDown,
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textMedium,
                                    width: 14,
                                  ),
                                ],
                              ),
                            ),
                            body: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ...options.where((e) => e != header).map(
                                      (e) => Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            height: 1,
                                            color: Theme.of(context)
                                                .extension<StackColors>()!
                                                .textDark
                                                .withOpacity(0.1),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                header = e;
                                              });
                                              _expandableController.toggle
                                                  ?.call();
                                            },
                                            child: Container(
                                              color: Colors.transparent,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Text(
                                                  e,
                                                  style:
                                                      STextStyles.body(context)
                                                          .copyWith(
                                                    color: Theme.of(context)
                                                        .extension<
                                                            StackColors>()!
                                                        .textMedium,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 32,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            child: Text(
                              "DATE",
                              style: STextStyles.overLineBold(context),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        _buildDateRangePicker(),
                        const SizedBox(
                          height: 32,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            child: Text(
                              "AMOUNT",
                              style: STextStyles.overLineBold(context),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        TextField(
                          autocorrect: false,
                          enableSuggestions: false,
                          key: const Key("transactionSearchViewAmountFieldKey"),
                          controller: _amountTextEditingController,
                          focusNode: amountTextFieldFocusNode,
                          onChanged: (_) => setState(() {}),
                          textAlignVertical: TextAlignVertical.center,
                          style: STextStyles.body(context),
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
                          decoration: InputDecoration(
                            hintText: "Enter amount...",
                            hintStyle: STextStyles.fieldLabel(context).copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textFieldDefaultSearchIconLeft,
                            ),
                            suffixIcon: UnconstrainedBox(
                              child: Row(
                                children: [
                                  if (_amountTextEditingController
                                      .text.isNotEmpty)
                                    TextFieldIconButton(
                                      child: const XIcon(),
                                      onTap: () async {
                                        setState(() {
                                          _amountTextEditingController.text =
                                              "";
                                        });
                                      },
                                    ),
                                  if (_amountTextEditingController.text.isEmpty)
                                    const SearchIcon(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 32,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            child: Text(
                              "KEYWORD",
                              style: STextStyles.overLineBold(context),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        TextField(
                          autocorrect: false,
                          enableSuggestions: false,
                          key:
                              const Key("transactionSearchViewKeywordFieldKey"),
                          controller: _keywordTextEditingController,
                          focusNode: keywordTextFieldFocusNode,
                          textAlignVertical: TextAlignVertical.center,
                          style: STextStyles.body(context),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: "Type keyword...",
                            hintStyle: STextStyles.fieldLabel(context).copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textFieldDefaultSearchIconLeft,
                            ),
                            suffixIcon: UnconstrainedBox(
                              child: Row(
                                children: [
                                  if (_keywordTextEditingController
                                      .text.isNotEmpty)
                                    TextFieldIconButton(
                                      child: const XIcon(),
                                      onTap: () async {
                                        setState(() {
                                          _keywordTextEditingController.text =
                                              "";
                                        });
                                      },
                                    ),
                                  if (_keywordTextEditingController
                                      .text.isEmpty)
                                    const SearchIcon(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(
                          height: 16,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryButton(
                                label: "Cancel",
                                onPressed: () async {
                                  if (FocusScope.of(context).hasFocus) {
                                    FocusScope.of(context).unfocus();
                                    await Future<void>.delayed(
                                      const Duration(
                                        milliseconds: 75,
                                      ),
                                    );
                                  }

                                  if (mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            Expanded(
                              child: PrimaryButton(
                                onPressed: () async {
                                  await _onApplyPressed();
                                },
                                label: "APPLY",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 24,
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
