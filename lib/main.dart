import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:store_review/store_review.dart';

import 'app/orientation_controller.dart';
import 'app/route_observer.dart';
import 'app/sensor_lifecycle.dart';
import 'repositories/best_score_repository.dart';
import 'screens/home_screen.dart';
import 'services/angle_provider.dart';
import 'services/angle_provider_resolver.dart';
import 'services/app_settings.dart';
import 'services/best_score_store.dart';
import 'services/diagnostics_log.dart';
import 'services/feedback.dart';
import 'ui/retro_theme.dart';

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
  unawaited(feedback.init());
  final bestScores = BestScoreRepository(BestScoreStore());
  runApp(
    PitattoAngleApp(
      settings: settings,
      feedback: feedback,
      bestScores: bestScores,
    ),
  );
}

final _storeReview = StoreReview();

class const PitattoAngleApp({
  super.key,
  required final AppSettings settings,
  required final GameFeedback feedback,
  required final BestScoreRepository bestScores,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppServices(
      settings: settings,
      feedback: feedback,
      bestScores: bestScores,
      requestReview: _storeReview.request,
      child: _app(),
    );
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
class const _Bootstrap() extends StatefulWidget {
  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState() extends State<_Bootstrap> with WidgetsBindingObserver {
  late final Future<AngleProvider> _provider = resolveAngleProviderOrTilt();
  late final SensorLifecycle _sensors = SensorLifecycle(_provider);
  final OrientationController _orientation = OrientationController();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // バックグラウンド中はセンサー（Android の加速度など）を止める（SensorLifecycle）。
    WidgetsBinding.instance.addObserver(this);
    _logSize();
    _provider.then((p) {
      if (!mounted) return;
      _orientation.attach(p);
    });
    _lifecycle = AppLifecycleListener(
      // 実機確認用: 開閉で inactive / hidden / paused のどれが出るかを記録する。
      onStateChange: (s) => DiagnosticsLog.instance.add('life', s.name),
      onPause: _sensors.onPause,
      onResume: _sensors.onResume,
    );
  }

  /// 外側⇔内側の画面切り替えはサイズの変化として現れるので記録する。
  @override
  void didChangeMetrics() => _logSize();

  String? _lastSize;

  void _logSize() {
    final s = currentViewSize();
    if (s == null) return;
    final label =
        '${s.width.toStringAsFixed(0)}x${s.height.toStringAsFixed(0)}';
    if (label == _lastSize) return; // 同じサイズの通知は記録しない
    _lastSize = label;
    DiagnosticsLog.instance.add('size', label);
  }

  @override
  void dispose() {
    _orientation.dispose();
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
