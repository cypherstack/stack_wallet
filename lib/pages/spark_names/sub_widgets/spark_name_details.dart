import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../db/drift/database.dart';
import '../../../models/isar/models/isar_models.dart';
import '../../../providers/db/drift_provider.dart';
import '../../../providers/db/main_db_provider.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/isar/providers/wallet_info_provider.dart';
import '../../../widgets/background.dart';
import '../../../widgets/conditional_parent.dart';
import '../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../widgets/custom_buttons/simple_copy_button.dart';
import '../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/dialogs/s_dialog.dart';
import '../../../widgets/rounded_container.dart';
import '../../wallet_view/transaction_views/transaction_details_view.dart';
import '../buy_spark_name_view.dart';

class SparkNameDetailsView extends ConsumerStatefulWidget {
  const SparkNameDetailsView({
    super.key,
    required this.name,
    required this.walletId,
  });

  static const routeName = "/sparkNameDetails";

  final SparkName name;
  final String walletId;

  @override
  ConsumerState<SparkNameDetailsView> createState() =>
      _SparkNameDetailsViewState();
}

class _SparkNameDetailsViewState extends ConsumerState<SparkNameDetailsView> {
  // todo change arbitrary 1000 to something else?
  static const _remainingMagic = 1000;

  late Stream<SparkName?> _nameStream;
  late SparkName name;

  Stream<AddressLabel?>? _labelStream;
  AddressLabel? label;

  (String, Color, int) _getExpiry(int currentChainHeight, StackColors theme) {
    final String message;
    final Color color;

    final remaining = name.validUntil - currentChainHeight;

    if (widget.name.validUntil == -99999) {
      color = theme.accentColorYellow;
      message = "Pending";
    } else if (remaining <= 0) {
      color = theme.accentColorRed;
      message = "Expired";
    } else {
      message = "Expires in $remaining blocks";
      if (remaining < _remainingMagic) {
        color = theme.accentColorYellow;
      } else {
        color = theme.accentColorGreen;
      }
    }

    return (message, color, remaining);
  }

  bool _lock = false;

  Future<void> _renew() async {
    if (_lock) return;
    _lock = true;
    try {
      if (Util.isDesktop) {
        await showDialog<void>(
          context: context,
          builder:
              (context) => SDialog(
                child: SizedBox(
                  width: 580,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 32),
                            child: Text(
                              "Renew name",
                              style: STextStyles.desktopH3(context),
                            ),
                          ),
                          const DesktopDialogCloseButton(),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: BuySparkNameView(
                          walletId: widget.walletId,
                          name: name.name,
                          nameToRenew: name,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        );
      } else {
        await Navigator.of(context).pushNamed(
          BuySparkNameView.routeName,
          arguments: (
            walletId: widget.walletId,
            name: name.name,
            nameToRenew: name,
          ),
        );
      }
    } finally {
      _lock = false;
    }
  }

  @override
  void initState() {
    super.initState();
    name = widget.name;

    label = ref
        .read(mainDBProvider)
        .getAddressLabelSync(widget.walletId, name.address);

    if (label != null) {
      _labelStream = ref.read(mainDBProvider).watchAddressLabel(id: label!.id);
    }

    final db = ref.read(pDrift(widget.walletId));

    _nameStream =
        (db.select(db.sparkNames)
          ..where((e) => e.name.equals(name.name))).watchSingleOrNull();
  }

  @override
  Widget build(BuildContext context) {
    final currentHeight = ref.watch(pWalletChainHeight(widget.walletId));

    final (message, color, remaining) = _getExpiry(
      currentHeight,
      Theme.of(context).extension<StackColors>()!,
    );

    return ConditionalParent(
      condition: !Util.isDesktop,
      builder:
          (child) => Background(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                // Theme.of(context).extension<StackColors>()!.background,
                leading: const AppBarBackButton(),
                title: Text(
                  "Spark name details",
                  style: STextStyles.navBarTitle(context),
                ),
              ),
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
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
      child: ConditionalParent(
        condition: Util.isDesktop,
        builder: (child) {
          return SizedBox(
            width: 641,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Text(
                        "Spark name details",
                        style: STextStyles.desktopH3(context),
                      ),
                    ),
                    const DesktopDialogCloseButton(),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 32,
                    right: 32,
                    bottom: 32,
                    top: 10,
                  ),
                  child: RoundedContainer(
                    padding: EdgeInsets.zero,
                    color: Colors.transparent,
                    borderColor:
                        Theme.of(
                          context,
                        ).extension<StackColors>()!.textFieldDefaultBG,
                    child: child,
                  ),
                ),
              ],
            ),
          );
        },
        child: StreamBuilder(
          stream: _nameStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              name = snapshot.data!;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RoundedContainer(
                  padding: const EdgeInsets.all(12),
                  color:
                      Util.isDesktop
                          ? Colors.transparent
                          : Theme.of(context).extension<StackColors>()!.popupBG,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SelectableText(
                        name.name,
                        style:
                            Util.isDesktop
                                ? STextStyles.pageTitleH2(context)
                                : STextStyles.w500_14(context),
                      ),
                    ],
                  ),
                ),

                const _Div(),
                RoundedContainer(
                  padding:
                      Util.isDesktop
                          ? const EdgeInsets.all(16)
                          : const EdgeInsets.all(12),
                  color:
                      Util.isDesktop
                          ? Colors.transparent
                          : Theme.of(context).extension<StackColors>()!.popupBG,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Address",
                            style: STextStyles.w500_14(context).copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).extension<StackColors>()!.textSubtitle1,
                            ),
                          ),
                          Util.isDesktop
                              ? IconCopyButton(data: name.address)
                              : SimpleCopyButton(data: name.address),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        name.address,
                        style: STextStyles.w500_14(context),
                      ),
                    ],
                  ),
                ),
                if (_labelStream != null)
                  StreamBuilder(
                    stream: _labelStream!,
                    builder: (context, snapshot) {
                      label = snapshot.data;

                      return (label != null && label!.value.isNotEmpty)
                          ? Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Div(),

                              RoundedContainer(
                                padding:
                                    Util.isDesktop
                                        ? const EdgeInsets.all(16)
                                        : const EdgeInsets.all(12),
                                color:
                                    Util.isDesktop
                                        ? Colors.transparent
                                        : Theme.of(
                                          context,
                                        ).extension<StackColors>()!.popupBG,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Address label",
                                          style: STextStyles.w500_14(
                                            context,
                                          ).copyWith(
                                            color:
                                                Theme.of(context)
                                                    .extension<StackColors>()!
                                                    .textSubtitle1,
                                          ),
                                        ),
                                        Util.isDesktop
                                            ? IconCopyButton(data: label!.value)
                                            : SimpleCopyButton(
                                              data: label!.value,
                                            ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    SelectableText(
                                      label!.value,
                                      style: STextStyles.w500_14(context),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                          : const SizedBox(width: 0, height: 0);
                    },
                  ),

                const _Div(),
                RoundedContainer(
                  padding:
                      Util.isDesktop
                          ? const EdgeInsets.all(16)
                          : const EdgeInsets.all(12),
                  color:
                      Util.isDesktop
                          ? Colors.transparent
                          : Theme.of(context).extension<StackColors>()!.popupBG,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Expiry",
                            style: STextStyles.w500_14(context).copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).extension<StackColors>()!.textSubtitle1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            message,
                            style: STextStyles.w500_14(
                              context,
                            ).copyWith(color: color),
                          ),
                        ],
                      ),
                      if (remaining < _remainingMagic)
                        PrimaryButton(
                          label: "Renew",
                          buttonHeight:
                              Util.isDesktop ? ButtonHeight.xs : ButtonHeight.l,
                          onPressed: _renew,
                        ),
                    ],
                  ),
                ),
                const _Div(),
                RoundedContainer(
                  padding:
                      Util.isDesktop
                          ? const EdgeInsets.all(16)
                          : const EdgeInsets.all(12),
                  color:
                      Util.isDesktop
                          ? Colors.transparent
                          : Theme.of(context).extension<StackColors>()!.popupBG,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Additional info",
                        style: STextStyles.w500_14(context).copyWith(
                          color:
                              Theme.of(
                                context,
                              ).extension<StackColors>()!.textSubtitle1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        name.additionalInfo ?? "",
                        style: STextStyles.w500_14(context),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Div extends StatelessWidget {
  const _Div({super.key});

  @override
  Widget build(BuildContext context) {
    if (Util.isDesktop) {
      return Container(
        width: double.infinity,
        height: 1.0,
        color: Theme.of(context).extension<StackColors>()!.textFieldDefaultBG,
      );
    } else {
      return const SizedBox(height: 12);
    }
  }
}
