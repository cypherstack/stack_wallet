class HardwareAccountData {
  final String address;
  final int accountIndex;
  final String derivationPath;
  final String masterFingerprint;
  final String xpub;

  HardwareAccountData({
    required this.address,
    required this.accountIndex,
    required this.derivationPath,
    required this.masterFingerprint,
    required this.xpub,
  });
}
