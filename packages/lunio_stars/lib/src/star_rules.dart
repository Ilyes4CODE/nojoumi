/// One star, in internal units.
///
/// The contract awards half stars (Article 5: "بطاقة في مراجعة لاحقة = 0.5"),
/// and the appendix lets one star be worth as little as half a minute. Floating
/// point would accumulate error across a school term, so the ledger is integer
/// units throughout and 1 star = 100 units.
const int starUnit = 100;

/// Convenience for reading tests and logs.
double unitsToStars(int units) => units / starUnit;
int starsToUnits(num stars) => (stars * starUnit).round();

/// The award amounts of Article 5.
///
/// These are **not** parent-adjustable. Article 6 says the numeric values are
/// adjustable "within a defined range, detailed in the appendix", and the
/// appendix's §5 table lists exactly six settings — none of which is an award
/// amount. So these are constants, and [StarRules] holds the six that move.
class Article5 {
  const Article5._();

  /// "بطاقة حفظ صحيحة (أول مرة) = 1"
  static const int memorizeCardFirstTime = 1 * starUnit;

  /// "بطاقة في مراجعة لاحقة = 0.5"
  static const int cardInLaterReview = starUnit ~/ 2;

  /// "سؤال مراجعة صحيح = 2"
  static const int reviewQuestion = 2 * starUnit;

  /// "إكمال الجلسة اليومية كاملة = 5+ مكافأة"
  static const int fullSessionBonus = 5 * starUnit;

  /// "يومان متتاليان دون انقطاع (مواظبة) = 3+"
  static const int streakBonus = 3 * starUnit;

  /// Weekly test scale, "10 – 40 حسب النتيجة".
  static const int weeklyTestBelow50 = 10 * starUnit;
  static const int weeklyTest50to74 = 20 * starUnit;
  static const int weeklyTest75to89 = 30 * starUnit;
  static const int weeklyTest90plus = 40 * starUnit;

  /// The streak in Article 5 is "two consecutive days"; the bonus is granted on
  /// each day that continues an unbroken run of at least this many days.
  static const int streakMinimumDays = 2;
}

/// What expires, and when — appendix §5, "انتهاء صلاحية الرصيد".
enum ExpiryMode {
  /// Article 6's default: "الرصيد غير المستعمل ينتهي في نهاية اليوم".
  daily,

  /// The appendix offers this as a parent choice.
  weekly,
}

/// The six settings the parent controls, from appendix §5.
///
/// Values outside the appendix's published ranges are rejected rather than
/// clamped: a silently clamped value is a contract violation that nobody
/// notices, and an exception is one that shows up in a test.
class StarRules {
  StarRules({
    this.starValueSeconds = 60,
    this.dailyCeilingUnits = 60 * starUnit,
    this.minimumTimeOnTargetMs = 1500,
    this.expiryMode = ExpiryMode.daily,
    this.welcomeUnits = 10 * starUnit,
    this.dailySessionCards = 0,
    this.dailyQuestionCount = 5,
  }) {
    _validate();
  }

  /// "قيمة النجمة الواحدة بالدقائق" — default 1 minute, range 0.5 – 3.
  ///
  /// Held in seconds and restricted to half-minute steps. The appendix gives a
  /// range but no step; half-minute steps are how the range is written
  /// (0.5 – 3), and they keep every conversion in this package exact, because
  /// award amounts are always multiples of 50 units.
  final int starValueSeconds;

  /// "السقف اليومي للنجوم" — default 60 stars, range 20 – 150.
  ///
  /// This is also the daily play cap: Article 2 lets the parent set daily play
  /// time, and the appendix does not list it as a separate setting, so play
  /// minutes are this ceiling expressed in minutes — one stored value, two
  /// presentations. See docs/decisions.md D-2.
  final int dailyCeilingUnits;

  /// "الحد الأدنى للوقت على البطاقة" — default 1.5 s, range 1 – 5 s.
  final int minimumTimeOnTargetMs;

  /// "انتهاء صلاحية الرصيد" — default end of day.
  final ExpiryMode expiryMode;

  /// "رصيد ترحيبي عند البداية" — default 10 stars, range 0 – 30.
  final int welcomeUnits;

  /// "حجم الجلسة اليومية" — appendix §5 range 5 – 30, **amended to 0 – 30 and
  /// defaulted to 0 on 2026-08-31** at the client's request: the day is
  /// questions only, with no memorization cards.
  ///
  /// At 0, Article 5's first two rows earn nothing because nothing presents
  /// them — 1 star for a card answered first time, and 0.5 on a later review.
  /// Article 2's spaced repetition has nothing to schedule, and Article 4.3's
  /// memorize step does not happen. **None of that machinery was deleted**;
  /// setting this back to 12 restores all of it, which is the reason the change
  /// was made as a value rather than as a new flag. See decisions.md D-85.
  final int dailySessionCards;

  /// Not in the appendix's table; its worked example uses 5 review questions.
  /// See docs/decisions.md D-15.
  final int dailyQuestionCount;

  /// The daily ceiling expressed the way Article 2 words it.
  int get dailyPlayCapSeconds => dailyCeilingUnits * starValueSeconds ~/ starUnit;

  /// Playable seconds for a balance, exact by construction: award amounts are
  /// multiples of 50 units and [starValueSeconds] is a multiple of 30, so the
  /// division never leaves a remainder.
  int playableSecondsFor(int units) => units * starValueSeconds ~/ starUnit;

  void _validate() {
    void check(bool ok, String what) {
      if (!ok) throw ArgumentError('StarRules: $what');
    }

    check(
      starValueSeconds >= 30 && starValueSeconds <= 180,
      'star value must be 0.5–3 minutes (appendix §5), got '
      '${starValueSeconds / 60} min',
    );
    check(
      starValueSeconds % 30 == 0,
      'star value must be in half-minute steps, got ${starValueSeconds}s',
    );
    check(
      dailyCeilingUnits >= 20 * starUnit && dailyCeilingUnits <= 150 * starUnit,
      'daily ceiling must be 20–150 stars (appendix §5), got '
      '${unitsToStars(dailyCeilingUnits)}',
    );
    check(
      dailyCeilingUnits % starUnit == 0,
      'daily ceiling must be a whole number of stars',
    );
    check(
      minimumTimeOnTargetMs >= 1000 && minimumTimeOnTargetMs <= 5000,
      'minimum time on card must be 1–5 s (appendix §5), got '
      '${minimumTimeOnTargetMs}ms',
    );
    check(
      welcomeUnits >= 0 && welcomeUnits <= 30 * starUnit,
      'welcome balance must be 0–30 stars (appendix §5), got '
      '${unitsToStars(welcomeUnits)}',
    );
    check(
      welcomeUnits % starUnit == 0,
      'welcome balance must be a whole number of stars',
    );
    // **0 is a contract amendment, and it is deliberate.**
    //
    // Appendix §5 publishes this range as 5–30, and the floor of 5 is what
    // guarantees Article 5's first two rows — 1 star for a memorization card
    // answered first time, 0.5 on a later review — are reachable at all. The
    // client asked on 2026-08-31 for the cards to be removed and the day to be
    // questions only, which is precisely what a session size of 0 expresses.
    //
    // It is written as a *value in the published range* rather than as a new
    // flag on purpose: this way the change is one number a parent can set back,
    // the card machinery and `lunio_sm2` stay alive and tested, and nothing had
    // to be deleted to satisfy a request the client may reverse. See
    // decisions.md D-85 for what stops being earnable while it is 0.
    check(
      dailySessionCards >= 0 && dailySessionCards <= 30,
      'daily session size must be 0–30 cards (appendix §5, amended 2026-08-31 '
      'to allow 0), got $dailySessionCards',
    );
    check(
      dailyQuestionCount >= 0 && dailyQuestionCount <= 15,
      'daily question count must be 0–15 (decisions.md D-15), got '
      '$dailyQuestionCount',
    );
  }

  StarRules copyWith({
    int? starValueSeconds,
    int? dailyCeilingUnits,
    int? minimumTimeOnTargetMs,
    ExpiryMode? expiryMode,
    int? welcomeUnits,
    int? dailySessionCards,
    int? dailyQuestionCount,
  }) {
    return StarRules(
      starValueSeconds: starValueSeconds ?? this.starValueSeconds,
      dailyCeilingUnits: dailyCeilingUnits ?? this.dailyCeilingUnits,
      minimumTimeOnTargetMs:
          minimumTimeOnTargetMs ?? this.minimumTimeOnTargetMs,
      expiryMode: expiryMode ?? this.expiryMode,
      welcomeUnits: welcomeUnits ?? this.welcomeUnits,
      dailySessionCards: dailySessionCards ?? this.dailySessionCards,
      dailyQuestionCount: dailyQuestionCount ?? this.dailyQuestionCount,
    );
  }
}
