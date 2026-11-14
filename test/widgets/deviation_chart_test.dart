import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/game/scoring.dart';
import 'package:hinge_angle_game/widgets/deviation_chart.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('ズレは 実際−お題 の符号つき（+ = 折りすぎ）', () {
    expect(
      DeviationChart.signedError(const RoundResult(target: 40, actual: 47)),
      7,
    );
    expect(
      DeviationChart.signedError(const RoundResult(target: 40, actual: 31)),
      -9,
    );
    expect(
      DeviationChart.signedError(const RoundResult(target: 40, actual: null)),
      isNull,
    );
  });

  testWidgets('10人の結果発表（ズレ図つき）が内側の画面に収まる', (tester) async {
    tester.view.physicalSize = const Size(951, 669);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final rows = [
      for (var i = 0; i < 10; i++)
        (
          'P${i + 1}',
          RoundResult(
            target: 40,
            actual: i == 3 ? null : (i == 9 ? 90 : 40.0 + (i - 5) * 4),
          ),
        ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              const Expanded(flex: 5, child: SizedBox()),
              Expanded(flex: 4, child: DeviationChart(rows: rows)),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('計測なし'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_right), findsOneWidget); // +50° は端でははみ出し表示
    final pitta = tester.getTopLeft(find.byKey(const ValueKey('dev_P6')));
    final over = tester.getTopLeft(find.byKey(const ValueKey('dev_P10')));
    expect(over.dx, greaterThan(pitta.dx));
  });
}
