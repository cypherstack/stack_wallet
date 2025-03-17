import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/text_styles.dart';
import '../../../widgets/progress_bar.dart';

import '../providers/providers.dart';

class XelisTableProgress extends ConsumerWidget {
  const XelisTableProgress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsyncValue = ref.watch(xelisTableProgressProvider);
    
    return DefaultTextStyle(
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
        fontSize: 14,
      ),
      child: Center(
        child: progressAsyncValue.when(
          data: (progress) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).extension<StackColors>()!.popupBG,
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Generating Precomputed Tables...",
                  style: STextStyles.desktopH3(context).copyWith(
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "These tables are required for the fast decryption of private transactions. This is a one-time process upon the creation of your first Xelis wallet in Stack Wallet.",
                  style: STextStyles.subtitle600(context).copyWith(
                    fontSize: 14,
                    color: Theme.of(context).extension<StackColors>()!.textSubtitle1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  progress.currentStep.displayName,
                  style: STextStyles.titleBold12(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ProgressBar(
                  width: 200,
                  height: 8,
                  fillColor: const Color.fromARGB(255,2,255,207),
                  backgroundColor: Theme.of(context).extension<StackColors>()!.textFieldDefaultBG,
                  percent: progress.tableProgress ?? 0.0,
                ),
                const SizedBox(height: 4),
                Text(
                  "${((progress.tableProgress ?? 0.0) * 100).toStringAsFixed(1)}%",
                  style: STextStyles.label(context),
                ),
              ],
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}