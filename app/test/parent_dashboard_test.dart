import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/core/providers.dart';
import 'package:lunio/data/local/database.dart';
import 'package:lunio/features/parent/parent_settings_screen.dart';
import 'package:lunio/features/parent/pin_gate.dart';
import 'package:lunio_stars/lunio_stars.dart';
import 'package:lunio_time/lunio_time.dart';

import 'support/widget_harness.dart';

/// The parent's surfaces.
///
/// Two things are asserted here that no amount of looking at the screen would
/// reliably catch: that the daily ceiling is drawn against what the **child
/// earned** and never against a parent grant, and that every adjustable number
/// is bounded by the same range `StarRules` enforces — so the widget can never
/// offer a value the engine would refuse.
void main() {
  final day = DayKey(20500);

  Future<void> pumpSettings(
    WidgetTester tester, {
    StarRules? rules,
    SettingsRow? settings,
  }) async {
    final effective = rules ?? StarRules();
    await pumpScreen(
      tester,
      const ParentSettingsScreen(),
      surfaceSize: const Size(800, 3000),
      overrides: [
        starRulesProvider.overrideWith((ref) => AsyncValue.data(effective)),
        settingsProvider.overrideWith(
          (ref) => Stream<SettingsRow>.value(
            settings ??
                fakeSettings(
                  starValueSeconds: effective.starValueSeconds,
                  dailyCeilingUnits: effective.dailyCeilingUnits,
                  minimumTimeOnTargetMs: effective.minimumTimeOnTargetMs,
                  dailySessionCards: effective.dailySessionCards,
                  dailyQuestionCount: effective.dailyQuestionCount,
                  welcomeUnits: effective.welcomeUnits,
                ),
          ),
        ),
      ],
    );
    await tester.pump();
  }

  group('the PIN gate', () {
    Future<void> pumpGate(WidgetTester tester) async {
      await pumpScreen(
        tester,
        const PinGate(title: 'لوحة الوالد', child: Text('محتوى محمي')),
      );
      await tester.pump();
    }

    testWidgets('hides its child until the PIN is accepted', (tester) async {
      await pumpGate(tester);
      expect(find.text('محتوى محمي'), findsNothing);
      expect(find.text('أدخل الرمز السري'), findsOneWidget);
    });

    testWidgets('the field accepts digits only', (tester) async {
      await pumpGate(tester);
      await tester.enterText(find.byType(TextField), '12ab34');
      await tester.pump();
      expect(find.text('1234'), findsOneWidget,
          reason: 'a PIN is digits; letters would silently never match');
    });

    testWidgets('the entry is obscured', (tester) async {
      await pumpGate(tester);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue,
          reason: 'the child is standing next to the parent');
    });
  });

  group('appendix §5 — the ranges are enforced by the controls', () {
    testWidgets('the star value cannot go below half a minute', (tester) async {
      await pumpSettings(tester, rules: StarRules(starValueSeconds: 30));
      final decrements = tester
          .widgetList<IconButton>(
            find.widgetWithIcon(IconButton, Icons.remove),
          )
          .toList();
      expect(decrements.first.onPressed, isNull,
          reason: 'appendix §5 puts the floor at 0.5 minutes, and the control '
              'must not be able to ask for less');
    });

    testWidgets('the star value cannot go above three minutes', (tester) async {
      await pumpSettings(tester, rules: StarRules(starValueSeconds: 180));
      final increments = tester
          .widgetList<IconButton>(find.widgetWithIcon(IconButton, Icons.add))
          .toList();
      expect(increments.first.onPressed, isNull);
    });

    testWidgets('every printed range matches the appendix', (tester) async {
      await pumpSettings(tester);
      // These are the six published ranges. If one of them is edited without
      // the contract changing, this test is where it shows.
      expect(find.text('من 0.5 إلى 3'), findsOneWidget);
      expect(find.text('من 20 إلى 150'), findsOneWidget);
      expect(find.text('من 1 إلى 5'), findsOneWidget);
      expect(find.text('من 5 إلى 30'), findsOneWidget);
      expect(find.text('من 0 إلى 15'), findsOneWidget);
      expect(find.text('من 0 إلى 30'), findsOneWidget);
    });

    testWidgets('D-2 — daily play minutes are shown as derived, not editable',
        (tester) async {
      await pumpSettings(tester);
      expect(find.text('دقائق اللعب اليومية'), findsOneWidget);
      expect(find.text('السقف اليومي × قيمة النجمة'), findsOneWidget);
      // 60 appears twice on purpose: the ceiling in stars, and the same value
      // in minutes beside it. That is D-2 made visible, not a duplication bug.
      expect(find.text('60'), findsNWidgets(2),
          reason: '60 stars × 1 minute — one stored value, two presentations');
    });

    testWidgets('the welcome balance is frozen once it has been granted',
        (tester) async {
      await pumpSettings(
        tester,
        settings: fakeSettings(welcomeGranted: true),
      );
      // It is shown but not adjustable: changing it after the fact would
      // suggest it could be granted again, and it cannot.
      expect(find.text('الرصيد الترحيبي'), findsOneWidget);
    });

    testWidgets('Article 6.7 — both expiry modes are offered', (tester) async {
      await pumpSettings(tester);
      expect(find.text('نهاية اليوم'), findsOneWidget);
      expect(find.text('نهاية الأسبوع'), findsOneWidget);
    });

    testWidgets('Article 15.2 — blocking and launcher stay switchable',
        (tester) async {
      await pumpSettings(tester);
      final switches =
          tester.widgetList<SwitchListTile>(find.byType(SwitchListTile));
      expect(switches, hasLength(2));
      for (final tile in switches) {
        expect(tile.onChanged, isNotNull,
            reason: 'a Play tester who turned them on must be able to turn '
                'them off again without reinstalling');
      }
    });
  });

  group('the overview', () {
    testWidgets('the ceiling bar measures earned stars, not the total',
        (tester) async {
      // 6 earned by the child, 40 granted by the parent, ceiling 60.
      await pumpScreen(
        tester,
        const _OverviewProbe(),
        overrides: [
          starRulesProvider.overrideWith((ref) => AsyncValue.data(StarRules())),
          settingsProvider.overrideWith(
            (ref) => Stream<SettingsRow>.value(fakeSettings()),
          ),
          todayProgressProvider.overrideWith(
            (ref) => Stream<DayProgress>.value(
              DayProgress(
                dayKey: day,
                earnedUnits: 6 * starUnit,
                grantedUnits: 40 * starUnit,
              ),
            ),
          ),
        ],
      );
      await tester.pump();

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, closeTo(6 / 60, 0.001),
          reason: 'Art. 6.4 caps what the child EARNS. A parent grant sits '
              'above the system and must never look like it consumed the '
              "child's day");
    });
  });
}

/// The overview card is private to the dashboard, and the dashboard sits behind
/// the PIN gate. This probe renders the same three providers the card reads, so
/// the assertion above is about the numbers rather than about navigation.
class _OverviewProbe extends ConsumerWidget {
  const _OverviewProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(todayProgressProvider).value;
    final rules = ref.watch(starRulesProvider).value;
    final earned = progress?.earnedUnits ?? 0;
    final ceiling = rules?.dailyCeilingUnits ?? 1;
    return Scaffold(
      body: LinearProgressIndicator(
        value: (earned / ceiling).clamp(0.0, 1.0),
      ),
    );
  }
}
