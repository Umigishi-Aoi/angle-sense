import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/services/demo_angle_provider.dart';

// DEMO_ANGLE は --dart-define でしか変えられないので、テストでは常に未指定（無効）の状態を試す。
// 読み取るファイルはアプリと同じ一時フォルダの demo_angle.txt（テストでは OS の一時フォルダ）。

void main() {
  final file = File('${Directory.systemTemp.path}/demo_angle.txt');

  setUp(() {
    if (file.existsSync()) file.deleteSync();
  });
  tearDown(() {
    if (file.existsSync()) file.deleteSync();
  });

  test('DEMO_ANGLE を付けないビルドでは無効', () {
    expect(DemoAngleProvider.enabled, isFalse);
  });

  test('外側の画面には移らない', () {
    expect(DemoAngleProvider().onOuterDisplay.value, isFalse);
  });

  testWidgets('ファイルの数値（度）を開始時と 200ms ごとに読む', (tester) async {
    file.writeAsStringSync('45\n');
    final provider = DemoAngleProvider();
    await provider.start();
    expect(provider.latestAngle, 45);
    file.writeAsStringSync('30');
    await tester.pump(const Duration(milliseconds: 199));
    expect(provider.latestAngle, 45);
    await tester.pump(const Duration(milliseconds: 1));
    expect(provider.latestAngle, 30);
    await provider.stop();
  });

  testWidgets('0〜180° の外の値は丸める', (tester) async {
    file.writeAsStringSync('200');
    final provider = DemoAngleProvider();
    await provider.start();
    expect(provider.latestAngle, 180);
    await provider.stop();
  });

  testWidgets('数値でない内容は無視して前の値を残す', (tester) async {
    file.writeAsStringSync('60');
    final provider = DemoAngleProvider();
    await provider.start();
    file.writeAsStringSync('abc');
    await tester.pump(const Duration(milliseconds: 200));
    expect(provider.latestAngle, 60);
    await provider.stop();
  });

  testWidgets('ファイルがまだ無ければ値なし', (tester) async {
    final provider = DemoAngleProvider();
    await provider.start();
    await tester.pump(const Duration(milliseconds: 200));
    expect(provider.latestAngle, isNull);
    await provider.stop();
  });

  testWidgets('stop のあとはファイルが変わっても読まない', (tester) async {
    file.writeAsStringSync('10');
    final provider = DemoAngleProvider();
    await provider.start();
    await provider.stop();
    file.writeAsStringSync('20');
    await tester.pump(const Duration(seconds: 1));
    expect(provider.latestAngle, 10);
  });
}
