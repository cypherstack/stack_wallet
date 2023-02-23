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
          'Epic Box server test webSocket message from server: "$inMsg"',
          level: LogLevel.Info);

      if (inMsg.contains("Challenge")) {
        // Successful response, close socket
        Logging.instance
            .log('Epic Box server test succeeded', level: LogLevel.Info);

        // Disconnect from server:
        textSocketHandler.disconnect('manual disconnect');
        // Disposing webSocket:
        textSocketHandler.close();
      } /* else if(inMsg.contains("InvalidRequest")) {
        // Handle when many InvalidRequest responses occur
      }*/
    });

    // Connecting to server:
    final isTextSocketConnected = await textSocketHandler.connect();
    if (!isTextSocketConnected) {
      Logging.instance.log(
          'Epic Box server test failed: "$host":"$port" unable to connect',
          level: LogLevel.Warning);
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
  if (data.host == null || data.port == null) {
    return null;
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
