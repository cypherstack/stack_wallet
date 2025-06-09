import 'package:isar/isar.dart';

import '../../../models/isar/models/isar_models.dart';
import '../../crypto_currency/interfaces/electrumx_currency_interface.dart';
import 'electrumx_interface.dart';

mixin MwebInterface<T extends ElectrumXCurrencyInterface>
    on ElectrumXInterface<T> {
  // TODO

  Future<Address?> getCurrentReceivingMwebAddress() async {
    return await mainDB.isar.addresses
        .where()
        .walletIdEqualTo(walletId)
        .filter()
        .typeEqualTo(AddressType.mweb)
        .sortByDerivationIndexDesc()
        .findFirst();
  }
}
