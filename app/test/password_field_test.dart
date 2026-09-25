import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/features/auth/password_field.dart';

import 'support/widget_harness.dart';

/// The eye on the password fields. Client request, 2026-09-25.
void main() {
  Future<TextEditingController> open(WidgetTester tester) async {
    final controller = TextEditingController(text: 'K8-Masaa-Noor');
    addTearDown(controller.dispose);
    await pumpScreen(
      tester,
      Scaffold(
        body: PasswordField(controller: controller, label: 'كلمة المرور'),
      ),
    );
    return controller;
  }

  bool hidden(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).obscureText;

  testWidgets('the password starts hidden', (tester) async {
    // Every time. A field that remembered being revealed would eventually show
    // a password on a screen somebody else was looking at.
    await open(tester);
    expect(hidden(tester), isTrue);
  });

  testWidgets('the eye shows it, and a second tap hides it again', (tester) async {
    await open(tester);

    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(hidden(tester), isFalse);

    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(hidden(tester), isTrue);
  });

  testWidgets('the button is labelled for a screen reader', (tester) async {
    // Material has no password-visibility string. Its nearest neighbour,
    // `showAccountsLabel`, would announce "show accounts" on a password field.
    await open(tester);
    expect(find.byTooltip('إظهار كلمة المرور'), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(find.byTooltip('إخفاء كلمة المرور'), findsOneWidget);
  });

  testWidgets('the keyboard is not allowed to learn it', (tester) async {
    // Suggestions on a password field are how a password ends up in the
    // keyboard's learned-words list, offered back later in another app.
    await open(tester);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enableSuggestions, isFalse);
    expect(field.autocorrect, isFalse);
  });
}
