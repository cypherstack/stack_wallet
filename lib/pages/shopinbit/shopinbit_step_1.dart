import 'package:flutter/material.dart';

import '../../models/shopinbit/shopinbit_order_model.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/dialogs/s_dialog.dart';
import '../../widgets/textfields/adaptive_text_field.dart';
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

  bool _canContinue = false;

  void _continue() {
    widget.model.displayName = _nameController.text.trim();
    Navigator.of(
      context,
    ).pushNamed(ShopInBitStep2.routeName, arguments: widget.model);
  }

  @override
  void initState() {
    super.initState();
    _canContinue = widget.model.displayName.isNotEmpty;
    _nameController = TextEditingController(text: widget.model.displayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    return ConditionalParent(
      condition: isDesktop,
      builder: (child) => SDialog(
        child: SizedBox(
          width: 580,
          child: Column(
            mainAxisSize: .min,
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
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
      child: ConditionalParent(
        condition: !isDesktop,
        builder: (child) => Background(
          child: Scaffold(
            backgroundColor: Theme.of(
              context,
            ).extension<StackColors>()!.background,
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
                        child: IntrinsicHeight(child: child),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isDesktop)
              StepRow(
                count: 4,
                current: 0,
                width: MediaQuery.of(context).size.width - 32,
              ),
            const SizedBox(height: 14),
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
            AdaptiveTextField(
              labelText: "Display name",
              controller: _nameController,
              autocorrect: false,
              enableSuggestions: false,
              onChangedComprehensive: (value) {
                if (mounted && _canContinue != value.isNotEmpty) {
                  setState(() => _canContinue = value.isNotEmpty);
                }
              },
            ),
            isDesktop ? const SizedBox(height: 32) : const Spacer(),
            PrimaryButton(
              label: "Next",
              enabled: _canContinue,
              onPressed: _canContinue ? _continue : null,
            ),
            if (isDesktop) const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
