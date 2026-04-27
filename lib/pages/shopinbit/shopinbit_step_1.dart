import 'package:flutter/material.dart';

import '../../models/shopinbit/shopinbit_order_model.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/constants.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/stack_text_field.dart';
import '../exchange_view/sub_widgets/step_row.dart';
import 'shopinbit_step_2.dart';

class ShopInBitStep1 extends StatefulWidget {
  const ShopInBitStep1({super.key, required this.model});

  static const String routeName = "/shopInBitStep1";

  final ShopInBitOrderModel model;

  @override
  State<ShopInBitStep1> createState() => _ShopInBitStep1State();
}

class _ShopInBitStep1State extends State<ShopInBitStep1> {
  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;

  bool get _canContinue => _nameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.model.displayName);
    _nameFocusNode = FocusNode();

    _nameFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _continue() {
    widget.model.displayName = _nameController.text.trim();
    if (Util.isDesktop) {
      Navigator.of(context, rootNavigator: true).pop();
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ShopInBitStep2(model: widget.model),
      );
    } else {
      Navigator.of(
        context,
      ).pushNamed(ShopInBitStep2.routeName, arguments: widget.model);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isDesktop)
          StepRow(
            count: 4,
            current: 0,
            width: MediaQuery.of(context).size.width - 32,
          ),
        if (!isDesktop) const SizedBox(height: 14),
        Text(
          "Create your profile",
          style: isDesktop
              ? STextStyles.desktopH2(context)
              : STextStyles.pageTitleH1(context),
        ),
        SizedBox(height: isDesktop ? 16 : 8),
        Text(
          "Enter a display name to use with ShopinBit.",
          style: isDesktop
              ? STextStyles.desktopTextSmall(context)
              : STextStyles.itemSubtitle(context),
        ),
        SizedBox(height: isDesktop ? 32 : 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
          child: TextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) => setState(() {}),
            style: isDesktop
                ? STextStyles.desktopTextExtraSmall(context).copyWith(
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.textFieldActiveText,
                    height: 1.8,
                  )
                : STextStyles.field(context),
            decoration:
                standardInputDecoration(
                  "Display name",
                  _nameFocusNode,
                  context,
                  desktopMed: isDesktop,
                ).copyWith(
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
          ),
        ),
        const Spacer(),
        PrimaryButton(
          label: "Next",
          enabled: _canContinue,
          onPressed: _canContinue ? _continue : null,
        ),
      ],
    );

    if (isDesktop) {
      return DesktopDialog(
        maxWidth: 580,
        maxHeight: 400,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    "ShopinBit",
                    style: STextStyles.desktopH3(context),
                  ),
                ),
                const DesktopDialogCloseButton(),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                child: content,
              ),
            ),
          ],
        ),
      );
    }

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text("ShopinBit", style: STextStyles.navBarTitle(context)),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: IntrinsicHeight(child: content),
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
