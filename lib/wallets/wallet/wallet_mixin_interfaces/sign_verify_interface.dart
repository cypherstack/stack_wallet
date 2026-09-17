import '../../../models/isar/models/blockchain_data/address.dart';

mixin SignVerifyInterface {
  Future<String> signMessage(String message, {required Address address});

  Future<bool> verifyMessage(
    String message, {
    required String address,
    required String signature,
  });
}
