import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/services/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart';

/// 読み書きがすべて失敗する端末保存。
class _FailingPrefs() extends SharedPreferencesAsync {
  @override
  Future<bool?> getBool(String key) async => throw Exception('read failed');

  @override
  Future<void> setBool(String key, bool value) async =>
      throw Exception('write failed');
}

void main() {
  setUp(useInMemoryPrefs);

  group('AppSettings', () {
    test('保存が無ければすべてオン', () async {
      final settings = AppSettings(prefs: SharedPreferencesAsync());
      await settings.load();
      expect(settings.sound, isTrue);
      expect(settings.haptics, isTrue);
      expect(settings.blindTick, isTrue);
    });

    test('変えた設定は次の起動（新しいインスタンスの load）で戻る', () async {
      AppSettings(prefs: SharedPreferencesAsync())
        ..sound = false
        ..haptics = false
        ..blindTick = false;
      // 保存は待たずに投げているので、書き込みが終わるまで 1 回待つ。
      await Future<void>.delayed(Duration.zero);
      final reloaded = AppSettings(prefs: SharedPreferencesAsync());
      await reloaded.load();
      expect(reloaded.sound, isFalse);
      expect(reloaded.haptics, isFalse);
      expect(reloaded.blindTick, isFalse);
    });

    test('設定ごとに別々に保存する', () async {
      AppSettings(prefs: SharedPreferencesAsync()).haptics = false;
      await Future<void>.delayed(Duration.zero);
      final reloaded = AppSettings(prefs: SharedPreferencesAsync());
      await reloaded.load();
      expect(reloaded.sound, isTrue);
      expect(reloaded.haptics, isFalse);
      expect(reloaded.blindTick, isTrue);
    });

    test('値を変えるとすぐ反映して通知する', () {
      final settings = AppSettings();
      var notified = 0;
      settings
        ..addListener(() => notified++)
        ..sound = false;
      expect(settings.sound, isFalse);
      expect(notified, 1);
    });

    test('load は読み終えたら通知する', () async {
      final settings = AppSettings(prefs: SharedPreferencesAsync());
      var notified = 0;
      settings.addListener(() => notified++);
      await settings.load();
      expect(notified, 1);
    });

    test('端末保存が無ければ load は何もしない（既定のまま・通知なし）', () async {
      final settings = AppSettings();
      var notified = 0;
      settings.addListener(() => notified++);
      await settings.load();
      expect(settings.sound, isTrue);
      expect(notified, 0);
    });

    test('読み込みに失敗したら既定のままにする', () async {
      final settings = AppSettings(prefs: _FailingPrefs());
      await settings.load();
      expect(settings.sound, isTrue);
      expect(settings.haptics, isTrue);
      expect(settings.blindTick, isTrue);
    });

    test('保存に失敗しても画面上の値は変わり、例外を出さない', () async {
      final settings = AppSettings(prefs: _FailingPrefs())..sound = false;
      await Future<void>.delayed(Duration.zero);
      expect(settings.sound, isFalse);
    });
  });
}
