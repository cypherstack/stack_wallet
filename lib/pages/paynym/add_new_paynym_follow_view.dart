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
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/paynym_search_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/clipboard_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/qrcode_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class AddNewPaynymFollowView extends ConsumerStatefulWidget {
  const AddNewPaynymFollowView({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

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

  final isDesktop = Util.isDesktop;

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

    final paynymAccount = await ref.read(paynymAPIProvider).nym(_searchString);

    if (mounted) {
      if (!didPopLoading) {
        Navigator.of(context).pop();
      }

      setState(() {
        _searchResult = paynymAccount.value;
      });
    }
  }

  Future<void> _clear() async {
    _searchString = "";
    setState(() {
      _searchController.text = "";
    });
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
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
        _searchController.selection = TextSelection.collapsed(
          offset: content.length,
        );
      });
    }
  }

  Future<void> _scanQr() async {
    try {
      if (!isDesktop && FocusScope.of(context).hasFocus) {
        FocusScope.of(context).unfocus();
        await Future<void>.delayed(const Duration(milliseconds: 75));
      }

      final qrResult = await const BarcodeScannerWrapper().scan();

      final pCodeString = qrResult.rawContent;

      _searchString = pCodeString;

      setState(() {
        _searchController.text = pCodeString;
        _searchController.selection = TextSelection.collapsed(
          offset: pCodeString.length,
        );
      });
    } catch (_) {
      // scan failed
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

    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) => MasterScaffold(
        isDesktop: isDesktop,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          titleSpacing: 0,
          title: Text(
            "New follow",
            style: STextStyles.navBarTitle(context),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      child: ConditionalParent(
        condition: isDesktop,
        builder: (child) => DesktopDialog(
          maxWidth: 580,
          maxHeight: double.infinity,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Text(
                      "New follow",
                      style: STextStyles.desktopH3(context),
                    ),
                  ),
                  const DesktopDialogCloseButton(),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 32,
                  right: 32,
                  bottom: 32,
                ),
                child: child,
              ),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 10,
            ),
            Text(
              "Featured PayNyms",
              style: isDesktop
                  ? STextStyles.desktopTextExtraExtraSmall(context)
                  : STextStyles.sectionLabelMedium12(context),
            ),
            const SizedBox(
              height: 12,
            ),
            FeaturedPaynymsWidget(
              walletId: widget.walletId,
            ),
            const SizedBox(
              height: 24,
            ),
            Text(
              "Add new",
              style: isDesktop
                  ? STextStyles.desktopTextExtraExtraSmall(context)
                  : STextStyles.sectionLabelMedium12(context),
            ),
            const SizedBox(
              height: 12,
            ),
            if (isDesktop)
              Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        RoundedContainer(
                          padding: const EdgeInsets.all(0),
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textFieldDefaultBG,
                          height: 56,
                          child: Center(
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
                              style: STextStyles.desktopTextExtraExtraSmall(
                                      context)
                                  .copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textFieldActiveText,
                                // height: 1.8,
                              ),
                              decoration: InputDecoration(
                                hintText: "Paste payment code",
                                hoverColor: Colors.transparent,
                                fillColor: Colors.transparent,
                                contentPadding: const EdgeInsets.all(16),
                                hintStyle:
                                    STextStyles.desktopTextFieldLabel(context)
                                        .copyWith(
                                  fontSize: 14,
                                ),
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: UnconstrainedBox(
                                    child: Row(
                                      children: [
                                        _searchController.text.isNotEmpty
                                            ? TextFieldIconButton(
                                                onTap: _clear,
                                                child: RoundedContainer(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  color: Theme.of(context)
                                                      .extension<StackColors>()!
                                                      .buttonBackSecondary,
                                                  child: const XIcon(),
                                                ),
                                              )
                                            : TextFieldIconButton(
                                                key: const Key(
                                                    "paynymPasteAddressFieldButtonKey"),
                                                onTap: _paste,
                                                child: RoundedContainer(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  color: Theme.of(context)
                                                      .extension<StackColors>()!
                                                      .buttonBackSecondary,
                                                  child: const ClipboardIcon(),
                                                ),
                                              ),
                                        TextFieldIconButton(
                                          key: const Key(
                                              "paynymScanQrButtonKey"),
                                          onTap: _scanQr,
                                          child: RoundedContainer(
                                            padding: const EdgeInsets.all(8),
                                            color: Theme.of(context)
                                                .extension<StackColors>()!
                                                .buttonBackSecondary,
                                            child: const QrCodeIcon(),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  PaynymSearchButton(onPressed: _search),
                ],
              ),
            if (!isDesktop)
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
                  style: STextStyles.field(context),
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
                                    onTap: _clear,
                                    child: const XIcon(),
                                  )
                                : TextFieldIconButton(
                                    key: const Key(
                                        "paynymPasteAddressFieldButtonKey"),
                                    onTap: _paste,
                                    child: const ClipboardIcon(),
                                  ),
                            TextFieldIconButton(
                              key: const Key("paynymScanQrButtonKey"),
                              onTap: _scanQr,
                              child: const QrCodeIcon(),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (!isDesktop)
              const SizedBox(
                height: 12,
              ),
            if (!isDesktop)
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
                borderColor: isDesktop
                    ? Theme.of(context)
                        .extension<StackColors>()!
                        .backgroundAppBar
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Nothing found. Please check the payment code.",
                      style: isDesktop
                          ? STextStyles.desktopTextExtraExtraSmall(context)
                          : STextStyles.label(context),
                    ),
                  ],
                ),
              ),
            if (_didSearch && _searchResult != null)
              RoundedWhiteContainer(
                padding: const EdgeInsets.all(0),
                borderColor: isDesktop
                    ? Theme.of(context)
                        .extension<StackColors>()!
                        .backgroundAppBar
                    : null,
                child: PaynymCard(
                  key: UniqueKey(),
                  label: _searchResult!.nymName,
                  paymentCodeString: _searchResult!.nonSegwitPaymentCode.code,
                  walletId: widget.walletId,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
