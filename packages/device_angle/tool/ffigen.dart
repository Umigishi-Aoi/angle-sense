// UIKit（ヒンジ）と Core Motion（傾き）の Dart バインディングを生成する。
// 実行: dart run tool/ffigen.dart（packages/device_angle で）
import 'package:ffigen/ffigen.dart';

/// 生成するクラスと、使うメソッド（null = すべて）。
const _wanted = <String, Set<String>?>{
  // ヒンジ
  'UIHingeInteraction': null,
  'UIHingeInteractionUpdate': null,
  'UIHinge': null,
  'UIView': {'addInteraction:', 'removeInteraction:'},
  'UIApplication': {'sharedApplication', 'connectedScenes'},
  'UIWindowScene': {'keyWindow'},
  'UIWindow': {'rootViewController'},
  'UIViewController': {'view'},
  // 傾き
  'CMMotionManager': {
    'alloc',
    'init',
    'accelerometerUpdateInterval',
    'setAccelerometerUpdateInterval:',
    'isAccelerometerAvailable',
    'accelerometerData',
    'startAccelerometerUpdates',
    'stopAccelerometerUpdates',
  },
  'CMAccelerometerData': {'acceleration'},
};

Uri _header(String framework, String file) => iosSdkUri.resolve(
  'System/Library/Frameworks/$framework.framework/Headers/$file',
);

Future<void> main() async {
  final generator = FfiGenerator(
    input: Input(
      entryPoints: [
        _header('UIKit', 'UIKit.h'),
        _header('CoreMotion', 'CoreMotion.h'),
      ],
      compilerOptions: [
        '-isysroot',
        iosSdkPath,
        '-target',
        'arm64-apple-ios27.1',
      ],
    ),
    objectiveC: const ObjectiveC(),
    output: Output(
      dart: DartOutput(path: Uri.file('lib/src/bindings.dart')),
      objectiveCFile: Uri.file('src/bindings.m'),
      preamble: '// ignore_for_file: type=lint',
    ),
    visitors: [
      Visitor(
        objCInterface: (node) =>
            node.isIncluded = _wanted.containsKey(node.name),
        objCProtocol: (node) => node.isIncluded = false,
        objCCategory: (node) => node.isIncluded = false,
        enumClass: (node) {
          node.isIncluded = node.name == 'UIHingeStatus';
          // UIHingeStatus は NS_ENUM(NSInteger)＝64 ビット固定なので安全。
          if (node.isIncluded) node.silenceWarning = true;
        },
        struct: (node) => node.isIncluded = node.name == 'CMAcceleration',
        func: (node) => node.isIncluded = false,
        global: (node) => node.isIncluded = false,
        macroConstant: (node) => node.isIncluded = false,
        unnamedEnumConstant: (node) => node.isIncluded = false,
        objCMethod: (node) {
          final methods = _wanted[node.parent.name];
          if (methods != null) {
            node.isIncluded = methods.contains(node.selector);
          }
        },
      ),
    ],
  );
  await generator.generate();
}
