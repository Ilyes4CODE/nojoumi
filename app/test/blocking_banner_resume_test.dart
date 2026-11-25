import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/core/providers.dart';
import 'package:lunio/data/local/database.dart';
import 'package:lunio/features/child/child_home_screen.dart';
import 'package:lunio/platform/blocking_channel.dart';
import 'package:lunio_stars/lunio_stars.dart';
import 'package:lunio_time/lunio_time.dart';

import 'support/widget_harness.dart';

/// The "blocking is on but not running" warning goes away once it is fixed.
///
/// Found on 2026-11-25 while recording the demo video: the parent taps «أعد
/// تفعيلها», switches the service on in the phone's settings, comes back — and
/// the warning is still there, saying blocking does not work while it does.
/// `blockingStatusProvider` is documented as "invalidate on resume", but only
/// the parent's blocking screen did; the home screen kept the answer it read
/// before the parent left, until the app was closed and reopened.
void main() {
  const title = 'الحجب مُفعَّل لكنّه لا يعمل';
  const day = DayKey(20500);

  testWidgets('switching the service on and coming back clears the warning', (
    tester,
  ) async {
    var status = const BlockingStatus(accessibilityEnabled: false);

    await pumpScreen(
      tester,
      const ChildHomeScreen(),
      overrides: [
        settingsProvider.overrideWith(
          (ref) => Stream<SettingsRow>.value(fakeSettings(blockingEnabled: true)),
        ),
        starRulesProvider.overrideWith((ref) => AsyncValue.data(StarRules())),
        todayProgressProvider.overrideWith(
          (ref) => Stream<DayProgress>.value(DayProgress(dayKey: day)),
        ),
        clockIsTrustworthyProvider.overrideWithValue(true),
        welcomeGrantProvider.overrideWith((ref) async => null),
        weeklyTestDueProvider.overrideWith((ref) async => false),
        blockingStatusProvider.overrideWith((ref) async => status),
      ],
    );
    await tester.pump();
    expect(find.text(title), findsOneWidget, reason: 'the service is off');

    // The parent is in the phone's settings now. They switch it on...
    status = const BlockingStatus(accessibilityEnabled: true);
    // ...and come back to Lunio.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    // One frame for the re-read to finish, one for the screen to redraw.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text(title), findsNothing,
        reason: 'blocking is running; a warning that says otherwise is a lie');
  });
}
