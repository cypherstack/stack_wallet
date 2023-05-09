import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/isar/sw_theme.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/defaults/dark.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/node_card.dart';
import 'package:stackwallet/widgets/node_options_sheet.dart';

import 'node_card_test.mocks.dart';

@GenerateMocks([NodeService])
void main() {
  testWidgets("NodeCard builds inactive node correctly", (tester) async {
    final nodeService = MockNodeService();

    when(nodeService.getPrimaryNodeFor(coin: Coin.bitcoin)).thenAnswer(
        (realInvocation) => NodeModel(
            host: "127.0.0.1",
            port: 2000,
            name: "Stack Default",
            id: "node id",
            useSSL: true,
            enabled: true,
            coinName: "Bitcoin",
            isFailover: false,
            isDown: false));

    when(nodeService.getNodeById(id: "node id")).thenAnswer((realInvocation) =>
        NodeModel(
            host: "127.0.0.1",
            port: 2000,
            name: "some other name",
            id: "node id",
            useSSL: true,
            enabled: true,
            coinName: "Bitcoin",
            isFailover: false,
            isDown: false));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nodeServiceChangeNotifierProvider.overrideWithValue(nodeService),
        ],
        child: MaterialApp(
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
          home: const NodeCard(
              nodeId: "node id", coin: Coin.bitcoin, popBackToRoute: ""),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text("some other name"), findsOneWidget);
    expect(find.text("Disconnected"), findsOneWidget);
    expect(find.byType(SvgPicture), findsWidgets);

    verify(nodeService.getPrimaryNodeFor(coin: Coin.bitcoin)).called(1);
    verify(nodeService.getNodeById(id: "node id")).called(1);
    verify(nodeService.addListener(any)).called(1);
    verifyNoMoreInteractions(nodeService);
  });

  testWidgets("NodeCard builds active node correctly", (tester) async {
    final nodeService = MockNodeService();

    when(nodeService.getPrimaryNodeFor(coin: Coin.bitcoin)).thenAnswer(
        (realInvocation) => NodeModel(
            host: "127.0.0.1",
            port: 2000,
            name: "Some other node name",
            id: "node id",
            useSSL: true,
            enabled: true,
            coinName: "Bitcoin",
            isFailover: false,
            isDown: false));

    when(nodeService.getNodeById(id: "node id")).thenAnswer((realInvocation) =>
        NodeModel(
            host: "127.0.0.1",
            port: 2000,
            name: "Some other node name",
            id: "node id",
            useSSL: true,
            enabled: true,
            coinName: "Bitcoin",
            isFailover: false,
            isDown: false));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nodeServiceChangeNotifierProvider.overrideWithValue(nodeService),
        ],
        child: MaterialApp(
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
          home: const NodeCard(
              nodeId: "node id", coin: Coin.bitcoin, popBackToRoute: ""),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Some other node name"), findsOneWidget);
    expect(find.text("Connected"), findsOneWidget);
    expect(find.byType(Text), findsNWidgets(2));
    expect(find.byType(SvgPicture), findsWidgets);

    verify(nodeService.getPrimaryNodeFor(coin: Coin.bitcoin)).called(1);
    verify(nodeService.getNodeById(id: "node id")).called(1);
    verify(nodeService.addListener(any)).called(1);

    verifyNoMoreInteractions(nodeService);
  });

  testWidgets("tap to open context menu on default node", (tester) async {
    final nodeService = MockNodeService();

    when(nodeService.getPrimaryNodeFor(coin: Coin.bitcoin)).thenAnswer(
        (realInvocation) => NodeModel(
            host: "127.0.0.1",
            port: 2000,
            name: "Stack Default",
            id: "node id",
            useSSL: true,
            enabled: true,
            coinName: "Bitcoin",
            isFailover: false,
            isDown: false));

    when(nodeService.getNodeById(id: "node id")).thenAnswer((realInvocation) =>
        NodeModel(
            host: "127.0.0.1",
            port: 2000,
            name: "Stack Default",
            id: "node id",
            useSSL: true,
            enabled: true,
            coinName: "Bitcoin",
            isFailover: false,
            isDown: false));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nodeServiceChangeNotifierProvider.overrideWithValue(nodeService),
        ],
        child: MaterialApp(
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
          home: const NodeCard(
              nodeId: "node id", coin: Coin.bitcoin, popBackToRoute: ""),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text("Stack Default"), findsOneWidget);
    expect(find.text("Connected"), findsOneWidget);
    expect(find.byType(Text), findsNWidgets(2));
    expect(find.byType(SvgPicture), findsNWidgets(2));

    await tester.tap(find.byType(NodeCard));
    await tester.pumpAndSettle();

    if (Util.isDesktop) {
      expect(find.text("Connect"), findsNothing);
      expect(find.text("Details"), findsNothing);

      verify(nodeService.getPrimaryNodeFor(coin: Coin.bitcoin)).called(1);
      verify(nodeService.getNodeById(id: "node id")).called(1);
    } else {
      expect(find.text("Connect"), findsOneWidget);
      expect(find.text("Details"), findsOneWidget);
      expect(find.byType(NodeOptionsSheet), findsOneWidget);
      expect(find.byType(Text), findsNWidgets(7));

      verify(nodeService.getPrimaryNodeFor(coin: Coin.bitcoin)).called(2);
      verify(nodeService.getNodeById(id: "node id")).called(2);
    }

    verify(nodeService.addListener(any)).called(1);

    verifyNoMoreInteractions(nodeService);
  });
}
