import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications/show_flush_bar.dart';
import '../../providers/db/drift_provider.dart';
import '../../providers/global/shopin_bit_service_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/text_styles.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/icon_widgets/copy_icon.dart';
import '../../widgets/rounded_white_container.dart';
import 'shopinbit_step_2.dart';

class ShopInBitSetupView extends ConsumerStatefulWidget {
  const ShopInBitSetupView({super.key});

  static const String routeName = "/shopInBitSetup";

  @override
  ConsumerState<ShopInBitSetupView> createState() => _ShopInBitSetupViewState();
}

class _ShopInBitSetupViewState extends ConsumerState<ShopInBitSetupView> {
  late final Future<String> _keyFuture;
  String? _key;

  @override
  void initState() {
    super.initState();
    _keyFuture = ref.read(pShopinBitService).ensureCustomerKey();
    () async {
      final key = await _keyFuture;
      if (mounted) setState(() => _key = key);
    }();
  }

  Future<void> _completeSetup() async {
    final key = _key;
    if (key == null) return;
    await ref
        .read(pSharedDrift)
        .shopInBitSettingsDao
        .setSetupComplete(key, true);

    if (mounted) {
      await Navigator.of(
        context,
      ).pushReplacementNamed(ShopInBitStep2.routeName);
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
                                      icon: const CopyIcon(
                                        width: 20,
                                        height: 20,
                                      ),
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
                          const Spacer(),
                          PrimaryButton(
                            label: "Complete Setup",
                            enabled: _key != null,
                            onPressed: _key != null ? _completeSetup : null,
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
