import 'package:epicmobile/pages/add_wallet_views/add_wallet_view/sub_widgets/add_wallet_text.dart';
import 'package:epicmobile/pages/add_wallet_views/add_wallet_view/sub_widgets/mobile_coin_list.dart';
import 'package:epicmobile/pages/add_wallet_views/add_wallet_view/sub_widgets/next_button.dart';
import 'package:epicmobile/pages/add_wallet_views/add_wallet_view/sub_widgets/searchable_coin_list.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/utilities/util.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/desktop/desktop_app_bar.dart';
import 'package:epicmobile/widgets/desktop/desktop_scaffold.dart';
import 'package:epicmobile/widgets/icon_widgets/x_icon.dart';
import 'package:epicmobile/widgets/rounded_white_container.dart';
import 'package:epicmobile/widgets/stack_text_field.dart';
import 'package:epicmobile/widgets/textfield_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AddWalletView extends StatefulWidget {
  const AddWalletView({Key? key}) : super(key: key);

  static const routeName = "/addWallet";

  @override
  State<AddWalletView> createState() => _AddWalletViewState();
}

class _AddWalletViewState extends State<AddWalletView> {
  late final TextEditingController _searchFieldController;
  late final FocusNode _searchFocusNode;

  String _searchTerm = "";

  final List<Coin> coins = [...Coin.values];

  @override
  void initState() {
    _searchFieldController = TextEditingController();
    _searchFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _searchFieldController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    if (Util.isDesktop) {
      return DesktopScaffold(
        appBar: const DesktopAppBar(
          isCompactHeight: false,
          leading: AppBarBackButton(),
        ),
        body: Column(
          children: [
            const AddWalletText(
              isDesktop: true,
            ),
            const SizedBox(
              height: 16,
            ),
            Expanded(
              child: SizedBox(
                width: 480,
                child: RoundedWhiteContainer(
                  radiusMultiplier: 2,
                  padding: const EdgeInsets.only(
                    left: 16,
                    top: 16,
                    right: 16,
                    bottom: 0,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            Constants.size.circularBorderRadius,
                          ),
                          child: TextField(
                            autocorrect: Util.isDesktop ? false : true,
                            enableSuggestions: Util.isDesktop ? false : true,
                            controller: _searchFieldController,
                            focusNode: _searchFocusNode,
                            onChanged: (value) {
                              setState(() {
                                _searchTerm = value;
                              });
                            },
                            style:
                                STextStyles.desktopTextMedium(context).copyWith(
                              height: 2,
                            ),
                            decoration: standardInputDecoration(
                              "Search",
                              _searchFocusNode,
                              context,
                            ).copyWith(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  // vertical: 20,
                                ),
                                child: SvgPicture.asset(
                                  Assets.svg.search,
                                  width: 24,
                                  height: 24,
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textFieldDefaultSearchIconLeft,
                                ),
                              ),
                              suffixIcon: _searchFieldController.text.isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: UnconstrainedBox(
                                        child: Row(
                                          children: [
                                            TextFieldIconButton(
                                              child: const XIcon(
                                                width: 24,
                                                height: 24,
                                              ),
                                              onTap: () async {
                                                setState(() {
                                                  _searchFieldController.text =
                                                      "";
                                                  _searchTerm = "";
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
                      Expanded(
                        child: SearchableCoinList(
                          coins: coins,
                          isDesktop: true,
                          searchTerm: _searchTerm,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            const SizedBox(
              height: 70,
              width: 480,
              child: AddWalletNextButton(
                isDesktop: true,
              ),
            ),
            const SizedBox(
              height: 32,
            ),
          ],
        ),
      );
    } else {
      return Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: AppBarBackButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          body: Container(
            color: Theme.of(context).extension<StackColors>()!.background,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AddWalletText(
                    isDesktop: false,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Expanded(
                    child: MobileCoinList(
                      coins: coins,
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  const AddWalletNextButton(
                    isDesktop: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}
