import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/data/local/database.dart';
import 'package:lunio/data/repositories/star_repository.dart';
import 'package:lunio_stars/lunio_stars.dart';
import 'package:lunio_time/lunio_time.dart';

import 'support/test_db.dart';

/// The parent's free-play button, from the database up.
///
/// The package tests cover what free play *means* to Article 6. These cover the
/// two things only the app side can get wrong: that a grant survives a round
/// trip through SQLite, and that granting play time never puts a star anywhere.
void main() {
  late LunioDatabase db;
  late StarRepository stars;

  final rules = StarRules();
  const day = DayKey(20500);
  const now = TrustedInstant(
    epochMs: 1788000000000,
    level: TrustLevel.serverAnchored,
  );

  setUp(() async {
    db = await freshDatabase();
    stars = StarRepository(db);
  });

  tearDown(() => db.close());

  test('a grant survives being written and read back', () async {
    await stars.addFreePlay(day: day, seconds: 3600, now: now);

    final progress = await stars.dayProgress(day);
    expect(progress.freePlaySeconds, 3600);
    expect(progress.remainingPlaySeconds(rules), 3600);
  });

  test('it adds rather than replaces', () async {
    // Two taps on "one hour" mean two hours. Setting would throw the first hour
    // away silently, and once the child had spent part of it the button would
    // appear to do nothing at all.
    await stars.addFreePlay(day: day, seconds: 3600, now: now);
    await stars.addFreePlay(day: day, seconds: 1800, now: now);

    expect((await stars.dayProgress(day)).freePlaySeconds, 5400);
  });

  test('AD-4 — no star ever enters the ledger for it', () async {
    // The ledger has to be able to answer for every star in it. A star written
    // here would be one the child never earned, and the parent asking "where
    // did these come from" would get a row that lies.
    await stars.addFreePlay(day: day, seconds: 7200, now: now);

    final ledger = await db.select(db.starLedger).get();
    expect(ledger, isEmpty);
    expect(await stars.derivedBalanceUnits(day), 0);
    expect((await stars.dayProgress(day)).balanceUnits, 0);
  });

  test('it is recorded where the parent can be answered', () async {
    // Not in the star ledger, but not nowhere either: "why did my child play
    // for three hours" must have an answer.
    await stars.addFreePlay(day: day, seconds: 7200, now: now);

    final events = await db.select(db.eventLog).get();
    expect(events, hasLength(1));
    expect(events.single.type, 'free_play_granted');
    expect(events.single.detail, '7200');
    expect(events.single.atMs, now.epochMs);
  });

  test('the blocking engine is told about it', () async {
    // The whole point: the native side allows the game because the play time it
    // was pushed went up. If this ever stops flowing, the button does nothing
    // visible and nothing fails.
    await stars.addFreePlay(day: day, seconds: 1800, now: now);

    final progress = await stars.dayProgress(day);
    expect(progress.remainingPlaySeconds(rules), 1800);
  });

  test('yesterday keeps its own, and today starts with none', () async {
    // Article 6.7 through the database rather than through the value type.
    await stars.addFreePlay(day: day, seconds: 3600, now: now);

    const tomorrow = DayKey(20501);
    expect((await stars.dayProgress(tomorrow)).freePlaySeconds, 0);
    expect((await stars.dayProgress(day)).freePlaySeconds, 3600);
  });

  test('a negative grant cannot drive the day below zero', () async {
    // Taking play time away is the pause switch's job. This clamps rather than
    // trusting a caller, because a negative free-play pool would silently eat
    // into time the child actually earned.
    await stars.addFreePlay(day: day, seconds: 600, now: now);
    await stars.addFreePlay(day: day, seconds: -5000, now: now);

    expect((await stars.dayProgress(day)).freePlaySeconds, 0);
  });
}
