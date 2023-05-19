import 'package:stackwallet/models/epicbox_server_model.dart';

abstract class DefaultEpicBoxes {
  static const String defaultName = "Default";

  static List<EpicBoxServerModel> get all => [americas, asia, europe];
  static List<String> get defaultIds => ['americas', 'asia', 'europe'];

  static EpicBoxServerModel get americas => EpicBoxServerModel(
        host: 'epicbox.epic.tech',
        port: 443,
        name: 'Americas',
        id: 'americas',
        useSSL: true,
        enabled: true,
        isFailover: true,
        isDown: false,
      );

  static EpicBoxServerModel get asia => EpicBoxServerModel(
        host: 'epicbox.hyperbig.com',
        port: 443,
        name: 'Asia',
        id: 'asia',
        useSSL: true,
        enabled: true,
        isFailover: true,
        isDown: false,
      );

  static EpicBoxServerModel get europe => EpicBoxServerModel(
        host: 'epicbox.fastepic.eu',
        port: 443,
        name: 'Europe',
        id: 'europe',
        useSSL: true,
        enabled: true,
        isFailover: true,
        isDown: false,
      );

  static final defaultEpicBoxServer = americas;
}
