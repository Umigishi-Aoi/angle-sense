import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/services/angle_provider.dart';
import 'package:hinge_angle_game/services/angle_provider_resolver.dart';
import 'package:hinge_angle_game/services/hinge_angle_provider.dart';

import '../helpers/fakes.dart';

/// テストの間だけ iOS として動かす（ヒンジを試すのは iOS だけ）。
void _actAsIOS() {
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
}

void main() {
  group('resolveAngleProvider', () {
    late CountingAngleProvider tilt;
    late CountingAngleProvider demo;
    late FakeHingeObserver observer;

    setUp(() {
      tilt = CountingAngleProvider(id: 'tilt');
      demo = CountingAngleProvider(id: 'demo');
      observer = FakeHingeObserver();
    });

    Future<AngleProvider> resolve({bool demoMode = false}) =>
        resolveAngleProvider(
          demo: demoMode,
          createDemo: () => demo,
          createHinge: () => HingeAngleProvider(startObserver: observer.start),
          createTilt: () => tilt,
        );

    test('デモ版のビルドではデモの入力源を開始して返す', () async {
      _actAsIOS();
      final p = await resolve(demoMode: true);
      expect(p, same(demo));
      expect(demo.startCount, 1);
      expect(observer.startCount, 0);
      expect(tilt.startCount, 0);
    });

    test('iOS でヒンジが取れればヒンジを返す（傾きは始めない）', () async {
      _actAsIOS();
      final f = resolve();
      await Future<void>.delayed(Duration.zero);
      observer.onUpdate!((angleRadians: math.pi, status: .fullyOpen));
      final p = await f;
      expect(p, isA<HingeAngleProvider>());
      expect(observer.stopCount, 0);
      expect(tilt.startCount, 0);
    });

    test('iOS でもヒンジの無い端末なら、ヒンジを止めて傾きを返す', () async {
      _actAsIOS();
      final f = resolve();
      await Future<void>.delayed(Duration.zero);
      observer.onUpdate!(null);
      final p = await f;
      expect(p, same(tilt));
      expect(observer.stopCount, 1);
      expect(tilt.startCount, 1);
    });

    test('ヒンジの監視を始められなければ傾きを返す', () async {
      _actAsIOS();
      observer = FakeHingeObserver(available: false);
      final p = await resolve();
      expect(p, same(tilt));
      expect(tilt.startCount, 1);
    });

    testWidgets('ヒンジの最初の更新が 1 秒来なければ傾きを返す', (tester) async {
      _actAsIOS();
      AngleProvider? result;
      resolve().then((p) => result = p).ignore();
      await tester.pump(const Duration(milliseconds: 999));
      expect(result, isNull);
      await tester.pump(const Duration(milliseconds: 1));
      expect(result, same(tilt));
      expect(observer.stopCount, 1);
    });

    test('ヒンジの開始で例外が出ても傾きを返す', () async {
      _actAsIOS();
      final p = await resolveAngleProvider(
        createHinge: () => HingeAngleProvider(
          startObserver: (_) => throw Exception('boom'),
        ),
        createTilt: () => tilt,
      );
      expect(p, same(tilt));
      expect(tilt.startCount, 1);
    });

    test('iOS 以外ではヒンジを試さず傾きを返す', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final p = await resolve();
      expect(p, same(tilt));
      expect(observer.startCount, 0);
    });
  });

  group('resolveAngleProviderOrTilt', () {
    test('決まった入力源をそのまま返す', () async {
      final hinge = CountingAngleProvider(id: 'hinge');
      final tilt = CountingAngleProvider(id: 'tilt');
      final p = await resolveAngleProviderOrTilt(
        resolve: () async => hinge,
        createTilt: () => tilt,
      );
      expect(p, same(hinge));
      expect(tilt.startCount, 0);
    });

    test('決められなければ傾きを開始して返す', () async {
      final tilt = CountingAngleProvider(id: 'tilt');
      final p = await resolveAngleProviderOrTilt(
        resolve: () async => throw StateError('boom'),
        createTilt: () => tilt,
      );
      expect(p, same(tilt));
      expect(tilt.startCount, 1);
    });

    test('傾きの開始も失敗したら、開始していない傾きを返す（落ちない）', () async {
      final tilt = CountingAngleProvider(
        id: 'tilt',
        startError: Exception('no sensor'),
      );
      final p = await resolveAngleProviderOrTilt(
        resolve: () async => throw StateError('boom'),
        createTilt: () => tilt,
      );
      expect(p, same(tilt));
      expect(tilt.startCount, 1);
    });
  });

  group('guardSensorCall', () {
    test('失敗を握って記録だけする', () async {
      await expectLater(
        guardSensorCall('stop', () async => throw StateError('boom')),
        completes,
      );
    });

    test('成功したときは処理を 1 回だけ呼ぶ', () async {
      var calls = 0;
      await guardSensorCall('start', () async => calls++);
      expect(calls, 1);
    });
  });
}
