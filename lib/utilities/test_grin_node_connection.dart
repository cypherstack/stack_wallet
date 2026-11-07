import 'package:grin/grin.dart';

import '../app_config.dart';
import '../pages/settings_views/global_settings_view/manage_nodes_views/add_edit_node_view.dart';
import '../services/event_bus/events/global/tor_connection_status_changed_event.dart';
import '../services/tor_service.dart';
import '../wallets/wallet/supporting/grin/grin_errors.dart';
import '../wallets/wallet/supporting/grin/grin_node_url.dart';
import '../wallets/wallet/supporting/grin/grin_transport.dart';
import '../wl_gen/interfaces/libgrin_interface.dart';
import 'logger.dart';
import 'prefs.dart';
import 'tor_plain_net_option_enum.dart';

/// Asks a Grin node for its tip through the transport the wallet would use.
///
/// Returns [data] with the scheme in its host, or null when the node cannot
/// be reached or the Tor settings do not allow it. The foreign API's
/// `get_tip` needs no API secret, so a missing secret does not fail this.
Future<NodeFormData?> testGrinNodeConnection(
  NodeFormData data, {
  required Prefs prefs,
  required TorService Function() torService,
  GrinWalletBackend? backend,
  bool? torFeature,
}) async {
  final host = data.host?.trim();
  final port = data.port;
  final useSSL = data.useSSL;
  if (host == null || host.isEmpty || port == null || useSSL == null) {
    return null;
  }

  final String url;
  try {
    url = grinNodeUrl(host: host, port: port, useSSL: useSSL);
  } on GrinNodeUrlException catch (e) {
    Logging.instance.w("Grin node test: ${e.message}");
    return null;
  }

  final feature = torFeature ?? AppConfig.hasFeature(AppFeature.tor);
  final transport = resolveGrinTransport(
    torFeature: feature,
    useTor: prefs.useTor,
    torStatus: feature ? torService().status : TorConnectionStatus.disconnected,
    killSwitch: prefs.torKillSwitch,
    nodeNetOption: data.netOption ?? TorPlainNetworkOption.both,
    nodeIsOnion: isOnionHost(host),
    proxyAddress: () => grinProxyAddress(torService()),
  );
  if (transport is! GrinDirect && transport is! GrinProxy) {
    Logging.instance.w("Grin node test not run: $transport");
    return null;
  }

  try {
    await (backend ?? libGrin.backend).testNodeConnection(
      nodeUrl: url,
      apiSecret: data.apiSecret,
      socksProxy: transport is GrinProxy ? transport.address : null,
    );
  } catch (e) {
    Logging.instance.w("Grin node test failed: ${describeGrinError(e)}");
    return null;
  }

  final scheme = Uri.parse(url).scheme;
  if (!host.contains("://")) data.host = "$scheme://$host";
  data.useSSL = scheme == "https";
  return data;
}
