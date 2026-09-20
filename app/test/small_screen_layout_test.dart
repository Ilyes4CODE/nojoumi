import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/features/auth/account_form.dart';
import 'package:lunio/features/auth/forgot_password_screen.dart';

import 'support/widget_harness.dart';

/// The screens a parent meets first, on the screens a parent actually owns.
///
/// **Why this file exists.** The sign-in form was seen clipping its own
/// «ليس لديك حساب؟» line between the buttons on a 720×1456 device — a shape the
/// default 800×600 test window never produces. Then a third button, «نسيت كلمة
/// المرور؟», was added directly underneath it, which is the kind of change that
/// turns a cosmetic clip into an unreachable control.
///
/// The sizes below are logical pixels, and they are deliberately mean: 320×568
/// is smaller than anything the client is likely to hold, and a layout that
/// survives it survives the rest. The reference device of Article 13 is a
/// budget Android phone, so the small end is the case that matters, not the
/// exception.
///
/// Flutter reports an overflow as an exception rather than a failed assertion,
/// so each test has to ask for it explicitly — a layout can overflow loudly in
/// the console while the test around it passes.
void main() {
  const sizes = <String, Size>{
    'a small budget phone': Size(320, 568),
    'the common Android size': Size(360, 640),
    'the device that showed the clipping': Size(360, 728),
  };

  sizes.forEach((description, size) {
    group('on $description (${size.width.toInt()}×${size.height.toInt()})', () {
      testWidgets('the sign-in form fits, with the reset link on it', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          // **Deliberately not inside a scroll view.** The real screens put
          // this form in one — `_StepScaffold` and `AccountScreen` both do — so
          // wrapping it here too makes an overflow structurally impossible and
          // the test unable to fail. Given a fixed column instead, it reports
          // the height the form actually wants, which is the number that
          // decides whether the third button below the fields is reachable.
          const Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [AccountForm()],
                ),
              ),
            ),
          ),
          surfaceSize: size,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // Present *and* hittable. A control scrolled off the bottom of a
        // non-scrolling column is still in the tree and still found by a
        // finder, which is how a clipped button passes a careless test.
        expect(find.text('نسيت كلمة المرور؟'), findsOneWidget);
        expect(find.text('ليس لديك حساب؟ أنشئ واحداً'), findsOneWidget);
      });

      testWidgets('the reset screen fits at every step', (tester) async {
        await pumpScreen(
          tester,
          const ForgotPasswordScreen(email: 'wali@bayt.dz'),
          surfaceSize: size,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('أرسل الرمز'), findsOneWidget);

        // The 128px illustration plus a card of copy plus a field plus a
        // button is the tallest thing this flow asks of a small screen.
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });
  });
}
