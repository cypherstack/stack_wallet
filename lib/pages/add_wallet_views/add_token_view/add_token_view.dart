import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/ethereum/eth_token.dart';
import 'package:stackwallet/pages/add_wallet_views/add_token_view/add_custom_token_view.dart';
import 'package:stackwallet/pages/add_wallet_views/add_token_view/sub_widgets/add_token_list.dart';
import 'package:stackwallet/pages/add_wallet_views/add_token_view/sub_widgets/add_token_list_element.dart';
import 'package:stackwallet/pages/add_wallet_views/add_token_view/sub_widgets/add_token_text.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/exit_to_my_stack_button.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/coins/ethereum/ethereum_wallet.dart';
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
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class AddTokenView extends ConsumerStatefulWidget {
  const AddTokenView({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  static const routeName = "/addToken";

  @override
  ConsumerState<AddTokenView> createState() => _AddTokenViewState();
}

class _AddTokenViewState extends ConsumerState<AddTokenView> {
  late final TextEditingController _searchFieldController;
  late final FocusNode _searchFocusNode;

  String _searchTerm = "";

  final List<AddTokenListElementData> tokenEntities = [];

  final bool isDesktop = Util.isDesktop;

  List<AddTokenListElementData> filter(
    String text,
    List<AddTokenListElementData> entities,
  ) {
    final _entities = [...entities];
    if (text.isNotEmpty) {
      final lowercaseTerm = text.toLowerCase();
      _entities.retainWhere(
        (e) =>
            e.token.name.toLowerCase().contains(lowercaseTerm) ||
            e.token.symbol.toLowerCase().contains(lowercaseTerm) ||
            e.token.contractAddress.toLowerCase().contains(lowercaseTerm),
      );
    }

    return _entities;
  }

  Future<void> onNextPressed() async {
    final selectedTokens =
        tokenEntities.where((e) => e.selected).map((e) => e.token).toSet();

    final ethWallet = ref
        .read(walletsChangeNotifierProvider)
        .getManager(widget.walletId)
        .wallet as EthereumWallet;

    await ethWallet.addTokenContract(selectedTokens);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _addToken() async {
    final token = await Navigator.of(context).pushNamed(
      AddCustomTokenView.routeName,
      arguments: widget.walletId,
    );
    if (token is EthContractInfo) {
      setState(() {
        if (tokenEntities
            .where((e) => e.token.contractAddress == token.contractAddress)
            .isEmpty) {
          tokenEntities.add(AddTokenListElementData(token)..selected = true);
          tokenEntities.sort((a, b) => a.token.name.compareTo(b.token.name));
        }
      });
    }
  }

  @override
  void initState() {
    _searchFieldController = TextEditingController();
    _searchFocusNode = FocusNode();

    tokenEntities
        .addAll(DefaultTokens.list.map((e) => AddTokenListElementData(e)));
    tokenEntities.sort((a, b) => a.token.name.compareTo(b.token.name));

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
    final walletName = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(widget.walletId).walletName));

    if (isDesktop) {
      return DesktopScaffold(
        appBar: const DesktopAppBar(
          isCompactHeight: false,
          leading: AppBarBackButton(),
          trailing: ExitToMyStackButton(),
        ),
        body: Column(
          children: [
            AddTokenText(
              isDesktop: true,
              walletName: walletName,
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
                        child: AddTokenList(
                          walletId: widget.walletId,
                          items: filter(_searchTerm, tokenEntities),
                          addFunction: _addToken,
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
            SizedBox(
              height: 70,
              width: 480,
              child: PrimaryButton(
                label: "Next",
                onPressed: onNextPressed,
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
            actions: [
              AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AppBarIconButton(
                    icon: SvgPicture.asset(
                      Assets.svg.circlePlusFilled,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .topNavIconPrimary,
                    ),
                    onPressed: _addToken,
                  ),
                ),
              ),
            ],
          ),
          body: Container(
            color: Theme.of(context).extension<StackColors>()!.background,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AddTokenText(
                    isDesktop: false,
                    walletName: walletName,
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
                    child: AddTokenList(
                      walletId: widget.walletId,
                      items: filter(_searchTerm, tokenEntities),
                      addFunction: _addToken,
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  PrimaryButton(
                    label: "Next",
                    onPressed: onNextPressed,
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
