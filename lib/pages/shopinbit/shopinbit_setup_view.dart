import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/shopinbit/shopinbit_order_model.dart';
import '../../notifications/show_flush_bar.dart';
import '../../services/shopinbit/shopinbit_service.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/constants.dart';
import '../../utilities/text_styles.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_text_field.dart';
import 'shopinbit_step_2.dart';

class ShopInBitSetupView extends StatefulWidget {
  const ShopInBitSetupView({super.key, required this.model});

  static const String routeName = "/shopInBitSetup";

  final ShopInBitOrderModel model;

  @override
  State<ShopInBitSetupView> createState() => _ShopInBitSetupViewState();
}

class _ShopInBitSetupViewState extends State<ShopInBitSetupView> {
  late final Future<String> _keyFuture;
  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;

  bool get _canContinue => _nameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _keyFuture = ShopInBitService.instance.ensureCustomerKey();
    final existingName = ShopInBitService.instance.loadDisplayName();
    _nameController = TextEditingController(text: existingName ?? '');
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

  Future<void> _completeSetup() async {
    final name = _nameController.text.trim();
    widget.model.displayName = name;
    await ShopInBitService.instance.setDisplayName(name);
    await ShopInBitService.instance.setSetupComplete(true);

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacementNamed(ShopInBitStep2.routeName, arguments: widget.model);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Your ShopinBit Customer Key",
                            style: STextStyles.pageTitleH1(context),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "This is your ShopinBit customer key. Save it "
                            "somewhere safe: you'll need it to recover "
                            "your ShopinBit account on a new device.",
                            style: STextStyles.itemSubtitle(context),
                          ),
                          const SizedBox(height: 16),
                          FutureBuilder<String>(
                            future: _keyFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState !=
                                  ConnectionState.done) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return Text(
                                  "Failed to generate key. Please try again.",
                                  style: STextStyles.itemSubtitle(context)
                                      .copyWith(
                                        color: Theme.of(
                                          context,
                                        ).extension<StackColors>()!.textError,
                                      ),
                                );
                              }
                              final key = snapshot.data!;
                              return RoundedWhiteContainer(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: SelectableText(
                                        key,
                                        style: STextStyles.itemSubtitle12(
                                          context,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 20),
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(text: key),
                                        );
                                        showFloatingFlushBar(
                                          type: FlushBarType.info,
                                          message: "Copied to clipboard!",
                                          context: context,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          Text(
                            "Set a Display Name to use with ShopinBit staff",
                            style: STextStyles.smallMed12(context),
                          ),
                          const SizedBox(height: 8),
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
                              style: STextStyles.field(context),
                              decoration:
                                  standardInputDecoration(
                                    "Display name",
                                    _nameFocusNode,
                                    context,
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
                            label: "Complete Setup",
                            enabled: _canContinue,
                            onPressed: _canContinue ? _completeSetup : null,
                          ),
                        ],
                      ),
                    ),
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
