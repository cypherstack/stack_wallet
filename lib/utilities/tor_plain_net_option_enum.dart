enum TorPlainNetworkOption {
  tor,
  clear,
  both;

  bool allowsTor() => this == tor || this == both;
  bool allowsClear() => this == clear || this == both;

  static TorPlainNetworkOption fromNodeData(
    bool torEnabled,
    bool clearEnabled,
  ) {
    if (clearEnabled && torEnabled) {
      return TorPlainNetworkOption.both;
    } else if (torEnabled) {
      return TorPlainNetworkOption.tor;
    } else if (clearEnabled) {
      return TorPlainNetworkOption.clear;
    } else {
      return TorPlainNetworkOption.both;
    }
  }
}
