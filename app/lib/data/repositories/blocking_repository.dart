import 'package:drift/drift.dart';
import 'package:lunio_stars/lunio_stars.dart';
import 'package:lunio_time/lunio_time.dart';

import '../../platform/blocking_channel.dart';
import '../local/database.dart';
import '../local/tables.dart';
import 'star_repository.dart';

/// The parent's app classification, and the one place that feeds the engine.
///
/// Two responsibilities that look separate and are not:
///
///  * **which apps count as games** — rows in `managed_apps`, chosen by the
///    parent, and nothing else in the app writes them;
///  * **pushing the world into Kotlin** — [sync], called whenever any input
///    changes.
///
/// They live together because the failure mode is shared. If the push stops
/// happening, the engine keeps enforcing the *last* state it was given: a child
/// who earns twenty stars stays blocked, or worse, one whose time ran out keeps
/// playing. The engine cannot detect this — from inside, a stale state and a
/// correct state are the same value — so the only defence is that there is exactly
/// one writer and it is easy to find.
///
/// **The engine is never asked to compute anything.** Articles 5 and 6 live in
/// `lunio_stars` with tests on every clause; deriving the balance a second time in
/// Kotlin would create two implementations of the contract that could disagree,
/// and the one the child sees would be the wrong one.
class BlockingRepository {
  BlockingRepository(this._db, this._channel, this._stars);

  final LunioDatabase _db;
  final BlockingChannel _channel;
  final StarRepository _stars;

  // --- what the parent has classified --------------------------------------

  Stream<List<ManagedAppRow>> watchManagedApps() => (_db.select(
    _db.managedApps,
  )..orderBy([(t) => OrderingTerm(expression: t.label)])).watch();

  Future<List<ManagedAppRow>> managedApps() =>
      _db.select(_db.managedApps).get();

  /// Records one decision about one app.
  ///
  /// `protected` is accepted here for completeness, but note that the permanent
  /// allowlist in Kotlin (D-9) does not read this table: Settings, the dialer and
  /// the keyboard are protected by `BlockPolicy` before the parent's list is even
  /// consulted, so no row written here can unprotect them.
  Future<void> setPolicy({
    required String packageName,
    required String label,
    required AppPolicy policy,
    required int nowMs,
  }) {
    return _db
        .into(_db.managedApps)
        .insertOnConflictUpdate(
          ManagedAppsCompanion.insert(
            packageName: packageName,
            label: Value(label),
            policy: policy,
            addedAtMs: Value(nowMs),
          ),
        );
  }

  Future<void> forget(String packageName) => (_db.delete(
    _db.managedApps,
  )..where((t) => t.packageName.equals(packageName))).go();

  /// The list the engine blocks on: exactly the apps marked as games.
  ///
  /// `hidden` is deliberately not included. Hiding an app removes it from the
  /// child's home screen in launcher mode; blocking it stops it opening at all.
  /// A parent who hid an app did not necessarily mean to make it cost stars, and
  /// silently promoting one to the other would be us deciding for them.
  Future<List<String>> blockedPackages() async {
    final rows = await (_db.select(
      _db.managedApps,
    )..where((t) => t.policy.equalsValue(AppPolicy.blockedGame))).get();
    return rows.map((row) => row.packageName).toList(growable: false);
  }

  // --- the push ------------------------------------------------------------

  Future<BlockingStatus> status() => _channel.status();

  Future<List<InstalledApp>> installedApps({bool includeIcons = true}) =>
      _channel.launchableApps(includeIcons: includeIcons);

  /// Write the engine's measured play seconds into the ledger.
  ///
  /// Article 4.7's other half, and the piece that was missing until 2026-08-28:
  /// the child played, the engine counted the seconds, and nothing ever told the
  /// ledger. On screen the balance sat unchanged while the time was really being
  /// spent — the exact symptom reported from the first hardware run.
  ///
  /// Drained **before** the next [sync], never after. The order is the whole
  /// correctness argument: sync pushes the authoritative remaining and overwrites
  /// the engine's copy, so seconds still sitting in the tally at that moment are
  /// seconds the child is handed back for free.
  Future<PlayConsumption?> collectPlayTime({
    required DayKey day,
    required StarRules rules,
  }) async {
    final seconds = await _channel.drainConsumedSeconds();
    if (seconds <= 0) return null;
    return _stars.consumePlay(rules: rules, day: day, seconds: seconds);
  }

  /// Hands the engine everything it needs, computed here and never there.
  ///
  /// [priceInStars] is display text for the block card, so the child is told what
  /// the way back in costs rather than only that the door is shut (Art. 1 calls
  /// this a motivation tool). It is formatted by the caller because star
  /// formatting is a localisation concern and Kotlin has no access to the ARB
  /// files.
  ///
  /// **One method, always the whole state.**
  ///
  /// There was a version of this with a cheap variant that skipped the package
  /// query — the balance changes on every answered card and the list changes only
  /// when a parent edits it, so the query looked like waste. It is not: a partial
  /// push has to send *something* for the field it skips, and sending an empty
  /// list would silently unblock every game on the phone. The engine cannot tell
  /// a deliberate empty list from a forgotten one. So the state crosses the
  /// channel whole or not at all, and the extra query is the price of that being
  /// true by construction rather than by review.
  Future<void> sync({
    required SettingsRow settings,
    required DayProgress progress,
    required StarRules rules,
    String priceInStars = '',
  }) async {
    await _channel.push(
      // Article 15.2 — opt-in, and with it off the engine allows everything and
      // the watchdog stands down. That is the state the twelve Play testers are
      // in for fourteen continuous days.
      enabled: settings.blockingEnabled,
      blockedPackages: await blockedPackages(),
      remainingPlaySeconds: progress.remainingPlaySeconds(rules),
      playPaused: settings.playPaused,
      priceInStars: priceInStars,
      uninstallGuard: settings.uninstallGuard,
    );
  }
}
