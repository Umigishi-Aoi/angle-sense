import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/services/diagnostics_log.dart';
import 'package:hinge_angle_game/services/hinge_angle_provider.dart';

void main() {
  test('ヒンジの角度を平ら=0° に変換し、取れなくなったら古い角度を消す', () {
    final provider = HingeAngleProvider();
    DiagnosticsLog.instance.clear();
    provider.onUpdate((angleRadians: math.pi / 2, status: .partiallyOpen));
    expect(provider.latestAngle, closeTo(90, 1e-9));
    // ゲームの角度は平ら=0°（ヒンジの生の角度を反転）
    provider.onUpdate((
      angleRadians: 170 * math.pi / 180,
      status: .partiallyOpen,
    ));
    expect(provider.latestAngle, closeTo(10, 1e-9));
    expect(provider.onOuterDisplay.value, isFalse);
    // closed = 外側の画面に移った
    provider.onUpdate((angleRadians: 80 * math.pi / 180, status: .closed));
    expect(provider.latestAngle, closeTo(100, 1e-9));
    expect(provider.onOuterDisplay.value, isTrue);
    provider.onUpdate(null);
    expect(provider.latestAngle, isNull);
    // 診断ログに生の値が残る
    final log = DiagnosticsLog.instance.export();
    expect(
      log,
      contains('status=partiallyOpen available=true rad=1.5708 deg=90.0'),
    );
    expect(log, contains('status=unavailable'));
  });
}
