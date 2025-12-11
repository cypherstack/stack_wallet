import '../../../models/isar/models/blockchain_data/address.dart';

mixin SignVerifyInterface {
  Future<String> signMessage(
    final String message, {
    required final Address address,
  });

  Future<bool> verifyMessage(
    final String message, {
    required final String address,
    required final String signature,
  });
}
