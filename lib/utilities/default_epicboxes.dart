import 'dart:convert';

import 'package:epicpay/models/epicbox_model.dart';

abstract class DefaultEpicBoxes {
  static const String defaultName = "Default";

  static List<EpicBoxModel> get all => [americas, asia, europe];

  static EpicBoxModel get americas => EpicBoxModel(
        host: "epiccash.stackwallet.com",
        port: 443,
        name: 'Americas',
        id: 'americas',
        useSSL: true,
        enabled: true,
        isFailover: true,
        isDown: false,
      );

  static EpicBoxModel get asia => EpicBoxModel(
        host: "epiccash.stackwallet.com",
        port: 443,
        name: 'Asia',
        id: 'asia',
        useSSL: true,
        enabled: true,
        isFailover: true,
        isDown: false,
      );

  static EpicBoxModel get europe => EpicBoxModel(
        host: "epicbox.epic.tech",
        port: 443,
        name: 'Europe',
        id: 'europe',
        useSSL: true,
        enabled: true,
        isFailover: true,
        isDown: false,
      );

  static final String defaultEpicBoxConfig = jsonEncode({
    "epicbox_domain": "epicbox.fastepic.eu", //TODO - Default to Americas domain
    "epicbox_port": 443,
    "epicbox_protocol_unsecure": false,
    "epicbox_address_index": 0,
  });
}
