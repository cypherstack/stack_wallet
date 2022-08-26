// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:stackwallet/notifications/campfire_alert.dart';
// import 'package:stackwallet/notifications/modal_popup_dialog.dart';
// import 'package:stackwallet/pages/settings_view/settings_subviews/network_settings_subviews/node_details_view.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/node_service.dart';
// import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
// import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';
// import 'package:stackwallet/widgets/custom_buttons/simple_button.dart';
// import 'package:provider/provider.dart';
//
// import 'node_details_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<NodeService>(returnNullOnMissingStub: true),
  MockSpec<Manager>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("NodeDetailsView non-editing builds correctly", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: NodeDetailsView(
//           isEdit: false,
//           nodeName: "name",
//           nodeData: {
//             "id": "some uuid",
//             "ipAddress": "some url",
//             "port": "9000",
//             "useSSL": true,
//           },
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsNWidgets(2));
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//     expect(find.byType(Text), findsNWidgets(3));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//     expect(find.text("Node Details"), findsOneWidget);
//     expect(find.text("name"), findsOneWidget);
//     expect(find.text("some url"), findsOneWidget);
//     expect(find.text("9000"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect((find.byType(Checkbox).evaluate().first.widget as Checkbox).value,
//         true);
//     expect(
//         (find.byType(SimpleButton).evaluate().first.widget as SimpleButton)
//             .enabled,
//         true);
//   });
//
//   testWidgets("tap more then edit", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
//     mockingjay
//         .when(() => navigator.push(mockingjay.any()))
//         .thenAnswer((_) async {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: NodeDetailsView(
//             isEdit: false,
//             nodeName: "name",
//             nodeData: {
//               "id": "some uuid",
//               "ipAddress": "some url",
//               "port": "9000",
//               "useSSL": true,
//             },
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("nodeDetailsViewMoreButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsNWidgets(2));
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//     expect(find.byType(Text), findsNWidgets(5));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//     expect(find.text("Node Details"), findsOneWidget);
//     expect(find.text("name"), findsOneWidget);
//     expect(find.text("some url"), findsOneWidget);
//     expect(find.text("9000"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect((find.byType(Checkbox).evaluate().first.widget as Checkbox).value,
//         true);
//     expect(
//         (find.byType(SimpleButton).evaluate().first.widget as SimpleButton)
//             .enabled,
//         true);
//
//     expect(find.text("Edit node"), findsOneWidget);
//     expect(find.text("Delete node"), findsOneWidget);
//
//     await tester.tap(find.text("Edit node"));
//     await tester.pumpAndSettle();
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//     mockingjay
//         .verify(() => navigator.push(mockingjay.any(
//             that: mockingjay.isRoute(whereName: equals("/more/editnode")))))
//         .called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap more, then delete, and finally cancel", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: NodeDetailsView(
//             isEdit: false,
//             nodeName: "name",
//             nodeData: {
//               "id": "some uuid",
//               "ipAddress": "some url",
//               "port": "9000",
//               "useSSL": true,
//             },
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("nodeDetailsViewMoreButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsNWidgets(2));
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//     expect(find.byType(Text), findsNWidgets(5));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//     expect(find.text("Node Details"), findsOneWidget);
//     expect(find.text("name"), findsOneWidget);
//     expect(find.text("some url"), findsOneWidget);
//     expect(find.text("9000"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect((find.byType(Checkbox).evaluate().first.widget as Checkbox).value,
//         true);
//     expect(
//         (find.byType(SimpleButton).evaluate().first.widget as SimpleButton)
//             .enabled,
//         true);
//
//     expect(find.text("Edit node"), findsOneWidget);
//     expect(find.text("Delete node"), findsOneWidget);
//
//     await tester.tap(find.text("Delete node"));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(ModalPopupDialog), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsNWidgets(2));
//     expect(find.text("Do you want to delete name?"), findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("DELETE"), findsOneWidget);
//
//     await tester
//         .tap(find.byKey(Key("nodeDetailsConfirmDeleteCancelButtonKey")));
//     await tester.pumpAndSettle();
//
//     mockingjay.verify(() => navigator.pop()).called(2);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap more, then delete, and finally confirm where delete fails",
//       (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final nodeService = MockNodeService();
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
//
//     when(nodeService.deleteNode("name")).thenAnswer((_) async => false);
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
//             child: NodeDetailsView(
//               isEdit: false,
//               nodeName: "name",
//               nodeData: {
//                 "id": "some uuid",
//                 "ipAddress": "some url",
//                 "port": "9000",
//                 "useSSL": true,
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("nodeDetailsViewMoreButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsNWidgets(2));
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//     expect(find.byType(Text), findsNWidgets(5));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//     expect(find.text("Node Details"), findsOneWidget);
//     expect(find.text("name"), findsOneWidget);
//     expect(find.text("some url"), findsOneWidget);
//     expect(find.text("9000"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect((find.byType(Checkbox).evaluate().first.widget as Checkbox).value,
//         true);
//     expect(
//         (find.byType(SimpleButton).evaluate().first.widget as SimpleButton)
//             .enabled,
//         true);
//
//     expect(find.text("Edit node"), findsOneWidget);
//     expect(find.text("Delete node"), findsOneWidget);
//
//     await tester.tap(find.text("Delete node"));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(ModalPopupDialog), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsNWidgets(2));
//     expect(find.text("Do you want to delete name?"), findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("DELETE"), findsOneWidget);
//
//     await tester
//         .tap(find.byKey(Key("nodeDetailsConfirmDeleteConfirmButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(CampfireAlert), findsOneWidget);
//     expect(find.text("Error: Could not delete node named \"name\"!"),
//         findsOneWidget);
//
//     verify(nodeService.addListener(any)).called(1);
//     verify(nodeService.deleteNode("name")).called(1);
//
//     verifyNoMoreInteractions(nodeService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets(
//       "tap more, then delete, and finally confirm where delete succeeds",
//       (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final nodeService = MockNodeService();
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
//
//     when(nodeService.deleteNode("name")).thenAnswer((_) async => true);
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
//             child: NodeDetailsView(
//               isEdit: false,
//               nodeName: "name",
//               nodeData: {
//                 "id": "some uuid",
//                 "ipAddress": "some url",
//                 "port": "9000",
//                 "useSSL": true,
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byKey(Key("nodeDetailsViewMoreButtonKey")));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsNWidgets(2));
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//     expect(find.byType(Text), findsNWidgets(5));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//     expect(find.text("Node Details"), findsOneWidget);
//     expect(find.text("name"), findsOneWidget);
//     expect(find.text("some url"), findsOneWidget);
//     expect(find.text("9000"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect((find.byType(Checkbox).evaluate().first.widget as Checkbox).value,
//         true);
//     expect(
//         (find.byType(SimpleButton).evaluate().first.widget as SimpleButton)
//             .enabled,
//         true);
//
//     expect(find.text("Edit node"), findsOneWidget);
//     expect(find.text("Delete node"), findsOneWidget);
//
//     await tester.tap(find.text("Delete node"));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(ModalPopupDialog), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsNWidgets(2));
//     expect(find.text("Do you want to delete name?"), findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("DELETE"), findsOneWidget);
//
//     await tester
//         .tap(find.byKey(Key("nodeDetailsConfirmDeleteConfirmButtonKey")));
//     await tester.pumpAndSettle();
//
//     verify(nodeService.addListener(any)).called(1);
//     verify(nodeService.deleteNode("name")).called(1);
//
//     verifyNoMoreInteractions(nodeService);
//
//     mockingjay.verify(() => navigator.pop()).called(3);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap test connection fails", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final manager = MockManager();
//
//     when(manager.testNetworkConnection(any)).thenAnswer((_) async => false);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//             ],
//             child: NodeDetailsView(
//               isEdit: false,
//               nodeName: "name",
//               nodeData: {
//                 "id": "some uuid",
//                 "ipAddress": "some url",
//                 "port": "9000",
//                 "useSSL": false,
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsNWidgets(2));
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//     expect(find.byType(Text), findsNWidgets(3));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//     expect(find.text("Node Details"), findsOneWidget);
//     expect(find.text("name"), findsOneWidget);
//     expect(find.text("some url"), findsOneWidget);
//     expect(find.text("9000"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect((find.byType(Checkbox).evaluate().first.widget as Checkbox).value,
//         false);
//     expect(
//         (find.byType(SimpleButton).evaluate().first.widget as SimpleButton)
//             .enabled,
//         true);
//
//     await tester.tap(find.byType(SimpleButton));
//     await tester.pump(Duration(milliseconds: 200));
//
//     expect(find.text("Connection failed!"), findsOneWidget);
//     await tester.pump(Duration(seconds: 2));
//
//     expect(find.text("Connection failed!"), findsNothing);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.testNetworkConnection(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap test connection succeeds", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final manager = MockManager();
//
//     when(manager.testNetworkConnection(any)).thenAnswer((_) async => true);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: MultiProvider(
//             providers: [
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//             ],
//             child: NodeDetailsView(
//               isEdit: false,
//               nodeName: "name",
//               nodeData: {
//                 "id": "some uuid",
//                 "ipAddress": "some url",
//                 "port": "9000",
//                 "useSSL": false,
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsNWidgets(2));
//     expect(find.byType(SvgPicture), findsNWidgets(2));
//     expect(find.byType(Text), findsNWidgets(3));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//     expect(find.text("Node Details"), findsOneWidget);
//     expect(find.text("name"), findsOneWidget);
//     expect(find.text("some url"), findsOneWidget);
//     expect(find.text("9000"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect((find.byType(Checkbox).evaluate().first.widget as Checkbox).value,
//         false);
//     expect(
//         (find.byType(SimpleButton).evaluate().first.widget as SimpleButton)
//             .enabled,
//         true);
//
//     await tester.tap(find.byType(SimpleButton));
//     await tester.pump(Duration(milliseconds: 200));
//
//     expect(find.text("Connection test passed!"), findsOneWidget);
//     await tester.pump(Duration(seconds: 2));
//
//     expect(find.text("Connection test passed!"), findsNothing);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.testNetworkConnection(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("NodeDetailsView editing builds correctly", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: NodeDetailsView(
//           isEdit: true,
//           nodeName: "name",
//           nodeData: {
//             "id": "some uuid",
//             "ipAddress": "some url",
//             "port": "9000",
//             "useSSL": false,
//           },
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(4));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.text("Edit Node"), findsOneWidget);
//     expect(find.text("name"), findsOneWidget);
//     expect(find.text("some url"), findsOneWidget);
//     expect(find.text("9000"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect((find.byType(Checkbox).evaluate().first.widget as Checkbox).value,
//         false);
//     expect(
//         (find.byType(SimpleButton).evaluate().first.widget as SimpleButton)
//             .enabled,
//         true);
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         false);
//   });
//
//   testWidgets("check save and test button state based on textfield content",
//       (tester) async {
//     final navigator = mockingjay.MockNavigator();
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: NodeDetailsView(
//             isEdit: true,
//             nodeName: "name",
//             nodeData: {
//               "id": "some uuid",
//               "ipAddress": "some url",
//               "port": "9000",
//               "useSSL": false,
//             },
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(4));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.text("Edit Node"), findsOneWidget);
//     expect(find.text("name"), findsOneWidget);
//     expect(find.text("some url"), findsOneWidget);
//     expect(find.text("9000"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect((find.byType(Checkbox).evaluate().first.widget as Checkbox).value,
//         false);
//     expect(
//         (find.byType(SimpleButton).evaluate().first.widget as SimpleButton)
//             .enabled,
//         true);
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         false);
//
//     await tester.enterText(find.byKey(Key("editNodeNodePortFieldKey")), "");
//     await tester.pumpAndSettle();
//     expect(
//         (find.byType(SimpleButton).evaluate().first.widget as SimpleButton)
//             .enabled,
//         false);
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         false);
//
//     await tester.enterText(find.byKey(Key("editNodeAddressFieldKey")), "");
//     await tester.pumpAndSettle();
//     expect(
//         (find.byType(SimpleButton).evaluate().first.widget as SimpleButton)
//             .enabled,
//         false);
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         false);
//
//     await tester.enterText(find.byKey(Key("editNodeNodeNameFieldKey")), "");
//     await tester.pumpAndSettle();
//     expect(
//         (find.byType(SimpleButton).evaluate().first.widget as SimpleButton)
//             .enabled,
//         false);
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         false);
//
//     await tester.enterText(
//         find.byKey(Key("editNodeAddressFieldKey")), "someaddress");
//     await tester.pumpAndSettle();
//     expect(
//         (find.byType(SimpleButton).evaluate().first.widget as SimpleButton)
//             .enabled,
//         false);
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         false);
//
//     await tester.enterText(find.byKey(Key("editNodeNodePortFieldKey")), "100");
//     await tester.pumpAndSettle();
//     expect(
//         (find.byType(SimpleButton).evaluate().first.widget as SimpleButton)
//             .enabled,
//         true);
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         false);
//
//     await tester.enterText(find.byKey(Key("editNodeNodeNameFieldKey")), "name");
//     await tester.pumpAndSettle();
//     expect(
//         (find.byType(SimpleButton).evaluate().first.widget as SimpleButton)
//             .enabled,
//         true);
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         true);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap back", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: NodeDetailsView(
//             isEdit: true,
//             nodeName: "name",
//             nodeData: {
//               "id": "some uuid",
//               "ipAddress": "some url",
//               "port": "9000",
//               "useSSL": false,
//             },
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(4));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.text("Edit Node"), findsOneWidget);
//     expect(find.text("name"), findsOneWidget);
//     expect(find.text("some url"), findsOneWidget);
//     expect(find.text("9000"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect((find.byType(Checkbox).evaluate().first.widget as Checkbox).value,
//         false);
//     expect(
//         (find.byType(SimpleButton).evaluate().first.widget as SimpleButton)
//             .enabled,
//         true);
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         false);
//
//     await tester.tap(find.byKey(Key("nodeDetailsViewBackButtonKey")));
//     await tester.pump(Duration(milliseconds: 100));
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap save fails", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final nodeService = MockNodeService();
//
//     when(nodeService.editNode(
//       id: "some uuid",
//       originalName: "name",
//       updatedName: "name2",
//       updatedIpAddress: "new url",
//       updatedPort: "42",
//       useSSL: true,
//     )).thenAnswer((_) async => false);
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
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
//             child: NodeDetailsView(
//               isEdit: true,
//               nodeName: "name",
//               nodeData: {
//                 "id": "some uuid",
//                 "ipAddress": "some url",
//                 "port": "9000",
//                 "useSSL": false,
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(4));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.text("Edit Node"), findsOneWidget);
//     expect(find.text("name"), findsOneWidget);
//     expect(find.text("some url"), findsOneWidget);
//     expect(find.text("9000"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect((find.byType(Checkbox).evaluate().first.widget as Checkbox).value,
//         false);
//     expect(
//         (find.byType(SimpleButton).evaluate().first.widget as SimpleButton)
//             .enabled,
//         true);
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         false);
//
//     await tester.enterText(find.byKey(Key("editNodeNodePortFieldKey")), "42");
//     await tester.enterText(
//         find.byKey(Key("editNodeNodeNameFieldKey")), "name2");
//     await tester.enterText(
//         find.byKey(Key("editNodeAddressFieldKey")), "new url");
//     await tester.tap(find.byType(Checkbox));
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(CampfireAlert), findsOneWidget);
//     expect(find.text("A node with the name \"name2\" already exists!"),
//         findsOneWidget);
//
//     verify(nodeService.addListener(any)).called(1);
//     verify(nodeService.editNode(
//       id: "some uuid",
//       originalName: "name",
//       updatedName: "name2",
//       updatedIpAddress: "new url",
//       updatedPort: "42",
//       useSSL: true,
//     )).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap save succeeds", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//     final nodeService = MockNodeService();
//
//     when(nodeService.editNode(
//       id: "some uuid",
//       originalName: "name",
//       updatedName: "name",
//       updatedIpAddress: "new url",
//       updatedPort: "42",
//       useSSL: true,
//     )).thenAnswer((_) async => true);
//
//     mockingjay
//         .when(() => navigator.popUntil(mockingjay.any()))
//         .thenAnswer((_) {});
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
//             child: NodeDetailsView(
//               isEdit: true,
//               nodeName: "name",
//               nodeData: {
//                 "id": "some uuid",
//                 "ipAddress": "some url",
//                 "port": "9000",
//                 "useSSL": false,
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//     await tester.pumpAndSettle();
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(SvgPicture), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(4));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.text("Edit Node"), findsOneWidget);
//     expect(find.text("name"), findsOneWidget);
//     expect(find.text("some url"), findsOneWidget);
//     expect(find.text("9000"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect((find.byType(Checkbox).evaluate().first.widget as Checkbox).value,
//         false);
//     expect(
//         (find.byType(SimpleButton).evaluate().first.widget as SimpleButton)
//             .enabled,
//         true);
//     expect(
//         (find.byType(GradientButton).evaluate().first.widget as GradientButton)
//             .enabled,
//         false);
//
//     await tester.enterText(find.byKey(Key("editNodeNodePortFieldKey")), "42");
//     await tester.enterText(
//         find.byKey(Key("editNodeAddressFieldKey")), "new url");
//     await tester.tap(find.byType(Checkbox));
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pump(Duration(milliseconds: 300));
//
//     verify(nodeService.addListener(any)).called(1);
//     verify(nodeService.editNode(
//       id: "some uuid",
//       originalName: "name",
//       updatedName: "name",
//       updatedIpAddress: "new url",
//       updatedPort: "42",
//       useSSL: true,
//     )).called(1);
//
//     mockingjay.verify(() => navigator.popUntil(mockingjay.any())).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
}
