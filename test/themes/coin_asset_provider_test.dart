import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/themes/coin_icon_provider.dart';
import 'package:stackwallet/themes/coin_image_provider.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  test('a feature-gated coin uses the installed theme placeholder', () {
    final assets = ThemeAssetsV2()
      ..coinPlaceholder = '/theme/coin-placeholder.svg'
      ..coinIconsString = '{"bitcoin":"/theme/bitcoin.svg"}';
    final container = ProviderContainer(
      overrides: [
        themeAssetsProvider.overrideWithProvider(StateProvider((_) => assets)),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(coinIconProvider(Zcash(CryptoCurrencyNetwork.main))),
      assets.coinPlaceholder,
    );
  });

  test('feature-gated coin artwork uses the theme placeholder', () {
    final assets = ThemeAssetsV2()
      ..coinPlaceholder = '/theme/coin-placeholder.svg'
      ..coinImagesString = '{"bitcoin":"/theme/bitcoin-large.svg"}'
      ..coinSecondaryImagesString =
          '{"bitcoin":"/theme/bitcoin-secondary.svg"}';
    final container = ProviderContainer(
      overrides: [
        themeAssetsProvider.overrideWithProvider(StateProvider((_) => assets)),
      ],
    );
    addTearDown(container.dispose);
    final coin = Zcash(CryptoCurrencyNetwork.main);

    expect(container.read(coinImageProvider(coin)), assets.coinPlaceholder);
    expect(
      container.read(coinImageSecondaryProvider(coin)),
      assets.coinPlaceholder,
    );
  });

  test('a V3 theme without a feature-gated coin uses its placeholder', () {
    StackFileSystem.themesDir = Directory('/themes');
    final assets = ThemeAssetsV3()
      ..coinPlaceholderRelative = 'custom/assets/coin-placeholder.svg'
      ..coinIconsString = '{"bitcoin":"custom/assets/bitcoin.svg"}'
      ..coinImagesString = '{"bitcoin":"custom/assets/bitcoin-large.svg"}'
      ..coinSecondaryImagesString =
          '{"bitcoin":"custom/assets/bitcoin-secondary.svg"}';
    final container = ProviderContainer(
      overrides: [
        themeAssetsProvider.overrideWithProvider(StateProvider((_) => assets)),
      ],
    );
    addTearDown(container.dispose);
    final coin = Zcash(CryptoCurrencyNetwork.main);

    expect(container.read(coinIconProvider(coin)), assets.coinPlaceholder);
    expect(container.read(coinImageProvider(coin)), assets.coinPlaceholder);
    expect(
      container.read(coinImageSecondaryProvider(coin)),
      assets.coinPlaceholder,
    );
  });

  test('V2 theme-provided coin artwork is preserved', () {
    final assets = ThemeAssetsV2()
      ..coinPlaceholder = '/theme/coin-placeholder.svg'
      ..coinIconsString = '{"bitcoin":"/theme/bitcoin.svg"}'
      ..coinImagesString = '{"bitcoin":"/theme/bitcoin-large.svg"}'
      ..coinSecondaryImagesString =
          '{"bitcoin":"/theme/bitcoin-secondary.svg"}';
    final container = ProviderContainer(
      overrides: [
        themeAssetsProvider.overrideWithProvider(StateProvider((_) => assets)),
      ],
    );
    addTearDown(container.dispose);
    final coin = Bitcoin(CryptoCurrencyNetwork.main);

    expect(container.read(coinIconProvider(coin)), '/theme/bitcoin.svg');
    expect(container.read(coinImageProvider(coin)), '/theme/bitcoin-large.svg');
    expect(
      container.read(coinImageSecondaryProvider(coin)),
      '/theme/bitcoin-secondary.svg',
    );
  });

  test('V3 theme-provided coin artwork is preserved', () {
    StackFileSystem.themesDir = Directory('/themes');
    final assets = ThemeAssetsV3()
      ..coinPlaceholderRelative = 'custom/assets/coin-placeholder.svg'
      ..coinIconsString = '{"bitcoin":"custom/assets/bitcoin.svg"}'
      ..coinImagesString = '{"bitcoin":"custom/assets/bitcoin-large.svg"}'
      ..coinSecondaryImagesString =
          '{"bitcoin":"custom/assets/bitcoin-secondary.svg"}';
    final container = ProviderContainer(
      overrides: [
        themeAssetsProvider.overrideWithProvider(StateProvider((_) => assets)),
      ],
    );
    addTearDown(container.dispose);
    final coin = Bitcoin(CryptoCurrencyNetwork.main);

    expect(
      container.read(coinIconProvider(coin)),
      '/themes/custom/assets/bitcoin.svg',
    );
    expect(
      container.read(coinImageProvider(coin)),
      '/themes/custom/assets/bitcoin-large.svg',
    );
    expect(
      container.read(coinImageSecondaryProvider(coin)),
      '/themes/custom/assets/bitcoin-secondary.svg',
    );
  });
}
