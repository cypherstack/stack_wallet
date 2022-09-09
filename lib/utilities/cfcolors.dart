import 'package:flutter/material.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction_status.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

class _CoinThemeColor {
  const _CoinThemeColor();

  Color get bitcoin => const Color(0xFFFCC17B);
  Color get bitcoincash => const Color(0xFFFCC17B);
  Color get firo => const Color(0xFFFF897A);
  Color get dogecoin => const Color(0xFFFFE079);
  Color get epicCash => const Color(0xFFC1C1FF);
  Color get monero => const Color(0xFFB1C5FF);

  Color forCoin(Coin coin) {
    switch (coin) {
      case Coin.bitcoin:
      case Coin.bitcoinTestNet:
        return bitcoin;
      case Coin.bitcoincash:
        return bitcoincash;
      case Coin.dogecoin:
      case Coin.dogecoinTestNet:
        return dogecoin;
      case Coin.epicCash:
        return epicCash;
      case Coin.firo:
      case Coin.firoTestNet:
        return firo;
      case Coin.monero:
        return monero;
    }
  }
}

class _ChangeNowTradeStatusColors {
  const _ChangeNowTradeStatusColors();

  Color get yellow => const Color(0xFFD3A90F);
  Color get green => CFColors.stackGreen;
  Color get red => CFColors.link;
  Color get gray => CFColors.gray3;

  Color forStatus(ChangeNowTransactionStatus status) {
    switch (status) {
      case ChangeNowTransactionStatus.New:
      case ChangeNowTransactionStatus.Waiting:
      case ChangeNowTransactionStatus.Confirming:
      case ChangeNowTransactionStatus.Exchanging:
      case ChangeNowTransactionStatus.Sending:
      case ChangeNowTransactionStatus.Verifying:
        return yellow;
      case ChangeNowTransactionStatus.Finished:
        return green;
      case ChangeNowTransactionStatus.Failed:
        return red;
      case ChangeNowTransactionStatus.Refunded:
        return gray;
    }
  }
}

abstract class CFColors {
  static const coin = _CoinThemeColor();
  static const status = _ChangeNowTradeStatusColors();

  static const Color splashLight = Color(0x44A9ACAC);
  static const Color splashMed = Color(0x358E9192);
  static const Color splashDark = Color(0x33232323);

  static const Color selected = Color(0xFFF9F9FC);
  static const Color selected2 = Color(0xFFE0E3E3);

  static const Color primary = Color(0xFF0052DF);
  static const Color primaryLight = Color(0xFFDAE2FF);

  static const Color link = Color(0xFFC00205);
  static const Color link2 = Color(0xFF0056D2);

  static const Color warningBackground = Color(0xFFFFDAD3);

  static const Color marked = Color(0xFFF61515);
  static const Color stackGreen = Color(0xFF00A578);
  static const Color stackYellow = Color(0xFFF4C517);
  static const Color stackGreen15 = Color(0xFFD2EBE4);
  static const Color stackRed = Color(0xFFDC5673);
  static const Color sentTx = Color(0x66FE805C);
  static const Color receivedTx = Color(0x6600A578);
  // static const Color stackAccent = Color(0xFF232323);
  // static const Color stackAccent = Color(0xFF232323);
  static const Color stackAccent = Color(0xFF232323);
  static const Color black = Color(0xFF191B23);

  static const Color primaryBlue = Color(0xFF074EE8);
  static const Color notificationBlueBackground = Color(0xFFDAE2FF);
  static const Color notificationBlueForeground = Color(0xFF002A78);
  static const Color notificationGreenBackground = Color(0xFFB9E9D4);
  static const Color notificationGreenForeground = Color(0xFF006C4D);
  static const Color notificationRedBackground = Color(0xFFFFDAD4);
  static const Color notificationRedForeground = Color(0xFF930006);
  static const Color error = Color(0xFF930006);

  static const Color almostWhite = Color(0xFFF7F7F7);
  static const Color light1 = Color(0xFFF5F5F5);

  static const Color disabledButton = Color(0xFFE0E3E3);

  static const Color neutral80 = Color(0xFFC5C6C9);
  static const Color neutral60 = Color(0xFF8E9192);
  static const Color neutral50 = Color(0xFF747778);
  static const Color selection = Color(0xFFD9E2FF);
  static const Color buttonGray = Color(0xFFE0E3E3);

  static const Color textFieldInactive = Color(0xFFEEEFF1);
  static const Color fieldGray = Color(0xFFEEEFF1);
  static const Color textFieldActive = Color(0xFFE9EAEC);

  static const Color contactIconBackground = Color(0xFFF4F5F8);

  static const Color gray3 = Color(0xFFA9ACAC);
  // shadow
  static const Color shadowColor = Color(0x0F2D3132);
  static const BoxShadow standardBoxShadow = BoxShadow(
    color: CFColors.shadowColor,
    spreadRadius: 3,
    blurRadius: 4,
  );

  // generic
  static const Color white = Color(0xFFFFFFFF);

  static MaterialColor createMaterialColor(Color color) {
    List<double> strengths = <double>[.05];
    final swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}
