import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/widgets/angle_reveal.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('ズレの表示は符号つき（+ = 大きい、− = 小さい）', () {
    expect(AngleZoom.signedLabel(30, 34), '+4.0°');
    expect(AngleZoom.signedLabel(30, 26), '−4.0°');
    expect(AngleZoom.signedLabel(30, 30.02), '±0.0°');
  });

  testWidgets('拡大図は高さが足りなくても文字を残して縮む', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 150,
            height: 90,
            child: AngleZoom(target: 30, actual: 34),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('+4.0°'), findsOneWidget);
  });
}
