import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar/isar.dart';
import 'package:namecoin/namecoin.dart';

import '../../models/isar/models/blockchain_data/utxo.dart';
import '../../providers/db/main_db_provider.dart';
import '../../providers/global/wallets_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/assets.dart';
import '../../utilities/enums/fee_rate_type_enum.dart';
import '../../utilities/logger.dart';
import '../../utilities/show_loading.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../wallets/models/name_op_state.dart';
import '../../wallets/models/tx_data.dart';
import '../../wallets/wallet/impl/namecoin_wallet.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_app_bar.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_scaffold.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_dialog.dart';
import 'confirm_name_transaction_view.dart';

class NamecoinNamesHomeView extends ConsumerStatefulWidget {
  const NamecoinNamesHomeView({
    super.key,
    required this.walletId,
  });

  final String walletId;

  static const String routeName = "/namecoinNamesHomeView";

  @override
  ConsumerState<NamecoinNamesHomeView> createState() =>
      _NamecoinNamesHomeViewState();
}

class _NamecoinNamesHomeViewState extends ConsumerState<NamecoinNamesHomeView> {
  String? lastAvailableName;

  NamecoinWallet get _wallet =>
      ref.read(pWallets).getWallet(widget.walletId) as NamecoinWallet;

  Future<void> _preRegister() async {
    final data = scriptNameNew(lastAvailableName!);

    // TODO: fill out properly
    TxData txData = TxData(
      opNameState: NameOpState(
        name: lastAvailableName!,
        saltHex: data.$2,
        commitment: data.$3,
        value: "test", // TODO: get from user for automatic reg later
        nameScriptHex: data.$1,
        type: OpName.nameNew,
      ),
      feeRateType: FeeRateType.slow, // TODO: make configurable?
      recipients: [
        (
          address: (await _wallet.getCurrentReceivingAddress())!.value,
          isChange: false,
          amount: Amount.fromDecimal(
            Decimal.parse("0.015"),
            fractionDigits: _wallet.cryptoCurrency.fractionDigits,
          ),
        ),
      ],
    );

    txData = await _wallet.prepareNameSend(txData: txData);

    Logging.instance.f("SALTY: ${txData.opNameState!.saltHex}");

    if (mounted) {
      if (Util.isDesktop) {
        await showDialog<void>(
          context: context,
          builder: (context) => DesktopDialog(
            maxHeight: MediaQuery.of(context).size.height - 64,
            maxWidth: 580,
            child: ConfirmNameTransactionView(
              txData: txData,
              walletId: _wallet.walletId,
            ),
          ),
        );
      } else {
        await Navigator.of(context).pushNamed(
          ConfirmNameTransactionView.routeName,
          arguments: (txData, _wallet.walletId),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    final isDesktop = Util.isDesktop;

    return MasterScaffold(
      isDesktop: isDesktop,
      appBar: isDesktop
          ? DesktopAppBar(
              isCompactHeight: true,
              background: Theme.of(context).extension<StackColors>()!.popupBG,
              leading: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 20,
                    ),
                    child: AppBarIconButton(
                      size: 32,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textFieldDefaultBG,
                      shadows: const [],
                      icon: SvgPicture.asset(
                        Assets.svg.arrowLeft,
                        width: 18,
                        height: 18,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .topNavIconPrimary,
                      ),
                      onPressed: Navigator.of(context).pop,
                    ),
                  ),
                  SvgPicture.asset(
                    Assets.svg.file,
                    width: 32,
                    height: 32,
                    color: Theme.of(context).extension<StackColors>()!.textDark,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    "Names",
                    style: STextStyles.desktopH3(context),
                  ),
                ],
              ),
            )
          : AppBar(
              leading: AppBarBackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              titleSpacing: 0,
              title: Text(
                "Names",
                style: STextStyles.navBarTitle(context),
                overflow: TextOverflow.ellipsis,
              ),
            ),
      body: ConditionalParent(
        condition: !isDesktop,
        builder: (child) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            LookupNameForm(
              walletId: widget.walletId,
              onNameAvailable: (name) {
                if (name != lastAvailableName) {
                  setState(() {
                    lastAvailableName = name;
                  });
                }
              },
            ),
            if (lastAvailableName != null)
              PrimaryButton(
                label: "Register $lastAvailableName",
                onPressed: _preRegister,
              ),
            const SizedBox(
              height: 32,
            ),
            Expanded(
              child: StreamBuilder(
                stream: ref.watch(
                  mainDBProvider.select(
                    (s) => s.isar.utxos
                        .where()
                        .walletIdEqualTo(widget.walletId)
                        .filter()
                        .otherDataIsNotNull()
                        .watch(fireImmediately: true),
                  ),
                ),
                builder: (context, snapshot) {
                  List<UTXO> list = [];
                  if (snapshot.hasData) {
                    list = snapshot.data!;
                  }

                  return ListView.separated(
                    itemCount: list.length,
                    itemBuilder: (context, index) => RoundedWhiteContainer(
                      child: Text(list[index].otherData!),
                    ),
                    separatorBuilder: (context, index) => const SizedBox(
                      height: 10,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LookupNameForm extends ConsumerStatefulWidget {
  const LookupNameForm({
    super.key,
    required this.walletId,
    this.onNameAvailable,
  });

  final String walletId;

  final void Function(String? name)? onNameAvailable;

  @override
  ConsumerState<LookupNameForm> createState() => _LookupNameFormState();
}

class _LookupNameFormState extends ConsumerState<LookupNameForm> {
  final nameController = TextEditingController();
  final nameFieldFocus = FocusNode();

  NamecoinWallet get _wallet =>
      ref.read(pWallets).getWallet(widget.walletId) as NamecoinWallet;

  bool _lookupLock = false;
  Future<void> _lookup() async {
    if (_lookupLock) return;
    _lookupLock = true;
    try {
      widget.onNameAvailable?.call(null);
      final result = await showLoading(
        whileFuture: _wallet.lookupName(nameController.text),
        context: context,
        message: "Looking up ${nameController.text}",
        onException: (e) => throw e,
        rootNavigator: Util.isDesktop,
        delay: const Duration(seconds: 2),
      );

      if (result?.available == true) {
        widget.onNameAvailable?.call(nameController.text);
      }

      Logging.instance.i("LOOKUP RESULT: $result");
    } catch (e, s) {
      widget.onNameAvailable?.call(null);
      Logging.instance.e("_lookup failed", error: e, stackTrace: s);

      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => StackOkDialog(
            title: "Name lookup failed",
            desktopPopRootNavigator: Util.isDesktop,
            maxWidth: Util.isDesktop ? 600 : null,
          ),
        );
      }
    } finally {
      _lookupLock = false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        nameFieldFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    nameFieldFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          Util.isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        TextField(
          textInputAction: TextInputAction.search,
          focusNode: nameFieldFocus,
          controller: nameController,
          onSubmitted: (_) {
            if (nameController.text.isNotEmpty) {
              _lookup();
            }
          },
          onChanged: (_) {
            // trigger look up button enabled/disabled state change
            setState(() {});
          },
        ),
        const SizedBox(
          height: 20,
        ),
        SecondaryButton(
          label: "Look up name",
          enabled: nameController.text.isNotEmpty,
          width: 160,
          buttonHeight: ButtonHeight.l,
          onPressed: _lookup,
        ),
      ],
    );
  }
}
