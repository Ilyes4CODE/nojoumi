import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Article 7.2, enforced against the source rather than against intent.
///
///     «التطبيق لا يعرض أي سعر ولا زرّ شراء ولا رابط دفع. الشراء يتمّ في صفحة
///      ويب مستقلّة خارج التطبيق.»
///
/// **This is not a style rule.** The contract states the reason: the separation
/// is what keeps Lunio clear of Google Play's billing policy, which requires
/// digital purchases made inside an app to go through Play Billing. A
/// third-party gateway reached from within the app is a documented cause of
/// removal — and removal takes Article 15.2's twelve testers and Article 11's
/// acceptance with it.
///
/// ## The client's exception, and what still holds
///
/// On 2026-08-29 the client was shown the two options and **chose a button that
/// opens the payment page in the browser** (D-66). That is a recorded departure
/// from the article, not a defect — and it is one link, not a licence.
///
/// So this file was **narrowed rather than deleted**. Everything it guarded that
/// is still true is still guarded:
///
///  * no price in any user-facing string — both amounts live on the web page;
///  * no card-shaped field anywhere (Art. 7.7, which nothing may touch);
///  * no call to a payments endpoint from the app — the checkout is created by
///    the web page, and an app that created its own would be running the
///    purchase itself rather than handing it over;
///  * exactly **one** place may hold a payment URL, and it is the config.
///
/// Deleting the file would have thrown away four live protections to
/// accommodate one agreed change.
void main() {
  late List<File> sources;

  setUpAll(() {
    sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        // Generated localisations are checked through their ARB sources
        // instead — the generator reproduces whatever is in them.
        .where((f) => !f.path.contains('app_localizations'))
        .toList();
  });

  String read(File file) => file.readAsStringSync();

  /// The file with its comments removed.
  ///
  /// These guards look for identifiers, and identifiers appear in prose too —
  /// the first run of the WebView check failed on a comment that said "never a
  /// WebView". A guard that fires on the sentence explaining why it exists is a
  /// guard nobody keeps.
  String code(File file) => const LineSplitter()
      .convert(read(file))
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  test('no screen shows a price', () {
    // The two amounts of Article 7.1. Searched as bare numbers because a price
    // is a price whether or not it is next to the word "دج".
    final price = RegExp(r'\b(1000|10000|1\.000|10\.000)\b');

    for (final file in sources) {
      final text = read(file);
      for (final line in text.split('\n')) {
        // Interpolations are stripped first. `'${ms / 1000}'` is a millisecond
        // divisor, not a price, and the first version of this test failed on
        // exactly that — a guard that cries wolf is a guard somebody deletes.
        final literal = line.replaceAll(RegExp(r'\$\{[^}]*\}'), '');

        // Star units are 100 per star, so 1000 and 10000 appear legitimately all
        // over the ledger arithmetic. Only text a parent can read matters here.
        final inQuotes = RegExp(
          "['\"][^'\"]*\\b(1000|10000|1\\.000|10\\.000)\\b",
        ).hasMatch(literal);
        if (!inQuotes) continue;
        expect(
          price.hasMatch(literal),
          isFalse,
          reason:
              'a subscription price appears in ${file.path}:\n  ${line.trim()}\n'
              'Article 7.2 keeps every price on the web page.',
        );
      }
    }
  });

  test('the payment address lives in exactly one file', () {
    // `AppConfig.payUrl` is the single place. An address that starts appearing
    // in screens is an address that will be copied into a second screen with a
    // different path — and the client's exception was for one button, not for
    // the app growing its own opinions about where money is taken.
    final link = RegExp(r'/pay/|chargily\.|checkout_url|trycloudflare');
    for (final file in sources) {
      if (file.path.endsWith('config.dart')) continue;
      final match = link.firstMatch(code(file));
      expect(
        match,
        isNull,
        reason:
            'a payment address appears in ${file.path}: "${match?.group(0)}"\n'
            'It belongs in AppConfig.payUrl and nowhere else.',
      );
    }
  });

  test('the payment page opens in a browser, never a WebView', () {
    // A payment page rendered *inside* the app is unambiguously an in-app
    // purchase flow, which is precisely what Google's billing policy is about.
    // Handing the URL to the system browser keeps the transaction visibly
    // outside Lunio, with the address bar and the padlock a parent knows how to
    // read. If a WebView ever appears here, this is the assertion that should
    // stop it and make somebody argue for it out loud.
    for (final file in sources) {
      expect(
        code(file).contains('WebView'),
        isFalse,
        reason: '${file.path} embeds a WebView (Art. 7.2, D-66)',
      );
    }
  });

  test('the app never calls the checkout endpoint', () {
    // It exists on the server for the web page. An app that called it would be
    // starting a purchase from inside the app, which is the exact thing the
    // article forbids.
    for (final file in sources) {
      expect(
        code(file).contains('/api/payments/'),
        isFalse,
        reason: '${file.path} calls a payments endpoint (Art. 7.2)',
      );
    }
  });

  test('no user-facing string offers to buy anything', () {
    // The Arabic the client and a Play reviewer would look for. `اشتراك` alone
    // is fine and necessary — the app has to name the thing whose status it
    // shows — so only buying verbs are refused.
    // `احصل على رمز تفعيل` is the button the client asked for and is allowed.
    // What stays out is the language of a shop — an urgent verb next to a price
    // is what turns a link into a store front, and the exception was for a way
    // through, not for a shop.
    final selling = RegExp(r'ادفع|اشترِ|اشتري|شراء|اشتراك الآن|جدّد الآن');
    for (final path in ['lib/l10n/app_ar.arb', 'lib/l10n/app_en.arb']) {
      final text = File(path).readAsStringSync();
      for (final line in text.split('\n')) {
        final match = selling.firstMatch(line);
        expect(
          match,
          isNull,
          reason:
              'a buy prompt appears in $path:\n  ${line.trim()}\n'
              'Article 7.2 — no buy button, and no words that act as one.',
        );
      }
    }
  });

  test('a card-shaped field exists nowhere in the app', () {
    // Article 7.7 is absolute: the app never touches card data in any form. This
    // is the assertion docs/CONVENTIONS.md describes as the difference between a contract
    // breach and a code-review comment.
    final card = RegExp(
      r'cardNumber|card_number|\bcvv\b|\bcvc\b|expiryMonth|expiry_month|'
      r'expiryYear|expiry_year',
      caseSensitive: false,
    );
    for (final file in sources) {
      final match = card.firstMatch(code(file));
      expect(
        match,
        isNull,
        reason: 'card-shaped field "${match?.group(0)}" in ${file.path}',
      );
    }
  });
}
