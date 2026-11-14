import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'angle_provider.dart';

/// スクリーンショット撮影用（シミュレータは角度を入力できないため）。
///
/// `--dart-define=DEMO_ANGLE=tilt`（普通の iPhone / iPad の見た目）か
/// `--dart-define=DEMO_ANGLE=hinge`（iPhone Duo の見た目）を付けてビルドしたときだけ使う。
/// アプリの一時フォルダの `demo_angle.txt` に書かれた数値（度）を 200ms ごとに読む。
/// Mac 側から `xcrun simctl get_app_container booted <bundle id> data` の
/// `tmp/demo_angle.txt` に書き込んで角度を変える。
/// 画面の出し分け（横向き固定・あそびかたの説明）を本物と同じにするため、id は tilt / hinge にする。
class DemoAngleProvider implements AngleProvider {
  static const _mode = String.fromEnvironment('DEMO_ANGLE');
  static const enabled = _mode == 'tilt' || _mode == 'hinge';

  final _controller = StreamController<double>.broadcast();
  Timer? _timer;
  double? _latest;

  File get _file => File('${Directory.systemTemp.path}/demo_angle.txt');

  @override
  String get id => _mode;

  @override
  String get label => _mode == 'hinge' ? 'ヒンジ（iPhone Duo）' : '端末の傾き（加速度センサー）';

  @override
  double? get latestAngle => _latest;

  @override
  Stream<double> get angleStream => _controller.stream;

  @override
  final ValueListenable<bool> onOuterDisplay = ValueNotifier(false);

  @override
  Future<void> start() async {
    if (_timer != null) return;
    debugPrint('demo angle file: ${_file.path}');
    _poll();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _poll());
  }

  void _poll() {
    try {
      final v = double.tryParse(_file.readAsStringSync().trim());
      if (v == null) return;
      _latest = clampAngle(v);
      _controller.add(_latest!);
    } on FileSystemException {
      // まだ書かれていない間は値なし（「計測なし」と同じ扱い）。
    }
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }
}
