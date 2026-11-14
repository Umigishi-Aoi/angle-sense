import '../services/angle_provider.dart';
import '../services/angle_provider_resolver.dart';

/// バックグラウンド中はセンサー（Android の加速度など）を止め、戻ったら再開する。
/// inactive では止めない（Duo の開閉で画面が切り替わる瞬間に出る可能性があるため）。
class SensorLifecycle(final Future<AngleProvider> _provider) {
  bool _stoppedInBackground = false;

  /// AppLifecycleListener の onPause から呼ぶ。
  Future<void> onPause() async {
    _stoppedInBackground = true;
    await guardSensorCall('stop', () async => await (await _provider).stop());
  }

  /// AppLifecycleListener の onResume から呼ぶ。止めていなければ何もしない。
  Future<void> onResume() async {
    if (!_stoppedInBackground) return;
    _stoppedInBackground = false;
    await guardSensorCall(
      'start',
      () async => await (await _provider).start(),
    );
  }
}
