import 'dart:async';
import 'dart:math' as math;

import 'package:device_angle/device_angle.dart';
import 'package:flutter/foundation.dart';

import 'angle_provider.dart';
import 'diagnostics_log.dart';

/// iPhone Duo のヒンジ角度を FFIgen で直接読む（Swift のチャネルを通さない）。
class FfiHingeAngleProvider() implements AngleProvider {
  final _controller = StreamController<double>.broadcast();
  DuoHingeObserver? _observer;
  double? _latest;
  final _first = Completer<bool>();

  @override
  String get id => 'hinge';

  @override
  String get label => 'ヒンジ（iPhone Duo・FFIgen）';

  @override
  double? get latestAngle => _latest;

  @override
  Stream<double> get angleStream => _controller.stream;

  @override
  final ValueNotifier<bool> onOuterDisplay = ValueNotifier(false);

  @override
  Future<void> start() async {
    if (_observer != null) return;
    DiagnosticsLog.instance.add(
      'ffi',
      'start mainThread=${DuoHingeObserver.isMainThread}',
    );
    _observer = DuoHingeObserver.start(_onUpdate);
    if (_observer == null) _complete(false);
  }

  void _onUpdate(HingeUpdate? u) {
    DiagnosticsLog.instance.hinge({
      'available': u != null,
      'status': u?.status.name ?? 'unavailable',
      'angleRad': ?u?.angleRadians,
    });
    onOuterDisplay.value = u?.status == HingeStatus.closed;
    if (u == null) {
      _latest = null;
      _complete(false);
      return;
    }
    // ヒンジは 0=閉じた / π=全開。ゲームでは平ら=0° にするので反転する。
    final deg = u.angleRadians * 180 / math.pi;
    _latest = clampAngle(180 - clampAngle(deg));
    _controller.add(_latest!);
    _complete(true);
  }

  void _complete(bool v) {
    if (!_first.isCompleted) _first.complete(v);
  }

  /// 最初の更新を待つ（UIHingeInteraction は付けた時点の状態で必ず呼ぶ）。
  Future<bool> waitForAvailability({
    Duration timeout = const Duration(seconds: 1),
  }) => _first.future.timeout(timeout, onTimeout: () => false);

  @override
  Future<void> stop() async {
    _observer?.stop();
    _observer = null;
  }
}
