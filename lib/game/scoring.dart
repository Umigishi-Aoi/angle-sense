import 'dart:math' as math;

/// 1問の判定。
enum Judgement(final String label, final int points) {
  perfect('PERFECT', 100),
  great('GREAT', 70),
  good('GOOD', 40),
  miss('MISS', 0),
}

/// 誤差（度）から判定する。±1°=PERFECT / ±5°=GREAT / ±10°=GOOD / それ以上=MISS。
Judgement judge(double target, double actual) {
  final error = (actual - target).abs();
  if (error <= 1) return Judgement.perfect;
  if (error <= 5) return Judgement.great;
  if (error <= 10) return Judgement.good;
  return Judgement.miss;
}

enum Rank() {
  s,
  a,
  b,
  c,
}

extension RankLabel on Rank {
  String get label => name.toUpperCase();
}

/// 満点（問題数×100点）に対する割合で決める。S≥85% / A≥65% / B≥40% / C。
/// 例: 5問=500点満点なら S≥425 / A≥325 / B≥200。
Rank rankFor(int totalScore, {required int rounds}) {
  final ratio = totalScore / (rounds * Judgement.perfect.points);
  if (ratio >= 0.85) return Rank.s;
  if (ratio >= 0.65) return Rank.a;
  if (ratio >= 0.40) return Rank.b;
  return Rank.c;
}

/// 1問の結果。
class const RoundResult({
  required final double target,

  /// ロック時の角度。null = 計測なし（ロック時に角度が取れていなかった）→ MISS。
  required final double? actual,
}) {
  bool get measured => actual != null;
  double? get error => actual == null ? null : (actual! - target).abs();
  Judgement get judgement =>
      actual == null ? Judgement.miss : judge(target, actual!);
  int get points => judgement.points;
}

/// お題の最小・最大（ゲームの角度。0°=平ら / 90°=直角）。
///
/// iPhone Duo は折り具合がおよそ 85° を超える（ヒンジで 95° 未満になる）と外側の画面に
/// 切り替わり、アプリからは止められない（iOS 27.2 SDK に固定する API なし・実機確認 2026-11-06）。
/// そのため内側の画面だけで遊べる 10〜80° に限る。10° 未満はヒンジが 174° 超で 180° に丸めて届くため使わない。
const minTarget = 10;
const maxTarget = 80;

/// お題の角度を作る。ヒンジの実効精度（約5°）に合わせて5°刻み。
List<int> generateTargets({required int count, math.Random? random}) {
  final r = random ?? math.Random();
  final candidates = [for (var d = minTarget; d <= maxTarget; d += 5) d];
  return List.generate(count, (_) => candidates[r.nextInt(candidates.length)]);
}
