import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:material_ui/material_ui.dart';

import '../app/route_observer.dart';
import '../game/game_session.dart';
import '../l10n/l10n.dart';
import '../services/angle_provider.dart';
import '../services/feedback.dart';
import '../utils/result.dart';
import '../widgets/angle_reveal.dart';
import '../widgets/angle_text.dart';
import '../widgets/inner_display_guard.dart';
import 'battle_screen.dart';
import 'diagnostics_screen.dart';
import 'game_screen.dart';

class const HomeScreen({
  super.key,
  required final AngleProvider angleProvider,
}) extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState() extends State<HomeScreen> with RouteAware {
  late Future<int?> _best = _loadBest();
  bool _starting = false;

  // センサーの値は 1 秒に数十回届く。画面全体を作り直さないよう、
  // 角度の絵と数字は [_angle]、ボタンなどは角度が取れたかどうか（[_ready]）が変わったときだけ作り直す。
  late final ValueNotifier<double?> _angle = ValueNotifier(
    widget.angleProvider.latestAngle,
  );
  late final ValueNotifier<bool> _ready = ValueNotifier(
    widget.angleProvider.latestAngle != null,
  );
  late final StreamSubscription<double> _angleSub;

  /// ゲーム画面などに覆われて見えていない間は false（角度の絵を描き直さない）。
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _angleSub = widget.angleProvider.angleStream.listen(_onAngle);
  }

  void _onAngle(double _) {
    final latest = widget.angleProvider.latestAngle;
    _ready.value = latest != null;
    if (_visible) _angle.value = latest;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
    // 不透明な画面に覆われると、その下の画面は TickerMode が無効になる（ダイアログ等では無効にならない）。
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible && !_visible) _angle.value = widget.angleProvider.latestAngle;
    _visible = visible;
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    unawaited(_angleSub.cancel());
    _angle.dispose();
    _ready.dispose();
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

  /// 読めなかったときは記録なしと同じ表示にする。
  Future<int?> _loadBest() async {
    final best = await context.bestScores.load(
      providerId: widget.angleProvider.id,
      rounds: GameSession.defaultRounds,
    );
    return switch (best) {
      Ok(:final value) => value,
      Error() => null,
    };
  }

  Future<void> _start() async {
    if (_starting) return; // 連打で GameScreen が2つ積まれるのを防ぐ
    _starting = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GameScreen(angleProvider: widget.angleProvider),
        ),
      );
    } finally {
      _starting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final provider = widget.angleProvider;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: l10n.settingsTooltip,
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: InnerDisplayGuard(
        angleProvider: provider,
        child: SafeArea(
          child: Center(
            child: ValueListenableBuilder<bool>(
              valueListenable: _ready,
              builder: (context, ready, _) {
                final info = <Widget>[
                  Text(
                    l10n.appTitle,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.homeTagline),
                  const SizedBox(height: 4),
                  Text(l10n.homeAngleScale, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 32),
                  Text(
                    l10n.homeInput(_inputName(l10n, provider)),
                    style: theme.textTheme.bodySmall,
                  ),
                  // 今の角度を絵と数字で出す（ゲーム中は出さない）。動かすと線が動くので、遊び方が伝わる。
                  ready
                      // 角度が変わるたびに描き直すので、周りの文字やボタンを巻き込まないよう分ける。
                      ? RepaintBoundary(
                          child: ValueListenableBuilder<double?>(
                            valueListenable: _angle,
                            builder: (context, angle, _) =>
                                _livePreview(theme, angle ?? 0),
                          ),
                        )
                      : Text(l10n.homeAngleUnknown),
                  const SizedBox(height: 8),
                  FutureBuilder<int?>(
                    future: _best,
                    builder: (context, best) => Text(
                      best.data == null
                          ? l10n.homeBestNone
                          : l10n.homeBest(best.data!),
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
                    child: Text(l10n.homeSolo(GameSession.defaultRounds)),
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
                    child: Text(
                      l10n.homeBattle(
                        BattleSetupScreen.minPlayers,
                        BattleSetupScreen.maxPlayers,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _showHowTo(context),
                    child: Text(l10n.homeHowTo),
                  ),
                  if (!ready) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.homeWaitingSensor,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ];
                // 普通の iPhone の横向き（高さ約 400）では縦に並べると収まらないので左右に分ける。
                // 文字を大きくする設定で収まらないときだけスクロールできるようにする（収まるときは今までどおり中央）。
                return LayoutBuilder(
                  builder: (context, c) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: c.maxHeight),
                      child: Center(
                        child: c.maxHeight < 560
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // 幅が足りないときは、左右それぞれの中で折り返す。
                                  Flexible(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: info,
                                    ),
                                  ),
                                  Flexible(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: buttons,
                                    ),
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
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 今の角度の絵と数字。
  ///
  /// 読み上げは「今の角度 40°」の 1 つにまとめ、絵は読まない。値は角度が届くたび（1 秒に数十回）
  /// 変わるので、変化を自動で読み上げさせない（liveRegion にしない）。触れたときに今の値を読む。
  Widget _livePreview(ThemeData theme, double angle) => Semantics(
    container: true,
    label: context.l10n.homeCurrentAngle,
    value: '${angle.round()}°',
    excludeSemantics: true,
    child: _livePreviewRow(theme, angle),
  );

  Widget _livePreviewRow(ThemeData theme, double angle) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 120,
        child: AnglePreview(
          key: const ValueKey('home_preview'),
          target: angle,
          color: theme.colorScheme.secondary,
        ),
      ),
      const SizedBox(width: 12),
      // 0°〜180° のどれでも幅を同じにする（桁が変わっても絵がずれない）。
      AngleText(angle, fontSize: 32, reserveWidthFor: '180°'),
    ],
  );

  /// 入力源の名前（ヒンジ・傾き。テスト用などそれ以外は入力源が持つ名前）。
  static String _inputName(AppLocalizations l10n, AngleProvider provider) =>
      switch (provider.id) {
        'hinge' => l10n.inputHinge,
        'tilt' => l10n.inputTilt,
        _ => provider.label,
      };

  /// 持ち方・角度の測り方の説明。
  void _showHowTo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.howToTitle),
        content: SingleChildScrollView(
          child: Text(
            // 普通の iPhone / iPad は本体の傾きで遊ぶ（横向き固定）ので、説明を分ける。
            widget.angleProvider.id == 'hinge'
                ? context.l10n.howToHinge
                : context.l10n.howToTilt,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.ok),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    final settings = context.settings;
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListenableBuilder(
          listenable: settings,
          // 普通の iPhone の横向きでは、シートの高さ（画面の 9/16）に全項目が入らないのでスクロールする。
          builder: (context, _) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: Text(l10n.settingsSound),
                  subtitle: Text(l10n.settingsSoundNote),
                  value: settings.sound,
                  onChanged: (v) => settings.sound = v,
                ),
                SwitchListTile(
                  title: Text(l10n.settingsTick),
                  subtitle: Text(l10n.settingsTickNote),
                  value: settings.blindTick,
                  onChanged: settings.sound
                      ? (v) => settings.blindTick = v
                      : null,
                ),
                SwitchListTile(
                  title: Text(l10n.settingsHaptics),
                  subtitle: Text(l10n.settingsHapticsNote),
                  value: settings.haptics,
                  onChanged: (v) => settings.haptics = v,
                ),
                // 開発用。リリース版（TestFlight・App Store）には出さない。
                if (kDebugMode)
                  ListTile(
                    title: Text(l10n.settingsDiagnostics),
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
                  title: Text(l10n.settingsLicenses),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: l10n.appTitle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
