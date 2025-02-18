enum DNSRecordType {
  A,
  CNAME,
  NS,
  DS,
  TLS,
  SRV,
  TXT,
  IMPORT,
  SSH;

  String get info {
    switch (this) {
      case DNSRecordType.A:
        return "An A record maps your domain to an address (IPv4, IPv6, Tor,"
            " Freenet, I2P, or ZeroNet).";
      case DNSRecordType.CNAME:
        return "A CNAME record redirects your domain to another domain,"
            " essentially acting as an alias.";
      case DNSRecordType.NS:
        return "An NS record specifies the nameservers that are authoritative"
            " for your domain.";
      case DNSRecordType.DS:
        return "A DS record holds information about DNSSEC (DNS Security "
            "Extensions) for your domain, helping with verification and "
            "integrity.";
      case DNSRecordType.TLS:
        return "A TLS record is used for specifying details about how to "
            "establish secure connections (like TLS certificates) for your"
            " domain.";
      case DNSRecordType.SRV:
        return "An SRV record specifies the location of servers for specific"
            " services, such as SIP, XMPP, or Minecraft servers.";
      case DNSRecordType.TXT:
        return "A TXT record allows you to add arbitrary text to your domain's"
            " DNS record, often used for verification (e.g., SPF, DKIM).";
      case DNSRecordType.IMPORT:
        return "An IMPORT record is used to bring in DNS records from an"
            " external source into your domain's configuration.";
      case DNSRecordType.SSH:
        return "An SSH record provides information related to SSH public keys"
            " for securely connecting to your domain's services.";
    }
  }
}
