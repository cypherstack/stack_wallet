// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockingjay/mockingjay.dart' as mockingjay;
// import 'package:stackwallet/pages/onboarding_view/helpers/create_wallet_type.dart';
// import 'package:stackwallet/pages/onboarding_view/terms_and_conditions_view.dart';
// import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';
//
void main() {
//   testWidgets("terms and conditions screen builds correctly", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: TermsAndConditionsView(
//           type: CreateWalletType.NEW,
//         ),
//       ),
//     );
//
//     expect(find.byKey(Key("onboardingAppBarBackButton")), findsOneWidget);
//     expect(find.byKey(Key("onboardingAppBarBackButtonChevronSvg")),
//         findsOneWidget);
//
//     final imageFinder = find.byType(Image);
//     expect(imageFinder, findsOneWidget);
//
//     final imageSource =
//         ((imageFinder.evaluate().single.widget as Image).image as AssetImage)
//             .assetName;
//     expect(imageSource, "assets/images/logo.png");
//
//     expect(find.text("Terms and Conditions"), findsOneWidget);
//
//     expect(find.byType(SingleChildScrollView), findsOneWidget);
//     expect(find.text("""
// 1. Terms
//
// By accessing the website at https://cypherstack.com, you are agreeing to be bound by these terms of service, all applicable laws and regulations, and agree that you are responsible for compliance with any applicable local laws. If you do not agree with any of these terms, you are prohibited from using or accessing this site. The materials contained in this website are protected by applicable copyright and trademark law.
//
// 2. Use License
//
// Permission is granted to temporarily download one copy of the materials (information or software) on Cypher Stack's website for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:
//
// - modify or copy the materials;
//
// - use the materials for any commercial purpose, or for any public display (commercial or non-commercial);
//
// - attempt to decompile or reverse engineer any software contained on Cypher Stack's website;
//
// - remove any copyright or other proprietary notations from the materials; or
//
// - transfer the materials to another person or "mirror" the materials on any other server.
//
// This license shall automatically terminate if you violate any of these restrictions and may be terminated by Cypher Stack at any time.
//
// 3. Disclaimer
//
// The materials on Cypher Stack's website are provided on an 'as is' basis. Cypher Stack makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.
//
// Further, Cypher Stack does not warrant or make any representations concerning the accuracy, likely results, or reliability of the use of the materials on its website or otherwise relating to such materials or on any sites linked to this site.
//
// 4. Limitations
//
// In no event shall Cypher Stack or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on Cypher Stack's website, even if Cypher Stack or a Cypher Stack authorized representative has been notified orally or in writing of the possibility of such damage. Because some jurisdictions do not allow limitations on implied warranties, or limitations of liability for consequential or incidental damages, these limitations may not apply to you.
//
// 5. Accuracy of materials
//
// The materials appearing on Cypher Stack's website could include technical, typographical, or photographic errors. Cypher Stack does not warrant that any of the materials on its website are accurate, complete or current. Cypher Stack may make changes to the materials contained on its website at any time without notice. However Cypher Stack does not make any commitment to update the materials.
//
// 6. Links
//
// Cypher Stack has not reviewed all of the sites linked to its website and is not responsible for the contents of any such linked site. The inclusion of any link does not imply endorsement by Cypher Stack of the site. Use of any such linked website is at the user's own risk.
//
// 7. Modifications
//
// Cypher Stack may revise these terms of service for its website at any time without notice. By using this website you are agreeing to be bound by the then current version of these terms of service.
//
// 8. Governing Law
//
// These terms and conditions are governed by and construed in accordance with the laws of New Mexico and you irrevocably submit to the exclusive jurisdiction of the courts in that State or location.
// """), findsOneWidget);
//
//     expect(find.byType(GradientButton), findsOneWidget);
//     expect(find.text("I ACCEPT"), findsOneWidget);
//   });
//
//   testWidgets("scroll", (tester) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: TermsAndConditionsView(
//           type: CreateWalletType.NEW,
//         ),
//       ),
//     );
//
//     await tester.fling(
//         find.byType(SingleChildScrollView), Offset(-500, 0), 10000);
//     await tester.pumpAndSettle();
//
//     await tester.fling(
//         find.byType(SingleChildScrollView), Offset(500, 0), 10000);
//     await tester.pumpAndSettle();
//   });
//
//   testWidgets("back button test", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay.when(() => navigator.pop()).thenAnswer((_) async => {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: TermsAndConditionsView(
//             type: CreateWalletType.RESTORE,
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byKey(Key("onboardingAppBarBackButton")));
//     await tester.pumpAndSettle();
//
//     mockingjay.verify(() => navigator.pop()).called(1);
//   });
//
//   testWidgets("accept button pressed", (tester) async {
//     final navigator = mockingjay.MockNavigator();
//
//     mockingjay
//         .when(
//           () => navigator.push(
//             mockingjay.any(),
//           ),
//         )
//         .thenAnswer((_) async => {});
//
//     await tester.pumpWidget(
//       MaterialApp(
//         home: mockingjay.MockNavigatorProvider(
//           navigator: navigator,
//           child: TermsAndConditionsView(
//             type: CreateWalletType.NEW,
//           ),
//         ),
//       ),
//     );
//
//     await tester.tap(find.byType(GradientButton));
//     await tester.pumpAndSettle();
//
//     mockingjay
//         .verify(
//           () => navigator.push(
//             mockingjay.any(),
//           ),
//         )
//         .called(1);
//   });
}
