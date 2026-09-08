import 'package:lunio_stars/lunio_stars.dart';
import 'package:lunio_time/lunio_time.dart';

/// Algeria, UTC+1, no DST.
const int dz = DayKey.algeriaUtcOffsetMinutes;

int utcMs(int y, int m, int d, [int h = 0, int min = 0]) =>
    DateTime.utc(y, m, d, h, min).millisecondsSinceEpoch;

/// A trusted instant. Tests that care about trust pass the level explicitly.
TrustedInstant trusted({
  int? epochMs,
  TrustLevel level = TrustLevel.serverAnchored,
}) =>
    TrustedInstant(epochMs: epochMs ?? utcMs(2026, 8, 14, 16), level: level);

/// The anchor day for every test in this package: Friday 2026-08-14.
final DayKey theDay =
    DayKey.fromEpochMs(utcMs(2026, 8, 14, 16), utcOffsetMinutes: dz);

DayProgress today({
  int earnedUnits = 0,
  int grantedUnits = 0,
  int usedPlaySeconds = 0,
  Set<String> counted = const <String>{},
  int tasksTotal = 0,
  int tasksAnswered = 0,
  bool sessionBonusAwarded = false,
  bool streakBonusAwarded = false,
  DayKey? day,
}) =>
    DayProgress(
      dayKey: day ?? theDay,
      earnedUnits: earnedUnits,
      grantedUnits: grantedUnits,
      usedPlaySeconds: usedPlaySeconds,
      countedTargetIds: counted,
      tasksTotal: tasksTotal,
      tasksAnswered: tasksAnswered,
      sessionBonusAwarded: sessionBonusAwarded,
      streakBonusAwarded: streakBonusAwarded,
    );

/// An attempt that satisfies every Article 6 condition, so each test can break
/// exactly one of them and see that condition alone reported.
Attempt goodAttempt({
  EarnKind kind = EarnKind.memorizeCardFirstTime,
  String targetId = 'card-1',
  int attemptNumber = 1,
  bool correct = true,
  int msOnTarget = 3000,
  bool solutionRevealed = false,
}) =>
    Attempt(
      targetId: targetId,
      kind: kind,
      attemptNumber: attemptNumber,
      correct: correct,
      msOnTarget: msOnTarget,
      solutionRevealed: solutionRevealed,
    );
