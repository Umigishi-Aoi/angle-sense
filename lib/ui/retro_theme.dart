import 'package:material_ui/material_ui.dart';

import '../game/scoring.dart';

/// レトロ・ドット絵風の配色（独自。既存ゲームの配色は使わない）。
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

  static Color judgement(Judgement j) => switch (j) {
    Judgement.perfect => yellow,
    Judgement.great => cyan,
    Judgement.good => green,
    Judgement.miss => red,
  };

  static ThemeData theme() {
    const shape = RoundedRectangleBorder();
    const pad = EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    const scheme = ColorScheme.dark(
      primary: yellow,
      onPrimary: bg,
      secondary: cyan,
      onSecondary: bg,
      tertiary: cyan,
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
