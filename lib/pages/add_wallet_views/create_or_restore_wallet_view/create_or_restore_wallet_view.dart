import 'package:flutter/material.dart';
import 'package:stackwallet/pages/add_wallet_views/name_your_wallet_view/name_your_wallet_view.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/enums/add_wallet_type_enum.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:tuple/tuple.dart';

class CreateOrRestoreWalletView extends StatelessWidget {
  const CreateOrRestoreWalletView({
    Key? key,
    required this.coin,
  }) : super(key: key);

  static const routeName = "/createOrRestoreWallet";

  final Coin coin;

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return Scaffold(
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Container(
        color: CFColors.almostWhite,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(31),
                child: Image(
                  image: AssetImage(
                    Assets.png.imageFor(coin: coin),
                  ),
                  width: MediaQuery.of(context).size.width / 3,
                ),
              ),
              const Spacer(
                flex: 2,
              ),
              Text(
                "Add ${coin.prettyName} wallet",
                textAlign: TextAlign.center,
                style: STextStyles.pageTitleH1,
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                  "Create a new wallet or restore an existing wallet from seed.",
                  textAlign: TextAlign.center,
                  style: STextStyles.subtitle),
              const Spacer(
                flex: 5,
              ),
              TextButton(
                style: Theme.of(context).textButtonTheme.style?.copyWith(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        CFColors.stackAccent,
                      ),
                    ),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    NameYourWalletView.routeName,
                    arguments: Tuple2(
                      AddWalletType.New,
                      coin,
                    ),
                  );
                },
                child: Text(
                  "Create new wallet",
                  style: STextStyles.button,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              TextButton(
                style: Theme.of(context).textButtonTheme.style?.copyWith(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        CFColors.stackAccent.withOpacity(0.25),
                      ),
                    ),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    NameYourWalletView.routeName,
                    arguments: Tuple2(
                      AddWalletType.Restore,
                      coin,
                    ),
                  );
                },
                child: Text(
                  "Restore wallet",
                  style: STextStyles.button.copyWith(
                    color: CFColors.stackAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
