import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
import 'package:stackwallet/services/ethereum/ethereum_api.dart';
import 'package:stackwallet/utilities/show_loading.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class AddCustomTokenView extends ConsumerStatefulWidget {
  const AddCustomTokenView({
    Key? key,
  }) : super(key: key);

  static const routeName = "/addCustomToken";

  @override
  ConsumerState<AddCustomTokenView> createState() => _AddCustomTokenViewState();
}

class _AddCustomTokenViewState extends ConsumerState<AddCustomTokenView> {
  final isDesktop = Util.isDesktop;

  final contractController = TextEditingController();
  final nameController = TextEditingController();
  final symbolController = TextEditingController();
  final decimalsController = TextEditingController();

  bool enableSubFields = false;
  bool addTokenButtonEnabled = false;

  EthContract? currentToken;

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(
            top: 10,
            left: 16,
            right: 16,
            bottom: 16,
          ),
          child: Column(
            children: [
              Text(
                "Add custom ETH token",
                style: STextStyles.pageTitleH1(context),
              ),
              const SizedBox(
                height: 16,
              ),
              TextField(
                autocorrect: !isDesktop,
                enableSuggestions: !isDesktop,
                controller: contractController,
                style: STextStyles.field(context),
                decoration: InputDecoration(
                  hintText: "Contract address",
                  hintStyle: STextStyles.fieldLabel(context),
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              PrimaryButton(
                label: "Search",
                onPressed: () async {
                  final response = await showLoading(
                    whileFuture: EthereumAPI.getTokenContractInfoByAddress(
                        contractController.text),
                    context: context,
                    message: "Looking up contract",
                  );
                  currentToken = response.value;
                  if (currentToken != null) {
                    nameController.text = currentToken!.name;
                    symbolController.text = currentToken!.symbol;
                    decimalsController.text = currentToken!.decimals.toString();
                  } else {
                    nameController.text = "";
                    symbolController.text = "";
                    decimalsController.text = "";
                    if (mounted) {
                      unawaited(
                        showDialog<void>(
                          context: context,
                          builder: (context) => StackOkDialog(
                            title: "Failed to look up token",
                            message: response.exception?.message,
                          ),
                        ),
                      );
                    }
                  }
                  setState(() {
                    addTokenButtonEnabled = currentToken != null;
                  });
                },
              ),
              const SizedBox(
                height: 8,
              ),
              TextField(
                enabled: enableSubFields,
                autocorrect: !isDesktop,
                enableSuggestions: !isDesktop,
                controller: nameController,
                style: STextStyles.field(context),
                decoration: InputDecoration(
                  hintText: "Token name",
                  hintStyle: STextStyles.fieldLabel(context),
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              TextField(
                enabled: enableSubFields,
                autocorrect: !isDesktop,
                enableSuggestions: !isDesktop,
                controller: symbolController,
                style: STextStyles.field(context),
                decoration: InputDecoration(
                  hintText: "Ticker",
                  hintStyle: STextStyles.fieldLabel(context),
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              TextField(
                enabled: enableSubFields,
                autocorrect: !isDesktop,
                enableSuggestions: !isDesktop,
                controller: decimalsController,
                style: STextStyles.field(context),
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) =>
                      RegExp(r'^([0-9]*)$').hasMatch(newValue.text)
                          ? newValue
                          : oldValue),
                ],
                keyboardType: const TextInputType.numberWithOptions(
                  signed: false,
                  decimal: false,
                ),
                decoration: InputDecoration(
                  hintText: "Decimals",
                  hintStyle: STextStyles.fieldLabel(context),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              const Spacer(),
              PrimaryButton(
                label: "Add token",
                enabled: addTokenButtonEnabled,
                onPressed: () {
                  Navigator.of(context).pop(currentToken!);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
