import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pages_desktop_specific/desktop_home_view.dart';
import '../../providers/global/locale_provider.dart';
import '../../providers/global/wallets_provider.dart';
import '../../route_generator.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/amount/amount_formatter.dart';
import '../../utilities/amount/amount_input_formatter.dart';
import '../../utilities/amount/amount_unit.dart';
import '../../utilities/enums/fee_rate_type_enum.dart';
import '../../utilities/logger.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../wallets/isar/providers/wallet_info_provider.dart';
import '../../wallets/models/tx_data.dart';
import '../../wallets/wallet/impl/salvium_wallet.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/stack_dialog.dart';
import '../../wl_gen/interfaces/cs_salvium_interface.dart';
import '../send_view/confirm_transaction_view.dart';
import '../send_view/sub_widgets/building_transaction_dialog.dart';

class SalviumCreateStakeView extends ConsumerStatefulWidget {
  const SalviumCreateStakeView({super.key, required this.walletId});

  final String walletId;

  static const routeName = "/salviumCreateStakeView";

  @override
  ConsumerState<SalviumCreateStakeView> createState() =>
      _SalviumCreateStakeViewState();
}

class _SalviumCreateStakeViewState
    extends ConsumerState<SalviumCreateStakeView> {
  final _amountController = TextEditingController();
  final _amountFocus = FocusNode();

  Amount? _amount;

  void _clearSendForm() {
    if (mounted) {
      _amountController.text = "";
    }
  }

  void _parseAmount(String string) {
    final cryptoAmount = ref
        .read(pAmountFormatter(ref.read(pWalletCoin(widget.walletId))))
        .tryParse(string);

    if (_amount != cryptoAmount) {
      setState(() {
        _amount = cryptoAmount;
      });
    }
  }

  bool _lock = false;
  Future<void> _previewPressed() async {
    if (_lock) return;
    _lock = true;

    try {
      bool wasCancelled = false;

      unawaited(
        showDialog<dynamic>(
          context: context,
          useSafeArea: false,
          barrierDismissible: false,
          builder: (context) {
            return ConditionalParent(
              condition: Util.isDesktop,
              builder: (child) => DesktopDialog(
                maxWidth: 400,
                maxHeight: double.infinity,
                child: Padding(padding: const EdgeInsets.all(32), child: child),
              ),
              child: BuildingTransactionDialog(
                coin: ref.read(pWalletCoin(widget.walletId)),
                isSpark: false,
                onCancel: () {
                  wasCancelled = true;
                  Navigator.of(context).pop();
                },
              ),
            );
          },
        ),
      );

      final wallet =
          ref.read(pWallets).getWallet(widget.walletId) as SalviumWallet;

      final address = csSalvium.getAddress(wallet.wallet!);

      final time = Future<dynamic>.delayed(const Duration(milliseconds: 2500));

      final txDataFuture = wallet.prepareSend(
        txData: TxData(
          recipients: [
            TxRecipient(
              address: address,
              amount: _amount!,
              isChange: false,
              addressType: wallet.cryptoCurrency.getAddressType(address)!,
            ),
          ],
          feeRateType: FeeRateType.average,
          note: "Stake transaction",
          salviumStakeTx: true,
        ),
      );

      final results = await Future.wait([txDataFuture, time]);
      final txData = results.first as TxData;

      if (!wasCancelled && mounted) {
        // pop building dialog
        Navigator.of(context, rootNavigator: Util.isDesktop).pop();

        if (Util.isDesktop) {
          unawaited(
            showDialog(
              context: context,
              builder: (context) => DesktopDialog(
                maxHeight: MediaQuery.of(context).size.height - 64,
                maxWidth: 580,
                child: ConfirmTransactionView(
                  txData: txData,
                  walletId: widget.walletId,
                  onSuccess: _clearSendForm,
                  routeOnSuccessName: DesktopHomeView.routeName,
                ),
              ),
            ),
          );
        } else {
          unawaited(
            Navigator.of(context).push(
              RouteGenerator.getRoute(
                shouldUseMaterialRoute: RouteGenerator.useMaterialPageRoute,
                builder: (_) => ConfirmTransactionView(
                  txData: txData,
                  walletId: widget.walletId,
                  onSuccess: _clearSendForm,
                ),
                settings: const RouteSettings(
                  name: ConfirmTransactionView.routeName,
                ),
              ),
            ),
          );
        }
      }
    } catch (e, s) {
      Logging.instance.e("Salvium stake preview: ", error: e, stackTrace: s);

      if (mounted) {
        // pop building dialog
        Navigator.of(context, rootNavigator: Util.isDesktop).pop();

        unawaited(
          showDialog<dynamic>(
            context: context,
            useSafeArea: false,
            barrierDismissible: true,
            builder: (context) {
              return Util.isDesktop
                  ? DesktopDialog(
                      maxWidth: 450,
                      maxHeight: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 32, bottom: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Transaction failed",
                                  style: STextStyles.desktopH3(context),
                                ),
                                const DesktopDialogCloseButton(),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.only(right: 32),
                              child: Text(
                                e.toString(),
                                textAlign: TextAlign.left,
                                style: STextStyles.desktopTextExtraExtraSmall(
                                  context,
                                ).copyWith(fontSize: 18),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Row(
                              children: [
                                Expanded(
                                  child: SecondaryButton(
                                    buttonHeight: ButtonHeight.l,
                                    label: "Ok",
                                    onPressed: () {
                                      Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).pop();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 32),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : StackDialog(
                      title: "Transaction failed",
                      message: e.toString(),
                      rightButton: TextButton(
                        style: Theme.of(context)
                            .extension<StackColors>()!
                            .getSecondaryEnabledButtonStyle(context),
                        child: Text(
                          "Ok",
                          style: STextStyles.button(context).copyWith(
                            color: Theme.of(
                              context,
                            ).extension<StackColors>()!.accentColorDark,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    );
            },
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
    _amountController.addListener(() {
      if (mounted) {
        _parseAmount(_amountController.text);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _amountFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coin = ref.watch(pWalletCoin(widget.walletId));
    final locale = ref.watch(
      localeServiceChangeNotifierProvider.select((s) => s.locale),
    );

    return ConditionalParent(
      condition: !Util.isDesktop,
      builder: (child) => Background(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            // Theme.of(context).extension<StackColors>()!.background,
            leading: const AppBarBackButton(),
            title: Text(
              "Stake transaction",
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Amount",
                style: STextStyles.desktopTextExtraSmall(context).copyWith(
                  color: Theme.of(
                    context,
                  ).extension<StackColors>()!.textFieldActiveSearchIconRight,
                ),
                textAlign: TextAlign.left,
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            autocorrect: Util.isDesktop ? false : true,
            enableSuggestions: Util.isDesktop ? false : true,
            style: STextStyles.smallMed14(context).copyWith(
              color: Theme.of(context).extension<StackColors>()!.textDark,
            ),
            key: const Key("amountStakingInputFieldCryptoTextFieldKey"),
            controller: _amountController,
            focusNode: _amountFocus,
            keyboardType: Util.isDesktop
                ? null
                : const TextInputType.numberWithOptions(
                    signed: false,
                    decimal: true,
                  ),
            textAlign: TextAlign.right,
            inputFormatters: [
              AmountInputFormatter(
                decimals: coin.fractionDigits,
                unit: ref.watch(pAmountUnit(coin)),
                locale: locale,
              ),
            ],
            decoration: InputDecoration(
              contentPadding: Util.isDesktop
                  ? const EdgeInsets.only(top: 22, right: 12, bottom: 22)
                  : const EdgeInsets.only(top: 12, right: 12),
              hintText: "0",
              hintStyle: Util.isDesktop
                  ? STextStyles.desktopTextExtraSmall(context).copyWith(
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.textFieldDefaultText,
                    )
                  : STextStyles.fieldLabel(context).copyWith(fontSize: 14),
              prefixIcon: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    ref.watch(pAmountUnit(coin)).unitForCoin(coin),
                    style: STextStyles.smallMed14(context).copyWith(
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.accentColorDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          if (!Util.isDesktop) const Spacer(),
          ConditionalParent(
            condition: Util.isDesktop,
            builder: (child) => Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [child],
            ),
            child: PrimaryButton(
              width: Util.isDesktop ? 200 : null,
              buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
              label: "Preview",
              onPressed: _amount == null ? null : _previewPressed,
              enabled: _amount != null,
            ),
          ),
          if (!Util.isDesktop) const SizedBox(height: 16),
        ],
      ),
    );
  }
}
