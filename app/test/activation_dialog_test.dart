import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/core/providers.dart';
import 'package:lunio/data/local/database.dart';
import 'package:lunio/data/local/tables.dart';
import 'package:lunio/features/parent/subscription_screen.dart';

import 'support/widget_harness.dart';

/// The card the parent sees the moment their activation code is accepted.
///
/// Asked for by the client on 2026-08-31. The minute it covers is the least
/// certain in the product: the parent has left the app for a browser, paid on a
/// page they had never seen, and carried a short string back by hand. Until now
/// that ended with a text field clearing itself.
void main() {
  SubscriptionCacheRow cache({
    String plan = 'monthly',
    int? endsAtMs = 1790000000000,
  }) => SubscriptionCacheRow(
    id: 1,
    payloadJson: '',
    signatureHex: '',
    fetchedAtMs: null,
    state: SubscriptionStateRow.active,
    plan: plan,
    endsAtMs: endsAtMs,
    graceEndsAtMs: null,
  );

  Future<void> pumpDialog(
    WidgetTester tester, {
    SubscriptionCacheRow? row,
  }) async {
    await pumpScreen(
      tester,
      const ActivationDoneDialog(),
      overrides: [
        subscriptionCacheProvider.overrideWith(
          (ref) => Stream<SubscriptionCacheRow>.value(row ?? cache()),
        ),
      ],
    );
    await tester.pump();
  }

  testWidgets('it says plainly that the code worked', (tester) async {
    await pumpDialog(tester);

    expect(find.text('تمّ تفعيل اشتراكك'), findsOneWidget);
  });

  testWidgets('it says until when', (tester) async {
    // The second fact the parent needs, and the one they cannot work out for
    // themselves — the code carried no date on it.
    await pumpDialog(tester);

    expect(find.textContaining('سارٍ حتى'), findsOneWidget);
  });

  testWidgets('a cache with no end date does not show an empty line',
      (tester) async {
    await pumpDialog(tester, row: cache(endsAtMs: null));

    expect(find.text('تمّ تفعيل اشتراكك'), findsOneWidget);
    expect(find.textContaining('سارٍ حتى'), findsNothing);
  });

  testWidgets('Article 7.1 — it says what keeps working without a subscription',
      (tester) async {
    // A parent who believes the whole app dies at expiry is paying under a
    // false impression, and the contract is explicit that the child is never
    // punished for a payment delay.
    await pumpDialog(tester);

    expect(find.textContaining('الحجب والنجوم'), findsOneWidget);
  });

  testWidgets('Article 7.2 — no price and no way to buy anything',
      (tester) async {
    // A confirmation is not a place to sell the next renewal, and the shop
    // stays outside the app.
    await pumpDialog(tester);

    for (final forbidden in ['1000', '10000', '1.000', '10.000', 'دج']) {
      expect(
        find.textContaining(forbidden),
        findsNothing,
        reason: 'a price appeared in the confirmation: $forbidden',
      );
    }
    expect(find.textContaining('اشترِ'), findsNothing);
  });

  testWidgets('it closes on the button', (tester) async {
    await pumpDialog(tester);

    expect(find.text('متابعة'), findsOneWidget);
  });
}
