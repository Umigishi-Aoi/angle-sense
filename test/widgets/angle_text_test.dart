import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/widgets/angle_text.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('AngleText は reserveWidthFor があると桁数が変わっても幅が同じ', (
    tester,
  ) async {
    Future<Size> sizeFor(num deg) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: AngleText(deg, fontSize: 32, reserveWidthFor: '180°'),
          ),
        ),
      );
      return tester.getSize(find.byType(AngleText));
    }

    final one = await sizeFor(5);
    final two = await sizeFor(45);
    final three = await sizeFor(180);
    expect(two, one);
    expect(three, one);
  });
}
