import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/pages/exchange_view/exchange_form.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/step_row.dart';
import 'package:stackwallet/providers/exchange/exchange_form_state_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/services/exchange/exchange_data_loading_service.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_loading_overlay.dart';

class WalletInitiatedExchangeView extends ConsumerStatefulWidget {
  const WalletInitiatedExchangeView({
    Key? key,
    required this.walletId,
    required this.coin,
    this.contract,
  }) : super(key: key);

  static const String routeName = "/walletInitiatedExchange";

  final String walletId;
  final Coin coin;
  final EthContract? contract;

  @override
  ConsumerState<WalletInitiatedExchangeView> createState() =>
      _WalletInitiatedExchangeViewState();
}

class _WalletInitiatedExchangeViewState
    extends ConsumerState<WalletInitiatedExchangeView> {
  late final String walletId;
  late final Coin coin;

  bool _initialCachePopulationUnderway = false;

  @override
  void initState() {
    walletId = widget.walletId;
    coin = widget.coin;

    if (!ref.read(prefsChangeNotifierProvider).externalCalls) {
      if (ExchangeDataLoadingService.currentCacheVersion <
          ExchangeDataLoadingService.cacheVersion) {
        _initialCachePopulationUnderway = true;
        ExchangeDataLoadingService.instance.onLoadingComplete = () {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
            await ExchangeDataLoadingService.instance.setCurrenciesIfEmpty(
              ref.read(efCurrencyPairProvider),
              ref.read(efRateTypeProvider),
            );
            setState(() {
              _initialCachePopulationUnderway = false;
            });
          });
        };
      }
      ExchangeDataLoadingService.instance.loadAll();
    } else if (ExchangeDataLoadingService.instance.isLoading &&
        ExchangeDataLoadingService.currentCacheVersion <
            ExchangeDataLoadingService.cacheVersion) {
      _initialCachePopulationUnderway = true;
      ExchangeDataLoadingService.instance.onLoadingComplete = () {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
          await ExchangeDataLoadingService.instance.setCurrenciesIfEmpty(
            ref.read(efCurrencyPairProvider),
            ref.read(efRateTypeProvider),
          );
          setState(() {
            _initialCachePopulationUnderway = false;
          });
        });
      };
    }

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return ConditionalParent(
      condition: _initialCachePopulationUnderway,
      builder: (child) {
        return Stack(
          children: [
            child,
            Material(
              color: Theme.of(context)
                  .extension<StackColors>()!
                  .overlay
                  .withOpacity(0.6),
              child: const CustomLoadingOverlay(
                message: "Updating exchange data",
                subMessage: "This could take a few minutes",
                eventBus: null,
              ),
            )
          ],
        );
      },
      child: Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: AppBarBackButton(
              onPressed: () async {
                if (FocusScope.of(context).hasFocus) {
                  FocusScope.of(context).unfocus();
                  await Future<void>.delayed(const Duration(milliseconds: 75));
                }
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            title: Text(
              "Swap",
              style: STextStyles.navBarTitle(context),
            ),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final width = MediaQuery.of(context).size.width - 32;
              return Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 24,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            StepRow(
                              count: 4,
                              current: 0,
                              width: width,
                            ),
                            const SizedBox(
                              height: 14,
                            ),
                            Text(
                              "Exchange amount",
                              style: STextStyles.pageTitleH1(context),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                              "Network fees and other exchange charges are included in the rate.",
                              style: STextStyles.itemSubtitle(context),
                            ),
                            const SizedBox(
                              height: 24,
                            ),
                            ExchangeForm(
                              walletId: walletId,
                              coin: coin,
                              contract: widget.contract,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
