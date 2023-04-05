import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/wallet_navigation_bar/wallet_navigation_bar.dart';

class WalletNavigationBarItemData {
  WalletNavigationBarItemData({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isMore = false,
    this.overrideText,
  });

  final Widget icon;
  final String? label;
  final VoidCallback? onTap;
  final bool isMore;
  final Widget? overrideText;
}

class WalletNavigationBarItem extends ConsumerWidget {
  const WalletNavigationBarItem({
    Key? key,
    required this.data,
    required this.disableDuration,
  }) : super(key: key);

  final WalletNavigationBarItemData data;
  final Duration disableDuration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: data.isMore || !ref.watch(walletNavBarMore.state).state
          ? data.onTap
          : null,
      child: RoundedContainer(
        color: Colors.transparent,
        padding: const EdgeInsets.all(0),
        radiusMultiplier: 2,
        child: AnimatedOpacity(
          opacity:
              data.isMore || !ref.watch(walletNavBarMore.state).state ? 1 : 0.2,
          duration: disableDuration,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 45,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Center(
                      child: data.icon,
                    ),
                  ),
                  const Spacer(),
                  data.overrideText ??
                      Text(
                        data.label ?? "",
                        style: STextStyles.buttonSmall(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .bottomNavText),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WalletNavigationBarMoreItem extends ConsumerWidget {
  const WalletNavigationBarMoreItem({
    Key? key,
    required this.data,
  }) : super(key: key);

  final WalletNavigationBarItemData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        data.onTap?.call();
        ref.read(walletNavBarMore.state).state = false;
      },
      child: Material(
        color: Colors.transparent,
        child: RoundedContainer(
          color: Theme.of(context).extension<StackColors>()!.bottomNavBack,
          radiusMultiplier: 100,
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 30,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  data.label ?? "",
                  textAlign: TextAlign.center,
                  style: STextStyles.buttonSmall(context),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              data.icon,
            ],
          ),
        ),
      ),
    );
  }
}
