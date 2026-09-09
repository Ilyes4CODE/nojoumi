import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// No user-facing string may give the parent an instruction only a developer
/// could follow.
///
/// **The one that shipped.** The connection-error message said «تحقّق من أنّ
/// الهاتف والحاسوب على نفس الشبكة» — check that the phone and the computer are
/// on the same network. That was exactly right while the server was a laptop on
/// the workshop LAN. It survived into the first build handed to the client, by
/// which time the server was `bafisslunio.com` and the sentence was addressed to
/// somebody with no computer in the story.
///
/// Found on the device on 2026-09-09, on a phone with no network at all. The
/// diagnosis was correct and the instruction was impossible — the worst
/// combination, because the parent believes they have understood and then acts
/// on nothing.
///
/// This file is not about that one sentence. It is about the class: **a message
/// written during development, still true for the developer, and useless to the
/// person reading it.**
void main() {
  /// Instructions only somebody building the app could act on.
  ///
  /// Deliberately short and specific. A broad ban would catch legitimate Arabic
  /// — «الخادم» appears in perfectly good messages — and a guard that fires on
  /// correct text is a guard somebody deletes.
  const instructions = <String, String>{
    'نفس الشبكة': 'the parent has no second machine to be on a network with',
    'الحاسوب': "there is no computer in the parent's story",
    'adb ': 'a developer tool',
    'logcat': 'a developer tool',
    'flutter ': 'a developer tool',
  };

  /// Addresses that mean nothing on a parent's phone.
  ///
  /// Banned in **messages**, allowed in `core/config.dart` — that is where the
  /// build-time default for `LUNIO_API_BASE` legitimately lives, and an emulator
  /// alias is configuration rather than something anybody reads. Separating the
  /// two is the difference between a guard that is kept and one that is deleted
  /// the first time it cries wolf.
  const addresses = <String, String>{
    'localhost': 'an address that means nothing on a phone',
    '127.0.0.1': 'an address that means nothing on a phone',
    '192.168.': 'a workshop LAN address',
    '10.0.2.2': 'the emulator alias for the build machine',
  };

  bool isConfiguration(File file) =>
      file.path.replaceAll(r'\', '/').endsWith('lib/core/config.dart');

  List<File> dartSources() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      // Generated localisations reproduce the ARB files, checked directly below.
      .where((f) => !f.path.contains('app_localizations'))
      .toList();

  /// The file with comment lines removed.
  ///
  /// The explanation of why a phrase was removed contains the phrase. A guard
  /// that fires on its own rationale is a guard nobody keeps.
  String code(File file) => const LineSplitter()
      .convert(file.readAsStringSync())
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  test("no Dart string tells the parent to do a developer's job", () {
    for (final file in dartSources()) {
      final banned = <String, String>{
        ...instructions,
        if (!isConfiguration(file)) ...addresses,
      };

      for (final line in code(file).split('\n')) {
        // Only quoted text can reach a screen.
        if (!line.contains("'") && !line.contains('"')) continue;

        banned.forEach((phrase, why) {
          expect(
            line.contains(phrase),
            isFalse,
            reason:
                'developer-only phrase "$phrase" in ${file.path}:\n'
                '  ${line.trim()}\n'
                '$why.',
          );
        });
      }
    }
  });

  test('no translated string does either', () {
    final banned = <String, String>{...instructions, ...addresses};

    for (final path in ['lib/l10n/app_ar.arb', 'lib/l10n/app_en.arb']) {
      final arb =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      arb.forEach((key, value) {
        // `@key` entries are metadata and are never shown.
        if (key.startsWith('@') || value is! String) return;
        banned.forEach((phrase, why) {
          expect(
            value.contains(phrase),
            isFalse,
            reason: '"$key" in $path says "$phrase": $value\n$why.',
          );
        });
      });
    }
  });

  test('the failure box does not show the parent a server address', () {
    // It was there for the workshop, where the build's address was the first
    // thing worth knowing. A parent cannot check it, cannot change it, and a URL
    // inside an error box reads as the app leaking something technical at the
    // moment they most need calm.
    for (final file in dartSources()) {
      expect(
        code(file).contains('serverAddress('),
        isFalse,
        reason:
            '${file.path} renders the server address to the parent. It belongs '
            'in the parent settings screen, not in a failure box.',
      );
    }
  });

  test('the connection error suggests something the parent can check', () {
    // Pinned not because the wording is sacred, but because "cannot reach the
    // server" on its own leaves a parent with nothing to try.
    final source = File('lib/data/remote/api_client.dart').readAsStringSync();
    expect(
      source.contains('تحقّق من اتصالك بالإنترنت'),
      isTrue,
      reason: 'the connection-error branch must name something checkable',
    );
  });
}
