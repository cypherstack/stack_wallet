import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/drift/shared_db/shared_database.dart';
import '../../external_api_keys.dart';
import '../../services/shopinbit/shopinbit_api.dart';
import '../../services/shopinbit/shopinbit_service.dart';
import '../db/drift_provider.dart';

final pShopinBitService = Provider(
  (ref) => ShopInBitService(
    client: ShopInBitClient(
      accessKey: kShopInBitAccessKey,
      partnerSecret: kShopInBitPartnerSecret,
      sandbox: false,
    ),
    db: ref.watch(pSharedDrift),
  ),
);

/// The active customer key's settings row (or null if none yet).
final pShopInBitSettings = StreamProvider.autoDispose<ShopInBitSetting?>(
  (ref) => ref.watch(pSharedDrift).shopInBitSettingsDao.watchCurrentSettings(),
);

/// All tickets for the active customer key, newest first.
final pShopInBitTickets = StreamProvider.autoDispose<List<ShopInBitTicket>>((
  ref,
) async* {
  final db = ref.watch(pSharedDrift);
  final settings = await db.shopInBitSettingsDao.getCurrentSettings();
  if (settings == null) {
    yield const [];
    return;
  }
  yield* db.shopInBitTicketsDao.watchByCustomerKey(settings.customerKey);
});

final pShopInBitTicket = StreamProvider.autoDispose
    .family<ShopInBitTicket?, int>(
      (ref, apiTicketId) =>
          ref.watch(pSharedDrift).shopInBitTicketsDao.watchByApiId(apiTicketId),
    );
