import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/frost_route_generator.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class FrostErrorDialog extends ConsumerWidget {
  const FrostErrorDialog({
    super.key,
    required this.title,
    this.icon,
    this.message,
  });

  final String title;
  final Widget? icon;
  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: StackDialogBase(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: STextStyles.pageTitleH2(context),
                  ),
                ),
                icon != null ? icon! : Container(),
              ],
            ),
            if (message != null)
              const SizedBox(
                height: 8,
              ),
            if (message != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message!,
                    style: STextStyles.smallMed14(context),
                  ),
                ],
              ),
            const SizedBox(
              height: 8,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Process must be restarted",
                  style: STextStyles.smallMed14(context),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              children: [
                const Spacer(),
                const SizedBox(
                  width: 8,
                ),
                PrimaryButton(
                  label: "Ok",
                  onPressed: () {
                    ref.read(pFrostScaffoldCanPopDesktop.notifier).state = true;
                    ref.read(pFrostScaffoldArgs)!.parentNav.popUntil(
                          ModalRoute.withName(
                            ref.read(pFrostScaffoldArgs)!.callerRouteName,
                          ),
                        );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
