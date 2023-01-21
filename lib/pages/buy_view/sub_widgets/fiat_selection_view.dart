import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:stackwallet/models/buy/response_objects/fiat.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/fiat_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class FiatSelectionView extends StatefulWidget {
  const FiatSelectionView({
    Key? key,
    required this.fiats,
  }) : super(key: key);

  final List<Fiat> fiats;

  @override
  State<FiatSelectionView> createState() => _FiatSelectionViewState();
}

class _FiatSelectionViewState extends State<FiatSelectionView> {
  late TextEditingController _searchController;
  final _searchFocusNode = FocusNode();

  late final List<Fiat> fiats;
  late List<Fiat> _fiats;

  void filter(String text) {
    setState(() {
      _fiats = [
        ...fiats.where((e) =>
            e.name.toLowerCase().contains(text.toLowerCase()) ||
            e.ticker.toLowerCase().contains(text.toLowerCase()))
      ];
    });
  }

  @override
  void initState() {
    _searchController = TextEditingController();

    fiats = [...widget.fiats];
    fiats.sort(
        (a, b) => a.ticker.toLowerCase().compareTo(b.ticker.toLowerCase()));
    for (Fiats fiat in Fiats.values.reversed) {
      int index = fiats.indexWhere((element) =>
          element.ticker.toLowerCase() == fiat.ticker.toLowerCase());
      if (index > 0) {
        final currency = fiats.removeAt(index);
        fiats.insert(0, currency);
      }
    }

    _fiats = [...fiats];

    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    var format = NumberFormat.simpleCurrency(locale: locale.toString());
    // See https://stackoverflow.com/a/67055685

    final isDesktop = Util.isDesktop;

    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) {
        return Background(
          child: Scaffold(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.background,
            appBar: AppBar(
              leading: AppBarBackButton(
                onPressed: () async {
                  if (FocusScope.of(context).hasFocus) {
                    FocusScope.of(context).unfocus();
                    await Future<void>.delayed(
                        const Duration(milliseconds: 50));
                  }
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              title: Text(
                "Choose a currency with which to pay",
                style: STextStyles.pageTitleH2(context),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: child,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: isDesktop ? MainAxisSize.min : MainAxisSize.max,
        children: [
          if (!isDesktop)
            const SizedBox(
              height: 16,
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
            child: TextField(
              autofocus: isDesktop,
              autocorrect: !isDesktop,
              enableSuggestions: !isDesktop,
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: filter,
              style: STextStyles.field(context),
              decoration: standardInputDecoration(
                "Search",
                _searchFocusNode,
                context,
                desktopMed: isDesktop,
              ).copyWith(
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 16,
                  ),
                  child: SvgPicture.asset(
                    Assets.svg.search,
                    width: 16,
                    height: 16,
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
                                  });
                                  filter("");
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
            height: 10,
          ),
          Text(
            "All currencies",
            style: STextStyles.smallMed12(context),
          ),
          const SizedBox(
            height: 12,
          ),
          Flexible(
            child: RoundedWhiteContainer(
              padding: const EdgeInsets.all(0),
              child: ListView.builder(
                shrinkWrap: true,
                primary: isDesktop ? false : null,
                itemCount: _fiats.length,
                itemBuilder: (builderContext, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop(_fiats[index]);
                      },
                      child: RoundedWhiteContainer(
                        child: Row(
                          children: [
                            SizedBox(
                              width: 48,
                              height: 24,
                              child: _fiats[index].image.isNotEmpty
                                  ? SvgPicture.network(
                                      _fiats[index].image,
                                      width: 24,
                                      height: 24,
                                      placeholderBuilder: (_) =>
                                          const LoadingIndicator(),
                                    )
                                  : Text(
                                      format.simpleCurrencySymbol(
                                          _fiats[index].ticker.toUpperCase()),
                                      style: STextStyles.currencyTicker(context)
                                          .apply(
                                              fontSizeFactor: (1 /
                                                  format
                                                      .simpleCurrencySymbol(
                                                          _fiats[index]
                                                              .ticker
                                                              .toUpperCase())
                                                      .length * // Couldn't get pow() working here
                                                  format
                                                      .simpleCurrencySymbol(
                                                          _fiats[index]
                                                              .ticker
                                                              .toUpperCase())
                                                      .length)),
                                      textAlign: TextAlign.center,
                                    ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _fiats[index].name,
                                    style: STextStyles.largeMedium14(context),
                                  ),
                                  const SizedBox(
                                    height: 2,
                                  ),
                                  Text(
                                    _fiats[index].ticker.toUpperCase(),
                                    style: STextStyles.smallMed12(context)
                                        .copyWith(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .textSubtitle1,
                                    ),
                                  ),
                                ],
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
        ],
      ),
    );
  }
}
