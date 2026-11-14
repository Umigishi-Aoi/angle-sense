import Flutter
import UIKit

/// iPhone Duo のヒンジ角度を Dart に送る自前ブリッジ。
///
/// チャネル: `com.example.hinge_angle_game/hinge`
/// - Dart → Swift
///   - `start`: UIHingeInteraction を Flutter のビューに付けて監視を始める。
///              戻り値なし。最初の状態は `onHinge` で届く。
///   - `stop`:  監視をやめる。
/// - Swift → Dart
///   - `onHinge`: `{"available": Bool, "angleDeg": Double?, "angleRad": Double?, "status": String}`
///     - available=false … ヒンジ情報なし（iOS 27.1 未満 / Duo 以外 / 階層外）
///
/// API は iOS 27.2 SDK の UIKit/UIHinge.h・UIHingeInteraction.h で確認済み。
final class HingeAnglePlugin: NSObject, FlutterPlugin {
  static let channelName = "com.example.hinge_angle_game/hinge"

  private let channel: FlutterMethodChannel
  private weak var registrar: FlutterPluginRegistrar?
  /// UIHingeInteraction は iOS 27.1+ のため型を消して保持する。
  private var interaction: UIInteraction?
  private weak var attachedView: UIView?

  init(channel: FlutterMethodChannel, registrar: FlutterPluginRegistrar) {
    self.channel = channel
    self.registrar = registrar
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    let instance = HingeAnglePlugin(channel: channel, registrar: registrar)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "start":
      DispatchQueue.main.async {
        self.startObserving()
        result(nil)
      }
    case "stop":
      DispatchQueue.main.async {
        self.stopObserving()
        result(nil)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Hinge observation

  private func startObserving() {
    guard interaction == nil else { return }

    guard #available(iOS 27.1, *) else {
      sendUnavailable()
      return
    }
    guard let view = registrar?.viewController?.view else {
      sendUnavailable()
      return
    }

    let hingeInteraction = UIHingeInteraction { [weak self] _, update in
      guard let self else { return }
      // hinge が nil = この階層ではヒンジ情報が提供されない（Duo 以外の端末など）。
      guard let hinge = update.hinge else {
        self.sendUnavailable()
        return
      }
      self.send(
        available: true,
        angleDeg: Self.toFlutterDegrees(radians: hinge.angle),
        status: Self.statusName(hinge.status),
        angleRad: Double(hinge.angle)
      )
    }
    view.addInteraction(hingeInteraction)
    interaction = hingeInteraction
    attachedView = view
  }

  private func stopObserving() {
    if let interaction, let attachedView {
      attachedView.removeInteraction(interaction)
    }
    interaction = nil
    attachedView = nil
  }

  /// ラジアン → ゲームで使う度数（0=閉じた / 180=全開）。
  ///
  /// 実機確認済み（2026-11-06・iPhone Duo / TestFlight）: 閉じる=0.0000 rad、全開=3.1416 rad（π）。補正不要。
  /// - 約5°未満は 0、約174°超は π に丸めて届く（出題は 15〜165° なので影響なし）
  /// - 更新は動かしている間 25〜40 回/秒、止めると止まる
  /// - status（closed/partiallyOpen）は画面の切り替え用で角度とは別。closed でも角度は 90° 前後まで届く
  private static func toFlutterDegrees(radians: CGFloat) -> Double {
    let deg = Double(radians) * 180.0 / Double.pi
    return min(max(deg, 0), 180)
  }

  @available(iOS 27.1, *)
  private static func statusName(_ status: UIHinge.Status) -> String {
    switch status {
    case .closed: return "closed"
    case .partiallyOpen: return "partiallyOpen"
    case .fullyOpen: return "fullyOpen"
    case .unknown: return "unknown"
    @unknown default: return "unknown"
    }
  }

  private func sendUnavailable() {
    send(available: false, angleDeg: nil, status: "unavailable")
  }

  /// angleRad は換算前の生の値（実機確認用。診断画面に出す）。
  private func send(available: Bool, angleDeg: Double?, status: String, angleRad: Double? = nil) {
    var args: [String: Any] = ["available": available, "status": status]
    if let angleDeg { args["angleDeg"] = angleDeg }
    if let angleRad { args["angleRad"] = angleRad }
    // 実機確認用: 向きのロックが OS に受け入れられているか（UIWindowSceneGeometry.isInterfaceOrientationLocked, iOS 26+）。
    if #available(iOS 26.0, *), let scene = attachedView?.window?.windowScene {
      args["orientationLocked"] = scene.effectiveGeometry.isInterfaceOrientationLocked
    }
    channel.invokeMethod("onHinge", arguments: args)
  }
}
