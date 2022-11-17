import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/address_book_views/address_book_view.dart';
import 'package:stackwallet/pages/address_book_views/subviews/add_address_book_entry_view.dart';
import 'package:stackwallet/pages/address_book_views/subviews/address_book_filter_view.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class DesktopAddressBook extends ConsumerStatefulWidget {
  const DesktopAddressBook({Key? key}) : super(key: key);

  static const String routeName = "/desktopAddressBook";

  @override
  ConsumerState<DesktopAddressBook> createState() => _DesktopAddressBook();
}

class _DesktopAddressBook extends ConsumerState<DesktopAddressBook> {
  late final TextEditingController _searchController;

  late final FocusNode _searchFocusNode;

  String _searchTerm = "";

  Future<void> selectCryptocurrency() async {
    await showDialog<dynamic>(
      context: context,
      useSafeArea: false,
      barrierDismissible: true,
      builder: (context) {
        return const DesktopDialog(
          maxHeight: 609,
          maxWidth: 576,
          child: AddressBookFilterView(),
        );
      },
    );
  }

  Future<void> newContact() async {
    await showDialog<dynamic>(
      context: context,
      useSafeArea: false,
      barrierDismissible: true,
      builder: (context) {
        return const DesktopDialog(
          maxHeight: 609,
          maxWidth: 576,
          child: AddAddressBookEntryView(),
        );
      },
    );
  }

  @override
  void initState() {
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

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
    debugPrint("BUILD: $runtimeType");

    return DesktopScaffold(
      appBar: DesktopAppBar(
        isCompactHeight: true,
        leading: Row(
          children: [
            const SizedBox(
              width: 24,
            ),
            Text(
              "Address Book",
              style: STextStyles.desktopH3(context),
            )
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                    child: TextField(
                      autocorrect: Util.isDesktop ? false : true,
                      enableSuggestions: Util.isDesktop ? false : true,
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (value) {
                        setState(() {
                          _searchTerm = value;
                        });
                      },
                      style: STextStyles.field(context),
                      decoration: standardInputDecoration(
                        "Search",
                        _searchFocusNode,
                        context,
                      ).copyWith(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 20,
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
                  Expanded(
                    child: AddressBookView(
                      filterTerm: _searchTerm,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 20,
            ),
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  Row(
                    children: [
                      SecondaryButton(
                        width: 184,
                        label: "Filter",
                        desktopMed: true,
                        icon: SvgPicture.asset(
                          Assets.svg.filter,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .buttonTextSecondary,
                        ),
                        onPressed: selectCryptocurrency,
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      PrimaryButton(
                        width: 184,
                        label: "Add new",
                        desktopMed: true,
                        icon: SvgPicture.asset(
                          Assets.svg.circlePlus,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .buttonTextPrimary,
                        ),
                        onPressed: newContact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
