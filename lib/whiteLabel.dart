abstract class WhiteLabel {
  String get appName => appNamePrefix + appNameSuffix;

  String get appNamePrefix => "Stack";

  String get appNameSuffix => "Wallet";
}
