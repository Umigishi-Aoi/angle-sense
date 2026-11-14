import Flutter
import StoreKit
import UIKit

/// `AppStore.requestReview(in:)`（StoreKit 2・Swift 専用）を Dart から呼べるようにする。
public final class StoreReviewPlugin: NSObject, FlutterPlugin, StoreReviewHostApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    StoreReviewHostApiSetup.setUp(
      binaryMessenger: registrar.messenger(),
      api: StoreReviewPlugin()
    )
  }

  func requestReview() throws {
    // Pigeon のハンドラはメインスレッドで呼ばれる。
    MainActor.assumeIsolated {
      guard #available(iOS 16.0, *), let scene = Self.activeScene() else { return }
      AppStore.requestReview(in: scene)
    }
  }

  @MainActor
  private static func activeScene() -> UIWindowScene? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
  }
}
