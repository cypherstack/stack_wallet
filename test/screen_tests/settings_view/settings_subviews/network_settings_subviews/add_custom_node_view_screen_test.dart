// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:stackwallet/notifications/campfire_alert.dart';
// import 'package:stackwallet/pages/settings_view/settings_subviews/network_settings_subviews/add_custom_node_view.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/node_service.dart';

// import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';
// import 'package:stackwallet/widgets/custom_buttons/simple_button.dart';
// import 'package:provider/provider.dart';
//
// import 'add_custom_node_view_screen_test.mocks.dart';
//
@GenerateMocks([], customMocks: [
  MockSpec<NodeService>(returnNullOnMissingStub: true),
  MockSpec<Manager>(returnNullOnMissingStub: true),
])
void main() {
//   testWidgets("AddCustomNodeView builds correctly", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: AddCustomNodeView(),
//       ),
//     );
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(7));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.text("Add custom node"), findsOneWidget);
//     expect(find.text("Node name"), findsOneWidget);
//     expect(find.text("IP address"), findsOneWidget);
//     expect(find.text("Port"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     final saveButton =
//         find.byType(GradientButton).evaluate().first.widget as GradientButton;
//     final testButton =
//         find.byType(SimpleButton).evaluate().first.widget as SimpleButton;
//     expect(saveButton.enabled, false);
//     expect(testButton.enabled, false);
//
//     final checkbox = find.byType(Checkbox).evaluate().first.widget as Checkbox;
//     expect(checkbox.value, false);
//   });
//
//   testWidgets("tap back", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) => {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: AddCustomNodeView(),
//         ),
//       ),
//     );
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(7));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.text("Add custom node"), findsOneWidget);
//     expect(find.text("Node name"), findsOneWidget);
//     expect(find.text("IP address"), findsOneWidget);
//     expect(find.text("Port"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     final saveButton =
//         find.byType(GradientButton).evaluate().first.widget as GradientButton;
//     final testButton =
//         find.byType(SimpleButton).evaluate().first.widget as SimpleButton;
//     expect(saveButton.enabled, false);
//     expect(testButton.enabled, false);
//
//     final checkbox = find.byType(Checkbox).evaluate().first.widget as Checkbox;
//     expect(checkbox.value, false);
//
//     await tester.tap(find.byType(AppBarIconButton));
//     await tester.pump(Duration(milliseconds: 100));
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap to enable then disable ssl", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: AddCustomNodeView(),
//       ),
//     );
//     final checkbox = find.byType(Checkbox).evaluate().first.widget as Checkbox;
//     expect(checkbox.value, false);
//
//     await tester.tap(find.byWidget(checkbox));
//     await tester.pumpAndSettle();
//
//     expect((find.byType(Checkbox).evaluate().first.widget as Checkbox).value,
//         true);
//
//     await tester.tap(find.byType(Checkbox));
//     await tester.pumpAndSettle();
//
//     expect((find.byType(Checkbox).evaluate().first.widget as Checkbox).value,
//         false);
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(7));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.text("Add custom node"), findsOneWidget);
//     expect(find.text("Node name"), findsOneWidget);
//     expect(find.text("IP address"), findsOneWidget);
//     expect(find.text("Port"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     final saveButton =
//         find.byType(GradientButton).evaluate().first.widget as GradientButton;
//     final testButton =
//         find.byType(SimpleButton).evaluate().first.widget as SimpleButton;
//     expect(saveButton.enabled, false);
//     expect(testButton.enabled, false);
//   });
//
//   testWidgets("enter only a name", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: AddCustomNodeView(),
//       ),
//     );
//
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodeNameFieldKey")), "name");
//     await tester.pumpAndSettle();
//
//     expect(find.text("name"), findsOneWidget);
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(7));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.text("Add custom node"), findsOneWidget);
//     expect(find.text("Node name"), findsOneWidget);
//     expect(find.text("IP address"), findsOneWidget);
//     expect(find.text("Port"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     final saveButton =
//         find.byType(GradientButton).evaluate().first.widget as GradientButton;
//     final testButton =
//         find.byType(SimpleButton).evaluate().first.widget as SimpleButton;
//     expect(saveButton.enabled, false);
//     expect(testButton.enabled, false);
//
//     final checkbox = find.byType(Checkbox).evaluate().first.widget as Checkbox;
//     expect(checkbox.value, false);
//   });
//
//   testWidgets("enter only a name and port", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: AddCustomNodeView(),
//       ),
//     );
//
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodeNameFieldKey")), "name");
//     await tester.pumpAndSettle();
//
//     expect(find.text("name"), findsOneWidget);
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(7));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.text("Add custom node"), findsOneWidget);
//     expect(find.text("Node name"), findsOneWidget);
//     expect(find.text("IP address"), findsOneWidget);
//     expect(find.text("Port"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     final saveButton =
//         find.byType(GradientButton).evaluate().first.widget as GradientButton;
//     final testButton =
//         find.byType(SimpleButton).evaluate().first.widget as SimpleButton;
//     expect(saveButton.enabled, false);
//     expect(testButton.enabled, false);
//
//     final checkbox = find.byType(Checkbox).evaluate().first.widget as Checkbox;
//     expect(checkbox.value, false);
//   });
//
//   testWidgets("enter only a name and port", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: AddCustomNodeView(),
//       ),
//     );
//
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodeNameFieldKey")), "name");
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodePortFieldKey")), "9000");
//     await tester.pumpAndSettle();
//
//     expect(find.text("name"), findsOneWidget);
//     expect(find.text("9000"), findsOneWidget);
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(7));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.text("Add custom node"), findsOneWidget);
//     expect(find.text("Node name"), findsOneWidget);
//     expect(find.text("IP address"), findsOneWidget);
//     expect(find.text("Port"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     final saveButton =
//         find.byType(GradientButton).evaluate().first.widget as GradientButton;
//     final testButton =
//         find.byType(SimpleButton).evaluate().first.widget as SimpleButton;
//     expect(saveButton.enabled, false);
//     expect(testButton.enabled, false);
//
//     final checkbox = find.byType(Checkbox).evaluate().first.widget as Checkbox;
//     expect(checkbox.value, false);
//   });
//
//   testWidgets("enter only a name and address", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: AddCustomNodeView(),
//       ),
//     );
//
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodeNameFieldKey")), "name");
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodeAddressFieldKey")), "mynode.com");
//     await tester.pumpAndSettle();
//
//     expect(find.text("name"), findsOneWidget);
//     expect(find.text("mynode.com"), findsOneWidget);
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(7));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.text("Add custom node"), findsOneWidget);
//     expect(find.text("Node name"), findsOneWidget);
//     expect(find.text("IP address"), findsOneWidget);
//     expect(find.text("Port"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     final saveButton =
//         find.byType(GradientButton).evaluate().first.widget as GradientButton;
//     final testButton =
//         find.byType(SimpleButton).evaluate().first.widget as SimpleButton;
//     expect(saveButton.enabled, false);
//     expect(testButton.enabled, false);
//
//     final checkbox = find.byType(Checkbox).evaluate().first.widget as Checkbox;
//     expect(checkbox.value, false);
//   });
//
//   testWidgets("enter only a port and address", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: AddCustomNodeView(),
//       ),
//     );
//
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodePortFieldKey")), "9000");
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodeAddressFieldKey")), "mynode.com");
//     await tester.pumpAndSettle();
//
//     expect(find.text("9000"), findsOneWidget);
//     expect(find.text("mynode.com"), findsOneWidget);
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(7));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.text("Add custom node"), findsOneWidget);
//     expect(find.text("Node name"), findsOneWidget);
//     expect(find.text("IP address"), findsOneWidget);
//     expect(find.text("Port"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     final saveButton =
//         find.byType(GradientButton).evaluate().first.widget as GradientButton;
//     final testButton =
//         find.byType(SimpleButton).evaluate().first.widget as SimpleButton;
//     expect(saveButton.enabled, false);
//     expect(testButton.enabled, true);
//
//     final checkbox = find.byType(Checkbox).evaluate().first.widget as Checkbox;
//     expect(checkbox.value, false);
//   });
//
//   testWidgets("enter a name, a port, and an address", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: AddCustomNodeView(),
//       ),
//     );
//
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodePortFieldKey")), "9000");
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodeAddressFieldKey")), "mynode.com");
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodeNameFieldKey")), "name");
//     await tester.pumpAndSettle();
//
//     expect(find.text("name"), findsOneWidget);
//     expect(find.text("9000"), findsOneWidget);
//     expect(find.text("mynode.com"), findsOneWidget);
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(7));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.text("Add custom node"), findsOneWidget);
//     expect(find.text("Node name"), findsOneWidget);
//     expect(find.text("IP address"), findsOneWidget);
//     expect(find.text("Port"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     final saveButton =
//         find.byType(GradientButton).evaluate().first.widget as GradientButton;
//     final testButton =
//         find.byType(SimpleButton).evaluate().first.widget as SimpleButton;
//     expect(saveButton.enabled, true);
//     expect(testButton.enabled, true);
//
//     final checkbox = find.byType(Checkbox).evaluate().first.widget as Checkbox;
//     expect(checkbox.value, false);
//   });
//
//   testWidgets("tap disabled test", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: AddCustomNodeView(),
//       ),
//     );
//
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(7));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.text("Add custom node"), findsOneWidget);
//     expect(find.text("Node name"), findsOneWidget);
//     expect(find.text("IP address"), findsOneWidget);
//     expect(find.text("Port"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     final saveButton =
//         find.byType(GradientButton).evaluate().first.widget as GradientButton;
//     final testButton =
//         find.byType(SimpleButton).evaluate().first.widget as SimpleButton;
//     expect(saveButton.enabled, false);
//     expect(testButton.enabled, false);
//
//     final checkbox = find.byType(Checkbox).evaluate().first.widget as Checkbox;
//     expect(checkbox.value, false);
//
//     await tester.tap(find.byWidget(testButton));
//     await tester.pump(Duration(milliseconds: 200));
//
//     expect(find.text("Connection failed!"), findsNothing);
//   });
//
//   testWidgets("tap enabled test where connection fails", (tester) async {
//     final manager = MockManager();
//
//     when(manager.testNetworkConnection(any)).thenAnswer((_) async => false);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//           ],
//           child: AddCustomNodeView(),
//         ),
//       ),
//     );
//
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodePortFieldKey")), "9000");
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodeAddressFieldKey")), "mynode.com");
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodeNameFieldKey")), "name");
//     await tester.pumpAndSettle();
//
//     expect(find.text("name"), findsOneWidget);
//     expect(find.text("9000"), findsOneWidget);
//     expect(find.text("mynode.com"), findsOneWidget);
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(7));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.text("Add custom node"), findsOneWidget);
//     expect(find.text("Node name"), findsOneWidget);
//     expect(find.text("IP address"), findsOneWidget);
//     expect(find.text("Port"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     final saveButton =
//         find.byType(GradientButton).evaluate().first.widget as GradientButton;
//     final testButton =
//         find.byType(SimpleButton).evaluate().first.widget as SimpleButton;
//     expect(saveButton.enabled, true);
//     expect(testButton.enabled, true);
//
//     final checkbox = find.byType(Checkbox).evaluate().first.widget as Checkbox;
//     expect(checkbox.value, false);
//
//     await tester.tap(find.byWidget(testButton));
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
//   });
//
//   testWidgets("tap enabled test where connection succeeds", (tester) async {
//     final manager = MockManager();
//
//     when(manager.testNetworkConnection(any)).thenAnswer((_) async => true);
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: MultiProvider(
//           providers: [
//             ChangeNotifierProvider<Manager>(
//               create: (_) => manager,
//             ),
//           ],
//           child: AddCustomNodeView(),
//         ),
//       ),
//     );
//
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodePortFieldKey")), "9000");
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodeAddressFieldKey")), "mynode.com");
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodeNameFieldKey")), "name");
//     await tester.pumpAndSettle();
//
//     expect(find.text("name"), findsOneWidget);
//     expect(find.text("9000"), findsOneWidget);
//     expect(find.text("mynode.com"), findsOneWidget);
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(7));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.text("Add custom node"), findsOneWidget);
//     expect(find.text("Node name"), findsOneWidget);
//     expect(find.text("IP address"), findsOneWidget);
//     expect(find.text("Port"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     final saveButton =
//         find.byType(GradientButton).evaluate().first.widget as GradientButton;
//     final testButton =
//         find.byType(SimpleButton).evaluate().first.widget as SimpleButton;
//     expect(saveButton.enabled, true);
//     expect(testButton.enabled, true);
//
//     final checkbox = find.byType(Checkbox).evaluate().first.widget as Checkbox;
//     expect(checkbox.value, false);
//
//     await tester.tap(find.byWidget(testButton));
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
//   });
//
//   testWidgets("tap enabled save where save and node creation succeeds",
//       (tester) async {
//     final manager = MockManager();
//     final nodeService = MockNodeService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(manager.testNetworkConnection(any)).thenAnswer((_) async => true);
//
//     when(nodeService.createNode(
//       name: "name",
//       ipAddress: "mynode.com",
//       port: "9000",
//       useSSL: false,
//     )).thenAnswer((_) async => true);
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
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
//               ChangeNotifierProvider<NodeService>(
//                 create: (_) => nodeService,
//               ),
//             ],
//             child: AddCustomNodeView(),
//           ),
//         ),
//       ),
//     );
//
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodePortFieldKey")), "9000");
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodeAddressFieldKey")), "mynode.com");
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodeNameFieldKey")), "name");
//     await tester.pumpAndSettle();
//
//     expect(find.text("name"), findsOneWidget);
//     expect(find.text("9000"), findsOneWidget);
//     expect(find.text("mynode.com"), findsOneWidget);
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(7));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.text("Add custom node"), findsOneWidget);
//     expect(find.text("Node name"), findsOneWidget);
//     expect(find.text("IP address"), findsOneWidget);
//     expect(find.text("Port"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     final saveButton =
//         find.byType(GradientButton).evaluate().first.widget as GradientButton;
//     final testButton =
//         find.byType(SimpleButton).evaluate().first.widget as SimpleButton;
//     expect(saveButton.enabled, true);
//     expect(testButton.enabled, true);
//
//     final checkbox = find.byType(Checkbox).evaluate().first.widget as Checkbox;
//     expect(checkbox.value, false);
//
//     await tester.tap(find.byWidget(saveButton));
//     await tester.pump(Duration(milliseconds: 300));
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.testNetworkConnection(any)).called(1);
//
//     verify(nodeService.addListener(any)).called(1);
//     verify(nodeService.createNode(
//       name: "name",
//       ipAddress: "mynode.com",
//       port: "9000",
//       useSSL: false,
//     )).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(nodeService);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap enabled save where save and node creation fails",
//       (tester) async {
//     final manager = MockManager();
//     final nodeService = MockNodeService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(manager.testNetworkConnection(any)).thenAnswer((_) async => true);
//
//     when(nodeService.createNode(
//       name: "name",
//       ipAddress: "mynode.com",
//       port: "9000",
//       useSSL: false,
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
//               ChangeNotifierProvider<Manager>(
//                 create: (_) => manager,
//               ),
//               ChangeNotifierProvider<NodeService>(
//                 create: (_) => nodeService,
//               ),
//             ],
//             child: AddCustomNodeView(),
//           ),
//         ),
//       ),
//     );
//
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodePortFieldKey")), "9000");
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodeAddressFieldKey")), "mynode.com");
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodeNameFieldKey")), "name");
//     await tester.pumpAndSettle();
//
//     expect(find.text("name"), findsOneWidget);
//     expect(find.text("9000"), findsOneWidget);
//     expect(find.text("mynode.com"), findsOneWidget);
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(7));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.text("Add custom node"), findsOneWidget);
//     expect(find.text("Node name"), findsOneWidget);
//     expect(find.text("IP address"), findsOneWidget);
//     expect(find.text("Port"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     final saveButton =
//         find.byType(GradientButton).evaluate().first.widget as GradientButton;
//     final testButton =
//         find.byType(SimpleButton).evaluate().first.widget as SimpleButton;
//     expect(saveButton.enabled, true);
//     expect(testButton.enabled, true);
//
//     final checkbox = find.byType(Checkbox).evaluate().first.widget as Checkbox;
//     expect(checkbox.value, false);
//
//     await tester.tap(find.byWidget(saveButton));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(CampfireAlert), findsOneWidget);
//     expect(find.text("A node with the name \"name\" already exists!"),
//         findsOneWidget);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.testNetworkConnection(any)).called(1);
//
//     verify(nodeService.addListener(any)).called(1);
//     verify(nodeService.createNode(
//       name: "name",
//       ipAddress: "mynode.com",
//       port: "9000",
//       useSSL: false,
//     )).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(nodeService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap enabled save where save and connection test fails",
//       (tester) async {
//     final manager = MockManager();
//     final nodeService = MockNodeService();
//     final navigator = mockingjay.MockNavigator();
//
//     when(manager.testNetworkConnection(any)).thenAnswer((_) async => false);
//
//     when(nodeService.createNode(
//       name: "name",
//       ipAddress: "mynode.com",
//       port: "9000",
//       useSSL: false,
//     )).thenAnswer((_) async => true);
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
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
//               ChangeNotifierProvider<NodeService>(
//                 create: (_) => nodeService,
//               ),
//             ],
//             child: AddCustomNodeView(),
//           ),
//         ),
//       ),
//     );
//
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodePortFieldKey")), "9000");
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodeAddressFieldKey")), "mynode.com");
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodeNameFieldKey")), "name");
//     await tester.pumpAndSettle();
//
//     expect(find.text("name"), findsOneWidget);
//     expect(find.text("9000"), findsOneWidget);
//     expect(find.text("mynode.com"), findsOneWidget);
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(7));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.text("Add custom node"), findsOneWidget);
//     expect(find.text("Node name"), findsOneWidget);
//     expect(find.text("IP address"), findsOneWidget);
//     expect(find.text("Port"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     final saveButton =
//         find.byType(GradientButton).evaluate().first.widget as GradientButton;
//     final testButton =
//         find.byType(SimpleButton).evaluate().first.widget as SimpleButton;
//     expect(saveButton.enabled, true);
//     expect(testButton.enabled, true);
//
//     final checkbox = find.byType(Checkbox).evaluate().first.widget as Checkbox;
//     expect(checkbox.value, false);
//
//     await tester.tap(find.byWidget(saveButton));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(CouldNotConnectOnSaveDialog), findsOneWidget);
//
//     verify(manager.addListener(any)).called(1);
//     verify(manager.testNetworkConnection(any)).called(1);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(nodeService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("CouldNotConnectOnSaveDialog cancel", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//
//     int callCount = 0;
//     final callback = () => callCount++;
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
//
//     await tester.pumpWidget(MaterialApp(
//       home: mockingjay.MockNavigatorProvider(
//         navigator: navigator,
//         child: CouldNotConnectOnSaveDialog(
//           onOK: callback,
//         ),
//       ),
//     ));
//
//     expect(
//         find.text(
//             "Failed to connect to the server entered. Would you like to save it anyways?"),
//         findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     await tester.tap(find.byType(SimpleButton));
//     await tester.pumpAndSettle();
//
//     expect(callCount, 0);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("CouldNotConnectOnSaveDialog save", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//
//     int callCount = 0;
//     final callback = () => callCount++;
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) {});
//
//     await tester.pumpWidget(MaterialApp(
//       home: mockingjay.MockNavigatorProvider(
//         navigator: navigator,
//         child: CouldNotConnectOnSaveDialog(
//           onOK: callback,
//         ),
//       ),
//     ));
//
//     expect(
//         find.text(
//             "Failed to connect to the server entered. Would you like to save it anyways?"),
//         findsOneWidget);
//     expect(find.text("CANCEL"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     expect(callCount, 1);
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets(
//       "tap enabled save where save fails due to attempting to save duplicate default node",
//       (tester) async {
//     final manager = MockManager();
//     final nodeService = MockNodeService();
//     final navigator = mockingjay.MockNavigator();
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
//               ChangeNotifierProvider<NodeService>(
//                 create: (_) => nodeService,
//               ),
//             ],
//             child: AddCustomNodeView(),
//           ),
//         ),
//       ),
//     );
//
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodePortFieldKey")), "9000");
//     await tester.enterText(find.byKey(Key("addCustomNodeNodeAddressFieldKey")),
//         "testnet.electrumx-firo.cypherstack.com");
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodeNameFieldKey")), "name");
//     await tester.pumpAndSettle();
//
//     expect(find.text("name"), findsOneWidget);
//     expect(find.text("9000"), findsOneWidget);
//     expect(find.text("testnet.electrumx-firo.cypherstack.com"), findsOneWidget);
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(7));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.text("Add custom node"), findsOneWidget);
//     expect(find.text("Node name"), findsOneWidget);
//     expect(find.text("IP address"), findsOneWidget);
//     expect(find.text("Port"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     final saveButton =
//         find.byType(GradientButton).evaluate().first.widget as GradientButton;
//     final testButton =
//         find.byType(SimpleButton).evaluate().first.widget as SimpleButton;
//     expect(saveButton.enabled, true);
//     expect(testButton.enabled, true);
//
//     final checkbox = find.byType(Checkbox).evaluate().first.widget as Checkbox;
//     expect(checkbox.value, false);
//
//     await tester.tap(find.byWidget(saveButton));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(CampfireAlert), findsOneWidget);
//     expect(
//         find.text(
//             "Default node already exists. Please enter a different address."),
//         findsOneWidget);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(nodeService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
//
//   testWidgets("tap enabled save where save fails due to an invalid tcp port",
//       (tester) async {
//     final manager = MockManager();
//     final nodeService = MockNodeService();
//     final navigator = mockingjay.MockNavigator();
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
//               ChangeNotifierProvider<NodeService>(
//                 create: (_) => nodeService,
//               ),
//             ],
//             child: AddCustomNodeView(),
//           ),
//         ),
//       ),
//     );
//
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodePortFieldKey")), "90000");
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodeAddressFieldKey")), "mynode.com");
//     await tester.enterText(
//         find.byKey(Key("addCustomNodeNodeNameFieldKey")), "name");
//     await tester.pumpAndSettle();
//
//     expect(find.text("name"), findsOneWidget);
//     expect(find.text("90000"), findsOneWidget);
//     expect(find.text("mynode.com"), findsOneWidget);
//     expect(find.byType(AppBarIconButton), findsOneWidget);
//     expect(find.byType(Checkbox), findsOneWidget);
//     expect(find.byType(Text), findsNWidgets(7));
//     expect(find.byType(TextField), findsNWidgets(3));
//     expect(find.text("Add custom node"), findsOneWidget);
//     expect(find.text("Node name"), findsOneWidget);
//     expect(find.text("IP address"), findsOneWidget);
//     expect(find.text("Port"), findsOneWidget);
//     expect(find.text("Use SSL"), findsOneWidget);
//     expect(find.text("TEST CONNECTION"), findsOneWidget);
//     expect(find.text("SAVE"), findsOneWidget);
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.byType(SimpleButton), findsOneWidget);
//
//     final saveButton =
//         find.byType(GradientButton).evaluate().first.widget as GradientButton;
//     final testButton =
//         find.byType(SimpleButton).evaluate().first.widget as SimpleButton;
//     expect(saveButton.enabled, true);
//     expect(testButton.enabled, true);
//
//     final checkbox = find.byType(Checkbox).evaluate().first.widget as Checkbox;
//     expect(checkbox.value, false);
//
//     await tester.tap(find.byWidget(saveButton));
//     await tester.pumpAndSettle();
//
//     expect(find.byType(CampfireAlert), findsOneWidget);
//     expect(find.text("Invalid port entered!"), findsOneWidget);
//
//     verifyNoMoreInteractions(manager);
//     verifyNoMoreInteractions(nodeService);
//
//     mockingjay.verifyNoMoreInteractions(navigator);
//   });
}
