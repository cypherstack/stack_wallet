import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/add_wallet_list_entity/add_wallet_list_entity.dart';
import 'package:stackwallet/models/add_wallet_list_entity/sub_classes/eth_token_entity.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/sub_widgets/add_wallet_entity_list.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/sub_widgets/add_wallet_text.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/sub_widgets/next_button.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/exit_to_my_stack_button.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/default_eth_tokens.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class AddTokenView extends ConsumerStatefulWidget {
  const AddTokenView({
    Key? key,
  }) : super(key: key);

  static const routeName = "/addToken";

  @override
  ConsumerState<AddTokenView> createState() => _AddTokenViewState();
}

class _AddTokenViewState extends ConsumerState<AddTokenView> {
  late final TextEditingController _searchFieldController;
  late final FocusNode _searchFocusNode;

  String _searchTerm = "";

  final List<AddWalletListEntity> tokenEntities = [];

  final bool isDesktop = Util.isDesktop;

  List<AddWalletListEntity> filter(
    String text,
    List<AddWalletListEntity> entities,
  ) {
    final _entities = [...entities];
    if (text.isNotEmpty) {
      final lowercaseTerm = text.toLowerCase();
      _entities.retainWhere(
        (e) =>
            e.ticker.toLowerCase().contains(lowercaseTerm) ||
            e.name.toLowerCase().contains(lowercaseTerm) ||
            (e is EthTokenEntity &&
                e.token.contractAddress.toLowerCase().contains(lowercaseTerm)),
      );
    }

    return _entities;
  }

  @override
  void initState() {
    _searchFieldController = TextEditingController();
    _searchFocusNode = FocusNode();

    tokenEntities.addAll(DefaultTokens.list.map((e) => EthTokenEntity(e)));
    tokenEntities.sort((a, b) => a.name.compareTo(b.name));

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

    if (isDesktop) {
      return DesktopScaffold(
        appBar: const DesktopAppBar(
          isCompactHeight: false,
          leading: AppBarBackButton(),
          trailing: ExitToMyStackButton(),
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
                        child: AddWalletEntityList(
                          entities: filter(_searchTerm, tokenEntities),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                    child: TextField(
                      autofocus: isDesktop,
                      autocorrect: !isDesktop,
                      enableSuggestions: !isDesktop,
                      controller: _searchFieldController,
                      focusNode: _searchFocusNode,
                      onChanged: (value) => setState(() => _searchTerm = value),
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
                        suffixIcon: _searchFieldController.text.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(right: 0),
                                child: UnconstrainedBox(
                                  child: Row(
                                    children: [
                                      TextFieldIconButton(
                                        child: const XIcon(),
                                        onTap: () async {
                                          setState(() {
                                            _searchFieldController.text = "";
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
                  const SizedBox(
                    height: 10,
                  ),
                  Expanded(
                    child: AddWalletEntityList(
                      entities: filter(_searchTerm, tokenEntities),
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
