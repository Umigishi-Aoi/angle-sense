import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/game/scoring.dart';

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
    test('割合で決める（10問=1000点満点の閾値）', () {
      expect(rankFor(1000, rounds: 10), Rank.s);
      expect(rankFor(850, rounds: 10), Rank.s);
      expect(rankFor(849, rounds: 10), Rank.a);
      expect(rankFor(650, rounds: 10), Rank.a);
      expect(rankFor(649, rounds: 10), Rank.b);
      expect(rankFor(400, rounds: 10), Rank.b);
      expect(rankFor(399, rounds: 10), Rank.c);
    });
  });

  test('generateTargets は 10〜80 の5°刻み（内側の画面だけで遊べる範囲）', () {
    final t = generateTargets(count: 200);
    expect(t.length, 200);
    expect(t.every((d) => d >= 10 && d <= 80 && d % 5 == 0), isTrue);
  });
}
