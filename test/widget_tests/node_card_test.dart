// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
import 'package:stackwallet/services/node_service.dart';
// import 'package:stackwallet/widgets/node_card.dart';

// import 'node_card_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<NodeService>(returnNullOnMissingStub: true),
])
void main() {
  // testWidgets("NodeCard builds inactive node correctly", (tester) async {
  //   final nodeService = MockNodeService();
  //
  //   when(nodeService.activeNodeName).thenAnswer((_) => "some other node");
  //
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: MultiProvider(
  //         providers: [
  //           ChangeNotifierProvider<NodeService>(
  //             create: (_) => nodeService,
  //           ),
  //         ],
  //         child: NodeCard(
  //           nodeName: "Campfire default",
  //           nodeData: {
  //             "port": "9000",
  //             "ipAddress": "some url",
  //             "useSSL": true,
  //           },
  //         ),
  //       ),
  //     ),
  //   );
  //   await tester.pumpAndSettle();
  //
  //   expect(find.text("Campfire default"), findsOneWidget);
  //   expect(find.byType(Text), findsOneWidget);
  //   expect(find.byType(SvgPicture), findsOneWidget);
  //
  //   verify(nodeService.activeNodeName).called(1);
  //   verify(nodeService.addListener(any)).called(1);
  //
  //   verifyNoMoreInteractions(nodeService);
  // });
  //
  // testWidgets("NodeCard builds active node correctly", (tester) async {
  //   final nodeService = MockNodeService();
  //
  //   when(nodeService.activeNodeName).thenAnswer((_) => "Campfire default");
  //
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: MultiProvider(
  //         providers: [
  //           ChangeNotifierProvider<NodeService>(
  //             create: (_) => nodeService,
  //           ),
  //         ],
  //         child: NodeCard(
  //           nodeName: "Campfire default",
  //           nodeData: {
  //             "port": "9000",
  //             "ipAddress": "some url",
  //             "useSSL": true,
  //           },
  //         ),
  //       ),
  //     ),
  //   );
  //   await tester.pumpAndSettle();
  //
  //   expect(find.text("Campfire default"), findsOneWidget);
  //   expect(find.text("Connected"), findsOneWidget);
  //   expect(find.byType(Text), findsNWidgets(2));
  //   expect(find.byType(SvgPicture), findsOneWidget);
  //
  //   verify(nodeService.activeNodeName).called(1);
  //   verify(nodeService.addListener(any)).called(1);
  //
  //   verifyNoMoreInteractions(nodeService);
  // });
  //
  // testWidgets("tap to open context menu on default node", (tester) async {
  //   final nodeService = MockNodeService();
  //
  //   when(nodeService.activeNodeName).thenAnswer((_) => "Campfire default");
  //
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: MultiProvider(
  //         providers: [
  //           ChangeNotifierProvider<NodeService>(
  //             create: (_) => nodeService,
  //           ),
  //         ],
  //         child: NodeCard(
  //           nodeName: "Campfire default",
  //           nodeData: {
  //             "port": "9000",
  //             "ipAddress": "some url",
  //             "useSSL": true,
  //           },
  //         ),
  //       ),
  //     ),
  //   );
  //   await tester.pumpAndSettle();
  //
  //   expect(find.text("Campfire default"), findsOneWidget);
  //   expect(find.text("Connected"), findsOneWidget);
  //   expect(find.byType(Text), findsNWidgets(2));
  //   expect(find.byType(SvgPicture), findsOneWidget);
  //
  //   await tester.tap(find.byType(NodeCard));
  //   await tester.pumpAndSettle();
  //
  //   expect(find.text("Connect"), findsOneWidget);
  //   expect(find.text("Details"), findsOneWidget);
  //   expect(find.byType(Text), findsNWidgets(4));
  //
  //   verify(nodeService.activeNodeName).called(1);
  //   verify(nodeService.addListener(any)).called(1);
  //
  //   verifyNoMoreInteractions(nodeService);
  // });
  //
  // testWidgets("tap to open context menu on any other node", (tester) async {
  //   final nodeService = MockNodeService();
  //
  //   when(nodeService.activeNodeName).thenAnswer((_) => "Campfire default");
  //
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: MultiProvider(
  //         providers: [
  //           ChangeNotifierProvider<NodeService>(
  //             create: (_) => nodeService,
  //           ),
  //         ],
  //         child: NodeCard(
  //           nodeName: "some other node",
  //           nodeData: {
  //             "port": "9000",
  //             "ipAddress": "some url",
  //             "useSSL": true,
  //           },
  //         ),
  //       ),
  //     ),
  //   );
  //   await tester.pumpAndSettle();
  //
  //   expect(find.text("some other node"), findsOneWidget);
  //   expect(find.byType(Text), findsNWidgets(1));
  //   expect(find.byType(SvgPicture), findsOneWidget);
  //
  //   await tester.tap(find.byType(NodeCard));
  //   await tester.pumpAndSettle();
  //
  //   expect(find.text("Connect"), findsOneWidget);
  //   expect(find.text("Details"), findsOneWidget);
  //   expect(find.text("Edit"), findsOneWidget);
  //   expect(find.text("Delete"), findsOneWidget);
  //   expect(find.byType(Text), findsNWidgets(5));
  //
  //   verify(nodeService.activeNodeName).called(1);
  //   verify(nodeService.addListener(any)).called(1);
  //
  //   verifyNoMoreInteractions(nodeService);
  // });
  //
  // testWidgets("tap connect", (tester) async {
  //   final nodeService = MockNodeService();
  //   final navigator = mockingjay.MockNavigator();
  //
  //   when(nodeService.activeNodeName).thenAnswer((_) => "Campfire default");
  //   when(nodeService.setCurrentNode("some other node"))
  //       .thenAnswer((_) async {});
  //
  //   mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
  //
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: mockingjay.MockNavigatorProvider(
  //         navigator: navigator,
  //         child: MultiProvider(
  //           providers: [
  //             ChangeNotifierProvider<NodeService>(
  //               create: (_) => nodeService,
  //             ),
  //           ],
  //           child: NodeCard(
  //             nodeName: "some other node",
  //             nodeData: {
  //               "port": "9000",
  //               "ipAddress": "some url",
  //               "useSSL": true,
  //             },
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  //   await tester.pumpAndSettle();
  //
  //   expect(find.text("some other node"), findsOneWidget);
  //   expect(find.byType(Text), findsNWidgets(1));
  //   expect(find.byType(SvgPicture), findsOneWidget);
  //
  //   await tester.tap(find.byType(NodeCard));
  //   await tester.pumpAndSettle();
  //
  //   expect(find.text("Connect"), findsOneWidget);
  //   expect(find.text("Details"), findsOneWidget);
  //   expect(find.text("Edit"), findsOneWidget);
  //   expect(find.text("Delete"), findsOneWidget);
  //   expect(find.byType(Text), findsNWidgets(5));
  //
  //   await tester.tap(find.text("Connect"));
  //   await tester.pumpAndSettle();
  //
  //   verify(nodeService.activeNodeName).called(1);
  //   verify(nodeService.addListener(any)).called(1);
  //   verify(nodeService.setCurrentNode("some other node")).called(1);
  //
  //   verifyNoMoreInteractions(nodeService);
  //
  //   mockingjay.verify(() => navigator.pop()).called(1);
  //   mockingjay.verifyNoMoreInteractions(navigator);
  // });
  //
  // testWidgets("tap details", (tester) async {
  //   final nodeService = MockNodeService();
  //   final navigator = mockingjay.MockNavigator();
  //
  //   when(nodeService.activeNodeName).thenAnswer((_) => "Campfire default");
  //
  //   mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
  //   mockingjay
  //       .when(() => navigator.push(mockingjay.any()))
  //       .thenAnswer((_) async {});
  //
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: mockingjay.MockNavigatorProvider(
  //         navigator: navigator,
  //         child: MultiProvider(
  //           providers: [
  //             ChangeNotifierProvider<NodeService>(
  //               create: (_) => nodeService,
  //             ),
  //           ],
  //           child: NodeCard(
  //             nodeName: "some other node",
  //             nodeData: {
  //               "port": "9000",
  //               "ipAddress": "some url",
  //               "useSSL": true,
  //             },
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  //   await tester.pumpAndSettle();
  //
  //   expect(find.text("some other node"), findsOneWidget);
  //   expect(find.byType(Text), findsNWidgets(1));
  //   expect(find.byType(SvgPicture), findsOneWidget);
  //
  //   await tester.tap(find.byType(NodeCard));
  //   await tester.pumpAndSettle();
  //
  //   expect(find.text("Connect"), findsOneWidget);
  //   expect(find.text("Details"), findsOneWidget);
  //   expect(find.text("Edit"), findsOneWidget);
  //   expect(find.text("Delete"), findsOneWidget);
  //   expect(find.byType(Text), findsNWidgets(5));
  //
  //   await tester.tap(find.text("Details"));
  //   await tester.pump();
  //
  //   verify(nodeService.activeNodeName).called(1);
  //   verify(nodeService.addListener(any)).called(1);
  //
  //   verifyNoMoreInteractions(nodeService);
  //
  //   mockingjay.verify(() => navigator.pop()).called(1);
  //   mockingjay
  //       .verify(() => navigator.push(mockingjay.any(
  //           that: mockingjay.isRoute(whereName: equals("/nodedetailsview")))))
  //       .called(1);
  //
  //   mockingjay.verifyNoMoreInteractions(navigator);
  // });
  //
  // testWidgets("tap edit", (tester) async {
  //   final nodeService = MockNodeService();
  //   final navigator = mockingjay.MockNavigator();
  //
  //   when(nodeService.activeNodeName).thenAnswer((_) => "Campfire default");
  //
  //   mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
  //   mockingjay
  //       .when(() => navigator.push(mockingjay.any()))
  //       .thenAnswer((_) async {});
  //
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: mockingjay.MockNavigatorProvider(
  //         navigator: navigator,
  //         child: MultiProvider(
  //           providers: [
  //             ChangeNotifierProvider<NodeService>(
  //               create: (_) => nodeService,
  //             ),
  //           ],
  //           child: NodeCard(
  //             nodeName: "some other node",
  //             nodeData: {
  //               "port": "9000",
  //               "ipAddress": "some url",
  //               "useSSL": true,
  //             },
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  //   await tester.pumpAndSettle();
  //
  //   expect(find.text("some other node"), findsOneWidget);
  //   expect(find.byType(Text), findsNWidgets(1));
  //   expect(find.byType(SvgPicture), findsOneWidget);
  //
  //   await tester.tap(find.byType(NodeCard));
  //   await tester.pumpAndSettle();
  //
  //   expect(find.text("Connect"), findsOneWidget);
  //   expect(find.text("Details"), findsOneWidget);
  //   expect(find.text("Edit"), findsOneWidget);
  //   expect(find.text("Delete"), findsOneWidget);
  //   expect(find.byType(Text), findsNWidgets(5));
  //
  //   await tester.tap(find.text("Edit"));
  //   await tester.pump();
  //
  //   verify(nodeService.activeNodeName).called(1);
  //   verify(nodeService.addListener(any)).called(1);
  //
  //   verifyNoMoreInteractions(nodeService);
  //
  //   mockingjay.verify(() => navigator.pop()).called(1);
  //   mockingjay
  //       .verify(() => navigator.push(mockingjay.any(
  //           that:
  //               mockingjay.isRoute(whereName: equals("/editnodedetailsview")))))
  //       .called(1);
  //
  //   mockingjay.verifyNoMoreInteractions(navigator);
  // });
  //
  // testWidgets("tap delete and cancel", (tester) async {
  //   final nodeService = MockNodeService();
  //   final navigator = mockingjay.MockNavigator();
  //
  //   when(nodeService.activeNodeName).thenAnswer((_) => "Campfire default");
  //
  //   mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
  //
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: mockingjay.MockNavigatorProvider(
  //         navigator: navigator,
  //         child: MultiProvider(
  //           providers: [
  //             ChangeNotifierProvider<NodeService>(
  //               create: (_) => nodeService,
  //             ),
  //           ],
  //           child: NodeCard(
  //             nodeName: "some other node",
  //             nodeData: {
  //               "port": "9000",
  //               "ipAddress": "some url",
  //               "useSSL": true,
  //             },
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  //   await tester.pumpAndSettle();
  //
  //   expect(find.text("some other node"), findsOneWidget);
  //   expect(find.byType(Text), findsNWidgets(1));
  //   expect(find.byType(SvgPicture), findsOneWidget);
  //
  //   await tester.tap(find.byType(NodeCard));
  //   await tester.pumpAndSettle();
  //
  //   expect(find.text("Connect"), findsOneWidget);
  //   expect(find.text("Details"), findsOneWidget);
  //   expect(find.text("Edit"), findsOneWidget);
  //   expect(find.text("Delete"), findsOneWidget);
  //   expect(find.byType(Text), findsNWidgets(5));
  //
  //   await tester.tap(find.text("Delete"));
  //   await tester.pumpAndSettle();
  //
  //   expect(find.byType(ModalPopupDialog), findsOneWidget);
  //   expect(find.byType(SimpleButton), findsOneWidget);
  //   expect(find.byType(GradientButton), findsOneWidget);
  //   expect(find.text("CANCEL"), findsOneWidget);
  //   expect(find.text("DELETE"), findsOneWidget);
  //   expect(find.text("Do you want to delete some other node?"), findsOneWidget);
  //
  //   await tester.tap(find.byType(SimpleButton));
  //   await tester.pumpAndSettle();
  //
  //   verify(nodeService.activeNodeName).called(1);
  //   verify(nodeService.addListener(any)).called(1);
  //
  //   verifyNoMoreInteractions(nodeService);
  //
  //   mockingjay.verify(() => navigator.pop()).called(2);
  //
  //   mockingjay.verifyNoMoreInteractions(navigator);
  // });
  //
  // testWidgets("tap delete and confirm fails", (tester) async {
  //   final nodeService = MockNodeService();
  //   final navigator = mockingjay.MockNavigator();
  //
  //   when(nodeService.activeNodeName).thenAnswer((_) => "Campfire default");
  //   when(nodeService.deleteNode("some other node"))
  //       .thenAnswer((_) async => false);
  //
  //   mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
  //
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: mockingjay.MockNavigatorProvider(
  //         navigator: navigator,
  //         child: MultiProvider(
  //           providers: [
  //             ChangeNotifierProvider<NodeService>(
  //               create: (_) => nodeService,
  //             ),
  //           ],
  //           child: NodeCard(
  //             nodeName: "some other node",
  //             nodeData: {
  //               "port": "9000",
  //               "ipAddress": "some url",
  //               "useSSL": true,
  //             },
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  //   await tester.pumpAndSettle();
  //
  //   expect(find.text("some other node"), findsOneWidget);
  //   expect(find.byType(Text), findsNWidgets(1));
  //   expect(find.byType(SvgPicture), findsOneWidget);
  //
  //   await tester.tap(find.byType(NodeCard));
  //   await tester.pumpAndSettle();
  //
  //   expect(find.text("Connect"), findsOneWidget);
  //   expect(find.text("Details"), findsOneWidget);
  //   expect(find.text("Edit"), findsOneWidget);
  //   expect(find.text("Delete"), findsOneWidget);
  //   expect(find.byType(Text), findsNWidgets(5));
  //
  //   await tester.tap(find.text("Delete"));
  //   await tester.pumpAndSettle();
  //
  //   expect(find.byType(ModalPopupDialog), findsOneWidget);
  //   expect(find.byType(SimpleButton), findsOneWidget);
  //   expect(find.byType(GradientButton), findsOneWidget);
  //   expect(find.text("CANCEL"), findsOneWidget);
  //   expect(find.text("DELETE"), findsOneWidget);
  //   expect(find.text("Do you want to delete some other node?"), findsOneWidget);
  //
  //   await tester.tap(find.byType(GradientButton));
  //   await tester.pumpAndSettle();
  //
  //   expect(find.byType(CampfireAlert), findsOneWidget);
  //   expect(find.text("Error: Could not delete node named \"some other node\"!"),
  //       findsOneWidget);
  //
  //   verify(nodeService.activeNodeName).called(1);
  //   verify(nodeService.addListener(any)).called(1);
  //   verify(nodeService.deleteNode("some other node")).called(1);
  //
  //   verifyNoMoreInteractions(nodeService);
  //
  //   mockingjay.verify(() => navigator.pop()).called(2);
  //
  //   mockingjay.verifyNoMoreInteractions(navigator);
  // });
  //
  // testWidgets("tap delete and confirm succeeds", (tester) async {
  //   final nodeService = MockNodeService();
  //   final navigator = mockingjay.MockNavigator();
  //
  //   when(nodeService.activeNodeName).thenAnswer((_) => "Campfire default");
  //   when(nodeService.deleteNode("some other node"))
  //       .thenAnswer((_) async => true);
  //
  //   mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
  //
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: mockingjay.MockNavigatorProvider(
  //         navigator: navigator,
  //         child: MultiProvider(
  //           providers: [
  //             ChangeNotifierProvider<NodeService>(
  //               create: (_) => nodeService,
  //             ),
  //           ],
  //           child: NodeCard(
  //             nodeName: "some other node",
  //             nodeData: {
  //               "port": "9000",
  //               "ipAddress": "some url",
  //               "useSSL": true,
  //             },
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  //   await tester.pumpAndSettle();
  //
  //   expect(find.text("some other node"), findsOneWidget);
  //   expect(find.byType(Text), findsNWidgets(1));
  //   expect(find.byType(SvgPicture), findsOneWidget);
  //
  //   await tester.tap(find.byType(NodeCard));
  //   await tester.pumpAndSettle();
  //
  //   expect(find.text("Connect"), findsOneWidget);
  //   expect(find.text("Details"), findsOneWidget);
  //   expect(find.text("Edit"), findsOneWidget);
  //   expect(find.text("Delete"), findsOneWidget);
  //   expect(find.byType(Text), findsNWidgets(5));
  //
  //   await tester.tap(find.text("Delete"));
  //   await tester.pumpAndSettle();
  //
  //   expect(find.byType(ModalPopupDialog), findsOneWidget);
  //   expect(find.byType(SimpleButton), findsOneWidget);
  //   expect(find.byType(GradientButton), findsOneWidget);
  //   expect(find.text("CANCEL"), findsOneWidget);
  //   expect(find.text("DELETE"), findsOneWidget);
  //   expect(find.text("Do you want to delete some other node?"), findsOneWidget);
  //
  //   await tester.tap(find.byType(GradientButton));
  //   await tester.pumpAndSettle();
  //
  //   expect(find.byType(CampfireAlert), findsNothing);
  //   expect(find.text("Error: Could not delete node named \"some other node\"!"),
  //       findsNothing);
  //
  //   verify(nodeService.activeNodeName).called(1);
  //   verify(nodeService.addListener(any)).called(1);
  //   verify(nodeService.deleteNode("some other node")).called(1);
  //
  //   verifyNoMoreInteractions(nodeService);
  //
  //   mockingjay.verify(() => navigator.pop()).called(2);
  //
  //   mockingjay.verifyNoMoreInteractions(navigator);
  // });
}
