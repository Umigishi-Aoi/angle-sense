import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'services/angle_provider.dart';
import 'services/angle_provider_resolver.dart';
import 'services/app_settings.dart';
import 'services/diagnostics_log.dart';
import 'services/feedback.dart';
import 'ui/retro_theme.dart';

/// ホームに戻ったこと（上の画面が閉じたこと）を知るため。
final routeObserver = RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // OFL の条件: フォントと一緒にライセンス文を載せる（設定→ライセンス で表示）。
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(
      'assets/fonts/OFL_DotGothic16.txt',
    );
    yield LicenseEntryWithLineBreaks(['DotGothic16'], license);
  });
  final settings = AppSettings(prefs: SharedPreferencesAsync());
  await settings.load();
  final feedback = GameFeedback(settings: settings);
  // 効果音の読み込みは待たない（終わる前に鳴らそうとした音は鳴らないだけ）。
  feedback.init();
  runApp(PitattoAngleApp(settings: settings, feedback: feedback));
}

class PitattoAngleApp extends StatelessWidget {
  const PitattoAngleApp({
    super.key,
    required this.settings,
    required this.feedback,
  });

  final AppSettings settings;
  final GameFeedback feedback;

  @override
  Widget build(BuildContext context) {
    return AppServices(settings: settings, feedback: feedback, child: _app());
  }

  Widget _app() {
    return MaterialApp(
      title: 'ピタッとアングル',
      debugShowCheckedModeBanner: false,
      // 端末のライト/ダーク設定に関係なく、常にレトロ配色。
      theme: Retro.theme(),
      navigatorObservers: [routeObserver],
      home: const _Bootstrap(),
    );
  }
}

/// 入力源（ヒンジ or 傾き）を決めてからホームへ。
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> with WidgetsBindingObserver {
  late final Future<AngleProvider> _provider = resolveAngleProvider();
  late final AppLifecycleListener _lifecycle;
  bool _stoppedInBackground = false;

  @override
  void initState() {
    super.initState();
    // バックグラウンド中はセンサー（Android の加速度など）を止める。
    // inactive では止めない（Duo の開閉で画面が切り替わる瞬間に出る可能性があるため）。
    WidgetsBinding.instance.addObserver(this);
    _logSize();
    _provider.then((p) {
      if (!mounted) return;
      if (p.id != 'hinge') {
        // 普通の iPhone / iPad（傾きで遊ぶ）: 横向きに固定する。
        // 実機: 縦向きだと結果発表などのレイアウトが崩れる。傾きの角度は画面の法線だけで決まるので向きの影響はない。
        DiagnosticsLog.instance.add('rot', 'lock landscape (tilt)');
        SystemChrome.setPreferredOrientations(_landscape);
        return;
      }
      _hinge = p;
      p.onOuterDisplay.addListener(_applyOrientation);
      _applyOrientation();
    });
    _lifecycle = AppLifecycleListener(
      // 実機確認用: 開閉で inactive / hidden / paused のどれが出るかを記録する。
      onStateChange: (s) => DiagnosticsLog.instance.add('life', s.name),
      onPause: () async {
        _stoppedInBackground = true;
        await (await _provider).stop();
      },
      onResume: () async {
        if (!_stoppedInBackground) return;
        _stoppedInBackground = false;
        await (await _provider).start();
      },
    );
  }

  /// 外側⇔内側の画面切り替えはサイズの変化として現れるので記録する。
  @override
  void didChangeMetrics() => _logSize();

  AngleProvider? _hinge;

  /// 内側の画面で横長になる向きの組。最初は landscape を試し、縦長になったら portrait に切り替えて覚える
  /// （Duo の内側の画面でどちらが横長かを決め打ちしないため）。
  static const _landscape = [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];
  static const _portrait = [DeviceOrientation.portraitUp];
  List<DeviceOrientation> _innerSet = _landscape;
  List<DeviceOrientation>? _applied;

  /// 画面の回転を固定する（実機: 開いて持ち上げたり触ったりすると縦長に回ってしまう）。
  /// - 内側の画面: 横長に固定
  /// - 外側の画面（「ひらいてね」だけを出す）: 固定しない
  void _applyOrientation() {
    final p = _hinge;
    if (p == null) return;
    final want = p.onOuterDisplay.value
        ? const <DeviceOrientation>[]
        : _innerSet;
    if (identical(want, _applied)) return;
    _applied = want;
    DiagnosticsLog.instance.add(
      'rot',
      want.isEmpty
          ? 'unlocked (outer)'
          : 'lock ${want.map((o) => o.name).join(',')}',
    );
    SystemChrome.setPreferredOrientations(want);
    _verifyTimer?.cancel();
    if (want.isNotEmpty && !_flipped) {
      // 固定した「結果」のサイズで判定する。固定の直前に届く通知（開いた瞬間の、まだ回っていない縦長など）は使わない。
      _verifyTimer = Timer(const Duration(milliseconds: 800), _verifyInnerLock);
    }
  }

  Timer? _verifyTimer;

  /// 切り替えは1回だけ（どちらの組でも縦長になる異常時に行ったり来たりしないため）。
  bool _flipped = false;

  /// 固定したのに縦長 = この組は横長にならない。もう片方の組に切り替えて覚える。
  void _verifyInnerLock() {
    final p = _hinge;
    if (!mounted ||
        p == null ||
        p.onOuterDisplay.value ||
        !identical(_applied, _innerSet))
      return;
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return;
    final v = views.first;
    final size = v.physicalSize / v.devicePixelRatio;
    // 短辺 600 未満は外側の画面（466x678）なので見ない。
    if (size.shortestSide < 600 || size.width >= size.height) return;
    _flipped = true;
    _innerSet = identical(_innerSet, _landscape) ? _portrait : _landscape;
    DiagnosticsLog.instance.add(
      'rot',
      'tall after lock -> switch to ${_innerSet.map((o) => o.name).join(',')}',
    );
    _applyOrientation();
  }

  String? _lastSize;

  void _logSize() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return;
    final v = views.first;
    final s = v.physicalSize / v.devicePixelRatio;
    final label =
        '${s.width.toStringAsFixed(0)}x${s.height.toStringAsFixed(0)}';
    if (label == _lastSize) return; // 同じサイズの通知は記録しない
    _lastSize = label;
    DiagnosticsLog.instance.add('size', label);
  }

  @override
  void dispose() {
    _hinge?.onOuterDisplay.removeListener(_applyOrientation);
    _verifyTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AngleProvider>(
      future: _provider,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return HomeScreen(angleProvider: snap.data!);
      },
    );
  }
}
