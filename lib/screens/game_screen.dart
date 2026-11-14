import 'package:material_ui/material_ui.dart';

import '../game/game_session.dart';
import '../game/scoring.dart';
import '../services/angle_provider.dart';
import '../services/feedback.dart';
import '../ui/retro_theme.dart';
import '../view_models/game_view_model.dart';
import '../widgets/angle_reveal.dart';
import '../widgets/angle_text.dart';
import '../widgets/inner_display_guard.dart';
import '../widgets/judgement_burst.dart';
import 'result_screen.dart';

class const GameScreen({
  super.key,
  required final AngleProvider angleProvider,

  /// 問題数（バトルは 1）。
  final int rounds = GameSession.defaultRounds,

  /// 上部に出す見出し（バトルの「プレイヤー1」など）。null なら「第 N / M 問」。
  final String? title,

  /// 終わったときに呼ぶ。null なら自己ベストを保存して結果画面へ（1人モード）。
  final void Function(List<RoundResult> results)? onFinished,
}) extends StatefulWidget {
  @override
  State<GameScreen> createState() => _GameScreenState();
}

/// 表示と入力の受け渡しだけを行う。進行と判断は [GameViewModel]。
class _GameScreenState() extends State<GameScreen> {
  late final GameViewModel _vm;
  late final AppLifecycleListener _lifecycle;
  bool _endHandled = false;

  @override
  void initState() {
    super.initState();
    _vm = GameViewModel(
      angleProvider: widget.angleProvider,
      feedback: context.feedback,
      settings: context.settings,
      bestScores: context.bestScores,
      requestReview: context.requestReview,
      isBattle: widget.onFinished != null,
      rounds: widget.rounds,
    )..addListener(_onViewModelChanged);
    // バックグラウンドに回ったら一時停止。inactive では止めない
    // （Duo の開閉で画面が切り替わる瞬間に inactive が出る可能性があり、遊びそのものを止めてしまうため）。
    _lifecycle = AppLifecycleListener(onPause: _vm.pause);
    _vm.start();
  }

  void _onViewModelChanged() {
    final end = _vm.ended;
    if (end == null) {
      setState(() {});
      return;
    }
    if (_endHandled || !mounted) return;
    _endHandled = true;
    switch (end) {
      case BattleGameEnd(:final results):
        widget.onFinished?.call(results);
      case SoloGameEnd():
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => ResultScreen(
              results: end.results,
              totalScore: end.totalScore,
              rank: end.rank,
              angleProvider: widget.angleProvider,
              bestScore: end.bestScore,
              isNewBest: end.isNewBest,
            ),
          ),
        );
    }
  }

  /// 中断確認。表示中はタイマーを止め、キャンセルしたら同じ問題をお題からやり直す。
  Future<void> _confirmQuit() async {
    if (!_vm.canQuit) return;
    final wasPaused = _vm.beginQuit();
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ゲームをやめますか？'),
        content: Text(
          _vm.isBattle
              ? 'やめると、この人の番はここで終わりです（計測前なら「計測なし」）。'
              : 'ここまでの結果は保存されません。',
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
    if (quit != true) {
      _vm.cancelQuit(wasPaused: wasPaused);
      return;
    }
    if (_vm.isBattle) {
      _vm.quit(); // 確定した結果は ended 経由で onFinished に渡る
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _vm
      ..removeListener(_onViewModelChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blind = _vm.phase == GamePhase.blind;
    final retro = context.retroColors;
    final fg = blind ? retro.blindIcon : null;
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
              ? retro.blindBackground
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
                                          '第 ${_vm.roundIndex + 1} / ${widget.rounds} 問',
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
                          // 「アニメーションを削除」設定のときは切り替えを即時にする。
                          // iOS の「視差効果を減らす」はフェードを推奨しているので、こちらは残す。
                          child: AnimatedSwitcher(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 250),
                            child: KeyedSubtree(
                              key: ValueKey(
                                '${_vm.phase.name}-${_vm.roundIndex}',
                              ),
                              child: _buildPhase(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_vm.isPaused) _pausedOverlay(context),
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
              if (_vm.phase == GamePhase.showTarget ||
                  _vm.phase == GamePhase.blind)
                const Text('再開すると、この問題をお題からやり直します'),
              const SizedBox(height: 24),
              FilledButton(onPressed: _vm.resume, child: const Text('再開')),
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
    final retro = context.retroColors;
    switch (_vm.phase) {
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
                    target: _vm.currentTarget.toDouble(),
                    semanticsLabel: 'お題 ${_vm.currentTarget}° の見本の図',
                  ),
                ),
              ),
              const SizedBox(width: 32),
              // 文字を大きくする設定で高さに収まらないときは、数字ごと縮めて収める（収まるときは等倍）。
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AngleText(_vm.currentTarget, fontSize: 144),
                    const SizedBox(height: 8),
                    Text(
                      'あと ${_vm.countdown} 秒で暗くなる',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 12),
                    // 上の文と同じ内容なので読み上げない。
                    ExcludeSemantics(
                      child: CountdownBar(
                        remaining: _vm.countdown,
                        total: _vm.showTargetSeconds,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case GamePhase.blind:
        // 操作中は数字だけ: お題の角度と残り秒数。今の角度や見本の絵は出さない。
        // 文字を大きくする設定で高さに収まらないときは、全体を縮めて収める（収まるときは等倍）。
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: 'お題 ${_vm.currentTarget}°',
                excludeSemantics: true,
                child: Text(
                  '${_vm.currentTarget}°',
                  key: const ValueKey('blind_target'),
                  style: TextStyle(fontSize: 40, color: retro.blindText),
                ),
              ),
              const SizedBox(height: 16),
              // 残り秒数は下の四角の読み上げ（「残り N 秒」）で伝える。
              ExcludeSemantics(
                child: Text(
                  '${_vm.countdown}',
                  style: TextStyle(
                    fontSize: 160,
                    height: 1,
                    color: retro.blindText,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CountdownBar(
                remaining: _vm.countdown,
                total: _vm.blindSeconds,
                color: retro.blindText,
              ),
            ],
          ),
        );
      case GamePhase.reveal:
        final r = _vm.lastResult!;
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
                        enabled: !_vm.isPaused,
                        child: AngleReveal(
                          key: ValueKey(_vm.roundIndex),
                          target: r.target,
                          actual: r.actual,
                          onCompleted: _vm.onRevealCompleted,
                        ),
                      ),
                    ),
                    // 誤差が小さいと線が重なって見分けにくいので、先端を拡大して並べる。
                    if (r.measured && r.error! <= zoomMaxError) ...[
                      const SizedBox(width: 24),
                      AnimatedOpacity(
                        opacity: _vm.revealDone ? 1 : 0,
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
              // 凡例は図の読み上げ（目標・あなたの角度）と同じ内容なので読み上げない。
              ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legend(
                      theme.colorScheme.primary,
                      '目標 ${r.target.round()}°',
                    ),
                    const SizedBox(width: 24),
                    _legend(
                      theme.colorScheme.secondary,
                      r.measured ? 'あなた ${r.actual!.round()}°' : 'あなた 計測なし',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AnimatedOpacity(
                opacity: _vm.revealDone ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: Column(
                  children: [
                    if (_vm.revealDone)
                      JudgementBurst(
                        judgement: r.judgement,
                        child: Text(
                          r.judgement.label,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: retro.judgement(r.judgement),
                          ),
                        ),
                      )
                    else
                      Text(
                        r.judgement.label,
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: retro.judgement(r.judgement),
                        ),
                      ),
                    Text(
                      r.measured
                          ? '誤差 ${r.error!.toStringAsFixed(1)}°  +${r.points}点'
                          : '角度を取得できませんでした  +0点',
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _vm.revealDone ? _vm.next : null,
                      child: Text(
                        _vm.isLastRound
                            ? (_vm.isBattle ? '次へ' : '結果へ')
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
///
/// 1マスは 28px（間隔込みで 36px）。秒数が増えて幅に収まらないときだけ全体を縮める
/// （収まるときは等倍のまま）。
class const CountdownBar({
  super.key,
  required final int remaining,
  required final int total,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '残り $remaining 秒',
      child: _boxes(),
    );
  }

  Widget _boxes() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
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
      ),
    );
  }
}
