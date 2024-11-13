import '../../../models/keys/view_only_wallet_data.dart';
import '../../crypto_currency/interfaces/view_only_option_currency_interface.dart';
import '../wallet.dart';

mixin ViewOnlyOptionInterface<T extends ViewOnlyOptionCurrencyInterface>
    on Wallet<T> {
  ViewOnlyWalletType get viewOnlyType => info.viewOnlyWalletType!;

  bool get isViewOnly => info.isViewOnly;

  Future<void> recoverViewOnly();

  Future<ViewOnlyWalletData> getViewOnlyWalletData() async {
    if (!isViewOnly) {
      throw Exception("This is not a view only wallet");
    }

    final encoded = await secureStorageInterface.read(
      key: Wallet.getViewOnlyWalletDataSecStoreKey(walletId: walletId),
    );

    return ViewOnlyWalletData.fromJsonEncodedString(
      encoded!,
      walletId: walletId,
    );
  }
}
