import 'package:objective_c/objective_c.dart' as objc;
import 'package:pub_semver/pub_semver.dart';

import 'bindings.dart';

/// ヒンジの状態。
enum HingeStatus() {
  unknown,
  closed,
  partiallyOpen,
  fullyOpen,
}

/// 1 回分の更新。`angleRadians` は 0 = 閉じた、π = 全開。
typedef HingeUpdate = ({double angleRadians, HingeStatus status});

/// Flutter の画面に UIHingeInteraction を付けて、ヒンジの更新を受け取る。
///
/// UIKit の呼び出しはメインスレッドで行う必要がある。Flutter のメイン isolate は
/// iOS のメインスレッドで動くので、メイン isolate から呼ぶこと。
class DuoHingeObserver._(
  final UIView _view,
  final UIHingeInteraction _interaction,
) {
  /// 監視を始める。iOS 27.1 未満・画面が取れない場合は null。
  /// [onUpdate] には、ヒンジ情報が無い階層（Duo 以外）では null が届く。
  static DuoHingeObserver? start(void Function(HingeUpdate?) onUpdate) {
    if (!objc.checkOSVersion(iOS: Version(27, 1, 0))) return null;
    final view = _flutterView();
    if (view == null) return null;
    final handler =
        ObjCBlock_ffiVoid_UIHingeInteraction_UIHingeInteractionUpdate.listener((
          _,
          update,
        ) {
          final hinge = update.hinge;
          onUpdate(
            hinge == null
                ? null
                : (angleRadians: hinge.angle, status: _status(hinge.status)),
          );
        });
    final interaction = UIHingeInteraction.alloc().initWithUpdateHandler(
      handler,
    );
    view.addInteraction(interaction);
    return DuoHingeObserver._(view, interaction);
  }

  /// 監視をやめる。
  void stop() => _view.removeInteraction(_interaction);

  static UIView? _flutterView() {
    final scenes = UIApplication.getSharedApplication().connectedScenes;
    for (final scene in scenes.asDart()) {
      if (!UIWindowScene.isA(scene)) continue;
      final window = UIWindowScene.as(scene).keyWindow;
      final view = window?.rootViewController?.view;
      if (view != null) return view;
    }
    return null;
  }

  static HingeStatus _status(UIHingeStatus s) => switch (s) {
    UIHingeStatus.UIHingeStatusClosed => HingeStatus.closed,
    UIHingeStatus.UIHingeStatusPartiallyOpen => HingeStatus.partiallyOpen,
    UIHingeStatus.UIHingeStatusFullyOpen => HingeStatus.fullyOpen,
    UIHingeStatus.UIHingeStatusUnknown => HingeStatus.unknown,
  };
}
