import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/sw_theme.dart';
import 'package:stackwallet/models/notification_model.dart';
import 'package:stackwallet/notifications/notification_card.dart';
import 'package:stackwallet/themes/defaults/dark.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

void main() {
  testWidgets("test notification card", (widgetTester) async {
    final key = UniqueKey();
    final notificationCard = NotificationCard(
      key: key,
      notification: NotificationModel(
          id: 1,
          title: "notification title",
          description: "notification description",
          iconAssetName: Assets.svg.iconFor(coin: Coin.bitcoin),
          date: DateTime.parse("1662544771"),
          walletId: "wallet id",
          read: true,
          shouldWatchForUpdates: true,
          coinName: "Bitcoin"),
    );

    await widgetTester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(
              StackTheme.fromJson(
                json: darkJson,
                applicationThemesDirectoryPath: "",
              ),
            ),
          ],
        ),
        home: Material(
          child: notificationCard,
        ),
      ),
    );

    expect(find.byWidget(notificationCard), findsOneWidget);
    expect(find.text("notification title"), findsOneWidget);
    expect(find.text("notification description"), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
  });
}
