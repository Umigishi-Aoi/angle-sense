import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/game/scoring.dart';
import 'package:hinge_angle_game/widgets/judgement_burst.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('PERFECT と GREAT だけ紙吹雪を出す', (tester) async {
    expect(JudgementBurst.particleCount(Judgement.perfect), greaterThan(0));
    expect(JudgementBurst.particleCount(Judgement.great), greaterThan(0));
    expect(JudgementBurst.particleCount(Judgement.good), 0);
    expect(JudgementBurst.particleCount(Judgement.miss), 0);
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: JudgementBurst(
            judgement: Judgement.perfect,
            child: Text('PERFECT'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('PERFECT'), findsOneWidget);
  });
}
