import 'package:epicpay/models/epicbox_model.dart';

abstract class DefaultEpicBoxes {
  static const String defaultName = "Default";

  static List<EpicBoxModel> get all => [americas, asia, europe];

  static EpicBoxModel get americas => EpicBoxModel(
        host: 'epicbox.epic.tech',
        port: 443,
        name: 'Americas',
        id: 'americas',
        useSSL: true,
        enabled: true,
        isFailover: true,
        isDown: false,
      );

  static EpicBoxModel get asia => EpicBoxModel(
        host: 'epicbox.hyperbig.com',
        port: 443,
        name: 'Asia',
        id: 'asia',
        useSSL: true,
        enabled: true,
        isFailover: true,
        isDown: false,
      );

  static EpicBoxModel get europe => EpicBoxModel(
        host: 'epicbox.fastepic.eu',
        port: 443,
        name: 'Europe',
        id: 'europe',
        useSSL: true,
        enabled: true,
        isFailover: true,
        isDown: false,
      );

  static final defaultEpicBoxConfig = americas;
}
