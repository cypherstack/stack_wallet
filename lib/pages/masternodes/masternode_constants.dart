abstract final class MasternodeCollateralNotes {
  MasternodeCollateralNotes._();

  static const unshield =
      "Masternode collateral unshield (1000 FIRO to transparent).";
  static const prep = "Masternode collateral prep (1000 FIRO self-send).";

  static bool isUnshield(String? note) =>
      note != null && note.contains(unshield);

  static bool isPrep(String? note) => note != null && note.contains(prep);
}
