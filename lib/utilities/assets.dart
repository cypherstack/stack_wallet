import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

const _kPath_themed = "assets/svg/themed/";

abstract class Assets {
  static const svg = _SVG();
  static const png = _PNG();
  static const lottie = _ANIMATIONS();
  static const socials = _SOCIALS();
  static const exchange = _EXCHANGE();
  static const buy = _BUY();
}

class _SOCIALS {
  const _SOCIALS();

  static const _path = "assets/svg/socials/";

  String get discord => "${_path}discord.svg";
  String get reddit => "${_path}reddit-alien-brands.svg";
  String get twitter => "${_path}twitter-brands.svg";
  String get telegram => "${_path}telegram-brands.svg";
}

class _EXCHANGE {
  const _EXCHANGE();

  static const _path = "assets/svg/exchange_icons/";

  String get changeNow => "${_path}change_now_logo_1.svg";
  String get simpleSwap => "${_path}simpleswap-icon.svg";
  String get majesticBankBlue => "${_path}mb_blue.svg";
  String get majesticBankGreen => "${_path}mb_green.svg";
}

class _BUY {
  const _BUY();

  String simplexLogo(BuildContext context) {
    switch (Theme.of(context).extension<StackColors>()!.themeType) {
      case ThemeType.dark:
      case ThemeType.oledBlack:
        return "assets/svg/buy/Simplex-Nuvei-Logo-light.svg";

      case ThemeType.fruitSorbet:
      case ThemeType.forest:
      case ThemeType.oceanBreeze:
      case ThemeType.light:
      case ThemeType.chan:
        return "assets/svg/buy/Simplex-Nuvei-Logo.svg";
    }
  }
}

class _COIN_CONTROL {
  const _COIN_CONTROL();

  static const _path = "assets/svg/coin_control/";

  String get blocked => "${_path}frozen.svg";
  String get unBlocked => "${_path}unfrozen.svg";
  String get gamePad => "${_path}gamepad.svg";
  String get selected => "${_path}selected.svg";
}

class _SVG {
  const _SVG();

  static String _path(BuildContext context) {
    switch (Theme.of(context).extension<StackColors>()!.themeType) {
      // chan theme uses all the same assets as the light theme
      case ThemeType.chan:
        return "assets/svg/themed/${ThemeType.light.name}";
      default:
        return "assets/svg/themed/${Theme.of(context).extension<StackColors>()!.themeType.name}";
    }
  }

  final coinControl = const _COIN_CONTROL();

  String? background(BuildContext context) {
    switch (Theme.of(context).extension<StackColors>()!.themeType) {
      case ThemeType.light:
      case ThemeType.chan:
      case ThemeType.dark:
      case ThemeType.oledBlack:
        return null;

      case ThemeType.oceanBreeze:
      case ThemeType.fruitSorbet:
      case ThemeType.forest:
        return "${_path(context)}/bg.svg";
    }
  }

  String bellNew(BuildContext context) => "${_path(context)}/bell-new.svg";
  String stackIcon(BuildContext context) => "${_path(context)}/stack-icon1.svg";
  String exchange(BuildContext context) => "${_path(context)}/exchange-2.svg";
  String buy(BuildContext context) => "${_path(context)}/buy-coins-icon.svg";

  String receive(BuildContext context) =>
      "${_path(context)}/tx-icon-receive.svg";
  String receivePending(BuildContext context) =>
      "${_path(context)}/tx-icon-receive-pending.svg";
  String receiveCancelled(BuildContext context) =>
      "${_path(context)}/tx-icon-receive-failed.svg";

  String send(BuildContext context) => "${_path(context)}/tx-icon-send.svg";
  String sendPending(BuildContext context) =>
      "${_path(context)}/tx-icon-send-pending.svg";
  String sendCancelled(BuildContext context) =>
      "${_path(context)}/tx-icon-send-failed.svg";

  String txExchange(BuildContext context) =>
      "${_path(context)}/tx-exchange-icon.svg";
  String txExchangePending(BuildContext context) =>
      "${_path(context)}/tx-exchange-icon-pending.svg";
  String txExchangeFailed(BuildContext context) =>
      "${_path(context)}/tx-exchange-icon-failed.svg";

  String personaIncognito(BuildContext context) =>
      "${_path(context)}/persona-incognito-1.svg";
  String personaEasy(BuildContext context) =>
      "${_path(context)}/persona-easy-1.svg";

  String stack(BuildContext context) => "${_path(context)}/stack.svg";

  String get themeFruit => "assets/svg/fruit-sorbet-theme.svg";
  String get themeForest => "assets/svg/forest-theme.svg";
  String get themeOledBlack => "assets/svg/oled-black-theme.svg";
  String get themeOcean => "assets/svg/ocean-breeze-theme.svg";
  String get themeLight => "assets/svg/light-mode.svg";
  String get themeDark => "assets/svg/dark-theme.svg";

  String get circleSliders => "assets/svg/configuration.svg";
  String get circlePlus => "assets/svg/plus-circle.svg";
  String get circlePlusFilled => "assets/svg/circle-plus-filled.svg";
  String get framedGear => "assets/svg/framed-gear.svg";
  String get framedAddressBook => "assets/svg/framed-address-book.svg";
  String get circleNode => "assets/svg/node-circle.svg";
  String get circleSun => "assets/svg/sun-circle.svg";
  String get circleArrowRotate => "assets/svg/rotate-circle.svg";
  String get circleLanguage => "assets/svg/language-circle.svg";
  String get circleDollarSign => "assets/svg/dollar-sign-circle.svg";
  String get circleLock => "assets/svg/lock-circle.svg";
  String get enableButton => "assets/svg/enabled-button.svg";
  String get disableButton => "assets/svg/Button.svg";
  String get polygon => "assets/svg/Polygon.svg";
  String get drd => "assets/svg/drd-icon.svg";
  String get boxAuto => "assets/svg/box-auto.svg";
  String get plus => "assets/svg/plus.svg";
  String get gear => "assets/svg/gear.svg";
  String get bell => "assets/svg/bell.svg";
  String get arrowLeft => "assets/svg/arrow-left-fa.svg";
  String get star => "assets/svg/star.svg";
  String get copy => "assets/svg/copy-fa.svg";
  String get circleX => "assets/svg/x-circle.svg";
  String get check => "assets/svg/check.svg";
  String get circleAlert => "assets/svg/alert-circle2.svg";
  String get arrowDownLeft => "assets/svg/arrow-down-left.svg";
  String get arrowUpRight => "assets/svg/arrow-up-right.svg";
  String get bars => "assets/svg/bars.svg";
  String get filter => "assets/svg/filter.svg";
  String get pending => "assets/svg/pending.svg";
  String get radio => "assets/svg/signal-stream.svg";
  String get arrowRotate => "assets/svg/arrow-rotate.svg";
  String get arrowRotate2 => "assets/svg/arrow-rotate2.svg";
  String get alertCircle => "assets/svg/alert-circle.svg";
  String get checkCircle => "assets/svg/circle-check.svg";
  String get clipboard => "assets/svg/clipboard.svg";
  String get qrcode => "assets/svg/qrcode1.svg";
  String get ellipsis => "assets/svg/gear-3.svg";
  String get chevronDown => "assets/svg/chevron-down.svg";
  String get chevronUp => "assets/svg/chevron-up.svg";
  String get swap => "assets/svg/swap.svg";
  String get downloadFolder => "assets/svg/folder-down.svg";
  String get lock => "assets/svg/lock-keyhole.svg";
  String get lockOpen => "assets/svg/lock-open.svg";
  String get network => "assets/svg/network-wired.svg";
  String get networkWired => "assets/svg/network-wired-2.svg";
  String get addressBook => "assets/svg/address-book.svg";
  String get addressBook2 => "assets/svg/address-book2.svg";
  String get arrowRotate3 => "assets/svg/rotate-exclamation.svg";
  String get delete => "assets/svg/delete.svg";
  String get arrowRight => "assets/svg/arrow-right.svg";
  String get dollarSign => "assets/svg/dollar-sign.svg";
  String get language => "assets/svg/language2.svg";
  String get sun => "assets/svg/sun-bright2.svg";
  String get pencil => "assets/svg/pen-solid-fa.svg";
  String get search => "assets/svg/magnifying-glass.svg";
  String get thickX => "assets/svg/x-fat.svg";
  String get x => "assets/svg/x.svg";
  String get user => "assets/svg/user.svg";
  String get userPlus => "assets/svg/user-plus.svg";
  String get userMinus => "assets/svg/user-minus.svg";
  String get trash => "assets/svg/trash.svg";
  String get eye => "assets/svg/eye.svg";
  String get eyeSlash => "assets/svg/eye-slash.svg";
  String get folder => "assets/svg/folder.svg";
  String get calendar => "assets/svg/calendar-days.svg";
  String get circleQuestion => "assets/svg/circle-question.svg";
  String get circleInfo => "assets/svg/info-circle.svg";
  String get key => "assets/svg/key.svg";
  String get node => "assets/svg/node-alt.svg";
  String get radioProblem => "assets/svg/signal-problem-alt.svg";
  String get radioSyncing => "assets/svg/signal-sync-alt.svg";
  String get walletSettings => "assets/svg/wallet-settings.svg";
  String get verticalEllipsis => "assets/svg/ellipsis-vertical1.svg";
  String get dice => "assets/svg/dice-alt.svg";
  String get circleArrowUpRight => "assets/svg/circle-arrow-up-right2.svg";
  String get loader => "assets/svg/loader.svg";
  String get backupAdd => "assets/svg/add-backup.svg";
  String get backupAuto => "assets/svg/auto-backup.svg";
  String get backupRestore => "assets/svg/restore-backup.svg";
  String get solidSliders => "assets/svg/sliders-solid.svg";
  String get questionMessage => "assets/svg/message-question.svg";
  String get envelope => "assets/svg/envelope.svg";
  String get share => "assets/svg/share-2.svg";
  String get anonymize => "assets/svg/tx-icon-anonymize.svg";
  String get anonymizePending => "assets/svg/tx-icon-anonymize-pending.svg";
  String get anonymizeFailed => "assets/svg/tx-icon-anonymize-failed.svg";
  String get addressBookDesktop => "assets/svg/address-book-desktop.svg";
  String get exchangeDesktop => "assets/svg/exchange-desktop.svg";
  String get aboutDesktop => "assets/svg/about-desktop.svg";
  String get walletDesktop => "assets/svg/wallet-desktop.svg";
  String get exitDesktop => "assets/svg/exit-desktop.svg";
  String get keys => "assets/svg/keys.svg";
  String get arrowDown => "assets/svg/arrow-down.svg";
  String get robotHead => "assets/svg/robot-head.svg";
  String get whirlPool => "assets/svg/whirlpool.svg";
  String get fingerprint => "assets/svg/fingerprint.svg";
  String get faceId => "assets/svg/faceid.svg";
  String get ellipse1 => "assets/svg/Ellipse-43.svg";
  String get ellipse2 => "assets/svg/Ellipse-42.svg";
  String get chevronRight => "assets/svg/chevron-right.svg";
  String get minimize => "assets/svg/minimize.svg";
  String get walletFa => "assets/svg/wallet-fa.svg";
  String get exchange3 => "assets/svg/exchange-3.svg";
  String get messageQuestion => "assets/svg/message-question-1.svg";
  String get list => "assets/svg/list-ul.svg";
  String get unclaimedPaynym => "assets/svg/unclaimed.png";

// TODO provide proper assets
  String get bitcoinTestnet => "assets/svg/coin_icons/Bitcoin.svg";
  String get bitcoincashTestnet => "assets/svg/coin_icons/Bitcoincash.svg";
  String get firoTestnet => "assets/svg/coin_icons/Firo.svg";
  String get dogecoinTestnet => "assets/svg/coin_icons/Dogecoin.svg";
  String get particlTestnet => "assets/svg/coin_icons/Particl.svg";

  // small icons
  String get bitcoin => "assets/svg/coin_icons/Bitcoin.svg";
  String get litecoin => "assets/svg/coin_icons/Litecoin.svg";
  String get bitcoincash => "assets/svg/coin_icons/Bitcoincash.svg";
  String get dogecoin => "assets/svg/coin_icons/Dogecoin.svg";
  String get epicCash => "assets/svg/coin_icons/EpicCash.svg";
  String get firo => "assets/svg/coin_icons/Firo.svg";
  String get monero => "assets/svg/coin_icons/Monero.svg";
  String get wownero => "assets/svg/coin_icons/Wownero.svg";
  String get namecoin => "assets/svg/coin_icons/Namecoin.svg";
  String get particl => "assets/svg/coin_icons/Particl.svg";

  String iconFor({required Coin coin}) {
    switch (coin) {
      case Coin.bitcoin:
        return bitcoin;
      case Coin.litecoin:
      case Coin.litecoinTestNet:
        return litecoin;
      case Coin.bitcoincash:
        return bitcoincash;
      case Coin.dogecoin:
        return dogecoin;
      case Coin.epicCash:
        return epicCash;
      case Coin.firo:
        return firo;
      case Coin.monero:
        return monero;
      case Coin.wownero:
        return wownero;
      case Coin.namecoin:
        return namecoin;
      case Coin.particl:
        return particl;
      case Coin.bitcoinTestNet:
        return bitcoinTestnet;
      case Coin.bitcoincashTestnet:
        return bitcoincashTestnet;
      case Coin.firoTestNet:
        return firoTestnet;
      case Coin.dogecoinTestNet:
        return dogecoinTestnet;
    }
  }

  // big icons
  String bitcoinImage(BuildContext context) => "${_path(context)}/bitcoin.svg";
  String bitcoincashImage(BuildContext context) =>
      "${_path(context)}/bitcoincash.svg";
  String dogecoinImage(BuildContext context) => "${_path(context)}/doge.svg";
  String epicCashImage(BuildContext context) =>
      "${_path(context)}/epic-cash.svg";
  String firoImage(BuildContext context) => "${_path(context)}/firo.svg";
  String litecoinImage(BuildContext context) =>
      "${_path(context)}/litecoin.svg";
  String moneroImage(BuildContext context) => "${_path(context)}/monero.svg";
  String wowneroImage(BuildContext context) => "${_path(context)}/wownero.svg";
  String namecoinImage(BuildContext context) =>
      "${_path(context)}/namecoin.svg";
  String particlImage(BuildContext context) => "${_path(context)}/particl.svg";

  String imageFor({required BuildContext context, required Coin coin}) {
    switch (coin) {
      case Coin.bitcoin:
        return bitcoinImage(context);
      case Coin.litecoin:
      case Coin.litecoinTestNet:
        return litecoinImage(context);
      case Coin.bitcoincash:
        return bitcoincashImage(context);
      case Coin.dogecoin:
        return dogecoinImage(context);
      case Coin.epicCash:
        return epicCashImage(context);
      case Coin.firo:
        return firoImage(context);
      case Coin.monero:
        return moneroImage(context);
      case Coin.wownero:
        return wowneroImage(context);
      case Coin.namecoin:
        return namecoinImage(context);
      case Coin.particl:
        return particlImage(context);
      case Coin.bitcoinTestNet:
        return bitcoinImage(context);
      case Coin.bitcoincashTestnet:
        return bitcoincashImage(context);
      case Coin.firoTestNet:
        return firoImage(context);
      case Coin.dogecoinTestNet:
        return dogecoinImage(context);
    }
  }
}

class _PNG {
  const _PNG();

  String stack(BuildContext context) =>
      "assets/images/${Theme.of(context).extension<StackColors>()!.themeType.name}/stack.png";
  String get splash => "assets/images/splash.png";

  String get glasses => "assets/images/glasses.png";
  String get glassesHidden => "assets/images/glasses-hidden.png";
}

class _ANIMATIONS {
  const _ANIMATIONS();

  String get test2 => "assets/lottie/test2.json";

  String plain(Coin coin) {
    return "assets/lottie/coins/${coin.mainNetVersion.name}/plain.lottie.json";
  }

  String kiss(Coin coin) {
    return "assets/lottie/coins/${coin.mainNetVersion.name}/kiss.lottie.json";
  }
}
