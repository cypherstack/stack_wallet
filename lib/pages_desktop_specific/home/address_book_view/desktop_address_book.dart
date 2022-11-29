import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:epicmobile/providers/global/wallets_provider.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/widgets/desktop/desktop_app_bar.dart';
import 'package:epicmobile/widgets/icon_widgets/x_icon.dart';
import 'package:epicmobile/widgets/stack_text_field.dart';
import 'package:epicmobile/widgets/textfield_icon_button.dart';

class DesktopAddressBook extends ConsumerStatefulWidget {
  const DesktopAddressBook({Key? key}) : super(key: key);

  static const String routeName = "/desktopAddressBook";

  @override
  ConsumerState<DesktopAddressBook> createState() => _DesktopAddressBook();
}

class _DesktopAddressBook extends ConsumerState<DesktopAddressBook> {
  late final TextEditingController _searchController;

  late final FocusNode _searchFocusNode;

  String filter = "";

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
    final hasWallets = ref.watch(walletsChangeNotifierProvider).hasWallets;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DesktopAppBar(
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
        const SizedBox(height: 53),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              SizedBox(
                height: 60,
                width: 489,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                  child: TextField(
                    autocorrect: false,
                    enableSuggestions: false,
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (newString) {
                      setState(() => filter = newString);
                    },
                    style: STextStyles.field(context),
                    decoration: standardInputDecoration(
                      "Search...",
                      _searchFocusNode,
                      context,
                    ).copyWith(
                      labelStyle: STextStyles.fieldLabel(context)
                          .copyWith(fontSize: 16),
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
                                          filter = "";
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
            ],
          ),
        ),
        // Expanded(
        //   child: hasWallets ? const MyWallets() : const EmptyWallets(),
        // ),
      ],
    );
  }
}
