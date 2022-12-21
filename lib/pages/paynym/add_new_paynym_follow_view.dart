import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/paynym/paynym_account.dart';
import 'package:stackwallet/pages/paynym/subwidgets/featured_paynyms_widget.dart';
import 'package:stackwallet/pages/paynym/subwidgets/paynym_card.dart';
import 'package:stackwallet/providers/global/paynym_api_provider.dart';
import 'package:stackwallet/utilities/barcode_scanner_interface.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/clipboard_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/qrcode_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class AddNewPaynymFollowView extends ConsumerStatefulWidget {
  const AddNewPaynymFollowView({
    Key? key,
    required this.walletId,
    required this.nymAccount,
  }) : super(key: key);

  final String walletId;
  final PaynymAccount nymAccount;

  static const String routeName = "/addNewPaynymFollow";

  @override
  ConsumerState<AddNewPaynymFollowView> createState() =>
      _AddNewPaynymFollowViewState();
}

class _AddNewPaynymFollowViewState
    extends ConsumerState<AddNewPaynymFollowView> {
  late final TextEditingController _searchController;
  late final FocusNode searchFieldFocusNode;

  String _searchString = "";

  bool _didSearch = false;
  PaynymAccount? _searchResult;

  Future<void> _search() async {
    _didSearch = true;
    bool didPopLoading = false;
    unawaited(
      showDialog<void>(
        barrierDismissible: false,
        context: context,
        builder: (context) => const LoadingIndicator(
          width: 200,
        ),
      ).then((_) => didPopLoading = true),
    );

    final paynymAccount =
        await ref.read(paynymAPIProvider).nym(_searchString, true);

    if (mounted) {
      if (!didPopLoading) {
        Navigator.of(context).pop();
      }

      setState(() {
        _searchResult = paynymAccount;
      });
    }
  }

  @override
  void initState() {
    _searchController = TextEditingController();
    searchFieldFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    searchFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    final isDesktop = Util.isDesktop;

    return MasterScaffold(
      isDesktop: isDesktop,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        titleSpacing: 0,
        title: Text(
          "Add new",
          style: STextStyles.navBarTitle(context),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ConditionalParent(
        condition: !isDesktop,
        builder: (child) => SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: child,
                ),
              ),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 10,
              ),
              Text(
                "Featured PayNyms",
                style: STextStyles.sectionLabelMedium12(context),
              ),
              const SizedBox(
                height: 12,
              ),
              const FeaturedPaynymsWidget(),
              const SizedBox(
                height: 24,
              ),
              Text(
                "Add new",
                style: STextStyles.sectionLabelMedium12(context),
              ),
              const SizedBox(
                height: 12,
              ),
              ClipRRect(
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
                      ? STextStyles.desktopTextExtraSmall(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textFieldActiveText,
                          height: 1.8,
                        )
                      : STextStyles.field(context),
                  decoration: standardInputDecoration(
                    "Paste payment code",
                    searchFieldFocusNode,
                    context,
                    desktopMed: isDesktop,
                  ).copyWith(
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: UnconstrainedBox(
                        child: Row(
                          children: [
                            _searchController.text.isNotEmpty
                                ? TextFieldIconButton(
                                    child: const XIcon(),
                                    onTap: () async {
                                      _searchString = "";
                                      setState(() {
                                        _searchController.text = "";
                                      });
                                    },
                                  )
                                : TextFieldIconButton(
                                    key: const Key(
                                        "paynymPasteAddressFieldButtonKey"),
                                    onTap: () async {
                                      final ClipboardData? data =
                                          await Clipboard.getData(
                                              Clipboard.kTextPlain);
                                      if (data?.text != null &&
                                          data!.text!.isNotEmpty) {
                                        String content = data.text!.trim();
                                        if (content.contains("\n")) {
                                          content = content.substring(
                                            0,
                                            content.indexOf(
                                              "\n",
                                            ),
                                          );
                                        }

                                        _searchString = content;
                                        setState(() {
                                          _searchController.text = content;
                                          _searchController.selection =
                                              TextSelection.collapsed(
                                            offset: content.length,
                                          );
                                        });
                                      }
                                    },
                                    child: const ClipboardIcon(),
                                  ),
                            TextFieldIconButton(
                              key: const Key("paynymScanQrButtonKey"),
                              onTap: () async {
                                try {
                                  if (FocusScope.of(context).hasFocus) {
                                    FocusScope.of(context).unfocus();
                                    await Future<void>.delayed(
                                        const Duration(milliseconds: 75));
                                  }

                                  final qrResult =
                                      await const BarcodeScannerWrapper()
                                          .scan();

                                  final pCodeString = qrResult.rawContent;

                                  _searchString = pCodeString;

                                  setState(() {
                                    _searchController.text = pCodeString;
                                    _searchController.selection =
                                        TextSelection.collapsed(
                                      offset: pCodeString.length,
                                    );
                                  });
                                } catch (_) {
                                  // scan failed
                                }
                              },
                              child: const QrCodeIcon(),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              SecondaryButton(
                label: "Search",
                onPressed: _search,
              ),
              if (_didSearch)
                const SizedBox(
                  height: 20,
                ),
              if (_didSearch && _searchResult == null)
                RoundedWhiteContainer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Nothing found. Please check the payment code.",
                        style: STextStyles.label(context),
                      ),
                    ],
                  ),
                ),
              if (_didSearch && _searchResult != null)
                RoundedWhiteContainer(
                  padding: const EdgeInsets.all(0),
                  child: PaynymCard(
                    label: _searchResult!.nymName,
                    paymentCodeString: _searchResult!.codes.first.code,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
