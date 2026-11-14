import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/game/scoring.dart';
import 'package:hinge_angle_game/widgets/judgement_burst.dart';
import 'package:material_ui/material_ui.dart';

import 'angle_reveal_test.dart' show painterIn, reducedMotionApp;

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

  testWidgets('紙吹雪は時刻が同じでも、粒や重力が違えば描き直す', (tester) async {
    Future<CustomPainter> pump(Judgement j) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: JudgementBurst(
              key: ValueKey(j),
              judgement: j,
              child: const Text('x'),
            ),
          ),
        ),
      );
      return painterIn(tester, find.byType(JudgementBurst));
    }

    final perfect = await pump(Judgement.perfect); // 最初のフレーム（t = 0）
    final great = await pump(Judgement.great); // こちらも t = 0
    expect(great.shouldRepaint(perfect), isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('動きを控える設定では弾まず、紙吹雪も動かさない（最後の状態と同じ）', (tester) async {
    await tester.pumpWidget(
      reducedMotionApp(
        const Center(
          child: JudgementBurst(
            judgement: Judgement.perfect,
            child: Text('PERFECT'),
          ),
        ),
      ),
    );
    expect(tester.hasRunningAnimations, isFalse);
    final scale = tester.widget<Transform>(
      find.ancestor(of: find.text('PERFECT'), matching: find.byType(Transform)),
    );
    expect(scale.transform.getMaxScaleOnAxis(), closeTo(1, 1e-9));
  });
}
