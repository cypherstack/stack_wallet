// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:epicmobile/pages/settings_view/settings_subviews/network_settings_view.dart';
import 'package:epicmobile/services/node_service.dart';
// import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
// import 'package:epicmobile/widgets/node_card.dart';
// import 'package:provider/provider.dart';
//
// import 'network_settings_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<NodeService>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("NetworkSettingsView builds correctly", (tester) async {
//     final nodeService = MockNodeService();
//
//     when(nodeService.activeNodeName).thenAnswer((_) => "Campfire default");
//     when(nodeService.nodes).thenAnswer((_) => {
//           "Campfire default": {
//             "id": "some uuid",
//             "ipAddress": "some url",
//             "port": "9000",
//             "useSSL": true,
//           }
//         });
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<NodeService>(
//               create: (_) => nodeService,
//             ),
//           ],
//           child: NetworkSettingsView(),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsNWidgets(2));
//     expect(find.byType(SvgPicture), findsNWidgets(4));
//     expect(find.text("Network"), findsOneWidget);
//     expect(find.text("Blockchain Status"), findsOneWidget);
//     expect(find.text("Synchronized"), findsOneWidget);
//     expect(find.text("My Nodes"), findsOneWidget);
//     expect(find.byType(NodeCard), findsOneWidget);
//
//     verify(nodeService.nodes).called(1);
//     verify(nodeService.activeNodeName).called(1);
//     verify(nodeService.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(nodeService);
//   });
//
//   testWidgets("tap back", (tester) async {
//     final nodeService = MockNodeService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(nodeService.activeNodeName).thenAnswer((_) => "Campfire default");
//     when(nodeService.nodes).thenAnswer((_) => {
//           "Campfire default": {
//             "id": "some uuid",
//             "ipAddress": "some url",
//             "port": "9000",
//             "useSSL": true,
//           }
//         });
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) => {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<NodeService>(
//                 create: (_) => nodeService,
//               ),
//             ],
//             child: NetworkSettingsView(),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsNWidgets(2));
//     expect(find.byType(SvgPicture), findsNWidgets(4));
//     expect(find.text("Network"), findsOneWidget);
//     expect(find.text("Blockchain Status"), findsOneWidget);
//     expect(find.text("Synchronized"), findsOneWidget);
//     expect(find.text("My Nodes"), findsOneWidget);
//     expect(find.byType(NodeCard), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("settingsAppBarBackButton")));
//     await tester.pump(Duration(milliseconds: 100));
//
//     verify(nodeService.nodes).called(2);
//     verify(nodeService.activeNodeName).called(2);
//     verify(nodeService.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(nodeService);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap add", (tester) async {
//     final nodeService = MockNodeService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(nodeService.activeNodeName).thenAnswer((_) => "Campfire default");
//     when(nodeService.nodes).thenAnswer((_) => {
//           "Campfire default": {
//             "id": "some uuid",
//             "ipAddress": "some url",
//             "port": "9000",
//             "useSSL": true,
//           }
//         });
//
//     mockingjay
//         .when(() => navigator.pushNamed("/settings/addcustomnode"))
//         .thenAnswer((_) async => {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<NodeService>(
//                 create: (_) => nodeService,
//               ),
//             ],
//             child: NetworkSettingsView(),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsNWidgets(2));
//     expect(find.byType(SvgPicture), findsNWidgets(4));
//     expect(find.text("Network"), findsOneWidget);
//     expect(find.text("Blockchain Status"), findsOneWidget);
//     expect(find.text("Synchronized"), findsOneWidget);
//     expect(find.text("My Nodes"), findsOneWidget);
//     expect(find.byType(NodeCard), findsOneWidget);
//
//     await tester.tap(find.byKey(Key("networkSettingsAddNodeButtonKey")));
//     await tester.pumpAndSettle();
//
//     verify(nodeService.nodes).called(1);
//     verify(nodeService.activeNodeName).called(1);
//     verify(nodeService.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(nodeService);
//
//     mockingjay
//         .verify(() => navigator.pushNamed("/settings/addcustomnode"))
//         .called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("node status events", (tester) async {
//     fail("waiting for icon designs");
//
//     final nodeService = MockNodeService();
//
//     when(nodeService.activeNodeName).thenAnswer((_) => "Campfire default");
//     when(nodeService.nodes).thenAnswer((_) => {
//           "Campfire default": {
//             "id": "some uuid",
//             "ipAddress": "some url",
//             "port": "9000",
//             "useSSL": true,
//           }
//         });
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<NodeService>(
//               create: (_) => nodeService,
//             ),
//           ],
//           child: NetworkSettingsView(),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsNWidgets(2));
//     expect(find.byType(SvgPicture), findsNWidgets(4));
//     expect(find.text("Network"), findsOneWidget);
//     expect(find.text("Blockchain Status"), findsOneWidget);
//     expect(find.text("Synchronized"), findsOneWidget);
//     expect(find.text("My Nodes"), findsOneWidget);
//     expect(find.byType(NodeCard), findsOneWidget);
//
//     verify(nodeService.nodes).called(1);
//     verify(nodeService.activeNodeName).called(1);
//     verify(nodeService.addListener(any)).called(1);
//
//     verifyNoMoreInteractions(nodeService);
//   });
}
