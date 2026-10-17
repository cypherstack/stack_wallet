import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:openalias/openalias.dart' show isOpenAliasApplication;
import 'package:stackwallet/app_config.dart';

void main() {
  test('every coin has no OpenAlias application or a valid one', () {
    for (final coin in AppConfig.coins) {
      final application = coin.openAliasApplication;
      if (application != null) {
        expect(
          isOpenAliasApplication(application),
          isTrue,
          reason: coin.identifier,
        );
      }
    }
    expect(AppConfig.coins.map((e) => e.openAliasApplication), contains('xmr'));
  });
}
