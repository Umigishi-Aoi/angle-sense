import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPageTransition;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/game/game_session.dart';
import 'package:hinge_angle_game/game/scoring.dart';
import 'package:hinge_angle_game/main.dart' show routeObserver;
import 'package:hinge_angle_game/screens/battle_screen.dart';
import 'package:hinge_angle_game/screens/game_screen.dart';
import 'package:hinge_angle_game/screens/home_screen.dart';
import 'package:hinge_angle_game/screens/result_screen.dart';
import 'package:hinge_angle_game/services/angle_provider.dart';
import 'package:hinge_angle_game/services/app_settings.dart';
import 'package:hinge_angle_game/services/best_score_store.dart';
import 'package:hinge_angle_game/services/diagnostics_log.dart';
import 'package:hinge_angle_game/services/feedback.dart';
import 'package:hinge_angle_game/services/hinge_angle_provider.dart';
import 'package:hinge_angle_game/services/tilt_angle_provider.dart';
import 'package:hinge_angle_game/ui/retro_theme.dart';
import 'package:hinge_angle_game/widgets/angle_reveal.dart';
import 'package:hinge_angle_game/widgets/deviation_chart.dart';
import 'package:hinge_angle_game/widgets/judgement_burst.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// 鳴らした音と振動を記録するだけの GameFeedback。
class RecordingFeedback(super.settings) extends GameFeedback {
  this : super.silent();
  final events = <String>[];
  @override
  void play(Sfx sfx) => events.add(sfx.name);
  @override
  void haptic(HapticPattern pattern) => events.add('haptic:${pattern.name}');
}

class FakeAngleProvider() implements AngleProvider {
  @override
  double? latestAngle;
  @override
  Stream<double> get angleStream => const Stream.empty();
  @override
  String get id => 'fake';
  @override
  String get label => 'fake';
  @override
  final ValueNotifier<bool> onOuterDisplay = ValueNotifier(false);
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
}

void main() {
  group('judge', () {
    test('境界値', () {
      expect(judge(45, 46), Judgement.perfect);
      expect(judge(45, 44), Judgement.perfect);
      expect(judge(45, 46.5), Judgement.great);
      expect(judge(45, 50), Judgement.great);
      expect(judge(45, 50.5), Judgement.good);
      expect(judge(45, 35), Judgement.good);
      expect(judge(45, 34.9), Judgement.miss);
    });
  });

  group('rankFor', () {
    test('1000点満点の閾値', () {
      expect(rankFor(1000), Rank.s);
      expect(rankFor(850), Rank.s);
      expect(rankFor(849), Rank.a);
      expect(rankFor(650), Rank.a);
      expect(rankFor(649), Rank.b);
      expect(rankFor(400), Rank.b);
      expect(rankFor(399), Rank.c);
    });
  });

  test('generateTargets は 10〜80 の5°刻み（内側の画面だけで遊べる範囲）', () {
    final t = generateTargets(count: 200);
    expect(t.length, 200);
    expect(t.every((d) => d >= 10 && d <= 80 && d % 5 == 0), isTrue);
  });

  group('tiltDegrees', () {
    test('平置き=0 / 立てた=90 / 伏せ=180', () {
      expect(tiltDegrees(0, 0, 9.8), closeTo(0, 1e-9));
      expect(tiltDegrees(0, 9.8, 0), closeTo(90, 1e-9));
      expect(tiltDegrees(0, 0, -9.8), closeTo(180, 1e-9));
      expect(tiltDegrees(0, 0, 0), isNull);
    });
  });

  testWidgets('GameSession: 3秒→暗転5秒→ロック→次→5問で終了', (tester) async {
    final provider = FakeAngleProvider()..latestAngle = 45;
    var locks = 0;
    final session = GameSession(
      angleProvider: provider,
      targets: List.filled(5, 45),
      onLock: () => locks++,
    )..start();

    for (var i = 0; i < 5; i++) {
      expect(session.phase, GamePhase.showTarget);
      expect(session.countdown, 3);
      await tester.pump(const Duration(seconds: 3));
      expect(session.phase, GamePhase.blind);
      expect(session.countdown, 5);
      await tester.pump(const Duration(seconds: 4));
      expect(session.phase, GamePhase.blind);
      await tester.pump(const Duration(seconds: 1));
      expect(session.phase, GamePhase.reveal);
      expect(session.lastResult!.judgement, Judgement.perfect);
      session.next();
    }
    expect(session.phase, GamePhase.finished);
    expect(locks, 5);
    expect(session.totalScore, 500);
    expect(session.rank, Rank.s);
    session.dispose();
  });

  group('GameSession の一時停止', () {
    testWidgets('暗転中に止めるとロックされず、再開で同じ問題をお題からやり直す', (tester) async {
      final session = GameSession(
        angleProvider: FakeAngleProvider()..latestAngle = 45,
        targets: List.filled(10, 45),
      )..start();
      await tester.pump(const Duration(seconds: 4)); // 暗転 1 秒目
      expect(session.phase, GamePhase.blind);
      session.pause();
      await tester.pump(const Duration(seconds: 30));
      expect(session.phase, GamePhase.blind);
      expect(session.results, isEmpty);
      session.resume();
      expect(session.phase, GamePhase.showTarget);
      expect(session.roundIndex, 0);
      expect(session.countdown, 3);
      await tester.pump(const Duration(seconds: 8));
      expect(session.phase, GamePhase.reveal);
      expect(session.results.length, 1);
      session.dispose();
    });

    testWidgets('答え合わせ中に止めても結果は二重にならず、そのまま答え合わせに戻る', (tester) async {
      final session = GameSession(
        angleProvider: FakeAngleProvider()..latestAngle = 45,
        targets: List.filled(10, 45),
      )..start();
      await tester.pump(const Duration(seconds: 8));
      expect(session.phase, GamePhase.reveal);
      session
        ..pause()
        ..next(); // 一時停止中は進まない
      expect(session.roundIndex, 0);
      session.resume();
      expect(session.phase, GamePhase.reveal);
      expect(session.results.length, 1);
      session.dispose();
    });
  });

  testWidgets('ロック時に角度が無ければ「計測なし」= MISS', (tester) async {
    final session = GameSession(
      angleProvider: FakeAngleProvider(),
      targets: List.filled(10, 45),
    )..start();
    await tester.pump(const Duration(seconds: 8));
    final r = session.lastResult!;
    expect(r.measured, isFalse);
    expect(r.error, isNull);
    expect(r.judgement, Judgement.miss);
    expect(r.points, 0);
    session.dispose();
  });

  testWidgets('ヒンジが取れなくなったら古い角度を消す', (tester) async {
    const channel = MethodChannel('test/hinge');
    final provider = HingeAngleProvider(channel: channel);
    Future<void> send(Map<String, Object?> args) async {
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(MethodCall('onHinge', args)),
        (_) {},
      );
    }

    DiagnosticsLog.instance.clear();
    await send({
      'available': true,
      'angleDeg': 90.0,
      'angleRad': 1.5708,
      'status': 'partiallyOpen',
    });
    expect(provider.latestAngle, 90);
    // ゲームの角度は平ら=0°（ヒンジの生の角度を反転）
    await send({
      'available': true,
      'angleDeg': 170.0,
      'angleRad': 2.9671,
      'status': 'partiallyOpen',
    });
    expect(provider.latestAngle, closeTo(10, 1e-9));
    expect(provider.onOuterDisplay.value, isFalse);
    // closed = 外側の画面に移った
    await send({
      'available': true,
      'angleDeg': 80.0,
      'angleRad': 1.3963,
      'status': 'closed',
    });
    expect(provider.latestAngle, closeTo(100, 1e-9));
    expect(provider.onOuterDisplay.value, isTrue);
    await send({'available': false, 'status': 'unavailable'});
    expect(provider.latestAngle, isNull);
    // 診断ログに生の値が残る
    final log = DiagnosticsLog.instance.export();
    expect(
      log,
      contains('status=partiallyOpen available=true rad=1.5708 deg=90.0'),
    );
    expect(log, contains('status=unavailable'));
  });

  testWidgets('外側の画面に移ったら「ひらいてね」を出し、戻ったら消す', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final provider = FakeAngleProvider()..latestAngle = 45;
    final settings = AppSettings();
    await tester.pumpWidget(
      AppServices(
        settings: settings,
        feedback: RecordingFeedback(settings),
        child: MaterialApp(
          home: GameScreen(
            angleProvider: provider,
            bestScoreStore: BestScoreStore(prefs: SharedPreferencesAsync()),
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
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final settings = AppSettings();
    await tester.pumpWidget(
      AppServices(
        settings: settings,
        feedback: RecordingFeedback(settings),
        child: MaterialApp(
          home: GameScreen(
            angleProvider: FakeAngleProvider()..latestAngle = 45,
            bestScoreStore: BestScoreStore(prefs: SharedPreferencesAsync()),
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

  group('BestScoreStore', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('上回ったときだけ保存し、入力源・問題数ごとに分ける', () async {
      final store = BestScoreStore(prefs: SharedPreferencesAsync());
      expect(await store.load(providerId: 'hinge', rounds: 10), isNull);
      expect(
        await store.submit(providerId: 'hinge', rounds: 10, score: 500),
        isTrue,
      );
      expect(
        await store.submit(providerId: 'hinge', rounds: 10, score: 500),
        isFalse,
      );
      expect(
        await store.submit(providerId: 'hinge', rounds: 10, score: 300),
        isFalse,
      );
      expect(await store.load(providerId: 'hinge', rounds: 10), 500);
      expect(await store.load(providerId: 'tilt', rounds: 10), isNull);
      expect(await store.load(providerId: 'hinge', rounds: 5), isNull);
      expect(
        await store.submit(providerId: 'hinge', rounds: 10, score: 700),
        isTrue,
      );
      expect(await store.load(providerId: 'hinge', rounds: 10), 700);
    });
  });

  group('GameScreen', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    Future<void> pumpGame(WidgetTester tester, AngleProvider provider) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => GameScreen(
                        angleProvider: provider,
                        bestScoreStore: BestScoreStore(
                          prefs: SharedPreferencesAsync(),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('go'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
    }

    testWidgets('5問終えると結果画面に進み、自己ベストが保存される', (tester) async {
      await pumpGame(tester, FakeAngleProvider()..latestAngle = 90);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle(); // 答え合わせアニメ
        await tester.tap(find.byType(FilledButton));
        await tester.pump();
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ResultScreen), findsOneWidget);
      final best = await tester.runAsync(
        () =>
            BestScoreStore(prefs: SharedPreferencesAsync())
                .load(providerId: 'fake', rounds: 5),
      );
      final result = tester.widget<ResultScreen>(find.byType(ResultScreen));
      expect(best, result.totalScore);
      expect(result.isNewBest, isTrue);
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
        child: MaterialApp(
          home: GameScreen(
            angleProvider: FakeAngleProvider()..latestAngle = 45,
            bestScoreStore: BestScoreStore(prefs: SharedPreferencesAsync()),
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

  testWidgets('ホームとバトル設定が内側の画面（951x669）に収まる', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    tester.view.physicalSize = const Size(951, 669);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = AppSettings();
    final provider = FakeAngleProvider()..latestAngle = 45;
    await tester.pumpWidget(
      AppServices(
        settings: settings,
        feedback: RecordingFeedback(settings),
        child: MaterialApp(
          home: HomeScreen(
            angleProvider: provider,
            bestScoreStore: BestScoreStore(prefs: SharedPreferencesAsync()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('バトル（2〜10人）'));
    await tester.pumpAndSettle();
    expect(find.text('2 人'), findsOneWidget);
    for (var i = 0; i < 12; i++) {
      await tester.tap(find.text('＋'));
      await tester.pump();
    }
    await tester.pump();
    expect(find.text('10 人'), findsOneWidget); // 上限
    expect(tester.takeException(), isNull);
  });

  testWidgets('バトル設定からホームに戻っても、ホームのボタンが効く', (tester) async {
    // didPopNext の setState が Future を返すとアサーションで Navigator がロックされた（2026-11-09）。
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final settings = AppSettings();
    await tester.pumpWidget(
      AppServices(
        settings: settings,
        feedback: RecordingFeedback(settings),
        child: MaterialApp(
          navigatorObservers: [routeObserver],
          home: HomeScreen(
            angleProvider: FakeAngleProvider()..latestAngle = 45,
            bestScoreStore: BestScoreStore(prefs: SharedPreferencesAsync()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('バトル（2〜10人）'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('バトル（2〜10人）'));
    await tester.pumpAndSettle();
    expect(find.text('2 人'), findsOneWidget);
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

  testWidgets('ホームに今の角度の絵を出す', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final settings = AppSettings();
    await tester.pumpWidget(
      AppServices(
        settings: settings,
        feedback: RecordingFeedback(settings),
        child: MaterialApp(
          home: HomeScreen(
            angleProvider: FakeAngleProvider()..latestAngle = 45,
            bestScoreStore: BestScoreStore(prefs: SharedPreferencesAsync()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home_preview')), findsOneWidget);
  });

  testWidgets('バトル: 名前は任意。入れた人は名前、入れない人はプレイヤーN で出る', (tester) async {
    final settings = AppSettings();
    await tester.pumpWidget(
      AppServices(
        settings: settings,
        feedback: RecordingFeedback(settings),
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

  testWidgets('ひとり・バトルへ入るときは横スライドでなくフェードで切り替える', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final settings = AppSettings();
    await tester.pumpWidget(
      AppServices(
        settings: settings,
        feedback: RecordingFeedback(settings),
        child: MaterialApp(
          theme: Retro.theme(),
          home: HomeScreen(
            angleProvider: FakeAngleProvider()..latestAngle = 45,
            bestScoreStore: BestScoreStore(prefs: SharedPreferencesAsync()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final label in ['バトル（2〜10人）', 'ひとりで（5問）']) {
      await tester.tap(find.text(label));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100)); // 切り替えの途中
      expect(find.byType(CupertinoPageTransition), findsNothing);
      await tester.pumpAndSettle();
      if (label.startsWith('バトル')) {
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    }
    // ゲームを閉じる（タイマーを残さない）
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'やめる'));
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  group('普通の iPhone の横向き（874x402・左右にノッチ分の余白）', () {
    void phoneLandscape(WidgetTester tester) {
      tester.view.physicalSize = const Size(874, 402);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(
        left: 62,
        right: 62,
        bottom: 21,
      );
      addTearDown(tester.view.reset);
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    }

    testWidgets('ホーム→ひとりで5問→結果画面が崩れない', (tester) async {
      phoneLandscape(tester);
      final settings = AppSettings();
      final provider = FakeAngleProvider()..latestAngle = 40;
      await tester.pumpWidget(
        AppServices(
          settings: settings,
          feedback: RecordingFeedback(settings),
          child: MaterialApp(
            home: HomeScreen(
              angleProvider: provider,
              bestScoreStore: BestScoreStore(prefs: SharedPreferencesAsync()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ひとりで（5問）'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FilledButton).last);
        await tester.pump();
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ResultScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('result_chart')), findsOneWidget);
    });

    testWidgets('バトル: 長い名前を入れても崩れない（文字数で切る）', (tester) async {
      phoneLandscape(tester);
      final settings = AppSettings();
      await tester.pumpWidget(
        AppServices(
          settings: settings,
          feedback: RecordingFeedback(settings),
          child: MaterialApp(
            home: BattleScreen(
              angleProvider: FakeAngleProvider()..latestAngle = 40,
              playerCount: 2,
            ),
          ),
        ),
      );
      for (var i = 0; i < 2; i++) {
        await tester.enterText(
          find.byKey(const ValueKey('battle_name')),
          'ＷＷＷＷＷＷＷＷＷＷＷＷ',
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('スタート'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('次へ'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.text('結果発表'), findsOneWidget);
      final limited = 'Ｗ' * BattleScreen.maxNameLength;
      expect(find.text(limited), findsWidgets);
      expect(find.text('ＷＷＷＷＷＷＷＷＷＷＷＷ'), findsNothing);
      for (final e in find.text(limited).evaluate()) {
        expect(e.size!.height, lessThan(40)); // 1 行に収まる
      }
    });

    testWidgets('バトル設定→10人→結果発表が崩れない', (tester) async {
      phoneLandscape(tester);
      final settings = AppSettings();
      await tester.pumpWidget(
        AppServices(
          settings: settings,
          feedback: RecordingFeedback(settings),
          child: MaterialApp(
            home: BattleSetupScreen(
              angleProvider: FakeAngleProvider()..latestAngle = 40,
            ),
          ),
        ),
      );
      for (var i = 0; i < 8; i++) {
        await tester.tap(find.text('＋'));
        await tester.pump();
      }
      expect(find.text('10 人'), findsOneWidget);
      await tester.tap(find.text('はじめる'));
      await tester.pumpAndSettle();
      for (var i = 1; i <= 10; i++) {
        await tester.tap(find.text('スタート'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.tap(find.text('次へ'));
        await tester.pumpAndSettle();
      }
      expect(find.text('結果発表'), findsOneWidget);
      expect(find.byKey(const ValueKey('dev_P10')), findsOneWidget);
      // 名前が1行に収まっている（縦に折り返していない）
      final names = find.textContaining('プレイヤー');
      expect(names, findsWidgets);
      for (final e in names.evaluate()) {
        expect(e.size!.height, lessThan(40));
      }
    });
  });
}
