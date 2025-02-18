enum DNSAddressType {
  IPv4,
  IPv6,
  Tor,
  Freenet,
  I2P,
  ZeroNet;

  String get key {
    switch (this) {
      case DNSAddressType.IPv4:
        return "ip";
      case DNSAddressType.IPv6:
        return "ip6";
      case DNSAddressType.Tor:
        return "_tor";
      case DNSAddressType.Freenet:
        return "freenet";
      case DNSAddressType.I2P:
        return "i2p";
      case DNSAddressType.ZeroNet:
        return "zeronet";
    }
  }
}
