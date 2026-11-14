import 'dart:async';

import 'package:flutter/foundation.dart';

import '../game/game_session.dart';
import '../game/scoring.dart';
import '../repositories/best_score_repository.dart';
import '../services/angle_provider.dart';
import '../services/app_settings.dart';
import '../services/feedback.dart';
import '../utils/result.dart';

/// 結果画面が出てからレビュー依頼を出すまでの待ち時間。
const reviewRequestDelay = Duration(milliseconds: 1500);

/// ゲームが終わったときに画面がすること。
sealed class GameEnd();

/// 1人モード: 自己ベストを記録し終えた。結果画面へ進む。
final class SoloGameEnd({
  required final List<RoundResult> results,
  required final int totalScore,
  required final Rank rank,

  /// 保存済みの最高点（今回分を反映後）。保存に失敗したときは null。
  required final int? bestScore,
  required final bool isNewBest,
}) extends GameEnd;

/// バトル: この人の番の結果が確定した。呼び出し元に渡す。
final class BattleGameEnd(final List<RoundResult> results) extends GameEnd;

/// ゲーム画面の進行と判断（効果音・振動のきっかけ、自己ベストの記録、レビュー依頼、中断時の結果）。
///
/// 画面（GameScreen）は表示と入力の受け渡しだけを行い、[ended] が立ったら遷移する。
class GameViewModel({
  required final AngleProvider angleProvider,
  required final GameFeedback _feedback,
  required final AppSettings _settings,
  required final BestScoreRepository _bestScores,

  /// App Store のレビュー依頼。
  required final Future<void> Function() _requestReview,

  /// バトル（1人ずつ 1 問）か。true なら自己ベストを記録せず、結果は [BattleGameEnd] で返す。
  final bool isBattle = false,
  final int rounds = GameSession.defaultRounds,

  /// テストで差し替える用。null ならランダム。
  List<int>? targets,
}) extends ChangeNotifier {
  final GameSession _session = GameSession(
    angleProvider: angleProvider,
    rounds: rounds,
    targets: targets,
    onLock: () {
      _feedback
        ..play(Sfx.lock)
        ..haptic(HapticPattern.lock);
    },
  );

  bool _revealDone = false;
  bool _finishing = false;
  bool _disposed = false;
  GameEnd? _ended;

  // 効果音のきっかけ（段階・カウント・問題番号の変化）を見分けるための直前の値。
  GamePhase? _lastPhase;
  int? _lastCount;
  int? _lastRound;

  GamePhase get phase => _session.phase;
  int get roundIndex => _session.roundIndex;
  int get countdown => _session.countdown;
  int get currentTarget => _session.currentTarget;
  int get showTargetSeconds => _session.showTargetSeconds;
  int get blindSeconds => _session.blindSeconds;
  RoundResult? get lastResult => _session.lastResult;
  bool get isLastRound => _session.isLastRound;
  bool get isPaused => _session.isPaused;

  /// 答え合わせのアニメが終わったか（判定と「次へ」を出してよいか）。
  bool get revealDone => _revealDone;

  /// 終わったときにすること。null の間は遊んでいる途中。
  GameEnd? get ended => _ended;

  /// 中断の確認を出してよいか（結果の保存・遷移中は出さない。
  /// 遷移がダイアログを置き換えて GameScreen が残るのを防ぐ）。
  bool get canQuit => !_finishing && _session.phase != GamePhase.finished;

  /// 1問目を始める。
  void start() {
    _session.addListener(_onSessionChanged);
    // 閉じて外側の画面に移ったら一時停止（「ひらいてね」の裏で時間切れになって計測が確定しないように）。
    // 内側に戻ると一時停止画面が見えるので、「再開」でこの問題をお題からやり直す。
    angleProvider.onOuterDisplay.addListener(_onOuterDisplay);
    _session.start();
  }

  void pause() => _session.pause();
  void resume() => _session.resume();
  void next() => _session.next();

  /// 答え合わせのアニメが終わった。判定の音と振動を鳴らす。
  void onRevealCompleted() {
    final r = _session.lastResult;
    if (r == null) return;
    _feedback.judgement(r.judgement);
    _revealDone = true;
    notifyListeners();
  }

  /// 中断確認を出す前に呼ぶ。止める前に一時停止していたかを返す（[cancelQuit] に渡す）。
  bool beginQuit() {
    final wasPaused = _session.isPaused;
    _session.pause();
    return wasPaused;
  }

  /// 「続ける」を選んだ。一時停止画面から開いた場合は一時停止画面に戻す（「再開」は押してから）。
  void cancelQuit({required bool wasPaused}) {
    if (!wasPaused) _session.resume();
  }

  /// 「やめる」を選んだ。1人モードは保存せずに抜ける（何もしない）。
  /// バトルは抜けてやり直すことはできないので、計測済みならその結果、計測前なら「計測なし」で確定する。
  void quit() {
    if (!isBattle) return;
    _finishing = true;
    final results = _session.results.isNotEmpty
        ? List.of(_session.results)
        : [
            RoundResult(
              target: _session.currentTarget.toDouble(),
              actual: null,
            ),
          ];
    _end(BattleGameEnd(results));
  }

  void _onOuterDisplay() {
    if (angleProvider.onOuterDisplay.value) _session.pause();
  }

  void _onSessionChanged() {
    if (_session.phase == GamePhase.finished) {
      unawaited(_finish());
      return;
    }
    if (_session.phase != GamePhase.reveal) _revealDone = false;
    _playCues();
    notifyListeners();
  }

  /// お題のカウント・暗転開始・暗転中のカウントの音。
  void _playCues() {
    final phase = _session.phase;
    final count = _session.countdown;
    final round = _session.roundIndex;
    if (_session.isPaused) {
      // 再開したら（同じカウントでも）鳴らし直す。
      _lastPhase = null;
      return;
    }
    final changed =
        phase != _lastPhase || count != _lastCount || round != _lastRound;
    if (changed) {
      if (phase == GamePhase.showTarget) {
        _feedback.play(Sfx.countdown);
      } else if (phase == GamePhase.blind) {
        if (_lastPhase != GamePhase.blind) {
          _feedback.play(Sfx.blindStart);
        } else if (_settings.blindTick) {
          _feedback.play(Sfx.tick);
        }
      }
    }
    _lastPhase = phase;
    _lastCount = count;
    _lastRound = round;
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    final results = List.of(_session.results);
    if (isBattle) {
      _end(BattleGameEnd(results));
      return;
    }
    final saved = await _bestScores.submit(
      providerId: angleProvider.id,
      rounds: _session.rounds,
      score: _session.totalScore,
    );
    // 保存に失敗しても結果は見せる（記録欄だけ出さない）。
    final update = switch (saved) {
      Ok(:final value) => value,
      Error() => null,
    };
    if (_disposed) return;
    final isNewBest = update?.isNewBest ?? false;
    // 前の記録を上回ったときだけレビューを頼む（初回は誰でも「自己ベスト」になるので除く）。
    if (isNewBest && update?.previousBest != null) {
      unawaited(_requestReviewLater(_requestReview));
    }
    _end(
      SoloGameEnd(
        results: results,
        totalScore: _session.totalScore,
        rank: _session.rank,
        bestScore: update?.best,
        isNewBest: isNewBest,
      ),
    );
  }

  void _end(GameEnd end) {
    _ended = end;
    notifyListeners();
  }

  /// 結果画面のランク表示と効果音が落ち着いてから頼む。
  /// 画面（とこの ViewModel）が結果画面に置き換わった後に呼ぶので、dispose とは切り離す。
  static Future<void> _requestReviewLater(
    Future<void> Function() requestReview,
  ) async {
    await Future<void>.delayed(reviewRequestDelay);
    try {
      await requestReview();
    } on Exception catch (e) {
      // 出なくてもゲームには関係ない。
      debugPrint('review request failed: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    angleProvider.onOuterDisplay.removeListener(_onOuterDisplay);
    _session
      ..removeListener(_onSessionChanged)
      ..dispose();
    super.dispose();
  }
}
