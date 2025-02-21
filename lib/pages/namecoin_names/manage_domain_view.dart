import 'package:flutter/material.dart';

import '../../models/isar/models/blockchain_data/utxo.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/constants.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/toggle.dart';
import 'sub_widgets/transfer_option_widget.dart';
import 'sub_widgets/update_option_widget.dart';

class ManageDomainView extends StatefulWidget {
  const ManageDomainView({
    super.key,
    required this.walletId,
    required this.utxo,
  });

  final String walletId;
  final UTXO utxo;

  static const routeName = "/manageDomainView";

  @override
  State<ManageDomainView> createState() => _ManageDomainViewState();
}

class _ManageDomainViewState extends State<ManageDomainView> {
  bool _onTransfer = true;

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: !Util.isDesktop,
      builder: (child) {
        return Background(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              leading: const AppBarBackButton(),
              titleSpacing: 0,
              title: Text(
                "Manage domain",
                style: STextStyles.navBarTitle(context),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: child,
              ),
            ),
          ),
        );
      },
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Toggle(
              key: UniqueKey(),
              onColor: Theme.of(context).extension<StackColors>()!.popupBG,
              offColor: Theme.of(context)
                  .extension<StackColors>()!
                  .textFieldDefaultBG,
              onText: "Transfer",
              offText: "Update",
              isOn: !_onTransfer,
              onValueChanged: (value) {
                FocusManager.instance.primaryFocus?.unfocus();
                setState(() {
                  _onTransfer = !value;
                });
              },
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          Expanded(
            child: IndexedStack(
              index: _onTransfer ? 0 : 1,
              children: [
                TransferOptionWidget(
                  walletId: widget.walletId,
                  utxo: widget.utxo,
                ),
                UpdateOptionWidget(
                  walletId: widget.walletId,
                  utxo: widget.utxo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
