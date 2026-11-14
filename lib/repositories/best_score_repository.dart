import 'package:flutter/foundation.dart';

import '../services/best_score_store.dart';
import '../utils/result.dart';

/// 1回分の記録の結果。
typedef BestScoreUpdate = ({
  /// 今回より前の最高点（初回は null）。
  int? previousBest,

  /// 今回分を反映した後の最高点（読み直せなかったときは null）。
  int? best,

  /// 今回で最高点を上回ったか（初回も true）。
  bool isNewBest,
});

/// 自己ベストの読み書き。保存先（[BestScoreStore]）の失敗は例外でなく [Result] で返す。
///
/// アプリ起動時に 1 つだけ作り、`AppServices` で画面に配る。
class BestScoreRepository(final BestScoreStore _store) {
  /// 記録がなければ Ok(null)。
  Future<Result<int?>> load({
    required String providerId,
    required int rounds,
  }) async {
    try {
      return Result.ok(
        await _store.load(providerId: providerId, rounds: rounds),
      );
    } on Exception catch (e) {
      debugPrint('best score load failed: $e');
      return Result.error(e);
    }
  }

  /// [score] を記録する。上回ったときだけ保存される。
  Future<Result<BestScoreUpdate>> submit({
    required String providerId,
    required int rounds,
    required int score,
  }) async {
    try {
      final previousBest = await _store.load(
        providerId: providerId,
        rounds: rounds,
      );
      final isNewBest = await _store.submit(
        providerId: providerId,
        rounds: rounds,
        score: score,
      );
      final best = await _store.load(providerId: providerId, rounds: rounds);
      return Result.ok((
        previousBest: previousBest,
        best: best,
        isNewBest: isNewBest,
      ));
    } on Exception catch (e) {
      debugPrint('best score save failed: $e');
      return Result.error(e);
    }
  }
}
