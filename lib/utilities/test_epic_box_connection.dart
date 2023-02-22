import 'package:epicpay/pages/settings_views/epicbox_settings_view/manage_epicbox_views/add_edit_epicbox_view.dart';
import 'package:epicpay/utilities/logger.dart';
import 'package:websocket_universal/websocket_universal.dart';

Future<bool> _testEpicBoxConnection(String host, int port) async {
  try {
    final websocketConnectionUri = 'wss://$host:$port';
    const connectionOptions = SocketConnectionOptions(
      pingIntervalMs: 3000,
      timeoutConnectionMs: 4000,

      /// see ping/pong messages in [logEventStream] stream
      skipPingMessages: true,

      /// Set this attribute to `true` if do not need any ping/pong
      /// messages and ping measurement. Default is `false`
      pingRestrictionForce: false,
    );

    final IMessageProcessor<String, String> textSocketProcessor =
        SocketSimpleTextProcessor();
    final textSocketHandler = IWebSocketHandler<String, String>.createClient(
      websocketConnectionUri,
      textSocketProcessor,
      connectionOptions: connectionOptions,
    );

    // Listening to webSocket status changes
    // textSocketHandler.socketHandlerStateStream.listen((stateEvent) {
    //   debugPrint('> status changed to ${stateEvent.status}');
    // });

    // Listening to server responses:
    bool isConnected = true;
    textSocketHandler.incomingMessagesStream.listen((inMsg) {
      Logging.instance.log(
          '> webSocket  got text message from server: "$inMsg" '
          '[ping: ${textSocketHandler.pingDelayMs}]',
          level: LogLevel.Info);
    });

    // Connecting to server:
    final isTextSocketConnected = await textSocketHandler.connect();
    if (!isTextSocketConnected) {
      // ignore: avoid_print
      Logging.instance.log(
          'Connection to [$websocketConnectionUri] failed for some reason!',
          level: LogLevel.Info);
      isConnected = false;
    }
    return isConnected;
  } catch (e, s) {
    Logging.instance.log("$e\n$s", level: LogLevel.Warning);
    return false;
  }
}

// returns node data with properly formatted host/url if successful, otherwise null
Future<EpicBoxFormData?> testEpicBoxConnection(EpicBoxFormData data) async {
  // TODO update function to test properly like Likho does with wscat
  if (data.host == null || data.port == null || data.useSSL == null) {
    return null;
  }

  if (data.host!.startsWith("https://")) {
    data.useSSL = true;
  } else if (data.host!.startsWith("http://")) {
    data.useSSL = false;
  } else {
    if (data.useSSL!) {
      data.host = "https://${data.host!}";
    } else {
      data.host = "http://${data.host!}";
    }
  }

  try {
    if (await _testEpicBoxConnection(data.host!, data.port!)) {
      return data;
    } else {
      return null;
    }
  } catch (e, s) {
    Logging.instance.log("$e\n$s", level: LogLevel.Warning);
    return null;
  }
}
