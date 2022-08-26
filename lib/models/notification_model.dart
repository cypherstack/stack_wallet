import 'package:hive/hive.dart';

part 'type_adaptors/notification_model.g.dart';

// @HiveType(typeId: 10)
class NotificationModel {
  // @HiveField(0)
  final int id;
  // @HiveField(1)
  final String title;
  // @HiveField(2)
  final String description;
  // @HiveField(3)
  final String iconAssetName;
  // @HiveField(4)
  final DateTime date;
  // @HiveField(5)
  final String walletId;
  // @HiveField(6)
  final bool read;
  // @HiveField(7)
  final bool shouldWatchForUpdates;
  // @HiveField(8)
  final String? txid;
  // @HiveField(9)
  final String coinName;
  // @HiveField(10)
  final String? changeNowId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconAssetName,
    required this.date,
    required this.walletId,
    required this.read,
    required this.shouldWatchForUpdates,
    this.txid,
    required this.coinName,
    this.changeNowId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    try {
      return NotificationModel(
        id: json["id"] as int,
        title: json["title"] as String,
        description: json["description"] as String,
        iconAssetName: json["iconAssetName"] as String,
        date: json["date"] as DateTime,
        walletId: json["walletId"] as String,
        read: json["read"] as bool,
        shouldWatchForUpdates: json["shouldWatchForUpdates"] as bool,
        coinName: json["coinName"] as String,
        txid: json["txid"] as String?,
        changeNowId: json["changeNowId"] as String?,
      );
    } catch (e) {
      rethrow;
    }
  }

  NotificationModel copyWith({
    String? title,
    String? description,
    String? iconAssetName,
    DateTime? date,
    String? walletId,
    bool? read,
    bool? shouldWatchForUpdates,
    String? txid,
    String? coinName,
    String? changeNowId,
  }) {
    return NotificationModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconAssetName: iconAssetName ?? this.iconAssetName,
      date: date ?? this.date,
      walletId: walletId ?? this.walletId,
      read: read ?? this.read,
      shouldWatchForUpdates:
          shouldWatchForUpdates ?? this.shouldWatchForUpdates,
      txid: txid ?? this.txid,
      coinName: coinName ?? this.coinName,
      changeNowId: changeNowId ?? this.changeNowId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "description": description,
      "iconAssetName": iconAssetName,
      "date": date,
      "read": read,
      "walletId": walletId,
      "shouldWatchForUpdates": shouldWatchForUpdates,
      "txid": txid,
      "coinName": coinName,
      "changeNowId": changeNowId,
    };
  }

  @override
  String toString() {
    return toMap().toString();
  }
}
