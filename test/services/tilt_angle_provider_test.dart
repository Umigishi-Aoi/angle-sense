import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/services/tilt_angle_provider.dart';

void main() {
  group('tiltDegrees', () {
    test('平置き=0 / 立てた=90 / 伏せ=180', () {
      expect(tiltDegrees(0, 0, 9.8), closeTo(0, 1e-9));
      expect(tiltDegrees(0, 9.8, 0), closeTo(90, 1e-9));
      expect(tiltDegrees(0, 0, -9.8), closeTo(180, 1e-9));
      expect(tiltDegrees(0, 0, 0), isNull);
    });
  });
}
