import 'package:shared_preferences/shared_preferences.dart';

/// 最高点の保存。ランクは点数から計算できるので保存しない（境目を変えても食い違わない）。
///
/// キーは「入力源 × 問題数」ごと。ヒンジと傾きは難しさが違い、
/// 問題数が違えば満点も違うため、別々に記録する。
class BestScoreStore {
  BestScoreStore({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static String keyFor({required String providerId, required int rounds}) =>
      'best_score_v2_${providerId}_r$rounds'; // v2: お題を 10〜80°（平ら=0°）に変えた 2026-11-06

  /// 記録がなければ null。
  Future<int?> load({required String providerId, required int rounds}) =>
      _prefs.getInt(keyFor(providerId: providerId, rounds: rounds));

  /// [score] が最高点を上回ったら保存して true を返す。
  Future<bool> submit({
    required String providerId,
    required int rounds,
    required int score,
  }) async {
    final key = keyFor(providerId: providerId, rounds: rounds);
    final best = await _prefs.getInt(key);
    if (best != null && score <= best) return false;
    await _prefs.setInt(key, score);
    return true;
  }
}
