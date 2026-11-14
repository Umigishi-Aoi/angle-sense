import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/game/scoring.dart';
import 'package:hinge_angle_game/l10n/l10n.dart';
import 'package:hinge_angle_game/widgets/deviation_chart.dart';
import 'package:material_ui/material_ui.dart';

/// 読み上げの文言は日本語（元の文言）で確かめる。
final AppLocalizations _ja = lookupAppLocalizations(const Locale('ja'));

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
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,

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

  test('行の読み上げは名前・符号つきのズレと向き・判定', () {
    expect(
      DeviationChart.semanticsLabel(
        _ja,
        'P1',
        const RoundResult(target: 40, actual: 44),
      ),
      'P1、+4.0° 折りすぎ、GREAT',
    );
    expect(
      DeviationChart.semanticsLabel(
        _ja,
        'P2',
        const RoundResult(target: 40, actual: 28),
      ),
      'P2、−12.0° 足りない、MISS',
    );
    expect(
      DeviationChart.semanticsLabel(
        _ja,
        'P3',
        const RoundResult(target: 40, actual: 40),
      ),
      'P3、±0.0° ピタッ、PERFECT',
    );
    expect(
      DeviationChart.semanticsLabel(
        _ja,
        'P4',
        const RoundResult(target: 40, actual: null),
      ),
      'P4、計測なし、MISS',
    );
  });

  testWidgets('読み上げは行ごとの説明だけ（見出し・目盛りは読まない）', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,

        home: Scaffold(
          body: DeviationChart(
            rows: [('P1', RoundResult(target: 40, actual: 44))],
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('P1、+4.0° 折りすぎ、GREAT'), findsOneWidget);
    expect(find.bySemanticsLabel('ピタッ'), findsNothing);
    expect(find.bySemanticsLabel('+30°'), findsNothing);
    handle.dispose();
  });

  testWidgets('文字を大きくする設定では、行の高さも同じ割合で広がる', (tester) async {
    Future<double> rowHeight(double scale) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,

          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const Scaffold(
            body: DeviationChart(
              rows: [('P1', RoundResult(target: 40, actual: 44))],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      return tester
          .getSize(
            find
                .ancestor(
                  of: find.text('P1'),
                  matching: find.byType(SizedBox),
                )
                .at(1), // 0 は名前の幅の箱、1 が行の箱
          )
          .height;
    }

    expect(await rowHeight(1), 30);
    expect(await rowHeight(2), 60);
  });
}
