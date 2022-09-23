// import 'package:flutter/material.dart';
// import 'package:stackwallet/models/exchange/change_now/exchange_transaction_status.dart';
// import 'package:stackwallet/utilities/enums/coin_enum.dart';
// import 'package:stackwallet/utilities/theme/color_theme.dart';
// import 'package:stackwallet/utilities/theme/dark_colors.dart';
// import 'package:stackwallet/utilities/theme/light_colors.dart';
//
// class StackTheme {
//   StackTheme._();
//   static final StackTheme _instance = StackTheme._();
//   static StackTheme get instance => _instance;
//
//   late StackColorTheme color;
//   late ThemeType theme;
//
//   void setTheme(ThemeType theme) {
//     this.theme = theme;
//     switch (theme) {
//       case ThemeType.light:
//         color = LightColors();
//         break;
//       case ThemeType.dark:
//         color = DarkColors();
//         break;
//     }
//   }
//
//   BoxShadow get standardBoxShadow => BoxShadow(
//         color: color.shadow,
//         spreadRadius: 3,
//         blurRadius: 4,
//       );
//
//   Color colorForCoin(Coin coin) {
//     switch (coin) {
//       case Coin.bitcoin:
//       case Coin.bitcoinTestNet:
//         return _coin.bitcoin;
//       case Coin.bitcoincash:
//       case Coin.bitcoincashTestnet:
//         return _coin.bitcoincash;
//       case Coin.dogecoin:
//       case Coin.dogecoinTestNet:
//         return _coin.dogecoin;
//       case Coin.epicCash:
//         return _coin.epicCash;
//       case Coin.firo:
//       case Coin.firoTestNet:
//         return _coin.firo;
//       case Coin.monero:
//         return _coin.monero;
//       case Coin.namecoin:
//         return _coin.namecoin;
//       // case Coin.wownero:
//       //   return wownero;
//     }
//   }
//
//   Color colorForStatus(ChangeNowTransactionStatus status) {
//     switch (status) {
//       case ChangeNowTransactionStatus.New:
//       case ChangeNowTransactionStatus.Waiting:
//       case ChangeNowTransactionStatus.Confirming:
//       case ChangeNowTransactionStatus.Exchanging:
//       case ChangeNowTransactionStatus.Sending:
//       case ChangeNowTransactionStatus.Verifying:
//         return const Color(0xFFD3A90F);
//       case ChangeNowTransactionStatus.Finished:
//         return color.accentColorGreen;
//       case ChangeNowTransactionStatus.Failed:
//         return color.accentColorRed;
//       case ChangeNowTransactionStatus.Refunded:
//         return color.textSubtitle2;
//     }
//   }
//
//   ButtonStyle? getPrimaryEnabledButtonColor(BuildContext context) =>
//       Theme.of(context).textButtonTheme.style?.copyWith(
//             backgroundColor: MaterialStateProperty.all<Color>(
//               color.buttonBackPrimary,
//             ),
//           );
//
//   ButtonStyle? getPrimaryDisabledButtonColor(BuildContext context) =>
//       Theme.of(context).textButtonTheme.style?.copyWith(
//             backgroundColor: MaterialStateProperty.all<Color>(
//               color.buttonBackPrimaryDisabled,
//             ),
//           );
//
//   ButtonStyle? getSecondaryEnabledButtonColor(BuildContext context) =>
//       Theme.of(context).textButtonTheme.style?.copyWith(
//             backgroundColor: MaterialStateProperty.all<Color>(
//               color.buttonBackSecondary,
//             ),
//           );
//
//   ButtonStyle? getSmallSecondaryEnabledButtonColor(BuildContext context) =>
//       Theme.of(context).textButtonTheme.style?.copyWith(
//             backgroundColor: MaterialStateProperty.all<Color>(
//               color.textFieldDefaultBG,
//             ),
//           );
//
//   ButtonStyle? getDesktopMenuButtonColor(BuildContext context) =>
//       Theme.of(context).textButtonTheme.style?.copyWith(
//             backgroundColor: MaterialStateProperty.all<Color>(
//               color.popupBG,
//             ),
//           );
//
//   ButtonStyle? getDesktopMenuButtonColorSelected(BuildContext context) =>
//       Theme.of(context).textButtonTheme.style?.copyWith(
//             backgroundColor: MaterialStateProperty.all<Color>(
//               color.textFieldDefaultBG,
//             ),
//           );
//
//   static const _coin = CoinThemeColor();
// }
