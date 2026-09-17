import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bitfinite/models/isar/stack_theme.dart';
import 'package:bitfinite/themes/stack_colors.dart';
import 'package:bitfinite/widgets/wallet_navigation_bar/components/wallet_navigation_bar_item.dart';
import 'package:bitfinite/widgets/wallet_navigation_bar/wallet_navigation_bar.dart';

import '../sample_data/theme_json.dart';

void main() {
  /// The floating dock hugs its actions; it does not stretch them.
  ///
  /// This test used to assert the opposite, and was right for six minutes. A
  /// commit that morning spread the actions across a fixed 260px pill with
  /// spaceBetween, and the commit after it reverted that because three 48px
  /// squares in a 260px pill left big dead gaps. The test was never updated,
  /// so it pinned a layout that had already been deleted, and a later change
  /// giving Receive and Send text labels broke its other assumption too.
  ///
  /// It has therefore been red since July while eight commits built on the
  /// layout it rejects. Rewritten here against what the dock actually
  /// promises: it is as wide as its contents, the gaps between actions are
  /// uniform, and it is symmetric. None of those depend on an action being
  /// 48px square, which is what went stale.
  testWidgets("floating dock hugs its actions with uniform gaps", (
    tester,
  ) async {
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);

    WalletNavigationBarItemData item(String label) =>
        WalletNavigationBarItemData(
          label: label,
          icon: const SizedBox(width: 20, height: 20),
          onTap: () {},
        );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: Scaffold(
            body: WalletNavigationBar(
              floating: true,
              items: [item("Receive"), item("Send")],
              moreItems: [item("Anything")],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The pill itself. Keyed rather than found by type, because the surface is
    // wrapped in a BackdropFilter only on iOS - Android gets a solid fill.
    final dock = tester.getRect(find.byKey(const Key("walletDockSurface")));

    // Two items + the generated "More" button.
    final buttons = find.byType(InkWell);
    expect(buttons, findsNWidgets(3));

    final centers = <double>[
      for (int i = 0; i < 3; i++) tester.getCenter(buttons.at(i)).dx,
    ];

    // Gaps measured between adjacent EDGES, not centres. Centres only line up
    // when every action is the same width, and they are not: Receive and Send
    // are labelled pills while More is a square.
    final rects = <Rect>[
      for (int i = 0; i < 3; i++) tester.getRect(buttons.at(i)),
    ];
    for (int i = 1; i < rects.length; i++) {
      expect(
        rects[i].left - rects[i - 1].right,
        closeTo(4, 0.5),
        reason: "actions should be separated by one uniform gap",
      );
    }

    // The dock is as wide as what it holds. A stretched dock would be as wide
    // as the screen it sits on, which is what this is really ruling out.
    final screen = tester.getSize(find.byType(Scaffold)).width;
    expect(
      dock.width,
      lessThan(screen - 40),
      reason: "the dock should hug its content, not span the screen",
    );

    // Symmetric: the outer actions sit the same distance from their own edge,
    // so the pill reads as balanced whatever the actions inside it weigh.
    expect(
      (rects.first.left - dock.left) - (dock.right - rects.last.right),
      closeTo(0, 0.5),
      reason: "outer actions should be inset equally from both edges",
    );
  });
}
