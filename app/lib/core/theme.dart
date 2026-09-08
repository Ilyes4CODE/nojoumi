import 'package:flutter/material.dart';

/// The app's visual language — v3, after the client's reference design.
///
/// See `docs/design-v3.md` for what was adopted from it and what was refused.
/// The short version: the **visual language** comes from the client's reference
/// (violet, pastel tinted tiles, big radii, a 3D character), and the
/// **information architecture** does not, because that reference is a different
/// product with in-app games, a child login and an upgrade banner.
///
/// Two colours here are **information, not decoration**, and that survives every
/// restyle:
///
///  * [star] means stars. Only stars. Never a button, never a heading.
///  * [play] means remaining play time. Only that.
///
/// The moment gold appears on a button, the child has to read every label to know
/// what they are looking at, and the one glanceable number in the app stops being
/// glanceable. The client's own reference breaks this — it puts gold on the star
/// count *and* on a subscription crown — which is exactly how a colour stops
/// carrying meaning.
class LunioTheme {
  const LunioTheme._();

  /// Primary violet. Warmer and more childlike than the blue of v2, and taken
  /// from the client's reference.
  static const Color seed = Color(0xFF5B3FD9);

  /// The star. Balances, awards, star icons — and nothing else, ever.
  static const Color star = Color(0xFFFFC22E);

  /// Remaining play time. The only green in the app.
  static const Color play = Color(0xFF22C55E);

  /// A blocked or exhausted state. Muted, never alarming: Article 1 calls this a
  /// motivation tool, and a red wall is the opposite of motivating.
  static const Color blocked = Color(0xFFB6BCCB);

  /// Celebration — streaks, finishing the day.
  static const Color celebrate = Color(0xFFFF7A59);

  /// The four pastel tile tints, from the client's reference. They are what make
  /// a row of actions readable at a glance without any of them shouting.
  static const Color tintMint = Color(0xFFDCF5E7);
  static const Color tintSky = Color(0xFFDCE9FB);
  static const Color tintLavender = Color(0xFFEDE8FC);
  static const Color tintPeach = Color(0xFFFDECD4);

  /// The app's ground. Very slightly violet rather than pure white.
  static const Color canvas = Color(0xFFF8F7FC);

  /// All body text.
  static const Color ink = Color(0xFF1E2436);

  /// The bundled family, named once.
  ///
  /// `ThemeData.fontFamily` reaches the text theme but **not** a standalone
  /// `TextStyle` handed to a component theme — a `styleFrom(textStyle: ...)`
  /// with no family falls back to the platform default. That is how an app ends
  /// up with every button in a different typeface from every label, which is
  /// precisely the split-typeface problem this family was chosen to avoid. So
  /// anywhere a raw TextStyle is unavoidable, it names this constant.
  static const String fontFamily = 'Tajawal';

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: isLight ? canvas : scheme.surface,
      // Tajawal, chosen by the client on 2026-08-28 and bundled with the app.
      //
      // This replaces a deliberate `null`, and the reasoning behind that null is
      // worth keeping because it says what to watch for: a Latin-first family
      // with no Arabic coverage falls back glyph by glyph, and the screen ends
      // up in two typefaces at once. Tajawal does not have that problem — it is
      // an Arabic family with a matching Latin set, drawn together, so
      // «أهلاً بك في Lunio» renders in one voice.
      //
      // Bundled, not fetched. A first launch with Wi-Fi off must not look like a
      // different app.
      fontFamily: fontFamily,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: isLight ? canvas : scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(LunioSpacing.tapTarget),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LunioRadius.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(LunioSpacing.tapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LunioRadius.button),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        // One elevation level in the whole app. Depth comes from the artwork,
        // not from stacked shadows — Article 13's floor is a 2 GB device.
        elevation: 0,
        color: isLight ? Colors.white : scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LunioRadius.card),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LunioRadius.button),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class LunioSpacing {
  const LunioSpacing._();

  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;

  /// Material's minimum is 48; a seven-year-old on a bus needs more.
  static const double tapTarget = 56;

  /// The standard page inset. Symmetric horizontal padding, so RTL needs no
  /// special case — docs/CONVENTIONS.md forbids `EdgeInsets.only(left:)` for this reason.
  static const EdgeInsets page = EdgeInsets.symmetric(
    horizontal: m,
    vertical: l,
  );
}

class LunioRadius {
  const LunioRadius._();

  static const double button = 16;

  /// Large and soft, from the client's reference. It is most of what makes the
  /// difference between "productivity tool" and "children's app".
  static const double card = 24;

  /// The pastel action tiles.
  static const double tile = 20;
}
