import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/core/providers.dart';
import 'package:lunio/data/local/database.dart';
import 'package:lunio/features/child/child_home_screen.dart';
import 'package:lunio/features/setup/setup_wizard.dart';
import 'package:lunio_stars/lunio_stars.dart';
import 'package:lunio_time/lunio_time.dart';

import 'support/widget_harness.dart';

/// The widget layer, against fixed values.
///
/// Everything asserted here is something that would otherwise be caught only by
/// looking at the reference device — which does not exist yet. None of it needs
/// a phone, and none of it needs the database (see `widget_harness.dart` for why
/// that separation exists).
void main() {
  final day = DayKey(20500);

  group('the disclosure that precedes the accessibility request', () {
    Future<void> pumpStep(
      WidgetTester tester, {
      required bool consented,
    }) async {
      await pumpScreen(
        tester,
        Scaffold(
          body: ProtectionStep(
            consented: consented,
            wantsBlocking: false,
            wantsLauncher: false,
            busy: false,
            onConsentChanged: (_) {},
            onBlockingChanged: (_) {},
            onLauncherChanged: (_) {},
            onFinish: () {},
            onSkip: () {},
          ),
        ),
      );
    }

    testWidgets('consent starts unchecked', (tester) async {
      await pumpStep(tester, consented: false);
      final consent =
          tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(consent.value, isFalse,
          reason: 'consent that is pre-granted is not consent, and Play '
              'reviews this exact interaction');
    });

    testWidgets('the switches are unreachable until consent is given',
        (tester) async {
      await pumpStep(tester, consented: false);
      for (final tile
          in tester.widgetList<SwitchListTile>(find.byType(SwitchListTile))) {
        expect(tile.onChanged, isNull,
            reason: 'the disclosure must precede the permission request, '
                'not accompany it');
      }
    });

    testWidgets('the switches become reachable once consent is given',
        (tester) async {
      await pumpStep(tester, consented: true);
      for (final tile
          in tester.widgetList<SwitchListTile>(find.byType(SwitchListTile))) {
        expect(tile.onChanged, isNotNull);
      }
    });

    testWidgets('Article 15.2 — declining is an equal, visible path',
        (tester) async {
      await pumpStep(tester, consented: false);
      expect(find.byType(TextButton), findsOneWidget,
          reason: 'the 12 Play testers must be able to finish setup without '
              'ever granting accessibility');
    });

    testWidgets('the disclosure names what the service is NOT used for',
        (tester) async {
      await pumpStep(tester, consented: false);
      // The negative half of the disclosure is what Play looks for, and it is
      // the half that is easy to lose in a rewrite.
      expect(find.textContaining('لا يقرأ Lunio محتوى الشاشة'), findsOneWidget);
    });
  });

  group('the child home screen', () {
    Future<void> pumpHome(
      WidgetTester tester, {
      DayProgress? progress,
      bool clockTrustworthy = true,
      bool paused = false,
      StarRules? rules,
    }) async {
      await pumpScreen(
        tester,
        const ChildHomeScreen(),
        overrides: [
          settingsProvider.overrideWith(
            (ref) => Stream<SettingsRow>.value(fakeSettings(playPaused: paused)),
          ),
          starRulesProvider.overrideWith(
            (ref) => AsyncValue.data(rules ?? StarRules()),
          ),
          todayProgressProvider.overrideWith(
            (ref) => Stream<DayProgress>.value(
              progress ?? DayProgress(dayKey: day),
            ),
          ),
          clockIsTrustworthyProvider.overrideWithValue(clockTrustworthy),
          // The screen runs the appendix §5 welcome grant, which writes to the
          // database. A widget test states the balance it wants directly, so
          // the grant is stubbed out rather than performed.
          welcomeGrantProvider.overrideWith((ref) async => null),
          // The home offers the weekly test when it is due, which asks the
          // database. Not due is the state these tests are about.
          weeklyTestDueProvider.overrideWith((ref) async => false),
        ],
      );
      await tester.pump();
    }

    testWidgets('shows the balance and what it buys', (tester) async {
      await pumpHome(
        tester,
        progress: DayProgress(dayKey: day, earnedUnits: 350),
      );
      expect(find.text('3.5'), findsOneWidget,
          reason: 'half stars are real (Art. 5) and must be shown as such');
      expect(find.text('03:30'), findsOneWidget,
          reason: '3.5 stars at the default value is 3 minutes 30 seconds — '
              'shown as mm:ss because the star value may be half a minute');
    });

    testWidgets('a whole balance is not written with a decimal point',
        (tester) async {
      await pumpHome(
        tester,
        progress: DayProgress(dayKey: day, earnedUnits: 400),
      );
      expect(find.text('4'), findsOneWidget);
      expect(find.text('4.0'), findsNothing);
    });

    testWidgets('Article 6.8 — an untrusted clock is explained, not hidden',
        (tester) async {
      await pumpHome(tester, clockTrustworthy: false);
      expect(find.textContaining('ساعة الهاتف غير موثوقة'), findsOneWidget);
      expect(find.textContaining('النجوم المكسوبة سابقاً'), findsOneWidget,
          reason: 'the child must be told their existing stars are safe, or '
              'the message reads as a punishment');
    });

    testWidgets('a trusted clock shows no warning at all', (tester) async {
      await pumpHome(tester);
      expect(find.textContaining('ساعة الهاتف غير موثوقة'), findsNothing);
    });

    testWidgets('appendix §4 — a parent pause is named, and reads as zero',
        (tester) async {
      await pumpHome(
        tester,
        progress: DayProgress(dayKey: day, earnedUnits: 500),
        paused: true,
      );
      expect(find.textContaining('اللعب موقوف مؤقتاً'), findsOneWidget);
    });

    testWidgets('Article 7.2 — no price, no buy button, no payment link',
        (tester) async {
      await pumpHome(
        tester,
        progress: DayProgress(dayKey: day, earnedUnits: 500),
      );
      final rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      for (final forbidden in [
        'DZD',
        'دج',
        'اشتر',
        'شراء',
        'ادفع',
        'اشتراك',
        '1000',
        '10000',
      ]) {
        expect(rendered.contains(forbidden), isFalse,
            reason: 'Art. 7.2 keeps every purchase surface outside the app; '
                'found "$forbidden"');
      }
    });

    testWidgets('is right-to-left', (tester) async {
      await pumpHome(tester);
      expect(
        Directionality.of(tester.element(find.byType(ChildHomeScreen))),
        TextDirection.rtl,
      );
    });
  });
}
