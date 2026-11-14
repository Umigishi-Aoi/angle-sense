import 'dart:async';
import 'dart:math' as math;

import 'package:device_angle/device_angle.dart';
import 'package:flutter/foundation.dart';

import 'angle_provider.dart';

/// 加速度センサーの読み取り口（read は単位 g・Core Motion の向き、まだ値が無ければ null）。
typedef TiltSensorHandle = ({
  ({double x, double y, double z})? Function() read,
  void Function() stop,
});

/// 加速度センサーを始める関数。センサーが無い端末では null。
/// テストでは偽物に差し替える（本物の [TiltSensor] は iOS の FFI でしか動かないため）。
typedef TiltSensorStarter = TiltSensorHandle? Function(Duration interval);

/// 本物の加速度センサー（Core Motion）を始める。
TiltSensorHandle? startTiltSensor(Duration interval) {
  final sensor = TiltSensor.start(interval: interval);
  if (sensor == null) return null;
  return (read: sensor.read, stop: sensor.stop);
}

/// 通常スマホ用: 加速度（重力）から端末の傾きを求める。
///
/// 0°=画面を上にして平置き、90°=立てた、180°=画面を下にして平置き。
/// Core Motion の加速度は平置き（画面上）で z ≈ -1 g なので、符号を反転して使う。
class TiltAngleProvider({
  /// ローパスフィルタ係数（0〜1、大きいほど追従が速い）。
  final double smoothing = 0.2,

  /// センサーを読む間隔（20ms = 50 回/秒）。
  final Duration interval = const Duration(milliseconds: 20),

  /// 加速度センサーの始め方（テスト用に差し替えられる）。
  final TiltSensorStarter _startSensor = startTiltSensor,
}) implements AngleProvider {
  final _controller = StreamController<double>.broadcast();
  TiltSensorHandle? _sensor;
  Timer? _timer;
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
    if (_sensor != null) return;
    // センサーが無い端末では値が来ないだけにする。
    final sensor = _startSensor(interval);
    if (sensor == null) return;
    _sensor = sensor;
    _timer = Timer.periodic(interval, (_) => _read());
  }

  void _read() {
    final a = _sensor?.read();
    if (a == null) return;
    onSample(-a.x, -a.y, -a.z);
  }

  /// 1 回分の重力ベクトル（画面上で平置き = z が正）を取り込む。
  @visibleForTesting
  void onSample(double x, double y, double z) {
    final a = smoothing;
    _gx = _gx == null ? x : _gx! + a * (x - _gx!);
    _gy = _gy == null ? y : _gy! + a * (y - _gy!);
    _gz = _gz == null ? z : _gz! + a * (z - _gz!);
    final angle = tiltDegrees(_gx!, _gy!, _gz!);
    if (angle == null) return;
    _latest = angle;
    _controller.add(angle);
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _sensor?.stop();
    _sensor = null;
  }
}

/// 重力ベクトルから「画面の法線と真上のなす角」を 0〜180° で返す。
double? tiltDegrees(double x, double y, double z) {
  final norm = math.sqrt(x * x + y * y + z * z);
  if (norm < 1e-6) return null;
  final cos = (z / norm).clamp(-1.0, 1.0);
  return clampAngle(math.acos(cos) * 180 / math.pi);
}
