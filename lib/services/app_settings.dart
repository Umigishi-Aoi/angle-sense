import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// アプリ内の設定（効果音・振動・暗転中のカウント音）。端末に保存する。
///
/// 振動は iPhone 側の「触覚」設定によってはサイレント中に鳴らないため、
/// 音と振動はそれぞれ独立にオン/オフできるようにしている。
class AppSettings({final SharedPreferencesAsync? _prefs})
    extends ChangeNotifier {
  static const _kSound = 'settings_sound';
  static const _kHaptics = 'settings_haptics';
  static const _kBlindTick = 'settings_blind_tick';

  bool _sound = true;
  bool _haptics = true;
  bool _blindTick = true;

  bool get sound => _sound;
  bool get haptics => _haptics;

  /// 暗転中に 1 秒ごとの小さな音を鳴らすか（リズムで時間が読めるので好みで切る）。
  bool get blindTick => _blindTick;

  Future<void> load() async {
    final p = _prefs;
    if (p == null) return;
    try {
      _sound = await p.getBool(_kSound) ?? true;
      _haptics = await p.getBool(_kHaptics) ?? true;
      _blindTick = await p.getBool(_kBlindTick) ?? true;
      notifyListeners();
    } on Exception catch (e) {
      debugPrint('settings load failed: $e');
    }
  }

  set sound(bool v) => _set(_kSound, v, () => _sound = v);
  set haptics(bool v) => _set(_kHaptics, v, () => _haptics = v);
  set blindTick(bool v) => _set(_kBlindTick, v, () => _blindTick = v);

  void _set(String key, bool v, VoidCallback apply) {
    apply();
    notifyListeners();
    _prefs
        ?.setBool(key, v)
        .catchError((Object e) => debugPrint('settings save failed: $e'));
  }
}
