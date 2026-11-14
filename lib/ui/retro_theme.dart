import 'package:material_ui/material_ui.dart';

import '../game/scoring.dart';

/// レトロ・ドット絵風の配色（独自。既存ゲームの配色は使わない）。
///
/// ここの色は [Retro.theme] で ColorScheme と [RetroColors] に詰めるための元の値。
/// 画面やウィジェットからは直接使わず、`Theme.of(context).colorScheme` か
/// `context.retroColors` から読む（テーマを差し替えたときに追従させるため）。
abstract final class Retro() {
  static const bg = Color(0xFF14182E); // 夜空の紺
  static const panel = Color(0xFF232A4D);
  static const line = Color(0xFF4A5285); // 枠・目盛り
  static const text = Color(0xFFE8E8F0);
  static const dim = Color(0xFF8A90B8);
  static const yellow = Color(0xFFF7C948); // 目標・主ボタン
  static const cyan = Color(0xFF4FD1C5); // あなたの線
  static const green = Color(0xFF7BD86A);
  static const red = Color(0xFFEF5D5D);

  /// フォント（pubspec の fonts: に同梱。未同梱なら標準フォントで表示される）。
  static const fontFamily = 'DotGothic16';

  /// ドットの太さ（論理 px）。枠線などはこの整数倍にする。
  static const px = 3.0;

  static ThemeData theme() {
    const shape = RoundedRectangleBorder();
    const pad = EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    const scheme = ColorScheme.dark(
      primary: yellow,
      onPrimary: bg,
      // あなたの線・見出しの水色。tertiary は指定しない（未指定なら secondary と同じ色になる）。
      secondary: cyan,
      onSecondary: bg,
      error: red,
      surface: bg,
      onSurface: text,
      surfaceContainerHigh: panel,
      surfaceContainerLow: panel,
      outline: line,
      outlineVariant: line,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: fontFamily,
      splashFactory: NoSplash.splashFactory, // 波紋は出さない（ドット絵に合わない）
      highlightColor: Colors.transparent,
      extensions: const [RetroColors.retro],
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: text, displayColor: text),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 24,
          color: text,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              backgroundColor: yellow,
              foregroundColor: bg,
              disabledBackgroundColor: line,
              disabledForegroundColor: dim,
              padding: pad,
              textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 18),
            ).copyWith(
              // 押せないときは枠も暗くして「押せそう」に見せない。
              shape: WidgetStateProperty.resolveWith(
                (s) => RoundedRectangleBorder(
                  side: BorderSide(
                    color: s.contains(WidgetState.disabled) ? line : text,
                    width: px,
                  ),
                ),
              ),
              foregroundColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.disabled)
                    ? text.withValues(alpha: 0.6)
                    : bg,
              ),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          padding: pad,
          shape: shape,
          side: const BorderSide(color: text, width: px),
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 18),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cyan,
          shape: shape,
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 16),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: panel,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: text, width: px),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: panel,
        shape: Border(
          top: BorderSide(color: text, width: px),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return line;
          return s.contains(WidgetState.selected) ? bg : dim;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return bg;
          return s.contains(WidgetState.selected) ? yellow : panel;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(line),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: px),
      // 画面の切り替えは横スライド（iOS 標準のページ送り）ではなくフェードにする。
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: FadePageTransitionsBuilder(),
          TargetPlatform.android: FadePageTransitionsBuilder(),
          TargetPlatform.macOS: FadePageTransitionsBuilder(),
        },
      ),
      listTileTheme: const ListTileThemeData(textColor: text),
    );
  }
}

/// ColorScheme の役割に当てはまらない、このゲームだけの色。
class const RetroColors({
  /// 補足の文字（物差しの目盛り・説明など）。
  required final Color dim,

  /// 判定ごとの色。
  required final Color perfect,
  required final Color great,
  required final Color good,
  required final Color miss,

  /// 暗転中の背景。
  required final Color blindBackground,

  /// 暗転中の数字（お題・残り秒数）。
  required final Color blindText,

  /// 暗転中の「やめる」アイコン（数字より目立たせない）。
  required final Color blindIcon,

  /// 紙吹雪の白い粒。
  required final Color sparkle,
}) extends ThemeExtension<RetroColors> {
  static const retro = RetroColors(
    dim: Retro.dim,
    perfect: Retro.yellow,
    great: Retro.cyan,
    good: Retro.green,
    miss: Retro.red,
    blindBackground: Colors.black,
    blindText: Colors.white70,
    blindIcon: Colors.white54,
    sparkle: Colors.white,
  );

  Color judgement(Judgement j) => switch (j) {
    Judgement.perfect => perfect,
    Judgement.great => great,
    Judgement.good => good,
    Judgement.miss => miss,
  };

  @override
  bool operator ==(Object other) =>
      other is RetroColors &&
      other.dim == dim &&
      other.perfect == perfect &&
      other.great == great &&
      other.good == good &&
      other.miss == miss &&
      other.blindBackground == blindBackground &&
      other.blindText == blindText &&
      other.blindIcon == blindIcon &&
      other.sparkle == sparkle;

  @override
  int get hashCode => Object.hash(
    dim,
    perfect,
    great,
    good,
    miss,
    blindBackground,
    blindText,
    blindIcon,
    sparkle,
  );

  @override
  RetroColors copyWith({
    Color? dim,
    Color? perfect,
    Color? great,
    Color? good,
    Color? miss,
    Color? blindBackground,
    Color? blindText,
    Color? blindIcon,
    Color? sparkle,
  }) => RetroColors(
    dim: dim ?? this.dim,
    perfect: perfect ?? this.perfect,
    great: great ?? this.great,
    good: good ?? this.good,
    miss: miss ?? this.miss,
    blindBackground: blindBackground ?? this.blindBackground,
    blindText: blindText ?? this.blindText,
    blindIcon: blindIcon ?? this.blindIcon,
    sparkle: sparkle ?? this.sparkle,
  );

  @override
  RetroColors lerp(covariant RetroColors? other, double t) {
    if (other == null) return this;
    return RetroColors(
      dim: Color.lerp(dim, other.dim, t)!,
      perfect: Color.lerp(perfect, other.perfect, t)!,
      great: Color.lerp(great, other.great, t)!,
      good: Color.lerp(good, other.good, t)!,
      miss: Color.lerp(miss, other.miss, t)!,
      blindBackground: Color.lerp(blindBackground, other.blindBackground, t)!,
      blindText: Color.lerp(blindText, other.blindText, t)!,
      blindIcon: Color.lerp(blindIcon, other.blindIcon, t)!,
      sparkle: Color.lerp(sparkle, other.sparkle, t)!,
    );
  }
}

extension RetroThemeContext on BuildContext {
  /// テーマに登録した [RetroColors]。
  /// [Retro.theme] を使わない画面（テストで MaterialApp だけを置く場合など）では既定の配色を返す。
  RetroColors get retroColors =>
      Theme.of(this).extension<RetroColors>() ?? RetroColors.retro;

  /// 動きの多い演出（紙吹雪・線が振り上がる動き）を控えるか。
  /// Android の「アニメーションを削除」は disableAnimations、iOS の「視差効果を減らす」は
  /// reduceMotion に入る（iOS では disableAnimations は立たない）ので両方を見る。
  bool get reduceMotion =>
      MediaQuery.disableAnimationsOf(this) || MediaQuery.reduceMotionOf(this);
}

/// 画面をフェードで切り替える（ゲーム機の画面切り替えのように、横に流さない）。
class const FadePageTransitionsBuilder() extends PageTransitionsBuilder {
  @override
  Duration get transitionDuration => const Duration(milliseconds: 250);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
    child: child,
  );
}
