import 'package:flutter/material.dart';
import 'package:stackwallet/services/exchange/change_now/change_now_exchange.dart';
import 'package:stackwallet/services/exchange/majestic_bank/majestic_bank_exchange.dart';
import 'package:stackwallet/services/exchange/simpleswap/simpleswap_exchange.dart';
import 'package:stackwallet/services/exchange/trocador/trocador_exchange.dart';

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
  String get trocador => "${_path}trocador.svg";

  String getIconFor({required String exchangeName}) {
    switch (exchangeName) {
      case SimpleSwapExchange.exchangeName:
        return simpleSwap;
      case ChangeNowExchange.exchangeName:
        return changeNow;
      case MajesticBankExchange.exchangeName:
        return majesticBankBlue;
      case TrocadorExchange.exchangeName:
        return trocador;
      default:
        throw ArgumentError("Invalid exchange name passed to "
            "Assets.exchange.getIconFor()");
    }
  }
}

class _BUY {
  const _BUY();

  String simplexLogo(BuildContext context) {
    switch (MediaQuery.of(context).platformBrightness) {
      case Brightness.dark:
        return "assets/svg/buy/Simplex-Nuvei-Logo-light.svg";

      case Brightness.light:
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

  final coinControl = const _COIN_CONTROL();

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
  String get arrowsTwoWay => "assets/svg/arrow-rotate2.svg";
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
  String get recycle => "assets/svg/anonymize.svg";
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
  String get tokens => "assets/svg/tokens.svg";
  String get circlePlusDark => "assets/svg/circle-plus.svg";
  String get creditCard => "assets/svg/cc.svg";
  String get file => "assets/svg/file.svg";
  String get fileUpload => "assets/svg/file-upload.svg";

  String get ellipse1 => "assets/svg/Ellipse-43.svg";
  String get ellipse2 => "assets/svg/Ellipse-42.svg";
  String get chevronRight => "assets/svg/chevron-right.svg";
  String get minimize => "assets/svg/minimize.svg";
  String get walletFa => "assets/svg/wallet-fa.svg";
  String get exchange3 => "assets/svg/exchange-3.svg";
  String get messageQuestion => "assets/svg/message-question-1.svg";
  String get list => "assets/svg/list-ul.svg";
  String get unclaimedPaynym => "assets/svg/unclaimed.svg";

  String get trocadorRatingA => "assets/svg/trocador_rating_a.svg";
  String get trocadorRatingB => "assets/svg/trocador_rating_b.svg";
  String get trocadorRatingC => "assets/svg/trocador_rating_c.svg";
  String get trocadorRatingD => "assets/svg/trocador_rating_d.svg";

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
  String get ethereum => "assets/svg/coin_icons/Ethereum.svg";
  String get firo => "assets/svg/coin_icons/Firo.svg";
  String get monero => "assets/svg/coin_icons/Monero.svg";
  String get wownero => "assets/svg/coin_icons/Wownero.svg";
  String get namecoin => "assets/svg/coin_icons/Namecoin.svg";
  String get particl => "assets/svg/coin_icons/Particl.svg";

  String get bnbIcon => "assets/svg/coin_icons/bnb_icon.svg";
}

class _PNG {
  const _PNG();

  String get splash => "assets/images/splash.png";

  String get glasses => "assets/images/glasses.png";
  String get glassesHidden => "assets/images/glasses-hidden.png";
}

class _ANIMATIONS {
  const _ANIMATIONS();

  String get test2 => "assets/lottie/test2.json";
  String get iconSend => "assets/lottie/icon_send.json";
  String get loaderAndCheckmark => "assets/lottie/loader_and_checkmark.json";
  String get arrowRotate => "assets/lottie/arrow_rotate.json";
}
