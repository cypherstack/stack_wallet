import '../utilities/tor_plain_net_option_enum.dart';
import 'node_model.dart';

class NodeFormData {
  NodeFormData();

  // The certificate is assigned last so it is bound to the node's endpoint.
  factory NodeFormData.fromNode(NodeModel node) => NodeFormData()
    ..name = node.name
    ..host = node.host
    ..port = node.port
    ..useSSL = node.useSSL
    ..login = node.loginName
    ..trusted = node.trusted
    ..isFailover = node.isFailover
    ..netOption = TorPlainNetworkOption.fromNodeData(
      node.torEnabled,
      node.clearnetEnabled,
    )
    ..forceNoTor = node.forceNoTor
    ..isPrimary = node.isPrimary
    ..apiSecret = node.nodeApiSecret
    ..trustedCertificatePem = node.trustedCertificatePem;

  String? name, host, login, password, apiSecret;
  int? port;
  bool? useSSL, isFailover, trusted, forceNoTor, isPrimary;
  TorPlainNetworkOption? netOption;

  // A certificate approval belongs to the endpoint it was reviewed for. It
  // stays with that endpoint: editing the host and restoring it keeps the
  // approval, while any other host, port or SSL setting reads as unapproved.
  String? _approvedPem;
  String? _approvedHost;
  int? _approvedPort;
  bool? _approvedUseSSL;

  String? get trustedCertificatePem =>
      _approvedPem != null &&
          host == _approvedHost &&
          port == _approvedPort &&
          useSSL == _approvedUseSSL
      ? _approvedPem
      : null;

  set trustedCertificatePem(String? value) {
    _approvedPem = value;
    _approvedHost = value == null ? null : host;
    _approvedPort = value == null ? null : port;
    _approvedUseSSL = value == null ? null : useSSL;
  }

  /// Whether the form currently names [node]'s endpoint, the identity a
  /// trusted certificate is bound to.
  bool matchesEndpointOf(NodeModel node) =>
      host == node.host && port == node.port && useSSL == node.useSSL;

  @override
  String toString() {
    return "{ name: $name, host: $host, port: $port, useSSL: $useSSL, "
        "trusted: $trusted, netOption: $netOption, isPrimary: $isPrimary }";
  }
}
