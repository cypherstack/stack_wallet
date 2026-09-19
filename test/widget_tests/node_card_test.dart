import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/node_card.dart';
import 'package:stackwallet/widgets/node_options_sheet.dart';

import '../sample_data/theme_json.dart';
import 'node_card_test.mocks.dart';
import 'support/platform_test_overrides.dart';

@GenerateMocks([NodeService])
void main() {
  final bitcoin = Bitcoin(CryptoCurrencyNetwork.main);

  NodeModel buildNode({required String id, required String name}) {
    return NodeModel(
      host: '127.0.0.1',
      port: 2000,
      name: name,
      id: id,
      useSSL: true,
      enabled: true,
      coinName: 'Bitcoin',
      isFailover: false,
      isDown: false,
      torEnabled: true,
      clearnetEnabled: true,
      isPrimary: true,
    );
  }

  ThemeData buildTheme() {
    return ThemeData(
      extensions: [
        StackColors.fromStackColorTheme(
          StackTheme.fromJson(json: lightThemeJsonMap),
        ),
      ],
    );
  }

  Future<void> pumpSubject(
    WidgetTester tester, {
    required MockNodeService nodeService,
    required List<Override> extraOverrides,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nodeServiceChangeNotifierProvider.overrideWithValue(nodeService),
          ...extraOverrides,
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: NodeCard(nodeId: 'node id', coin: bitcoin, popBackToRoute: ''),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('NodeCard builds inactive node correctly', (tester) async {
    final nodeService = MockNodeService();

    when(
      nodeService.getPrimaryNodeFor(currency: bitcoin),
    ).thenAnswer((_) => buildNode(id: 'other node id', name: 'Stack Default'));
    when(
      nodeService.getNodeById(id: 'node id'),
    ).thenAnswer((_) => buildNode(id: 'node id', name: 'some other name'));

    await pumpSubject(
      tester,
      nodeService: nodeService,
      extraOverrides: const [],
    );

    expect(find.text('some other name'), findsOneWidget);
    expect(find.text('Disconnected'), findsOneWidget);
    expect(find.byType(SvgPicture), findsWidgets);

    verify(nodeService.getPrimaryNodeFor(currency: bitcoin)).called(1);
    verify(nodeService.getNodeById(id: 'node id')).called(1);
    verify(nodeService.addListener(any)).called(1);
    verifyNoMoreInteractions(nodeService);
  });

  testWidgets('NodeCard builds active node correctly', (tester) async {
    final nodeService = MockNodeService();
    final activeNode = buildNode(id: 'node id', name: 'Some other node name');

    when(
      nodeService.getPrimaryNodeFor(currency: bitcoin),
    ).thenAnswer((_) => activeNode);
    when(nodeService.getNodeById(id: 'node id')).thenAnswer((_) => activeNode);

    await pumpSubject(
      tester,
      nodeService: nodeService,
      extraOverrides: const [],
    );

    expect(find.text('Some other node name'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.byType(Text), findsNWidgets(2));
    expect(find.byType(SvgPicture), findsWidgets);

    verify(nodeService.getPrimaryNodeFor(currency: bitcoin)).called(1);
    verify(nodeService.getNodeById(id: 'node id')).called(1);
    verify(nodeService.addListener(any)).called(1);
    verifyNoMoreInteractions(nodeService);
  });

  testWidgets('tap to open context menu on default node', (tester) async {
    final nodeService = MockNodeService();
    final activeNode = buildNode(id: 'node id', name: 'Stack Default');

    when(
      nodeService.getPrimaryNodeFor(currency: bitcoin),
    ).thenAnswer((_) => activeNode);
    when(nodeService.getNodeById(id: 'node id')).thenAnswer((_) => activeNode);

    await pumpSubject(
      tester,
      nodeService: nodeService,
      extraOverrides: const [],
    );

    expect(find.text('Stack Default'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.byType(Text), findsNWidgets(2));
    expect(find.byType(SvgPicture), findsNWidgets(2));

    await tester.tap(find.byType(NodeCard));
    await tester.pumpAndSettle();

    if (Util.isDesktop) {
      expect(find.text('Connect'), findsNothing);
      expect(find.text('Details'), findsNothing);

      verify(nodeService.getPrimaryNodeFor(currency: bitcoin)).called(1);
      verify(nodeService.getNodeById(id: 'node id')).called(1);
    } else {
      expect(find.text('Connect'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(find.byType(NodeOptionsSheet), findsOneWidget);
      expect(find.byType(Text), findsNWidgets(7));

      verify(nodeService.getPrimaryNodeFor(currency: bitcoin)).called(2);
      verify(nodeService.getNodeById(id: 'node id')).called(2);
    }

    verify(nodeService.addListener(any)).called(1);
    verifyNoMoreInteractions(nodeService);
  });

  testWidgets(
    'desktop connect failure uses seam once and does not promote node',
    (tester) async {
      final nodeService = MockNodeService();
      final platformOverrides = await createPlatformTestOverrides(
        connectionResult: false,
      );
      final disconnectedNode = buildNode(id: 'node id', name: 'Stack Default');

      when(nodeService.getPrimaryNodeFor(currency: bitcoin)).thenAnswer(
        (_) => buildNode(id: 'other node id', name: 'Some other node name'),
      );
      when(
        nodeService.getNodeById(id: 'node id'),
      ).thenAnswer((_) => disconnectedNode);

      await pumpSubject(
        tester,
        nodeService: nodeService,
        extraOverrides: platformOverrides.overrides,
      );

      if (!Util.isDesktop) {
        return;
      }

      await tester.tap(find.byType(NodeCard));
      await tester.pumpAndSettle();

      final connectFinder = find.byWidgetPredicate(
        (widget) => widget is CustomTextButton && widget.text == 'Connect',
      );
      expect(connectFinder, findsOneWidget);
      expect(tester.widget<CustomTextButton>(connectFinder).enabled, isTrue);

      tester.widget<CustomTextButton>(connectFinder).onTap?.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(platformOverrides.secureStorage.reads, 1);
      expect(platformOverrides.connectionInvocations, hasLength(1));
      expect(platformOverrides.connectionInvocations.single.password, isNull);
      expect(platformOverrides.connectionInvocations.single.host, '127.0.0.1');

      verifyNever(
        nodeService.setPrimaryNodeFor(
          coin: bitcoin,
          node: anyNamed('node'),
          shouldNotifyListeners: anyNamed('shouldNotifyListeners'),
        ),
      );
    },
  );
}
