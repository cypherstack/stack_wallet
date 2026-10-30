import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/default_eth_tokens.dart';
import 'package:stackwallet/widgets/icon_widgets/eth_token_icon.dart';

void main() {
  testWidgets('rsFIRO uses the per-app SVG by contract address', (
    tester,
  ) async {
    final token = DefaultTokens.rsFiro;
    expect(token.address, '0x2744ea5ac9b11cb5e3cd63d3a88e858336aeddc2');
    expect(token.decimals, 8);
    await tester.pumpWidget(
      ProviderScope(
        child: Center(
          child: EthTokenIcon(
            contractAddress: token.address.toUpperCase(),
            size: 26,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect((svg.bytesLoader as SvgAssetLoader).assetName, Assets.svg.rsFiro);
    expect(tester.getSize(find.byType(SvgPicture)), const Size.square(26));
    expect(tester.takeException(), isNull);
  });
}
