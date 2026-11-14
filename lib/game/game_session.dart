import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/angle_provider.dart';
import 'scoring.dart';

enum GamePhase() {
  /// 目標角度を表示（3秒カウントダウン）
  showTarget,

  /// 暗転。カウントのみ表示（5秒）→ 自動ロック
  blind,

  /// 答え合わせ
  reveal,

  /// 全問終了
  finished,
}

/// 1セット（10問）の進行。角度は [AngleProvider] から読むだけで、入力源を問わない。
class GameSession({
  required final AngleProvider angleProvider,
  final int rounds = defaultRounds,
  final int showTargetSeconds = 3,
  final int blindSeconds = 5,
  List<int>? targets,

  /// ロックした瞬間に呼ぶ（ハプティクス用）。
  final VoidCallback? onLock,
}) extends ChangeNotifier {
  static const defaultRounds = 5;

  final List<int> targets = targets ?? generateTargets(count: rounds);

  final List<RoundResult> results = [];
  GamePhase _phase = GamePhase.showTarget;
  int _roundIndex = 0;
  int _countdown = 0;
  Timer? _timer;
  bool _paused = false;

  GamePhase get phase => _phase;
  int get roundIndex => _roundIndex;
  int get countdown => _countdown;
  int get currentTarget => targets[_roundIndex];
  RoundResult? get lastResult => results.isEmpty ? null : results.last;
  int get totalScore => results.fold(0, (sum, r) => sum + r.points);
  Rank get rank => rankFor(totalScore, rounds: rounds);
  bool get isLastRound => _roundIndex >= rounds - 1;

  /// 一時停止中か（中断確認ダイアログ表示中・バックグラウンド中）。
  bool get isPaused => _paused;

  void start() => _beginRound();

  void _beginRound() {
    _phase = GamePhase.showTarget;
    _runCountdown(showTargetSeconds, _beginBlind);
  }

  void _beginBlind() {
    _phase = GamePhase.blind;
    _runCountdown(blindSeconds, _lock);
  }

  void _lock() {
    // 値が無い（未着・ヒンジが取れなくなった）場合は「計測なし」= MISS。
    final actual = angleProvider.latestAngle;
    results.add(RoundResult(target: currentTarget.toDouble(), actual: actual));
    onLock?.call();
    _phase = GamePhase.reveal;
    notifyListeners();
  }

  /// 答え合わせ画面から次へ。
  void next() {
    if (_phase != GamePhase.reveal || _paused) return;
    if (isLastRound) {
      _phase = GamePhase.finished;
      notifyListeners();
      return;
    }
    _roundIndex++;
    _beginRound();
  }

  /// 一時停止。お題・暗転中ならタイマーを止める（その問題は再開時にお題からやり直す）。
  /// 答え合わせ・終了時は結果が確定済みなので状態だけ立てる。
  void pause() {
    if (_paused || _phase == GamePhase.finished) return;
    _paused = true;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  /// 再開。お題・暗転中に止めた場合は同じ問題をお題からやり直す。
  void resume() {
    if (!_paused) return;
    _paused = false;
    if (_phase == GamePhase.showTarget || _phase == GamePhase.blind) {
      _beginRound();
    } else {
      notifyListeners();
    }
  }

  void _runCountdown(int seconds, VoidCallback onDone) {
    _timer?.cancel();
    _countdown = seconds;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_paused) return;
      _countdown--;
      if (_countdown <= 0) {
        t.cancel();
        onDone();
      } else {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
