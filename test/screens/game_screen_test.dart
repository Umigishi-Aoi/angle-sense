import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/screens/game_screen.dart';
import 'package:hinge_angle_game/screens/result_screen.dart';
import 'package:hinge_angle_game/services/app_settings.dart';
import 'package:hinge_angle_game/services/best_score_store.dart';
import 'package:hinge_angle_game/services/feedback.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart';
import '../helpers/pump.dart';

void main() {
  // 自己ベストの保存先は、テストごとに空のメモリ実装へ差し替える。
  setUp(useInMemoryPrefs);

  testWidgets('外側の画面に移ったら「ひらいてね」を出し、戻ったら消す', (tester) async {
    final provider = FakeAngleProvider()..latestAngle = 45;
    final settings = AppSettings();
    await tester.pumpWidget(
      AppServices(
        settings: settings,
        feedback: RecordingFeedback(settings),
        bestScores: inMemoryBestScores(),
        child: MaterialApp(
          home: GameScreen(
            angleProvider: provider,
          ),
        ),
      ),
    );
    expect(find.text('ひらいてね'), findsNothing);
    provider.onOuterDisplay.value = true;
    await tester.pump();
    expect(find.text('ひらいてね'), findsOneWidget);
    provider.onOuterDisplay.value = false;
    await tester.pump();
    expect(find.text('ひらいてね'), findsNothing);
    // 外側にいる間に時間切れで確定しないよう、一時停止している
    expect(find.text('一時停止中'), findsOneWidget);
    await tester.tap(find.text('再開'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();
  });

  testWidgets('暗転中もお題の角度と残り秒数を出す', (tester) async {
    final settings = AppSettings();
    await tester.pumpWidget(
      AppServices(
        settings: settings,
        feedback: RecordingFeedback(settings),
        bestScores: inMemoryBestScores(),
        child: MaterialApp(
          home: GameScreen(
            angleProvider: FakeAngleProvider()..latestAngle = 45,
          ),
        ),
      ),
    );
    // お題の表示中は数字と見本の絵を出し、「覚えよう」の文は出さない。
    expect(find.byKey(const ValueKey('target_preview')), findsOneWidget);
    expect(find.text('この角度を覚えよう'), findsNothing);
    await tester.pump(const Duration(seconds: 3)); // お題 3 秒 → 暗転
    await tester.pump(const Duration(milliseconds: 300)); // 切り替えのフェード
    // 操作中は数字だけ（見本の絵や説明文は出さない）。
    expect(find.byKey(const ValueKey('blind_target')), findsOneWidget);
    expect(find.byKey(const ValueKey('target_preview')), findsNothing);
    expect(find.text('に合わせて止めてね'), findsNothing);
    expect(find.text('5'), findsOneWidget);
    expect(find.byType(CountdownBar), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });

  group('GameScreen', () {
    testWidgets('5問終えると結果画面に進み、自己ベストが保存される（初回はレビューを頼まない）', (
      tester,
    ) async {
      var reviews = 0;
      await pumpGame(
        tester,
        FakeAngleProvider()..latestAngle = 90,
        requestReview: () async => reviews++,
      );
      await playFive(tester);
      expect(find.byType(ResultScreen), findsOneWidget);
      final best = await tester.runAsync(
        () =>
            BestScoreStore(prefs: SharedPreferencesAsync())
                .load(providerId: 'fake', rounds: 5),
      );
      final result = tester.widget<ResultScreen>(find.byType(ResultScreen));
      expect(best, result.totalScore);
      expect(result.isNewBest, isTrue);
      expect(reviews, 0);
    });

    testWidgets('前の自己ベストを上回ったらレビューを 1 回頼む', (tester) async {
      await tester.runAsync(
        () => SharedPreferencesAsync().setInt(
          BestScoreStore.keyFor(providerId: 'fake', rounds: 5),
          -1,
        ),
      );
      var reviews = 0;
      await pumpGame(
        tester,
        FakeAngleProvider()..latestAngle = 90,
        requestReview: () async => reviews++,
      );
      await playFive(tester);
      final result = tester.widget<ResultScreen>(find.byType(ResultScreen));
      expect(result.isNewBest, isTrue);
      expect(reviews, 1);
    });

    testWidgets('自己ベストを上回らなければレビューを頼まない', (tester) async {
      await tester.runAsync(
        () => SharedPreferencesAsync().setInt(
          BestScoreStore.keyFor(providerId: 'fake', rounds: 5),
          100000,
        ),
      );
      var reviews = 0;
      await pumpGame(
        tester,
        FakeAngleProvider()..latestAngle = 90,
        requestReview: () async => reviews++,
      );
      await playFive(tester);
      final result = tester.widget<ResultScreen>(find.byType(ResultScreen));
      expect(result.isNewBest, isFalse);
      expect(reviews, 0);
    });

    testWidgets('中断ダイアログ表示中はロックされず、「続ける」でお題からやり直す', (tester) async {
      await pumpGame(tester, FakeAngleProvider()..latestAngle = 90);
      await tester.pump(const Duration(seconds: 4)); // 暗転中
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(find.text('ゲームをやめますか？'), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('次の問題'), findsNothing);
      await tester.tap(find.text('続ける'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('target_preview')), findsOneWidget);
      expect(find.text('第 1 / 5 問'), findsOneWidget);
    });

    testWidgets('戻る操作では確認ダイアログが出て、「やめる」でホームに戻る', (tester) async {
      await pumpGame(tester, FakeAngleProvider()..latestAngle = 90);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('ゲームをやめますか？'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'やめる'));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsNothing);
      expect(find.text('go'), findsOneWidget);
    });
    testWidgets('バックグラウンドで一時停止画面→「やめる」→「続ける」で一時停止画面に戻り、「再開」でやり直す', (
      tester,
    ) async {
      await pumpGame(tester, FakeAngleProvider()..latestAngle = 90);
      await tester.pump(const Duration(seconds: 4)); // 暗転中
      [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ].forEach(tester.binding.handleAppLifecycleStateChanged);
      await tester.pump(const Duration(seconds: 10)); // バックグラウンド中に時間が過ぎる
      // 復帰（paused 中はフレームが描かれないので、表示の確認は復帰後に行う）
      [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ].forEach(tester.binding.handleAppLifecycleStateChanged);
      await tester.pump();
      expect(find.text('一時停止中'), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('次の問題'), findsNothing); // ロックされていない

      await tester.tap(find.widgetWithText(TextButton, 'やめる'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('続ける'));
      await tester.pumpAndSettle();
      expect(find.text('一時停止中'), findsOneWidget); // 勝手に動き出さない

      await tester.tap(find.text('再開'));
      await tester.pump();
      expect(find.byKey(const ValueKey('target_preview')), findsOneWidget);
      expect(find.text('第 1 / 5 問'), findsOneWidget);
    });

    testWidgets('inactive だけでは一時停止しない（Duo の開閉を止めないため）', (tester) async {
      await pumpGame(tester, FakeAngleProvider()..latestAngle = 90);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.text('一時停止中'), findsNothing);
      await tester.pump(const Duration(seconds: 8));
      await tester.pumpAndSettle();
      expect(find.text('次の問題'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
  });

  testWidgets('1問の効果音: カウント3回→暗転開始→チッ4回→ロック→判定', (tester) async {
    final settings = AppSettings();
    final fb = RecordingFeedback(settings);
    await tester.pumpWidget(
      AppServices(
        settings: settings,
        feedback: fb,
        bestScores: inMemoryBestScores(),
        child: MaterialApp(
          home: GameScreen(
            angleProvider: FakeAngleProvider()..latestAngle = 45,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();
    expect(fb.events.take(10).toList(), [
      'countdown',
      'countdown',
      'countdown',
      'blindStart',
      'tick',
      'tick',
      'tick',
      'tick',
      'lock',
      'haptic:lock',
    ]);
    expect(fb.events.length, 12); // + 判定の音・振動
    expect(fb.events[11], 'haptic:result'); // 振動は判定によらず同じ

    // 暗転中のカウント音を切ると tick は鳴らない
    settings.blindTick = false;
    fb.events.clear();
    await tester.tap(find.text('次の問題'));
    await tester.pump(const Duration(seconds: 8));
    expect(fb.events.where((e) => e == 'tick'), isEmpty);
    expect(fb.events, contains('blindStart'));
    await tester.pumpAndSettle();
  });

  group('CountdownBar', () {
    Future<Size> pumpBar(
      WidgetTester tester,
      int total, {
      double? width,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: width,
              child: Center(
                child: CountdownBar(
                  remaining: 1,
                  total: total,
                  color: const Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
        ),
      );
      return tester.getSize(find.byType(CountdownBar));
    }

    testWidgets('3 秒・5 秒は今までどおり 1 マス 36px の等倍', (tester) async {
      expect(await pumpBar(tester, 3), const Size(108, 28));
      expect(await pumpBar(tester, 5), const Size(180, 28));
    });

    testWidgets('幅に収まらない秒数は、はみ出さずに縮めて並べる', (tester) async {
      final size = await pumpBar(tester, 20, width: 300);
      expect(tester.takeException(), isNull);
      expect(size.width, lessThanOrEqualTo(300));
    });
  });

  testWidgets('「アニメーションを削除」設定ではお題→暗転→答え合わせの切り替えを即時にする', (tester) async {
    Future<Duration?> switcherDuration(
      MediaQueryData Function(MediaQueryData) edit,
    ) async {
      final settings = AppSettings();
      await tester.pumpWidget(
        AppServices(
          settings: settings,
          feedback: RecordingFeedback(settings),
          bestScores: inMemoryBestScores(),
          child: MaterialApp(
            builder: (context, child) =>
                MediaQuery(data: edit(MediaQuery.of(context)), child: child!),
            home: GameScreen(
              angleProvider: FakeAngleProvider()..latestAngle = 45,
            ),
          ),
        ),
      );
      final d = tester
          .widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher))
          .duration;
      await tester.pumpWidget(const SizedBox()); // タイマーを残さない
      return d;
    }

    expect(
      await switcherDuration((d) => d.copyWith(disableAnimations: true)),
      Duration.zero,
    );
    // iOS の「視差効果を減らす」はフェードを推奨しているので、フェードは残す。
    expect(
      await switcherDuration((d) => d.copyWith(reduceMotion: true)),
      const Duration(milliseconds: 250),
    );
  });
}
