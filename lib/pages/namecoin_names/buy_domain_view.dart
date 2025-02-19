import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:namecoin/namecoin.dart';

import '../../../providers/providers.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/util.dart';
import '../../../wallets/models/name_op_state.dart';
import '../../../wallets/models/tx_data.dart';
import '../../../wallets/wallet/impl/namecoin_wallet.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/stack_dialog.dart';
import '../../models/namecoin_dns/dns_a_record_address_type.dart';
import '../../models/namecoin_dns/dns_record.dart';
import '../../models/namecoin_dns/dns_record_type.dart';
import '../../route_generator.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/amount/amount_formatter.dart';
import '../../utilities/text_styles.dart';
import '../../wallets/isar/providers/wallet_info_provider.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/custom_buttons/blue_text_button.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/dialogs/s_dialog.dart';
import '../../widgets/rounded_white_container.dart';
import 'add_dns_record/add_dns_step_1.dart';
import 'confirm_name_transaction_view.dart';

class BuyDomainView extends ConsumerStatefulWidget {
  const BuyDomainView({
    super.key,
    required this.walletId,
    required this.domainName,
  });

  final String walletId;
  final String domainName;

  static const routeName = "/buyDomainView";

  @override
  ConsumerState<BuyDomainView> createState() => _BuyDomainWidgetState();
}

class _BuyDomainWidgetState extends ConsumerState<BuyDomainView> {
  bool _settingsHidden = true;
  final List<DNSRecord> _dnsRecords = [];

  String _getFormattedDNSRecords() {
    if (_dnsRecords.isEmpty) return "";

    return DNSRecord.merge(_dnsRecords);
  }

  bool _preRegLock = false;
  Future<void> _preRegister() async {
    if (_preRegLock) return;
    _preRegLock = true;
    try {
      final wallet =
          ref.read(pWallets).getWallet(widget.walletId) as NamecoinWallet;
      final myAddress = await wallet.getCurrentReceivingAddress();
      if (myAddress == null) {
        throw Exception("No receiving address found");
      }

      final value = _getFormattedDNSRecords();

      Logging.instance.f(value);

      // get address private key for deterministic salt
      final pk = await wallet.getPrivateKey(myAddress);

      String formattedName = widget.domainName;
      if (!formattedName.startsWith("d/")) {
        formattedName = "d/$formattedName";
      }
      if (formattedName.endsWith(".bit")) {
        formattedName.split(".bit").first;
      }

      final data = scriptNameNew(formattedName, pk.data);

      TxData txData = TxData(
        opNameState: NameOpState(
          name: formattedName,
          saltHex: data.$2,
          commitment: data.$3,
          value: value,
          nameScriptHex: data.$1,
          type: OpName.nameNew,
          outputPosition: -1, //currently unknown, updated later
        ),
        feeRateType: kNameTxDefaultFeeRate, // TODO: make configurable?
        recipients: [
          (
            address: myAddress.value,
            isChange: false,
            amount: Amount(
              rawValue: BigInt.from(kNameNewAmountSats),
              fractionDigits: wallet.cryptoCurrency.fractionDigits,
            ),
          ),
        ],
      );

      txData = await wallet.prepareNameSend(txData: txData);

      if (mounted) {
        if (Util.isDesktop) {
          await showDialog<void>(
            context: context,
            builder: (context) => SDialog(
              child: SizedBox(
                width: 580,
                child: ConfirmNameTransactionView(
                  txData: txData,
                  walletId: wallet.walletId,
                ),
              ),
            ),
          );
        } else {
          await Navigator.of(context).pushNamed(
            ConfirmNameTransactionView.routeName,
            arguments: (txData, wallet.walletId),
          );
        }
      }
    } catch (e, s) {
      Logging.instance.e("_preRegister failed", error: e, stackTrace: s);

      String err = e.toString();
      if (err.startsWith("Exception: ")) {
        err = err.replaceFirst("Exception: ", "");
      }

      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => StackOkDialog(
            title: "Add DNS record failed",
            message: err,
            desktopPopRootNavigator: Util.isDesktop,
            maxWidth: Util.isDesktop ? 600 : null,
          ),
        );
      }
    } finally {
      _preRegLock = false;
    }
  }

  bool _addLock = false;
  Future<void> _addRecord() async {
    if (_addLock) return;
    _addLock = true;
    try {
      final value = await showDialog<DNSRecord?>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Navigator(
            onGenerateRoute: (settings) {
              return RouteGenerator.getRoute(
                builder: (context) {
                  return Util.isDesktop
                      ? SDialog(
                          child: SizedBox(
                            width: 580,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 32,
                                      ),
                                      child: Text(
                                        "Add DNS record",
                                        style: STextStyles.desktopH3(context),
                                      ),
                                    ),
                                    DesktopDialogCloseButton(
                                      onPressedOverride: () {
                                        Navigator.of(context,
                                                rootNavigator: true)
                                            .pop();
                                      },
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 32),
                                  child: AddDnsStep1(),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const StackDialogBase(
                          child: AddDnsStep1(),
                        );
                },
              );
            },
          );
        },
      );

      if (mounted && value != null) {
        setState(() {
          _dnsRecords.add(value);
        });
      }
    } catch (e, s) {
      Logging.instance.e("Add DNS record failed", error: e, stackTrace: s);

      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => StackOkDialog(
            title: "Add DNS record failed",
            desktopPopRootNavigator: Util.isDesktop,
            maxWidth: Util.isDesktop ? 600 : null,
          ),
        );
      }
    } finally {
      _addLock = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final coin = ref.watch(pWalletCoin(widget.walletId));
    return ConditionalParent(
      condition: !Util.isDesktop,
      builder: (child) {
        return Background(
          child: Scaffold(
            appBar: AppBar(
              leading: const AppBarBackButton(),
              titleSpacing: 0,
              title: Text(
                "Buy domain",
                style: STextStyles.navBarTitle(context),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: child,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: Util.isDesktop
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.stretch,
        children: [
          if (!Util.isDesktop)
            Text(
              "Buy domain",
              style: Util.isDesktop
                  ? STextStyles.desktopH3(context)
                  : STextStyles.pageTitleH2(context),
            ),
          SizedBox(
            height: Util.isDesktop ? 24 : 16,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Name registration will take approximately 2 to 4 hours.",
                style: Util.isDesktop
                    ? STextStyles.w500_14(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textDark3,
                      )
                    : STextStyles.w500_12(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textDark3,
                      ),
              ),
            ],
          ),
          SizedBox(
            height: Util.isDesktop ? 24 : 16,
          ),
          RoundedWhiteContainer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Domain name",
                  style: Util.isDesktop
                      ? STextStyles.w500_14(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .infoItemLabel,
                        )
                      : STextStyles.w500_12(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .infoItemLabel,
                        ),
                ),
                Text(
                  "${widget.domainName.substring(2)}.bit",
                  style: Util.isDesktop
                      ? STextStyles.w500_14(context)
                      : STextStyles.w500_12(context),
                ),
              ],
            ),
          ),
          SizedBox(
            height: Util.isDesktop ? 16 : 8,
          ),
          RoundedWhiteContainer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Amount",
                  style: Util.isDesktop
                      ? STextStyles.w500_14(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .infoItemLabel,
                        )
                      : STextStyles.w500_12(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .infoItemLabel,
                        ),
                ),
                Text(
                  ref.watch(pAmountFormatter(coin)).format(
                        Amount(
                          rawValue: BigInt.from(kNameNewAmountSats),
                          fractionDigits: coin.fractionDigits,
                        ),
                      ),
                  style: Util.isDesktop
                      ? STextStyles.w500_14(context)
                      : STextStyles.w500_12(context),
                ),
              ],
            ),
          ),
          SizedBox(
            height: Util.isDesktop ? 16 : 8,
          ),
          CustomTextButton(
            text: _settingsHidden ? "More settings" : "Hide settings",
            onTap: () {
              setState(() {
                _settingsHidden = !_settingsHidden;
              });
            },
          ),
          if (!_settingsHidden)
            SizedBox(
              height: Util.isDesktop ? 24 : 16,
            ),
          if (!_settingsHidden)
            if (_dnsRecords.isEmpty)
              RoundedWhiteContainer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Add DNS records to your domain name",
                      style: STextStyles.w500_12(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textSubtitle1,
                      ),
                    ),
                  ],
                ),
              ),
          if (!_settingsHidden)
            if (_dnsRecords.isNotEmpty)
              ListView(
                shrinkWrap: true,
                children: [
                  ..._dnsRecords.map(
                    (e) => DNSRecordCard(
                      key: Key(e.toString()),
                      record: e,
                      onRemoveTapped: () => setState(() {
                        _dnsRecords.remove(e);
                      }),
                    ),
                  ),
                ],
              ),
          if (!_settingsHidden)
            SizedBox(
              height: Util.isDesktop ? 16 : 8,
            ),
          if (!_settingsHidden)
            SecondaryButton(
              label: _dnsRecords.isEmpty
                  ? "Add DNS record"
                  : "Add another DNS record",
              // width: Util.isDesktop ? 160 : double.infinity,
              buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
              onPressed: _addRecord,
            ),
          SizedBox(
            height: Util.isDesktop ? 24 : 16,
          ),
          if (!Util.isDesktop) const Spacer(),
          PrimaryButton(
            label: "Buy",
            // width: Util.isDesktop ? 160 : double.infinity,
            buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
            onPressed: _preRegister,
          ),
          SizedBox(
            height: Util.isDesktop ? 32 : 16,
          ),
        ],
      ),
    );
  }
}

class DNSRecordCard extends StatelessWidget {
  const DNSRecordCard({
    super.key,
    required this.record,
    required this.onRemoveTapped,
  });

  final DNSRecord record;
  final VoidCallback onRemoveTapped;

  String get _extraInfo {
    if (record.type == DNSRecordType.A) {
      // TODO error handling
      return " - ${DNSAddressType.values.firstWhere((e) => e.key == record.data.keys.first).name}";
    }

    return "";
  }

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${record.type.name}$_extraInfo",
              ),
              CustomTextButton(
                text: "Remove",
                onTap: onRemoveTapped,
              ),
            ],
          ),
          Text(record.getValueString()),
        ],
      ),
    );
  }
}
