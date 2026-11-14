import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/game/scoring.dart';
import 'package:hinge_angle_game/screens/battle_screen.dart';
import 'package:hinge_angle_game/services/app_settings.dart';
import 'package:hinge_angle_game/services/feedback.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fakes.dart';

void main() {
  // 端末保存は、テストごとに空のメモリ実装へ差し替える。
  setUp(useInMemoryPrefs);

  test('バトルの順位: 誤差の小さい順・同じ誤差は同順位・計測なしは最下位', () {
    BattleEntry e(String n, double t, double? a) => BattleEntry(
      name: n,
      result: RoundResult(target: t, actual: a),
      chartLabel: n,
    );
    final ranked = rankEntries([
      e('A', 40, 45), // 5
      e('B', 30, null), // 計測なし
      e('C', 60, 61), // 1
      e('D', 20, 15), // 5
    ]);
    expect(
      [for (final (r, x) in ranked) '${x.name}$r'],
      ['C1', 'A2', 'D2', 'B4'],
    );
  });

  testWidgets('バトル: 2人が1回ずつ計測して順位が出る', (tester) async {
    tester.view.physicalSize = const Size(951, 669);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = AppSettings();
    await tester.pumpWidget(
      AppServices(
        settings: settings,
        feedback: RecordingFeedback(settings),
        bestScores: inMemoryBestScores(),
        child: MaterialApp(
          home: BattleScreen(
            angleProvider: FakeAngleProvider()..latestAngle = 45,
            playerCount: 2,
          ),
        ),
      ),
    );
    for (var i = 1; i <= 2; i++) {
      expect(find.text('プレイヤー$i の番'), findsOneWidget);
      await tester.tap(find.text('スタート'));
      await tester.pumpAndSettle();
      expect(find.text('プレイヤー$i'), findsOneWidget); // ゲーム画面の見出し
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();
    }
    expect(find.text('結果発表'), findsOneWidget);
    expect(find.text('プレイヤー1'), findsOneWidget);
    expect(find.text('プレイヤー2'), findsOneWidget);
    expect(find.text('みんなの感覚のズレ'), findsOneWidget);
    expect(find.byKey(const ValueKey('dev_P1')), findsOneWidget);
    expect(find.byKey(const ValueKey('dev_P2')), findsOneWidget);
  });

  testWidgets('バトル: × でやめると、その人は計測なしで確定し、やり直せない', (tester) async {
    tester.view.physicalSize = const Size(951, 669);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = AppSettings();
    await tester.pumpWidget(
      AppServices(
        settings: settings,
        feedback: RecordingFeedback(settings),
        bestScores: inMemoryBestScores(),
        child: MaterialApp(
          home: BattleScreen(
            angleProvider: FakeAngleProvider()..latestAngle = 45,
            playerCount: 2,
          ),
        ),
      ),
    );
    await tester.tap(find.text('スタート'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('やめる'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'やめる'));
    await tester.pumpAndSettle();
    expect(find.text('プレイヤー2 の番'), findsOneWidget);
    expect(find.text('プレイヤー1: MISS'), findsOneWidget);
  });

  testWidgets('バトル: 名前は任意。入れた人は名前、入れない人はプレイヤーN で出る', (tester) async {
    final settings = AppSettings();
    await tester.pumpWidget(
      AppServices(
        settings: settings,
        feedback: RecordingFeedback(settings),
        bestScores: inMemoryBestScores(),
        child: MaterialApp(
          home: BattleScreen(
            angleProvider: FakeAngleProvider()..latestAngle = 45,
            playerCount: 2,
          ),
        ),
      ),
    );
    await tester.enterText(find.byKey(const ValueKey('battle_name')), ' たろう ');
    await tester.tap(find.text('スタート'));
    await tester.pumpAndSettle();
    expect(find.text('たろう'), findsOneWidget); // ゲーム画面の見出し
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();
    // 2 人目は入力欄が空に戻っていて、入れずに始める
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('battle_name')))
          .controller!
          .text,
      isEmpty,
    );
    await tester.tap(find.text('スタート'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();
    expect(find.text('結果発表'), findsOneWidget);
    expect(find.text('たろう'), findsWidgets); // 順位表とズレ図
    expect(find.text('プレイヤー2'), findsOneWidget);
    expect(find.byKey(const ValueKey('dev_たろう')), findsOneWidget);
    expect(find.byKey(const ValueKey('dev_P2')), findsOneWidget);
  });
}
