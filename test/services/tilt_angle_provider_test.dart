import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/services/tilt_angle_provider.dart';

import '../helpers/fakes.dart';

/// 重力ベクトル (0, y, z) と真上のなす角（度）。期待値を実装と別の式で出す。
double _degreesFromUp(double y, double z) => math.atan2(y, z) * 180 / math.pi;

void main() {
  group('tiltDegrees', () {
    test('平置き=0 / 立てた=90 / 伏せ=180', () {
      expect(tiltDegrees(0, 0, 9.8), closeTo(0, 1e-9));
      expect(tiltDegrees(0, 9.8, 0), closeTo(90, 1e-9));
      expect(tiltDegrees(0, 0, -9.8), closeTo(180, 1e-9));
      expect(tiltDegrees(0, 0, 0), isNull);
    });
  });

  group('TiltAngleProvider.onSample', () {
    test('最初の 1 回はそのままの値で角度を出す', () {
      final provider = TiltAngleProvider(startSensor: (_) => null)
        ..onSample(0, 1, 0);
      expect(provider.latestAngle, closeTo(90, 1e-9));
    });

    test('2 回目からは smoothing の割合だけ新しい値に寄せる', () {
      final provider = TiltAngleProvider(startSensor: (_) => null)
        ..onSample(0, 0, 1)
        ..onSample(0, 1, 0);
      // g = (0, 0.2, 0.8)
      expect(provider.latestAngle, closeTo(_degreesFromUp(0.2, 0.8), 1e-9));
    });

    test('smoothing=1 なら最新の値だけで決まる', () {
      final provider = TiltAngleProvider(smoothing: 1, startSensor: (_) => null)
        ..onSample(0, 0, 1)
        ..onSample(0, 1, 0);
      expect(provider.latestAngle, closeTo(90, 1e-9));
    });

    test('重力が 0 のときは角度を出さず、前の値を残す', () {
      final provider = TiltAngleProvider(smoothing: 1, startSensor: (_) => null)
        ..onSample(0, 0, 1)
        ..onSample(0, 0, 0);
      expect(provider.latestAngle, closeTo(0, 1e-9));
    });

    test('角度を angleStream に流す', () async {
      final provider = TiltAngleProvider(startSensor: (_) => null);
      final next = provider.angleStream.first;
      provider.onSample(0, 1, 0);
      expect(await next, closeTo(90, 1e-9));
    });
  });

  group('TiltAngleProvider（センサーの読み取り）', () {
    testWidgets('画面を上にした平置き（Core Motion で z=-1g）は 0°', (tester) async {
      final sensor = FakeTiltSensor()..next = (x: 0, y: 0, z: -1);
      final provider = TiltAngleProvider(startSensor: sensor.start);
      await provider.start();
      await tester.pump(const Duration(milliseconds: 20));
      expect(provider.latestAngle, closeTo(0, 1e-9));
      await provider.stop();
    });

    testWidgets('縦に立てた（Core Motion で y=-1g）は 90°', (tester) async {
      final sensor = FakeTiltSensor()..next = (x: 0, y: -1, z: 0);
      final provider = TiltAngleProvider(startSensor: sensor.start);
      await provider.start();
      await tester.pump(const Duration(milliseconds: 20));
      expect(provider.latestAngle, closeTo(90, 1e-9));
      await provider.stop();
    });

    testWidgets('画面を下にした平置き（Core Motion で z=+1g）は 180°', (tester) async {
      final sensor = FakeTiltSensor()..next = (x: 0, y: 0, z: 1);
      final provider = TiltAngleProvider(startSensor: sensor.start);
      await provider.start();
      await tester.pump(const Duration(milliseconds: 20));
      expect(provider.latestAngle, closeTo(180, 1e-9));
      await provider.stop();
    });

    testWidgets('interval ごとにセンサーを読み、値が無い間は角度を出さない', (tester) async {
      final sensor = FakeTiltSensor();
      final provider = TiltAngleProvider(
        interval: const Duration(milliseconds: 50),
        startSensor: sensor.start,
      );
      await provider.start();
      expect(sensor.interval, const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(provider.latestAngle, isNull);
      sensor.next = (x: 0, y: -1, z: 0);
      await tester.pump(const Duration(milliseconds: 49));
      expect(provider.latestAngle, isNull);
      await tester.pump(const Duration(milliseconds: 1));
      expect(provider.latestAngle, closeTo(90, 1e-9));
      await provider.stop();
    });

    test('2 回 start してもセンサーは 1 回しか始めない', () async {
      final sensor = FakeTiltSensor();
      final provider = TiltAngleProvider(startSensor: sensor.start);
      await provider.start();
      await provider.start();
      expect(sensor.startCount, 1);
      await provider.stop();
    });

    testWidgets('stop でセンサーを止め、それ以降は読まない', (tester) async {
      final sensor = FakeTiltSensor()..next = (x: 0, y: 0, z: -1);
      final provider = TiltAngleProvider(
        smoothing: 1,
        startSensor: sensor.start,
      );
      await provider.start();
      await tester.pump(const Duration(milliseconds: 20));
      await provider.stop();
      expect(sensor.stopCount, 1);
      sensor.next = (x: 0, y: -1, z: 0);
      await tester.pump(const Duration(milliseconds: 100));
      expect(provider.latestAngle, closeTo(0, 1e-9));
    });

    testWidgets('stop のあと start するとセンサーを始め直して読む', (tester) async {
      final sensor = FakeTiltSensor()..next = (x: 0, y: 0, z: -1);
      final provider = TiltAngleProvider(
        smoothing: 1,
        startSensor: sensor.start,
      );
      await provider.start();
      await provider.stop();
      sensor.next = (x: 0, y: -1, z: 0);
      await provider.start();
      expect(sensor.startCount, 2);
      await tester.pump(const Duration(milliseconds: 20));
      expect(provider.latestAngle, closeTo(90, 1e-9));
      await provider.stop();
    });

    test('センサーが無い端末では始められず、次の start で再び試す', () async {
      var calls = 0;
      final provider = TiltAngleProvider(
        startSensor: (_) {
          calls++;
          return null;
        },
      );
      await provider.start();
      await provider.start();
      expect(calls, 2);
      expect(provider.latestAngle, isNull);
      await provider.stop();
    });
  });
}
