import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';

import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';

import 'package:stackwallet/pages/token_view/all_tokens_view.dart';

import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';

import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';
import 'package:stackwallet/pages/wallet_view/sub_widgets/no_transactions_found.dart';

class MyTokensView extends ConsumerStatefulWidget {
  const MyTokensView({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  static const String routeName = "/myTokens";
  final String walletId;

  @override
  ConsumerState<MyTokensView> createState() => _TokenDetailsViewState();
}

class _TokenDetailsViewState extends ConsumerState<MyTokensView> {
  late final String walletId;

  late final TextEditingController _searchController;
  final searchFieldFocusNode = FocusNode();

  @override
  void initState() {
    walletId = widget.walletId;
    _searchController = TextEditingController();

    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    searchFieldFocusNode.dispose();
    super.dispose();
  }

  String _searchString = "";

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    return MasterScaffold(
      background: Theme.of(context).extension<StackColors>()!.background,
      isDesktop: isDesktop,
      appBar: isDesktop
          ? DesktopAppBar(
              isCompactHeight: true,
              background: Theme.of(context).extension<StackColors>()!.popupBG,
              leading: Row(
                children: [
                  const SizedBox(
                    width: 32,
                  ),
                  AppBarIconButton(
                    size: 32,
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textFieldDefaultBG,
                    shadows: const [],
                    icon: SvgPicture.asset(
                      Assets.svg.arrowLeft,
                      width: 18,
                      height: 18,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .topNavIconPrimary,
                    ),
                    onPressed: Navigator.of(context).pop,
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Text(
                    "My ETH Wallet Tokens",
                    style: STextStyles.desktopH3(context),
                  ),
                ],
              ),
            )
          : AppBar(
              backgroundColor:
                  Theme.of(context).extension<StackColors>()!.background,
              leading: AppBarBackButton(
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
              title: Text(
                "My ETH Wallet Tokens",
                style: STextStyles.navBarTitle(context),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 10,
                    bottom: 10,
                    right: 20,
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: AppBarIconButton(
                      key: const Key("transactionSearchFilterViewButton"),
                      size: 36,
                      shadows: const [],
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .background,
                      icon: SvgPicture.asset(
                        Assets.svg.circlePlusDark,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorDark,
                        width: 20,
                        height: 20,
                      ),
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          AllTokensView.routeName,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
      body: Padding(
        padding: EdgeInsets.only(
          left: isDesktop ? 20 : 12,
          top: isDesktop ? 20 : 12,
          right: isDesktop ? 20 : 12,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  ConditionalParent(
                    condition: isDesktop,
                    builder: (child) => SizedBox(
                      width: 570,
                      child: child,
                    ),
                    child: ConditionalParent(
                      condition: !isDesktop,
                      builder: (child) => Expanded(
                        child: child,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          Constants.size.circularBorderRadius,
                        ),
                        child: TextField(
                          autocorrect: !isDesktop,
                          enableSuggestions: !isDesktop,
                          controller: _searchController,
                          focusNode: searchFieldFocusNode,
                          onChanged: (value) {
                            setState(() {
                              _searchString = value;
                            });
                          },
                          style: isDesktop
                              ? STextStyles.desktopTextExtraSmall(context)
                                  .copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textFieldActiveText,
                                  height: 1.8,
                                )
                              : STextStyles.field(context),
                          decoration: standardInputDecoration(
                            "Search...",
                            searchFieldFocusNode,
                            context,
                            desktopMed: isDesktop,
                          ).copyWith(
                            prefixIcon: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 12 : 10,
                                vertical: isDesktop ? 18 : 16,
                              ),
                              child: SvgPicture.asset(
                                Assets.svg.search,
                                width: isDesktop ? 20 : 16,
                                height: isDesktop ? 20 : 16,
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
                                                _searchString = "";
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
                  ),
                  if (isDesktop)
                    const SizedBox(
                      width: 20,
                    ),
                  // const NoTransActionsFound(),
                ],
              ),
            ),
            if (isDesktop)
              const SizedBox(
                height: 8,
              ),
            const SizedBox(
              height: 8,
            ),
          ],
        ),
      ),
    );
  }
}
