import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../models/mwc_transaction_method.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/text_styles.dart';
import '../../../widgets/rounded_white_container.dart';

class MwcTransactionMethodSelector extends ConsumerStatefulWidget {
  const MwcTransactionMethodSelector({
    super.key,
    required this.onMethodSelected,
    this.selectedMethod,
    this.addressText,
  });

  final void Function(TransactionMethod) onMethodSelected;
  final TransactionMethod? selectedMethod;
  final String? addressText;

  @override
  ConsumerState<MwcTransactionMethodSelector> createState() =>
      _MwcTransactionMethodSelectorState();
}

class _MwcTransactionMethodSelectorState
    extends ConsumerState<MwcTransactionMethodSelector> {
  TransactionMethod? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.selectedMethod;
  }

  void _selectMethod(TransactionMethod method) {
    setState(() {
      _selectedMethod = method;
    });
    widget.onMethodSelected(method);
  }

  Widget _buildMethodTile({
    required TransactionMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool available,
    String? unavailableReason,
  }) {
    final isSelected = _selectedMethod == method;
    final canSelect = available && widget.addressText?.isNotEmpty != true;

    return GestureDetector(
      onTap: canSelect ? () => _selectMethod(method) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context)
                      .extension<StackColors>()!
                      .infoItemIcons
                      .withValues(alpha: 0.1)
                  : Theme.of(context).extension<StackColors>()!.popupBG,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? Theme.of(context).extension<StackColors>()!.infoItemIcons
                    : Theme.of(context).extension<StackColors>()!.background,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      available
                          ? Theme.of(context)
                              .extension<StackColors>()!
                              .infoItemIcons
                              .withValues(alpha: 0.1)
                          : Theme.of(
                            context,
                          ).extension<StackColors>()!.textFieldDefaultBG,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color:
                      available
                          ? Theme.of(
                            context,
                          ).extension<StackColors>()!.infoItemIcons
                          : Theme.of(
                            context,
                          ).extension<StackColors>()!.textSubtitle2,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: STextStyles.w600_14(context).copyWith(
                        color:
                            available
                                ? Theme.of(
                                  context,
                                ).extension<StackColors>()!.textDark
                                : Theme.of(
                                  context,
                                ).extension<StackColors>()!.textSubtitle2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      available ? subtitle : (unavailableReason ?? subtitle),
                      style: STextStyles.w400_14(context).copyWith(
                        color:
                            Theme.of(
                              context,
                            ).extension<StackColors>()!.textSubtitle2,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(
                          context,
                        ).extension<StackColors>()!.infoItemIcons,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 12,
                    color: Theme.of(context).extension<StackColors>()!.popupBG,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAddressInput = widget.addressText?.isNotEmpty == true;

    return RoundedWhiteContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                Assets.svg.swap,
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).extension<StackColors>()!.infoItemIcons,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Text("Transaction Method", style: STextStyles.w600_14(context)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hasAddressInput
                ? "Method detected from address format"
                : "Choose how to send this transaction",
            style: STextStyles.w400_14(context).copyWith(
              color: Theme.of(context).extension<StackColors>()!.textSubtitle2,
            ),
          ),
          const SizedBox(height: 16),

          Column(
            children: [
              // Slatepack method.
              _buildMethodTile(
                method: TransactionMethod.slatepack,
                title: "Slatepack (Manual)",
                subtitle: "Copy/paste, QR codes, or files",
                icon: Icons.qr_code,
                available: true,
              ),
              const SizedBox(height: 12),

              // MWCMQS method.
              _buildMethodTile(
                method: TransactionMethod.mwcmqs,
                title: "MWCMQS (Automatic)",
                subtitle: "Direct messaging to recipient",
                icon: Icons.message,
                available: true,
                unavailableReason: "Requires MWCMQS address",
              ),
              const SizedBox(height: 12),

              // HTTP method.
              _buildMethodTile(
                method: TransactionMethod.http,
                title: "HTTP (Direct)",
                subtitle: "Direct connection to wallet",
                icon: Icons.http,
                available: true,
                unavailableReason: "Requires HTTP address",
              ),
            ],
          ),

          if (hasAddressInput) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .infoItemIcons
                    .withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color:
                        Theme.of(
                          context,
                        ).extension<StackColors>()!.infoItemIcons,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Transaction method is automatically detected from the address format. Clear the address field to manually select a method.",
                      style: STextStyles.w400_14(context).copyWith(
                        color:
                            Theme.of(
                              context,
                            ).extension<StackColors>()!.textSubtitle2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
