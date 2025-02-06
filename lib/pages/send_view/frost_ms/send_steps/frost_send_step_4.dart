import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../frost_route_generator.dart';
import '../../../../pages_desktop_specific/my_stack_view/my_stack_view.dart';
import '../../../../providers/frost_wallet/frost_wallet_providers.dart';
import '../../../../providers/global/wallets_provider.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/amount/amount_formatter.dart';
import '../../../../utilities/assets.dart';
import '../../../../utilities/logger.dart';
import '../../../../utilities/show_loading.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../utilities/util.dart';
import '../../../../wallets/crypto_currency/crypto_currency.dart';
import '../../../../wallets/wallet/impl/bitcoin_frost_wallet.dart';
import '../../../../widgets/custom_buttons/simple_copy_button.dart';
import '../../../../widgets/desktop/primary_button.dart';
import '../../../../widgets/detail_item.dart';
import '../../../../widgets/expandable.dart';
import '../../../../widgets/stack_dialog.dart';
import '../../../wallet_view/transaction_views/tx_v2/transaction_v2_details_view.dart';
import '../../../wallet_view/wallet_view.dart';

class FrostSendStep4 extends ConsumerStatefulWidget {
  const FrostSendStep4({super.key});

  static const String routeName = "/FrostSendStep4";
  static const String title = "Preview transaction";

  @override
  ConsumerState<FrostSendStep4> createState() => _FrostSendStep4State();
}

class _FrostSendStep4State extends ConsumerState<FrostSendStep4> {
  final List<bool> _expandedStates = [];

  bool _broadcastLock = false;

  late final CryptoCurrency cryptoCurrency;

  @override
  void initState() {
    final wallet = ref.read(pWallets).getWallet(
          ref.read(pFrostScaffoldArgs)!.walletId!,
        ) as BitcoinFrostWallet;

    cryptoCurrency = wallet.cryptoCurrency;

    for (final _ in ref.read(pFrostTxData)!.recipients!) {
      _expandedStates.add(false);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final signerNames = ref.watch(pFrostTxData)!.frostSigners!;
    final recipients = ref.watch(pFrostTxData)!.recipients!;

    final String signers;
    if (signerNames.length > 1) {
      signers = signerNames
          .sublist(1)
          .fold(signerNames.first, (pv, e) => pv += ", $e");
    } else {
      signers = signerNames.first;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (kDebugMode)
            DetailItem(
              title: "Tx hex (debug mode only)",
              detail: ref.watch(pFrostTxData)!.raw!,
              button: Util.isDesktop
                  ? IconCopyButton(
                      data: ref.watch(pFrostTxData)!.raw!,
                    )
                  : SimpleCopyButton(
                      data: ref.watch(pFrostTxData)!.raw!,
                    ),
            ),
          if (kDebugMode)
            const SizedBox(
              height: 12,
            ),
          Text(
            "Send ${cryptoCurrency.ticker}",
            style: STextStyles.w600_20(context),
          ),
          const SizedBox(
            height: 12,
          ),
          recipients.length == 1
              ? _Recipient(
                  address: recipients[0].address,
                  amount: ref
                      .watch(pAmountFormatter(cryptoCurrency))
                      .format(recipients[0].amount),
                )
              : Column(
                  children: [
                    for (int i = 0; i < recipients.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Expandable(
                          onExpandChanged: (state) {
                            setState(() {
                              _expandedStates[i] =
                                  state == ExpandableState.expanded;
                            });
                          },
                          header: Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Recipient ${i + 1}",
                                  style: STextStyles.itemSubtitle(context),
                                ),
                                SvgPicture.asset(
                                  _expandedStates[i]
                                      ? Assets.svg.chevronUp
                                      : Assets.svg.chevronDown,
                                  width: 12,
                                  height: 6,
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textSubtitle1,
                                ),
                              ],
                            ),
                          ),
                          body: _Recipient(
                            address: recipients[i].address,
                            amount: ref
                                .watch(pAmountFormatter(cryptoCurrency))
                                .format(recipients[i].amount),
                          ),
                        ),
                      ),
                  ],
                ),
          const SizedBox(
            height: 12,
          ),
          DetailItem(
            title: "Transaction fee",
            detail: ref
                .watch(pAmountFormatter(cryptoCurrency))
                .format(ref.watch(pFrostTxData)!.fee!),
            horizontal: true,
          ),
          const SizedBox(
            height: 12,
          ),
          DetailItem(
            title: "Total",
            detail: ref.watch(pAmountFormatter(cryptoCurrency)).format(
                  ref.watch(pFrostTxData)!.fee! +
                      recipients.map((e) => e.amount).reduce((v, e) => v += e),
                ),
            horizontal: true,
          ),
          const SizedBox(
            height: 12,
          ),
          DetailItem(
            title: "Note",
            detail: ref.watch(pFrostTxData)!.note ?? "",
          ),
          const SizedBox(
            height: 12,
          ),
          DetailItem(
            title: "Signers",
            detail: signers,
          ),
          const SizedBox(
            height: 12,
          ),
          if (!Util.isDesktop) const Spacer(),
          const SizedBox(
            height: 12,
          ),
          PrimaryButton(
            label: "Approve transaction",
            onPressed: () async {
              if (_broadcastLock) {
                return;
              }
              _broadcastLock = true;

              try {
                Exception? ex;
                final txData = await showLoading(
                  whileFuture: ref
                      .read(pWallets)
                      .getWallet(
                        ref.read(pFrostScaffoldArgs)!.walletId!,
                      )
                      .confirmSend(
                        txData: ref.read(pFrostTxData)!,
                      ),
                  context: context,
                  message: "Broadcasting transaction to network",
                  rootNavigator: true, // used to pop using root nav
                  onException: (e) {
                    ex = e;
                  },
                );

                if (ex != null) {
                  throw ex!;
                }

                if (context.mounted) {
                  if (txData != null) {
                    ref.read(pFrostScaffoldCanPopDesktop.notifier).state = true;
                    ref.read(pFrostTxData.state).state = txData;
                    ref.read(pFrostScaffoldArgs)!.parentNav.popUntil(
                          ModalRoute.withName(
                            Util.isDesktop
                                ? MyStackView.routeName
                                : WalletView.routeName,
                          ),
                        );
                  }
                }
              } catch (e, s) {
                Logging.instance.f("$e\n$s", error: e, stackTrace: s,);
                if (context.mounted) {
                  return await showDialog<void>(
                    context: context,
                    builder: (_) => StackOkDialog(
                      title: "Broadcast error",
                      message: e.toString(),
                      desktopPopRootNavigator: Util.isDesktop,
                      onOkPressed:
                          Navigator.of(context, rootNavigator: true).pop,
                    ),
                  );
                }
              } finally {
                _broadcastLock = false;
              }
            },
          ),
        ],
      ),
    );
  }
}

class _Recipient extends StatelessWidget {
  const _Recipient({
    super.key,
    required this.address,
    required this.amount,
  });

  final String address;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DetailItem(
          title: "Address",
          detail: address,
        ),
        const SizedBox(
          height: 6,
        ),
        DetailItem(
          title: "Amount",
          detail: amount,
          horizontal: true,
        ),
      ],
    );
  }
}
