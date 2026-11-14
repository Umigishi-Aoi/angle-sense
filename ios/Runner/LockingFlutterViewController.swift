import Flutter
import UIKit

/// 画面の向きの固定を iPhone Duo の内側の画面（大きさを変えられるシーン）でも効かせるための FlutterViewController。
///
/// Flutter 3.47.8 の SystemChrome.setPreferredOrientations は supportedInterfaceOrientations と
/// requestGeometryUpdate だけを使い、iOS 26 の `prefersInterfaceOrientationLocked` を立てない。
/// 大きさを変えられるシーンではこのロックが無いと端末を傾けたときに回ってしまう（実機 2026-11-06）。
/// UIViewController.h（iOS 27.2 SDK）: シーンが画面と同じ大きさ・中央・他に隠れていないときにロックが考慮される。
class LockingFlutterViewController: FlutterViewController {
  /// Flutter のエンジンは向きの設定を変えるたびにこれを呼ぶので、ここでロックも更新する。
  @available(iOS 16.0, *)
  override func setNeedsUpdateOfSupportedInterfaceOrientations() {
    super.setNeedsUpdateOfSupportedInterfaceOrientations()
    if #available(iOS 26.0, *) {
      setNeedsUpdateOfPrefersInterfaceOrientationLocked()
    }
  }

  /// Dart 側が横だけ・縦だけに絞っているときにロックする（何も絞っていないときはしない）。
  @available(iOS 26.0, *)
  override var prefersInterfaceOrientationLocked: Bool {
    let mask = supportedInterfaceOrientations
    if mask.isEmpty || mask == .all || mask == .allButUpsideDown { return false }
    return mask.isSubset(of: .landscape) || mask.isSubset(of: [.portrait, .portraitUpsideDown])
  }
}
