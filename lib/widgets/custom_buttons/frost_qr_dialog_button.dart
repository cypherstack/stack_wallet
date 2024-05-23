import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../frost_route_generator.dart';
import '../../providers/frost_wallet/frost_wallet_providers.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../desktop/secondary_button.dart';
import '../dialogs/frost/frost_step_qr_dialog.dart';

class FrostQrDialogPopupButton extends ConsumerWidget {
  const FrostQrDialogPopupButton({super.key, required this.data});

  final String data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SecondaryButton(
      label: "View QR code",
      icon: SvgPicture.asset(
        Assets.svg.qrcode,
        colorFilter: ColorFilter.mode(
          Theme.of(context).extension<StackColors>()!.buttonTextSecondary,
          BlendMode.srcIn,
        ),
      ),
      onPressed: () async {
        await showDialog<void>(
          context: context,
          builder: (_) => FrostStepQrDialog(
            myName: ref.read(pFrostMyName)!,
            title: "Step "
                "${ref.read(pFrostCreateCurrentStep)}"
                " of "
                "${ref.read(pFrostScaffoldArgs)!.stepRoutes.length}"
                " - ${ref.read(pFrostScaffoldArgs)!.stepRoutes[ref.watch(pFrostCreateCurrentStep) - 1].title}",
            data: data,
          ),
        );
      },
    );
  }
}
