import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/game/game_session.dart';
import 'package:hinge_angle_game/game/scoring.dart';

import '../helpers/fakes.dart';

void main() {
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

  testWidgets('結果は外から書き換えられない（読み取り専用の見え方）', (tester) async {
    final session = GameSession(
      angleProvider: FakeAngleProvider()..latestAngle = 45,
      targets: List.filled(5, 45),
    )..start();
    final view = session.results;
    await tester.pump(const Duration(seconds: 8));
    expect(view, hasLength(1)); // 同じ見え方で増えた分も見える
    expect(
      () => session.results.add(const RoundResult(target: 0, actual: 0)),
      throwsUnsupportedError,
    );
    session.dispose();
  });

  test('お題が問題数より少ないと作れない', () {
    expect(
      () => GameSession(
        angleProvider: FakeAngleProvider(),
        targets: [45, 45], // 既定の 5 問に足りない
      ),
      throwsAssertionError,
    );
  });
}
