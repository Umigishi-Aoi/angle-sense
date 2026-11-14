import 'package:material_ui/material_ui.dart';

import '../game/game_session.dart';
import '../game/scoring.dart';
import '../services/angle_provider.dart';
import '../services/best_score_store.dart';
import '../services/feedback.dart';
import '../ui/retro_theme.dart';
import '../widgets/angle_reveal.dart';
import '../widgets/judgement_burst.dart';
import '../widgets/angle_text.dart';
import '../widgets/inner_display_guard.dart';
import 'result_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.angleProvider,
    this.bestScoreStore,
    this.rounds = GameSession.defaultRounds,
    this.title,
    this.onFinished,
  });

  final AngleProvider angleProvider;

  /// 問題数（バトルは 1）。
  final int rounds;

  /// 上部に出す見出し（バトルの「プレイヤー1」など）。null なら「第 N / M 問」。
  final String? title;

  /// 終わったときに呼ぶ。null なら自己ベストを保存して結果画面へ（1人モード）。
  final void Function(List<RoundResult> results)? onFinished;

  /// テストで差し替える用。null なら既定の保存先。
  final BestScoreStore? bestScoreStore;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameSession _session;
  late final AppLifecycleListener _lifecycle;
  bool _revealDone = false;
  bool _finishing = false;
  late final GameFeedback _fb;

  // 効果音のきっかけ（段階・カウント・問題番号の変化）を見分けるための直前の値。
  GamePhase? _lastPhase;
  int? _lastCount;
  int? _lastRound;

  @override
  void initState() {
    super.initState();
    _fb = context.feedback;
    _session = GameSession(
      angleProvider: widget.angleProvider,
      rounds: widget.rounds,
      onLock: () {
        _fb.play(Sfx.lock);
        _fb.haptic(HapticPattern.lock);
      },
    )..addListener(_onSessionChanged);
    // バックグラウンドに回ったら一時停止。inactive では止めない
    // （Duo の開閉で画面が切り替わる瞬間に inactive が出る可能性があり、遊びそのものを止めてしまうため）。
    _lifecycle = AppLifecycleListener(onPause: _session.pause);
    // 閉じて外側の画面に移ったら一時停止（「ひらいてね」の裏で時間切れになって計測が確定しないように）。
    // 内側に戻ると一時停止画面が見えるので、「再開」でこの問題をお題からやり直す。
    widget.angleProvider.onOuterDisplay.addListener(_onOuterDisplay);
    _session.start();
  }

  void _onOuterDisplay() {
    if (widget.angleProvider.onOuterDisplay.value) _session.pause();
  }

  void _onSessionChanged() {
    if (_session.phase == GamePhase.finished) {
      _finish();
      return;
    }
    if (_session.phase != GamePhase.reveal) _revealDone = false;
    _playCues();
    setState(() {});
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
        _fb.play(Sfx.countdown);
      } else if (phase == GamePhase.blind) {
        if (_lastPhase != GamePhase.blind) {
          _fb.play(Sfx.blindStart);
        } else if (context.settings.blindTick) {
          _fb.play(Sfx.tick);
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
    final onFinished = widget.onFinished;
    if (onFinished != null) {
      onFinished(List.of(_session.results));
      return;
    }
    final store = widget.bestScoreStore ?? BestScoreStore();
    var isNewBest = false;
    int? best;
    try {
      isNewBest = await store.submit(
        providerId: widget.angleProvider.id,
        rounds: _session.rounds,
        score: _session.totalScore,
      );
      best = await store.load(
        providerId: widget.angleProvider.id,
        rounds: _session.rounds,
      );
    } catch (e) {
      // 保存に失敗しても結果は見せる（記録欄だけ出さない）。
      debugPrint('best score save failed: $e');
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(
          results: List.of(_session.results),
          totalScore: _session.totalScore,
          rank: _session.rank,
          angleProvider: widget.angleProvider,
          bestScoreStore: widget.bestScoreStore,
          bestScore: best,
          isNewBest: isNewBest,
        ),
      ),
    );
  }

  /// 中断確認。表示中はタイマーを止め、キャンセルしたら同じ問題をお題からやり直す。
  Future<void> _confirmQuit() async {
    // 結果の保存・遷移中はダイアログを出さない（遷移がダイアログを置き換えて GameScreen が残るのを防ぐ）。
    if (_finishing || _session.phase == GamePhase.finished) return;
    // 一時停止画面から開いた場合は、キャンセルしても一時停止画面に戻す（「再開」は押してから）。
    final wasPaused = _session.isPaused;
    _session.pause();
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ゲームをやめますか？'),
        content: Text(
          widget.onFinished == null
              ? 'ここまでの結果は保存されません。'
              : 'やめると、この人の番はここで終わりです（計測前なら「計測なし」）。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('続ける'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('やめる'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (quit == true) {
      final onFinished = widget.onFinished;
      if (onFinished == null) {
        Navigator.of(context).pop();
        return;
      }
      // バトル: 抜けてやり直すことはできない。計測済みならその結果、計測前なら「計測なし」で確定。
      _finishing = true;
      final results = _session.results.isNotEmpty
          ? List.of(_session.results)
          : [
              RoundResult(
                target: _session.currentTarget.toDouble(),
                actual: null,
              ),
            ];
      onFinished(results);
    } else if (!wasPaused) {
      _session.resume();
    }
  }

  @override
  void dispose() {
    widget.angleProvider.onOuterDisplay.removeListener(_onOuterDisplay);
    _lifecycle.dispose();
    _session
      ..removeListener(_onSessionChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blind = _session.phase == GamePhase.blind;
    final fg = blind ? Colors.white54 : null;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: Scaffold(
        // 暗転はふっと暗くする（パッと切り替わると目が追いつかない）。
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          color: blind
              ? Colors.black
              : Theme.of(context).scaffoldBackgroundColor,
          child: InnerDisplayGuard(
            angleProvider: widget.angleProvider,
            child: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'やめる',
                              icon: Icon(Icons.close, color: fg),
                              onPressed: _confirmQuit,
                            ),
                            Expanded(
                              child: blind
                                  ? const SizedBox.shrink()
                                  : Text(
                                      widget.title ??
                                          '第 ${_session.roundIndex + 1} / ${_session.rounds} 問',
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Center(
                          // お題→暗転→答え合わせの切り替えをフェードでつなぐ。
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: KeyedSubtree(
                              key: ValueKey(
                                '${_session.phase.name}-${_session.roundIndex}',
                              ),
                              child: _buildPhase(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_session.isPaused) _pausedOverlay(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pausedOverlay(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: ColoredBox(
        color: theme.colorScheme.surface,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('一時停止中', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              if (_session.phase == GamePhase.showTarget ||
                  _session.phase == GamePhase.blind)
                const Text('再開すると、この問題をお題からやり直します'),
              const SizedBox(height: 24),
              FilledButton(onPressed: _session.resume, child: const Text('再開')),
              const SizedBox(height: 8),
              TextButton(onPressed: _confirmQuit, child: const Text('やめる')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhase(BuildContext context) {
    final theme = Theme.of(context);
    switch (_session.phase) {
      case GamePhase.showTarget:
        // お題の数字と、その角度の見本の絵を並べる（数字だけでは何度か想像しにくいため）。
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AnglePreview(
                    key: const ValueKey('target_preview'),
                    target: _session.currentTarget.toDouble(),
                  ),
                ),
              ),
              const SizedBox(width: 32),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AngleText(_session.currentTarget, fontSize: 144),
                  const SizedBox(height: 8),
                  Text(
                    'あと ${_session.countdown} 秒で暗くなる',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 12),
                  CountdownBar(
                    remaining: _session.countdown,
                    total: _session.showTargetSeconds,
                    color: Retro.yellow,
                  ),
                ],
              ),
            ],
          ),
        );
      case GamePhase.blind:
        // 操作中は数字だけ: お題の角度と残り秒数。今の角度や見本の絵は出さない。
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_session.currentTarget}°',
              key: const ValueKey('blind_target'),
              style: const TextStyle(fontSize: 40, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              '${_session.countdown}',
              style: const TextStyle(
                fontSize: 160,
                height: 1,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            CountdownBar(
              remaining: _session.countdown,
              total: _session.blindSeconds,
              color: Colors.white70,
            ),
          ],
        );
      case GamePhase.reveal:
        final r = _session.lastResult!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 横長の画面でも下の判定・ボタンが収まるよう、分度器のほうを縮める。
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      // 一時停止中はアニメを止める（ダイアログや一時停止画面の裏で判定音が鳴らないように）。
                      child: TickerMode(
                        enabled: !_session.isPaused,
                        child: AngleReveal(
                          key: ValueKey(_session.roundIndex),
                          target: r.target,
                          actual: r.actual,
                          onCompleted: () {
                            _fb.judgement(r.judgement);
                            setState(() => _revealDone = true);
                          },
                        ),
                      ),
                    ),
                    // 誤差が小さいと線が重なって見分けにくいので、先端を拡大して並べる。
                    if (r.measured && r.error! <= zoomMaxError) ...[
                      const SizedBox(width: 24),
                      AnimatedOpacity(
                        opacity: _revealDone ? 1 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: SizedBox(
                          width: 150,
                          child: AngleZoom(
                            key: const ValueKey('angle_zoom'),
                            target: r.target,
                            actual: r.actual!,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legend(theme.colorScheme.primary, '目標 ${r.target.round()}°'),
                  const SizedBox(width: 24),
                  _legend(
                    theme.colorScheme.tertiary,
                    r.measured ? 'あなた ${r.actual!.round()}°' : 'あなた 計測なし',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedOpacity(
                opacity: _revealDone ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: Column(
                  children: [
                    if (_revealDone)
                      JudgementBurst(
                        judgement: r.judgement,
                        child: Text(
                          r.judgement.label,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: Retro.judgement(r.judgement),
                          ),
                        ),
                      )
                    else
                      Text(
                        r.judgement.label,
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: Retro.judgement(r.judgement),
                        ),
                      ),
                    Text(
                      r.measured
                          ? '誤差 ${r.error!.toStringAsFixed(1)}°  +${r.points}点'
                          : '角度を取得できませんでした  +0点',
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _revealDone ? _session.next : null,
                      child: Text(
                        _session.isLastRound
                            ? (widget.onFinished == null ? '結果へ' : '次へ')
                            : '次の問題',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case GamePhase.finished:
        return const SizedBox.shrink();
    }
  }

  Widget _legend(Color color, String text) => Row(
    children: [
      Container(width: 16, height: 4, color: color),
      const SizedBox(width: 6),
      Text(text),
    ],
  );
}

/// 答え合わせで拡大図を出す誤差の上限（これより大きいズレは元の図で十分見える）。
const zoomMaxError = 10.0;

/// 残り秒数をドットの四角で出す（1秒=1マス。減っていくのが一目で分かるように）。
class CountdownBar extends StatelessWidget {
  const CountdownBar({
    super.key,
    required this.remaining,
    required this.total,
    required this.color,
  });

  final int remaining;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: i < remaining ? color : Colors.transparent,
              border: Border.all(color: color, width: Retro.px),
            ),
          ),
      ],
    );
  }
}
