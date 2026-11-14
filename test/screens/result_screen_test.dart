import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/game/scoring.dart';
import 'package:hinge_angle_game/screens/result_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fakes.dart';

void main() {
  setUp(useInMemoryPrefs);

  Future<void> pumpResult(
    WidgetTester tester, {
    required bool isNewBest,
    int? bestScore,
  }) async {
    final results = [
      for (var i = 0; i < 5; i++) const RoundResult(target: 45, actual: 46),
    ];
    final total = results.fold(0, (sum, r) => sum + r.points);
    await tester.pumpWidget(
      MaterialApp(
        home: ResultScreen(
          results: results,
          totalScore: total,
          rank: rankFor(total, rounds: results.length),
          angleProvider: FakeAngleProvider(),
          bestScore: bestScore,
          isNewBest: isNewBest,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('自己ベストを更新したら「自己ベスト更新！」を出す', (tester) async {
    await pumpResult(tester, isNewBest: true, bestScore: 500);
    expect(find.text('自己ベスト更新！'), findsOneWidget);
    expect(find.textContaining('自己ベスト 500 点'), findsNothing);
  });

  testWidgets('更新しなかったら今の自己ベストの点数を出す', (tester) async {
    await pumpResult(tester, isNewBest: false, bestScore: 999);
    expect(find.text('自己ベスト更新！'), findsNothing);
    expect(find.text('自己ベスト 999 点'), findsOneWidget);
  });

  testWidgets('記録が読めなかったら自己ベストの欄を出さない', (tester) async {
    await pumpResult(tester, isNewBest: false);
    expect(find.textContaining('自己ベスト'), findsNothing);
  });
}
