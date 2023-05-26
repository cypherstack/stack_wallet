import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/backup_frequency_type.dart';
import 'package:stackwallet/utilities/text_styles.dart';

class BackupFrequencyTypeSelectSheet extends ConsumerWidget {
  const BackupFrequencyTypeSelectSheet({
    Key? key,
  }) : super(key: key);

  String prettyFrequencyType(BackupFrequencyType type) {
    switch (type) {
      case BackupFrequencyType.everyTenMinutes:
        return "Every 10 minutes";
      case BackupFrequencyType.everyAppStart:
        return "Every app start";
      case BackupFrequencyType.afterClosingAWallet:
        return "After closing a cryptocurrency wallet";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context)
            .pop(ref.read(prefsChangeNotifierProvider).backupFrequencyType);
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).extension<StackColors>()!.popupBG,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 10,
            bottom: 0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textFieldDefaultBG,
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                  ),
                  width: 60,
                  height: 4,
                ),
              ),
              const SizedBox(
                height: 36,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Auto Backup frequency",
                    style: STextStyles.pageTitleH2(context),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  for (int i = 0; i < BackupFrequencyType.values.length; i++)
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            final state = ref
                                .read(prefsChangeNotifierProvider)
                                .backupFrequencyType;
                            if (state != BackupFrequencyType.values[i]) {
                              ref
                                      .read(prefsChangeNotifierProvider)
                                      .backupFrequencyType =
                                  BackupFrequencyType.values[i];
                            }

                            Navigator.of(context).pop();
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Radio(
                                    activeColor: Theme.of(context)
                                        .extension<StackColors>()!
                                        .radioButtonIconEnabled,
                                    value: BackupFrequencyType.values[i],
                                    groupValue: ref.watch(
                                        prefsChangeNotifierProvider.select(
                                            (value) =>
                                                value.backupFrequencyType)),
                                    onChanged: (x) {
                                      ref
                                              .read(prefsChangeNotifierProvider)
                                              .backupFrequencyType =
                                          BackupFrequencyType.values[i];
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                                Flexible(
                                  child: Column(
                                    children: [
                                      Text(
                                        prettyFrequencyType(
                                            BackupFrequencyType.values[i]),
                                        style: STextStyles.titleBold12(context),
                                        textAlign: TextAlign.left,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                      ],
                    ),
                  const SizedBox(
                    height: 24,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
