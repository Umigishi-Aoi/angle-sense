import 'dart:async';
import 'dart:math' as math;

import 'package:device_angle/device_angle.dart';
import 'package:flutter/foundation.dart';

import 'angle_provider.dart';
import 'diagnostics_log.dart';

/// ヒンジの監視を始める関数。返り値は監視を止める関数（始められなければ null）。
/// テストでは偽物に差し替える（本物の [DuoHingeObserver] は iOS の FFI でしか動かないため）。
typedef HingeObserverStarter = VoidCallback? Function(
  void Function(HingeUpdate?) onUpdate,
);

/// 本物のヒンジ監視（UIHingeInteraction）を始める。
VoidCallback? startDuoHingeObserver(void Function(HingeUpdate?) onUpdate) =>
    DuoHingeObserver.start(onUpdate)?.stop;

/// iPhone Duo のヒンジ角度（UIKit の UIHingeInteraction を FFIgen で直接読む）。
class HingeAngleProvider({
  /// ヒンジの監視の始め方（テスト用に差し替えられる）。
  final HingeObserverStarter _startObserver = startDuoHingeObserver,
}) implements AngleProvider {
  final _controller = StreamController<double>.broadcast();
  VoidCallback? _stopObserver;
  double? _latest;
  final _first = Completer<bool>();

  @override
  String get id => 'hinge';

  @override
  String get label => 'ヒンジ（iPhone Duo）';

  @override
  double? get latestAngle => _latest;

  @override
  Stream<double> get angleStream => _controller.stream;

  @override
  final ValueNotifier<bool> onOuterDisplay = ValueNotifier(false);

  @override
  Future<void> start() async {
    if (_stopObserver != null) return;
    _stopObserver = _startObserver(onUpdate);
    if (_stopObserver == null) _complete(false);
  }

  /// ヒンジの更新を 1 回分取り込む。null = この端末・階層ではヒンジが取れない。
  @visibleForTesting
  void onUpdate(HingeUpdate? u) {
    // ヒンジは 0=閉じた / π=全開。
    final deg = u == null ? null : u.angleRadians * 180 / math.pi;
    DiagnosticsLog.instance.hinge({
      'available': u != null,
      'status': u?.status.name ?? 'unavailable',
      'angleRad': ?u?.angleRadians,
      'angleDeg': ?deg,
    });
    // closed = 外側の画面に移った（ゲームは内側の画面で遊ぶ）。
    onOuterDisplay.value = u?.status == HingeStatus.closed;
    if (deg == null) {
      // ヒンジが取れなくなったら古い角度で判定しないよう無効にする。
      _latest = null;
      _complete(false);
      return;
    }
    // ゲームでは平ら=0° にするので反転する。
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
    _stopObserver?.call();
    _stopObserver = null;
  }
}
