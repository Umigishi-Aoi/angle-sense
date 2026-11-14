import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:material_ui/material_ui.dart';

import '../game/game_session.dart';
import '../main.dart' show routeObserver;
import '../services/angle_provider.dart';
import '../services/best_score_store.dart';
import '../services/feedback.dart';
import '../ui/retro_theme.dart';
import '../widgets/angle_reveal.dart';
import '../widgets/angle_text.dart';
import '../widgets/inner_display_guard.dart';
import 'battle_screen.dart';
import 'diagnostics_screen.dart';
import 'game_screen.dart';

class const HomeScreen({
  super.key,
  required final AngleProvider angleProvider,
  final BestScoreStore? bestScoreStore,
}) extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState() extends State<HomeScreen> with RouteAware {
  late final BestScoreStore _store = widget.bestScoreStore ?? BestScoreStore();
  late Future<int?> _best = _loadBest();
  bool _starting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// 結果画面などから戻ってきたら最高点を読み直す（「もう一度」を挟んでも反映される）。
  @override
  void didPopNext() {
    // setState のクロージャが Future を返すとデバッグ版でアサーションが出て、
    // Navigator がロックされたまま以降のタップが効かなくなる（2026-11-09 シミュレータで発生）。
    final best = _loadBest();
    setState(() {
      _best = best;
    });
  }

  Future<int?> _loadBest() async {
    try {
      return await _store.load(
        providerId: widget.angleProvider.id,
        rounds: GameSession.defaultRounds,
      );
    } on Exception catch (e) {
      debugPrint('best score load failed: $e');
      return null;
    }
  }

  Future<void> _start() async {
    if (_starting) return; // 連打で GameScreen が2つ積まれるのを防ぐ
    _starting = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GameScreen(
            angleProvider: widget.angleProvider,
            bestScoreStore: widget.bestScoreStore,
          ),
        ),
      );
    } finally {
      _starting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = widget.angleProvider;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: '設定',
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: InnerDisplayGuard(
        angleProvider: provider,
        child: SafeArea(
          child: Center(
            child: StreamBuilder<double>(
              stream: provider.angleStream,
              initialData: provider.latestAngle,
              builder: (context, snap) {
                final ready = provider.latestAngle != null;
                final info = <Widget>[
                  Text(
                    'ピタッとアングル',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: Retro.yellow,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('目標の角度を覚えて、暗闇の中で合わせよう'),
                  const SizedBox(height: 4),
                  Text('平らが 0°・直角が 90°', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 32),
                  Text(
                    '入力: ${provider.label}',
                    style: theme.textTheme.bodySmall,
                  ),
                  // 今の角度を絵と数字で出す（ゲーム中は出さない）。動かすと線が動くので、遊び方が伝わる。
                  ready
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 120,
                              child: AnglePreview(
                                key: const ValueKey('home_preview'),
                                target: provider.latestAngle!,
                                color: Retro.cyan,
                              ),
                            ),
                            const SizedBox(width: 12),
                            AngleText(provider.latestAngle!, fontSize: 32),
                          ],
                        )
                      : const Text('角度: --'),
                  const SizedBox(height: 8),
                  FutureBuilder<int?>(
                    future: _best,
                    builder: (context, best) => Text(
                      best.data == null ? '自己ベスト: --' : '自己ベスト: ${best.data} 点',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ];
                final buttons = <Widget>[
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 20,
                      ),
                      textStyle: theme.textTheme.titleLarge,
                    ),
                    // 角度が一度も取れていないうちは始めない（全問「計測なし」になるため）。
                    onPressed: ready ? _start : null,
                    child: const Text('ひとりで（5問）'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: ready
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  BattleSetupScreen(angleProvider: provider),
                            ),
                          )
                        : null,
                    child: const Text('バトル（2〜10人）'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _showHowTo(context),
                    child: const Text('あそびかた・持ち方'),
                  ),
                  if (!ready) ...[
                    const SizedBox(height: 8),
                    Text(
                      '角度を取得しています…（センサーのない端末では遊べません）',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ];
                // 普通の iPhone の横向き（高さ約 400）では縦に並べると収まらないので左右に分ける。
                return LayoutBuilder(
                  builder: (context, c) => c.maxHeight < 560
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: info,
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: buttons,
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...info,
                            const SizedBox(height: 32),
                            ...buttons,
                          ],
                        ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static const _howToHinge =
      '1. 内側の画面を見ながら、本を読むように両手で持つ\n'
      '   （机に置いてノートパソコンのように開いてもOK）\n\n'
      '2. 平らに開いた状態が 0°。折るほど大きくなり、直角が 90°\n\n'
      '3. お題の角度を覚えたら、画面が暗くなる。5秒のうちに合わせて、そのまま止めておく\n\n'
      '・お題は 10〜80°。直角より閉じると外側の画面に切り替わるので、そこまでは閉じない\n'
      '・0° に近い角度はバネで開ききるので、指で支えて止める';

  /// 普通の iPhone / iPad: 本体の傾きで遊ぶ（横向き固定）。
  static const _howToTilt =
      '1. 本体を横向きにして、両手で持つ\n\n'
      '2. 画面を上にして平らに置いた状態が 0°。起こすほど大きくなり、まっすぐ立てると 90°\n\n'
      '3. お題の角度を覚えたら、画面が暗くなる。5秒のうちに合わせて、そのまま止めておく\n\n'
      '・お題は 10〜80°\n'
      '・折りたたみ iPhone では、本体を折る角度で遊べます';

  /// 持ち方・角度の測り方の説明。
  void _showHowTo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('あそびかた'),
        content: SingleChildScrollView(
          child: Text(
            widget.angleProvider.id == 'hinge' ? _howToHinge : _howToTilt,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    final settings = context.settings;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('効果音'),
                subtitle: const Text('マナーモード中は鳴りません'),
                value: settings.sound,
                onChanged: (v) => settings.sound = v,
              ),
              SwitchListTile(
                title: const Text('暗転中のカウント音'),
                subtitle: const Text('1秒ごとの小さな音。リズムで時間が分かります'),
                value: settings.blindTick,
                onChanged: settings.sound
                    ? (v) => settings.blindTick = v
                    : null,
              ),
              SwitchListTile(
                title: const Text('振動'),
                subtitle: const Text('iPhoneの「触覚」設定によってはマナーモード中に鳴りません'),
                value: settings.haptics,
                onChanged: (v) => settings.haptics = v,
              ),
              // 開発用。リリース版（TestFlight・App Store）には出さない。
              if (kDebugMode)
                ListTile(
                  title: const Text('診断（実機確認用）'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DiagnosticsScreen(
                        angleProvider: widget.angleProvider,
                      ),
                    ),
                  ),
                ),
              ListTile(
                title: const Text('ライセンス'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'ピタッとアングル',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
