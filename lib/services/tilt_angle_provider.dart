import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'angle_provider.dart';

/// 通常スマホ用: 加速度（重力）から端末の傾きを求める。
///
/// 0°=画面を上にして平置き、90°=立てた、180°=画面を下にして平置き。
/// sensors_plus の加速度は平置き（画面上）で z ≈ +9.8。
class TiltAngleProvider({
  /// ローパスフィルタ係数（0〜1、大きいほど追従が速い）。
  final double smoothing = 0.2,
}) implements AngleProvider {
  final _controller = StreamController<double>.broadcast();
  // stop() で cancel している（解析ツールは別メソッドでの cancel を追えない）。
  // ignore: cancel_subscriptions
  StreamSubscription<AccelerometerEvent>? _sub;
  double? _gx;
  double? _gy;
  double? _gz;
  double? _latest;

  @override
  String get id => 'tilt';

  @override
  String get label => '端末の傾き（加速度センサー）';

  @override
  double? get latestAngle => _latest;

  @override
  Stream<double> get angleStream => _controller.stream;

  @override
  final ValueListenable<bool> onOuterDisplay = ValueNotifier(false);

  @override
  Future<void> start() async {
    if (_sub != null) return;
    _sub = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
        .listen(
          _onEvent,
          onError: (Object _) {
            // センサーが無い端末では値が来ないだけにする。
          },
          cancelOnError: false,
        );
  }

  void _onEvent(AccelerometerEvent e) {
    final a = smoothing;
    _gx = _gx == null ? e.x : _gx! + a * (e.x - _gx!);
    _gy = _gy == null ? e.y : _gy! + a * (e.y - _gy!);
    _gz = _gz == null ? e.z : _gz! + a * (e.z - _gz!);
    final angle = tiltDegrees(_gx!, _gy!, _gz!);
    if (angle == null) return;
    _latest = angle;
    _controller.add(angle);
  }

  @override
  Future<void> stop() async {
    // 先に null にしてから cancel を待つ（待っている間に start() が来ても再購読できるように）。
    final sub = _sub;
    _sub = null;
    await sub?.cancel();
  }
}

/// 重力ベクトルから「画面の法線と真上のなす角」を 0〜180° で返す。
double? tiltDegrees(double x, double y, double z) {
  final norm = math.sqrt(x * x + y * y + z * z);
  if (norm < 1e-6) return null;
  final cos = (z / norm).clamp(-1.0, 1.0);
  return clampAngle(math.acos(cos) * 180 / math.pi);
}
