mixin OrdinalsInterface {
  // late final String _walletId;
  // late final Coin _coin;
  // late final MainDB _db;
  //
  // void initOrdinalsInterface({
  //   required String walletId,
  //   required Coin coin,
  //   required MainDB db,
  // }) {
  //   _walletId = walletId;
  //   _coin = coin;
  //   _db = db;
  // }
  //
  // final LitescribeAPI litescribeAPI =
  //     LitescribeAPI(baseUrl: 'https://litescribe.io/api');
  //
  //
  //
  //
  //
  // // // check if an inscription is in a given <UTXO> output
  // // Future<bool> inscriptionInOutput(UTXO output) async {
  // //   if (output.address != null) {
  // //     var inscriptions =
  // //         await litescribeAPI.getInscriptionsByAddress("${output.address}");
  // //     if (inscriptions.isNotEmpty) {
  // //       return true;
  // //     } else {
  // //       return false;
  // //     }
  // //   } else {
  // //     throw UnimplementedError(
  // //         'TODO look up utxo without address. utxo->txid:output->address');
  // //   }
  // // }
  //
  // // check if an inscription is in a given <UTXO> output
  // Future<bool> inscriptionInAddress(String address) async {
  //   var inscriptions = await litescribeAPI.getInscriptionsByAddress(address);
  //   if (inscriptions.isNotEmpty) {
  //     return true;
  //   } else {
  //     return false;
  //   }
  // }
}
