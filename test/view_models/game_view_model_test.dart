import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/game/game_session.dart';
import 'package:hinge_angle_game/game/scoring.dart';
import 'package:hinge_angle_game/repositories/best_score_repository.dart';
import 'package:hinge_angle_game/services/app_settings.dart';
import 'package:hinge_angle_game/utils/result.dart';
import 'package:hinge_angle_game/view_models/game_view_model.dart';

import '../helpers/fakes.dart';

void main() {
  late AppSettings settings;
  late RecordingFeedback feedback;
  late FakeAngleProvider provider;
  late int reviews;

  setUp(() {
    settings = AppSettings();
    feedback = RecordingFeedback(settings);
    provider = FakeAngleProvider()..latestAngle = 45;
    reviews = 0;
  });

  GameViewModel create({
    BestScoreRepository? bestScores,
    bool isBattle = false,
    int rounds = 2,
  }) => GameViewModel(
    angleProvider: provider,
    feedback: feedback,
    settings: settings,
    bestScores: bestScores ?? FakeBestScoreRepository(),
    requestReview: () async => reviews++,
    isBattle: isBattle,
    rounds: rounds,
    targets: List.filled(rounds, 45),
  )..start();

  /// お題 3 秒 → 暗転 5 秒で答え合わせまで進める。
  Future<void> toReveal(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 5));
  }

  /// 全問を進めて、自己ベストの記録（非同期）を終わらせる。
  Future<void> playAll(
    WidgetTester tester,
    GameViewModel vm,
    int rounds,
  ) async {
    for (var i = 0; i < rounds; i++) {
      await toReveal(tester);
      vm
        ..onRevealCompleted()
        ..next();
    }
    await tester.pump();
  }

  group('GameViewModel: 1人モードの終わり', () {
    testWidgets('前の自己ベストを上回ったら、結果を返し、待ってからレビューを 1 回頼む', (tester) async {
      final repo = FakeBestScoreRepository(
        submitResult: const Result.ok((
          previousBest: 100,
          best: 200,
          isNewBest: true,
        )),
      );
      final vm = create(bestScores: repo);
      await playAll(tester, vm, 2);
      expect(vm.ended, isA<SoloGameEnd>());
      final end = vm.ended! as SoloGameEnd;
      expect(end.results, hasLength(2));
      expect(end.totalScore, 200);
      expect(end.rank, Rank.s);
      expect(end.bestScore, 200);
      expect(end.isNewBest, isTrue);
      expect(repo.submitted, [200]);
      expect(reviews, 0); // すぐには頼まない
      vm.dispose(); // 結果画面に置き換わってもレビュー依頼は残る
      await tester.pump(reviewRequestDelay);
      expect(reviews, 1);
    });

    testWidgets('初回の自己ベスト（前の記録なし）ではレビューを頼まない', (tester) async {
      final vm = create();
      await playAll(tester, vm, 2);
      expect((vm.ended! as SoloGameEnd).isNewBest, isTrue);
      await tester.pump(reviewRequestDelay);
      expect(reviews, 0);
      vm.dispose();
    });

    testWidgets('上回らなければレビューを頼まない', (tester) async {
      final vm = create(
        bestScores: FakeBestScoreRepository(
          submitResult: const Result.ok((
            previousBest: 999,
            best: 999,
            isNewBest: false,
          )),
        ),
      );
      await playAll(tester, vm, 2);
      final end = vm.ended! as SoloGameEnd;
      expect(end.isNewBest, isFalse);
      expect(end.bestScore, 999);
      await tester.pump(reviewRequestDelay);
      expect(reviews, 0);
      vm.dispose();
    });

    testWidgets('保存に失敗しても結果は返す（記録欄なし・レビューなし）', (tester) async {
      final vm = create(
        bestScores: FakeBestScoreRepository(
          submitResult: Result.error(Exception('disk full')),
        ),
      );
      await playAll(tester, vm, 2);
      final end = vm.ended! as SoloGameEnd;
      expect(end.totalScore, 200);
      expect(end.bestScore, isNull);
      expect(end.isNewBest, isFalse);
      await tester.pump(reviewRequestDelay);
      expect(reviews, 0);
      vm.dispose();
    });
  });

  group('GameViewModel: バトル', () {
    testWidgets('終わったら自己ベストを記録せずに結果を返す', (tester) async {
      final repo = FakeBestScoreRepository();
      final vm = create(bestScores: repo, isBattle: true, rounds: 1);
      await playAll(tester, vm, 1);
      final end = vm.ended;
      expect(end, isA<BattleGameEnd>());
      expect((end! as BattleGameEnd).results.single.actual, 45);
      expect(repo.submitted, isEmpty);
      vm.dispose();
    });

    testWidgets('計測前にやめたら「計測なし」で確定する', (tester) async {
      final vm = create(isBattle: true, rounds: 1);
      await tester.pump(const Duration(seconds: 1));
      final wasPaused = vm.beginQuit();
      expect(wasPaused, isFalse);
      expect(vm.isPaused, isTrue);
      vm.quit();
      final result = (vm.ended! as BattleGameEnd).results.single;
      expect(result.target, 45);
      expect(result.measured, isFalse);
      expect(vm.canQuit, isFalse); // 確定後は確認を出さない
      vm.dispose();
    });

    testWidgets('計測後にやめたらその結果で確定する', (tester) async {
      final vm = create(isBattle: true, rounds: 1);
      await toReveal(tester);
      vm
        ..beginQuit()
        ..quit();
      expect((vm.ended! as BattleGameEnd).results.single.actual, 45);
      vm.dispose();
    });
  });

  group('GameViewModel: 中断・一時停止', () {
    testWidgets('1人モードでやめても結果を返さない（保存しない）', (tester) async {
      final repo = FakeBestScoreRepository();
      final vm = create(bestScores: repo)
        ..beginQuit()
        ..quit();
      expect(vm.ended, isNull);
      expect(repo.submitted, isEmpty);
      vm.dispose();
    });

    testWidgets('「続ける」で、止める前に動いていたら再開・一時停止中だったらそのまま', (tester) async {
      final vm = create();
      await tester.pump(const Duration(seconds: 4)); // 暗転中
      final wasPaused = vm.beginQuit();
      vm.cancelQuit(wasPaused: wasPaused);
      expect(vm.isPaused, isFalse);
      expect(vm.phase, GamePhase.showTarget); // お題からやり直す

      vm.pause();
      final wasPaused2 = vm.beginQuit();
      expect(wasPaused2, isTrue);
      vm.cancelQuit(wasPaused: wasPaused2);
      expect(vm.isPaused, isTrue);
      vm.dispose();
    });

    testWidgets('外側の画面に移ったら一時停止する', (tester) async {
      final vm = create();
      provider.onOuterDisplay.value = true;
      expect(vm.isPaused, isTrue);
      provider.onOuterDisplay.value = false;
      vm.dispose();
    });
  });

  testWidgets('効果音のきっかけ: カウント3回→暗転開始→チッ4回→ロック、アニメ後に判定', (tester) async {
    final vm = create(rounds: 1);
    await toReveal(tester);
    expect(feedback.events, [
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
    expect(vm.revealDone, isFalse);
    vm.onRevealCompleted();
    expect(vm.revealDone, isTrue);
    expect(feedback.events.skip(10), ['perfect', 'haptic:result']);
    vm.dispose();
  });

  testWidgets('暗転中のカウント音を切ると tick は鳴らない', (tester) async {
    settings.blindTick = false;
    final vm = create(rounds: 1);
    await toReveal(tester);
    expect(feedback.events, isNot(contains('tick')));
    expect(feedback.events, contains('blindStart'));
    vm.dispose();
  });
}
