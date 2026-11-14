// FFIgen が生成した Objective-C（ブロックの橋渡し）を、iOS 向けにだけビルドする。
import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    // UIKit は iOS にしか無い。macOS（flutter test のホスト）では何も作らない。
    if (input.config.code.targetOS != OS.iOS) return;
    await CBuilder.library(
      name: 'device_angle',
      assetName: 'src/bindings.dart',
      sources: ['src/bindings.m'],
      language: Language.objectiveC,
      flags: ['-fobjc-arc'],
      // CoreMotion はクラスを実行時に引くので、ここでリンクして確実に読み込ませる。
      frameworks: ['Foundation', 'UIKit', 'CoreMotion'],
    ).run(
      input: input,
      output: output,
      logger: Logger('')..onRecord.listen((r) => print(r.message)),
    );
  });
}
