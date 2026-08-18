import 'package:drift/drift.dart';

/// The local database schema. **Every byte about the child lives here and
/// nowhere else** (Art. 14: "البيانات على الجهاز: النجوم والمهام والتقدّم
/// والملخّصات كلها محفوظة محلياً على الهاتف فقط").
///
/// Three rules run through the whole schema:
///
///  1. **No child identifier.** No name, no photo, no birth date, no location.
///     `grade` is the only pedagogical field, and a school level is not an
///     identity (Art. 14, decisions.md D-11).
///  2. **Integers, never doubles.** Stars are `starUnits` at 100 per star and
///     play time is whole seconds (AD-3). A REAL column holding a balance would
///     reintroduce exactly the drift the pure packages exist to prevent.
///  3. **Time is a stored value with its provenance.** Every timestamp is epoch
///     milliseconds *plus* the trust level it was recorded under, because
///     Art. 6.8 makes "which clock said so" part of the record.

/// How much a recorded instant can be trusted, mirroring `TrustLevel`.
enum TrustLevelRow { serverAnchored, monotonic, untrusted }

/// What the parent has decided about an installed app.
enum AppPolicy {
  /// Always launchable, and shown on the child's home screen.
  allowed,

  /// A game or distracting app: launchable only while play time remains.
  blockedGame,

  /// Hidden from the child's home screen entirely.
  hidden,

  /// Never blockable — Nojoumi itself, Settings, the dialer, the current IME.
  /// A parental-control app that can lock the parent out of Settings has bricked
  /// the phone (decisions.md D-9).
  protected,
}

enum TaskKind { memorize, review, exercise }

enum TaskState { pending, answered, skipped }

/// Why an attempt earned nothing, mirroring `Rejection` in nojoumi_stars.
enum RejectionRow {
  none,
  untrustedClock,
  wrongAnswer,
  solutionRevealed,
  notFirstAttempt,
  alreadyCountedToday,
  belowMinimumTime,
  dailyCeilingReached,
  alreadyAwardedToday,
  sessionIncomplete,
  streakTooShort,
}

/// Every kind of row the star ledger can hold (AD-4).
enum LedgerKind {
  cardFirstTime,
  cardReview,
  reviewQuestion,
  sessionBonus,
  streakBonus,
  weeklyTest,
  welcomeGrant,
  parentGrant,
  parentDeduct,
  expiry,
}

enum SubscriptionStateRow { trial, active, grace, expired, refunded }

enum ExpiryModeRow { daily, weekly }

enum PlayEndReason {
  balanceExhausted,
  screenOff,
  leftApp,
  parentPaused,
  dayRollover,
}

/// Singleton row (id is always 1). Holds every parent-adjustable number from
/// appendix §5, and nothing else.
@DataClassName('SettingsRow')
class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  // --- The parent's PIN. Salted hash only, never recoverable (D-10). --------
  TextColumn get pinHash => text().withDefault(const Constant(''))();
  TextColumn get pinSalt => text().withDefault(const Constant(''))();

  // --- Appendix §5, with the published defaults ----------------------------
  /// 0.5–3 minutes, in half-minute steps (D-20). Default 1 minute.
  IntColumn get starValueSeconds => integer().withDefault(const Constant(60))();

  /// 20–150 stars, in units. Default 60 stars.
  IntColumn get dailyCeilingUnits =>
      integer().withDefault(const Constant(6000))();

  /// 1–5 seconds. Default 1.5 s.
  IntColumn get minimumTimeOnTargetMs =>
      integer().withDefault(const Constant(1500))();

  IntColumn get expiryMode =>
      intEnum<ExpiryModeRow>().withDefault(const Constant(0))();

  /// 0–30 stars, in units. Default 10 stars. Granted once, ever.
  IntColumn get welcomeUnits => integer().withDefault(const Constant(1000))();
  BoolColumn get welcomeGranted =>
      boolean().withDefault(const Constant(false))();

  /// 5–30 cards. Default 12.
  IntColumn get dailySessionCards => integer().withDefault(const Constant(12))();

  /// 0–15 questions. Default 5 (D-15).
  IntColumn get dailyQuestionCount =>
      integer().withDefault(const Constant(5))();

  /// Which weekday closes the week for the test and the purge (D-13, Friday).
  IntColumn get expiryWeekday => integer().withDefault(const Constant(5))();

  // --- Art. 15.2: both opt-in, and the app is fully usable with both off, so
  // the 12 Play testers can evaluate it on their own phones. ----------------
  BoolColumn get blockingEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get launcherMode => boolean().withDefault(const Constant(false))();

  /// Appendix §4 — the parent may pause play without destroying the balance.
  BoolColumn get playPaused => boolean().withDefault(const Constant(false))();

  /// School level, e.g. «السنة الرابعة ابتدائي». Not an identifier (D-11).
  TextColumn get grade => text().withDefault(const Constant(''))();

  /// How far the setup wizard has progressed.
  IntColumn get onboardingStep => integer().withDefault(const Constant(0))();

  /// Minutes east of UTC. Injected into DayKey rather than read from the device,
  /// so a timezone change cannot silently move the day boundary.
  IntColumn get utcOffsetMinutes => integer().withDefault(const Constant(60))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Installed apps the parent has classified.
@DataClassName('ManagedAppRow')
class ManagedApps extends Table {
  TextColumn get packageName => text().withLength(min: 1, max: 255)();
  TextColumn get label => text().withDefault(const Constant(''))();
  IntColumn get policy => intEnum<AppPolicy>()();
  BoolColumn get isGameByStore =>
      boolean().withDefault(const Constant(false))();
  IntColumn get addedAtMs => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {packageName};
}

/// One captured lesson. The **summary survives** the weekly purge (Art. 14).
@DataClassName('LessonRow')
class Lessons extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get subject => text().withDefault(const Constant(''))();
  TextColumn get grade => text().withDefault(const Constant(''))();
  TextColumn get summary => text()();
  IntColumn get createdAtMs => integer()();
  IntColumn get weekKey => integer()();

  /// Set when the weekly purge removed this lesson's images and questions. The
  /// lesson row and its summary are kept — Art. 14 deletes only images and
  /// exercises.
  IntColumn get purgedAtMs => integer().nullable()();
}

/// Captured page images. Deleted from the device after the weekly test
/// (Art. 4.8, Art. 14) — both the file and this row.
@DataClassName('LessonImageRow')
class LessonImages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get lessonId =>
      integer().references(Lessons, #id, onDelete: KeyAction.cascade)();

  /// Absolute path inside the app's private storage. Never shared storage,
  /// never the gallery, never backed up.
  TextColumn get filePath => text()();
  IntColumn get capturedAtMs => integer()();
  IntColumn get deletedAtMs => integer().nullable()();
}

/// Memorization cards. These **survive** the weekly purge (decisions.md D-6):
/// deleting them would make spaced repetition weekly-only and empty a headline
/// feature of Art. 2.
@DataClassName('CardRow')
class Cards extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get lessonId =>
      integer().references(Lessons, #id, onDelete: KeyAction.cascade)();
  TextColumn get front => text()();
  TextColumn get back => text()();

  // --- SM-2 state, mirroring CardSchedule. Ease in permille, never a double.
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  IntColumn get easePermille => integer().withDefault(const Constant(2500))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();

  /// Days since the Unix epoch, matching DayKey. Null means never scheduled.
  IntColumn get dueDay => integer().nullable()();
  IntColumn get lastReviewedDay => integer().nullable()();

  /// When this card was first answered correctly — the difference between
  /// Article 5's 1 star and 0.5 stars.
  IntColumn get firstCorrectAtMs => integer().nullable()();
}

/// Review questions. **Purged weekly** along with the images (Art. 14's
/// "الصور والتمارين").
@DataClassName('QuestionRow')
class Questions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get lessonId =>
      integer().references(Lessons, #id, onDelete: KeyAction.cascade)();
  TextColumn get prompt => text()();

  /// JSON array of choice strings. A child-facing quiz has 2–4 of them; a
  /// separate table would buy nothing and cost a join on every question.
  TextColumn get choicesJson => text()();
  IntColumn get correctIndex => integer()();
  IntColumn get purgedAtMs => integer().nullable()();
}

/// The day's task list, in presentation order.
@DataClassName('TaskInstanceRow')
class TaskInstances extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dayKey => integer()();
  IntColumn get kind => intEnum<TaskKind>()();

  /// Card id or question id, depending on [kind].
  IntColumn get targetId => integer()();
  IntColumn get position => integer()();
  IntColumn get state => intEnum<TaskState>().withDefault(const Constant(0))();
  IntColumn get answeredAtMs => integer().nullable()();
}

/// **The Article 6 evidence table.** Every attempt is recorded, awarded or
/// rejected, with the reason.
///
/// AD-4: Article 6 has nine joint conditions, so when the client asks why a star
/// was not granted, the answer must be a query, not a guess.
@DataClassName('AttemptRow')
class Attempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dayKey => integer()();
  IntColumn get kind => intEnum<TaskKind>()();
  IntColumn get targetId => integer()();
  IntColumn get attemptNumber => integer()();
  BoolColumn get correct => boolean()();
  IntColumn get msOnTarget => integer()();
  BoolColumn get solutionRevealed =>
      boolean().withDefault(const Constant(false))();
  IntColumn get awardedUnits => integer().withDefault(const Constant(0))();
  IntColumn get rejection =>
      intEnum<RejectionRow>().withDefault(const Constant(0))();
  BoolColumn get cappedByCeiling =>
      boolean().withDefault(const Constant(false))();
  IntColumn get atMs => integer()();
  IntColumn get trustLevel => intEnum<TrustLevelRow>()();
}

/// The append-only star ledger (AD-4). Balance is **derived** from these rows,
/// never patched in place.
@DataClassName('StarLedgerRow')
class StarLedger extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dayKey => integer()();
  IntColumn get kind => intEnum<LedgerKind>()();

  /// Signed: positive for an award, negative for a deduction or expiry.
  IntColumn get starUnits => integer()();
  IntColumn get balanceAfterUnits => integer()();

  /// Card id, question id, weekly-test id, or null for a parent action.
  IntColumn get sourceRef => integer().nullable()();
  IntColumn get atMs => integer()();
  IntColumn get trustLevel => intEnum<TrustLevelRow>()();
  TextColumn get note => text().withDefault(const Constant(''))();
}

/// One row per child-day, mirroring `DayProgress`.
@DataClassName('DayProgressRow')
class DayProgressRows extends Table {
  IntColumn get dayKey => integer()();

  /// Earned by the child. Counts against the daily ceiling.
  IntColumn get earnedUnits => integer().withDefault(const Constant(0))();

  /// Parent grants, welcome balance, weekly test, carried-over balance. Exempt
  /// from the ceiling — the parent's authority is "فوق النظام" (appendix §4).
  IntColumn get grantedUnits => integer().withDefault(const Constant(0))();

  IntColumn get usedPlaySeconds => integer().withDefault(const Constant(0))();
  IntColumn get tasksTotal => integer().withDefault(const Constant(0))();
  IntColumn get tasksAnswered => integer().withDefault(const Constant(0))();
  BoolColumn get sessionBonusAwarded =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get streakBonusAwarded =>
      boolean().withDefault(const Constant(false))();
  IntColumn get expiredAtMs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {dayKey};
}

/// Article 6.2 — "ألّا تكون البطاقة أو السؤال قد احتُسب في اليوم ذاته".
///
/// A table rather than a JSON blob on the day row, so the check is an indexed
/// lookup and the history stays queryable.
@DataClassName('CountedTargetRow')
class CountedTargets extends Table {
  IntColumn get dayKey => integer()();
  IntColumn get kind => intEnum<TaskKind>()();
  IntColumn get targetId => integer()();
  IntColumn get atMs => integer()();

  @override
  Set<Column> get primaryKey => {dayKey, kind, targetId};
}

/// Singleton. Article 5's attendance streak, Article 6.6's reset rule.
@DataClassName('StreakRow')
class StreakStates extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get lastActiveDay => integer().nullable()();
  IntColumn get consecutiveDays => integer().withDefault(const Constant(0))();
  IntColumn get best => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Weekly tests. **Results survive** the purge (Art. 14).
@DataClassName('WeeklyTestRow')
class WeeklyTests extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get weekKey => integer()();
  IntColumn get startedAtMs => integer()();
  IntColumn get finishedAtMs => integer().nullable()();
  IntColumn get totalQuestions => integer().withDefault(const Constant(0))();
  IntColumn get correctAnswers => integer().withDefault(const Constant(0))();

  /// Percentage times 100, so 87.5% is stored as 8750. Integer, like everything
  /// else a contract number depends on.
  IntColumn get percentBasisPoints =>
      integer().withDefault(const Constant(0))();
  IntColumn get awardedUnits => integer().withDefault(const Constant(0))();

  /// Set when the automatic deletion that follows the test has completed
  /// (Art. 11.6). Null means the purge still owes work.
  IntColumn get purgeDoneAtMs => integer().nullable()();
}

@DataClassName('WeeklyTestItemRow')
class WeeklyTestItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get testId =>
      integer().references(WeeklyTests, #id, onDelete: KeyAction.cascade)();

  /// Snapshotted, because the question itself is purged after the test but the
  /// result must remain explainable.
  TextColumn get promptSnapshot => text()();
  BoolColumn get correct => boolean()();
  IntColumn get answeredAtMs => integer()();
}

/// One period of actual play. Appendix §2: the counter runs during real play
/// only, stops on screen-off or leaving the game, and resumes on return.
@DataClassName('PlaySessionRow')
class PlaySessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get packageName => text()();
  IntColumn get dayKey => integer()();
  IntColumn get startedAtMs => integer()();
  IntColumn get endedAtMs => integer().nullable()();

  /// Measured foreground seconds, not a wall-clock difference. This is what
  /// makes the appendix's "الطفل لا يخسر دقائق وهو لا يلعب" exact.
  IntColumn get secondsConsumed => integer().withDefault(const Constant(0))();
  IntColumn get endReason => intEnum<PlayEndReason>().nullable()();
}

/// Singleton. The signed subscription snapshot of Art. 7.6.
@DataClassName('SubscriptionCacheRow')
class SubscriptionCaches extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  /// The exact canonical JSON the server signed. Stored verbatim, because
  /// re-serialising it locally would change the bytes and break verification.
  TextColumn get payloadJson => text().withDefault(const Constant(''))();
  TextColumn get signatureHex => text().withDefault(const Constant(''))();

  /// Trusted time at which this was fetched — the anchor for the 7-day offline
  /// window. Storing an untrusted timestamp here would let a child extend the
  /// window by moving the clock.
  IntColumn get fetchedAtMs => integer().nullable()();

  // Denormalised for cheap reads. The signed payload remains the authority.
  IntColumn get state =>
      intEnum<SubscriptionStateRow>().withDefault(const Constant(3))();
  TextColumn get plan => text().withDefault(const Constant(''))();
  IntColumn get endsAtMs => integer().nullable()();
  IntColumn get graceEndsAtMs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Singleton. Everything `TrustedClock` must remember across process death and
/// reboots (Art. 6.8, Art. 7.6).
@DataClassName('ClockStateRow')
class ClockStates extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get anchorServerEpochMs => integer().nullable()();
  IntColumn get anchorElapsedRealtimeMs => integer().nullable()();
  TextColumn get anchorBootId => text().nullable()();

  /// The latest instant ever resolved. Forward-only: this single value is what
  /// makes "set the clock back to replay yesterday" pointless.
  IntColumn get highWaterEpochMs => integer().withDefault(const Constant(0))();
  TextColumn get lastBootId => text().nullable()();
  IntColumn get lastElapsedRealtimeMs =>
      integer().withDefault(const Constant(0))();
  IntColumn get tamperCount => integer().withDefault(const Constant(0))();
  TextColumn get lastTamperSignal => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Diagnostics for the parent's dashboard and for the developer's support
/// questions. **Never** lesson content, never image bytes (Art. 14).
@DataClassName('EventLogRow')
class EventLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  TextColumn get detail => text().withDefault(const Constant(''))();
  IntColumn get atMs => integer()();
}
