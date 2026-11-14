import 'bindings.dart';

/// 端末の傾きを Core Motion の加速度センサーから読む。
///
/// 値は Dart から一定間隔で読み取る（CMMotionManager の「pull」方式）。
/// コールバックを使わないので、スレッドをまたぐ心配がない。
class TiltSensor {
  TiltSensor._(this._manager);

  final CMMotionManager _manager;

  /// 加速度センサーが無い端末（シミュレータの一部など）は null。
  static TiltSensor? start({
    Duration interval = const Duration(milliseconds: 20),
  }) {
    final manager = CMMotionManager.alloc().init();
    if (!manager.isAccelerometerAvailable) return null;
    manager
      ..accelerometerUpdateInterval = interval.inMicroseconds / 1e6
      ..startAccelerometerUpdates();
    return TiltSensor._(manager);
  }

  /// 最新の加速度（単位 g）。まだ値が無ければ null。
  /// Core Motion は画面を上にして平置きで z ≈ -1。
  ({double x, double y, double z})? read() {
    final data = _manager.accelerometerData;
    if (data == null) return null;
    final a = data.acceleration;
    return (x: a.x, y: a.y, z: a.z);
  }

  void stop() => _manager.stopAccelerometerUpdates();
}
