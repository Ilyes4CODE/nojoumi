import 'package:flutter/material.dart';

/// The app's visual language.
///
/// Two audiences share one binary and they want opposite things, so the theme is
/// split rather than compromised:
///
///  * **The child's surfaces** are large, warm and legible at arm's length on a
///    cheap screen in daylight. Article 13 puts the floor at a 2 GB Android 10
///    phone, so nothing here depends on blur, shadow layers or animation.
///  * **The parent's surfaces** are ordinary Material: dense, boring, and
///    readable. A parent reading a ledger does not want a playground.
///
/// Every geometry constant that a widget would otherwise inline lives in
/// [NojoumiSpacing] / [NojoumiRadius], because the same numbers reappear in
/// every screen and drift when they are typed by hand.
class NojoumiTheme {
  const NojoumiTheme._();

  /// Deep indigo — night sky, the thing stars sit in. Not a stock purple.
  static const Color seed = Color(0xFF2B3A67);

  /// The star. Used for balances and awards, and for nothing else, so that a
  /// gold surface always means "this is about stars".
  static const Color star = Color(0xFFF2B138);

  /// Play time remaining. Green while there is time, and it is the only green.
  static const Color play = Color(0xFF2E9E6B);

  /// A blocked or exhausted state. Muted, never alarming: Article 1 calls this a
  /// motivation tool, and a red wall is the opposite of motivating.
  static const Color blocked = Color(0xFF8A8FA3);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      // The Arabic system font on Android is the one shaped correctly for the
      // reader's device. Bundling a Latin-first family and letting it fall back
      // per glyph is how Arabic ends up rendering in two typefaces at once.
      fontFamily: null,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(NojoumiSpacing.tapTarget),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NojoumiRadius.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(NojoumiSpacing.tapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NojoumiRadius.button),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NojoumiRadius.card),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NojoumiRadius.button),
        ),
      ),
    );
  }
}

class NojoumiSpacing {
  const NojoumiSpacing._();

  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;

  /// Material's minimum is 48; a seven-year-old on a bus needs more.
  static const double tapTarget = 56;

  /// The standard page inset. Uses symmetric horizontal padding so RTL needs no
  /// special case — CLAUDE.md forbids `EdgeInsets.only(left:)` for this reason.
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: m, vertical: l);
}

class NojoumiRadius {
  const NojoumiRadius._();

  static const double button = 14;
  static const double card = 20;
}
