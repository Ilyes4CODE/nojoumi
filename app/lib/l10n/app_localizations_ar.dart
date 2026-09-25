// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppL10nAr extends AppL10n {
  AppL10nAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'Lunio';

  @override
  String get starsBalance => 'رصيدك';

  @override
  String get starsUnit => 'نجمة';

  @override
  String get minutesUnit => 'دقيقة';

  @override
  String get playTimeRemaining => 'وقت اللعب المتبقّي';

  @override
  String get todayTasks => 'مهام اليوم';

  @override
  String get taskMemorize => 'حفظ';

  @override
  String get taskReview => 'مراجعة';

  @override
  String get taskExercise => 'تمرين';

  @override
  String get sessionComplete => 'أنهيتَ مهام اليوم كلها';

  @override
  String sessionBonusEarned(String stars) {
    return 'مكافأة الإكمال: $stars نجوم';
  }

  @override
  String get cardShowAnswer => 'أظهر الجواب';

  @override
  String get cardIKnewIt => 'أعرفها';

  @override
  String get cardIDidNot => 'لم أعرفها';

  @override
  String get answerCorrect => 'إجابة صحيحة';

  @override
  String get answerWrong => 'إجابة خاطئة. ستعود إليها لاحقاً.';

  @override
  String get tryAgainMessage => 'حاول مرة أخرى';

  @override
  String needStarsToPlay(String stars) {
    return 'تحتاج $stars نجمة لتفتح هذه اللعبة';
  }

  @override
  String get blockedTitle => 'وقت اللعب انتهى';

  @override
  String get blockedBody => 'أنجز مهامك لتكسب نجوماً جديدة';

  @override
  String get earnStarsNow => 'اكسب نجوماً الآن';

  @override
  String get playPausedByParent => 'اللعب موقوف مؤقتاً من طرف الوالد';

  @override
  String get weeklyTest => 'الاختبار الأسبوعي';

  @override
  String weeklyTestResult(String percent) {
    return 'نتيجتك: $percent%';
  }

  @override
  String get parentArea => 'لوحة الوالد';

  @override
  String get enterPin => 'أدخل الرمز السري';

  @override
  String get wrongPin => 'الرمز غير صحيح';

  @override
  String get settings => 'الإعدادات';

  @override
  String get starValueMinutes => 'قيمة النجمة بالدقائق';

  @override
  String get dailyStarCeiling => 'السقف اليومي للنجوم';

  @override
  String get minimumCardSeconds => 'الحد الأدنى للوقت على البطاقة';

  @override
  String get dailySessionSize => 'حجم الجلسة اليومية';

  @override
  String get balanceExpiry => 'انتهاء صلاحية الرصيد';

  @override
  String get expiryDaily => 'نهاية اليوم';

  @override
  String get expiryWeekly => 'نهاية الأسبوع';

  @override
  String get grantStars => 'منح نجوم';

  @override
  String get deductStars => 'خصم نجوم';

  @override
  String get pausePlay => 'إيقاف اللعب مؤقتاً';

  @override
  String get managedApps => 'الألعاب والتطبيقات المشتّتة';

  @override
  String get captureLesson => 'التقاط درس';

  @override
  String get captureHintFlat => 'ضع الصفحة مستوية';

  @override
  String get captureHintLight => 'إضاءة جيدة، بلا فلاش';

  @override
  String get captureHintStraight => 'الكاميرا موازية للصفحة';

  @override
  String get processing => 'جارٍ المعالجة…';

  @override
  String get imageUnclear =>
      'الصورة غير واضحة. أعد التصوير بإضاءة أفضل وصفحة مستوية.';

  @override
  String get subscription => 'الاشتراك';

  @override
  String get subscriptionTrial => 'تجريبي';

  @override
  String get subscriptionActive => 'فعّال';

  @override
  String get subscriptionGrace => 'مهلة سماح';

  @override
  String get subscriptionExpired => 'منتهٍ';

  @override
  String get subscriptionRefunded => 'مسترجع';

  @override
  String expiresOn(String date) {
    return 'ينتهي في $date';
  }

  @override
  String get enterActivationCode => 'أدخل رمز التفعيل';

  @override
  String get activate => 'تفعيل';

  @override
  String get freeModeNotice =>
      'توليد الدروس الجديدة متوقّف. الحجب والنجوم والدروس المحفوظة تعمل كما هي.';

  @override
  String get continueAction => 'متابعة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get offlineNotice => 'لا يوجد اتصال بالإنترنت';

  @override
  String get setupTitle => 'إعداد Lunio';

  @override
  String get setupWelcomeTitle => 'أهلاً بك في Lunio';

  @override
  String get setupWelcomeBody =>
      'Lunio يحوّل وقت اللعب إلى شيء يكسبه طفلك بالمذاكرة، لا إلى شيء تسحبه منه. الإعداد ثلاث خطوات، ويمكنك تغيير كل شيء لاحقاً.';

  @override
  String setupStepOf(String current, String total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get setupGradeTitle => 'المستوى الدراسي';

  @override
  String get setupGradeBody =>
      'يُستعمل لتوليد دروس مناسبة للعمر. لا نطلب اسم الطفل ولا صورته ولا تاريخ ميلاده.';

  @override
  String get setupGradeHint => 'مثال: السنة الرابعة ابتدائي';

  @override
  String get setupPinTitle => 'رمز الوالد';

  @override
  String get setupPinBody =>
      'أربعة أرقام على الأقل. يحمي الإعدادات ومنح النجوم. لا يُخزَّن الرمز نفسه، ولا يمكن استرجاعه إلا عبر حسابك على الخادم.';

  @override
  String get setupPinCreate => 'أدخل رمزاً جديداً';

  @override
  String get setupPinConfirm => 'أعد إدخال الرمز';

  @override
  String get setupPinMismatch => 'الرمزان غير متطابقين';

  @override
  String get setupPinTooShort => 'الرمز أربعة أرقام على الأقل';

  @override
  String get setupProtectionTitle => 'الحجب ووضع الشاشة الرئيسية';

  @override
  String get setupProtectionBody =>
      'هاتان الميزتان اختياريتان تماماً، والتطبيق يعمل بكامل مزاياه بدونهما: الدروس والبطاقات والنجوم والاختبار الأسبوعي ولوحة الوالد كلها تعمل.';

  @override
  String get setupEnableBlocking => 'تفعيل حجب الألعاب';

  @override
  String get setupEnableLauncher => 'جعل Lunio الشاشة الرئيسية';

  @override
  String get setupSkipProtection => 'أكمل بدونهما الآن';

  @override
  String get setupDisclosureTitle => 'إفصاح مهم قبل منح الإذن';

  @override
  String get setupDisclosureBody =>
      'لتفعيل الحجب، يحتاج Lunio إلى خدمة إمكانية الوصول (Accessibility). يستعملها التطبيق لغرض واحد فقط: معرفة أي تطبيق ظهر على الشاشة الآن، ليغلق الألعاب المحجوبة عند نفاد وقت اللعب.\n\nلا يقرأ Lunio محتوى الشاشة، ولا كلمات المرور، ولا الرسائل، ولا يسجّل ما تكتبه، ولا يرسل أي شيء من هذا إلى أي خادم. يمكنك إيقاف الخدمة في أي وقت من إعدادات الهاتف.';

  @override
  String get setupDisclosureConsent => 'قرأت الإفصاح وأوافق كوليّ أمر';

  @override
  String get setupDisclosureDecline => 'لا، أكمل بدون حجب';

  @override
  String get setupFinish => 'ابدأ';

  @override
  String get setupDoneTitle => 'كل شيء جاهز';

  @override
  String setupDoneBody(String stars) {
    return 'منحنا طفلك $stars نجمة ترحيبية ليبدأ.';
  }

  @override
  String get homeGreeting => 'مرحباً';

  @override
  String get startSession => 'ابدأ مهام اليوم';

  @override
  String get noTasksYet => 'لا توجد مهام بعد. اطلب من والدك التقاط درس.';

  @override
  String tasksRemaining(String count) {
    return 'بقيت $count مهمة';
  }

  @override
  String get dailyCeilingReached => 'بلغتَ سقف اليوم. عد غداً.';

  @override
  String streakDays(String days) {
    return 'مواظبة $days يوم';
  }

  @override
  String get clockUntrustedTitle => 'ساعة الهاتف غير موثوقة';

  @override
  String get clockUntrustedBody =>
      'تغيّر تاريخ الهاتف أو ساعته. لا يمكن كسب نجوم جديدة حتى تعود الساعة إلى الضبط التلقائي. النجوم المكسوبة سابقاً ووقت اللعب المتبقّي لم يتأثّرا.';

  @override
  String get fixClockAction => 'افتح إعدادات التاريخ والوقت';

  @override
  String get next => 'التالي';

  @override
  String get back => 'رجوع';

  @override
  String get skip => 'تخطٍّ';

  @override
  String get notNow => 'ليس الآن';

  @override
  String pinLockedFor(String seconds) {
    return 'محاولات كثيرة. أعد المحاولة بعد $seconds ثانية.';
  }

  @override
  String get parentOverview => 'نظرة عامة';

  @override
  String get parentStarsToday => 'نجوم اليوم';

  @override
  String get parentEarnedToday => 'كسبها الطفل';

  @override
  String get parentGrantedToday => 'منحتَها أنت';

  @override
  String get parentCeilingUsed => 'من السقف اليومي';

  @override
  String get parentPlayUsed => 'وقت اللعب المستهلك';

  @override
  String get parentStreak => 'المواظبة';

  @override
  String get parentAdjustTitle => 'منح أو خصم';

  @override
  String get parentAdjustBody =>
      'سلطتك فوق النظام: المنح والخصم لا يخضعان للسقف اليومي، ويعملان حتى لو كانت ساعة الهاتف غير موثوقة.';

  @override
  String get parentAdjustAmount => 'عدد النجوم';

  @override
  String get parentAdjustNote => 'السبب (اختياري)';

  @override
  String parentGrantDone(String stars) {
    return 'مُنحت $stars نجمة';
  }

  @override
  String parentDeductDone(String stars) {
    return 'خُصمت $stars نجمة';
  }

  @override
  String get parentDeductTooMuch => 'لا يمكن خصم أكثر من الرصيد الحالي';

  @override
  String get parentSettingsTitle => 'الأرقام التي تتحكّم فيها';

  @override
  String get parentSettingsBody =>
      'كل قيمة هنا لها مدى محدّد في ملحق العقد. القيم خارج المدى تُرفض ولا تُقرّب.';

  @override
  String parentRangeHint(String min, String max) {
    return 'من $min إلى $max';
  }

  @override
  String get parentDailyPlayMinutes => 'دقائق اللعب اليومية';

  @override
  String get parentDailyPlayHint => 'السقف اليومي × قيمة النجمة';

  @override
  String get parentQuestionsPerDay => 'عدد أسئلة المراجعة يومياً';

  @override
  String get parentWelcomeBalance => 'الرصيد الترحيبي';

  @override
  String get parentExpiryWeekday => 'يوم الاختبار الأسبوعي';

  @override
  String get parentPlayPausedOn => 'اللعب موقوف الآن';

  @override
  String get parentPlayPausedOff => 'اللعب مسموح';

  @override
  String get parentBlockingSection => 'الحجب والشاشة الرئيسية';

  @override
  String get parentLedgerTitle => 'سجلّ النجوم';

  @override
  String get parentLedgerEmpty => 'لا حركات بعد';

  @override
  String get parentWhyNoStar => 'لماذا لم تُمنح نجمة؟';

  @override
  String get parentSaved => 'حُفظ';

  @override
  String parentInvalidValue(String reason) {
    return 'قيمة غير مقبولة: $reason';
  }

  @override
  String get ledgerCardFirstTime => 'بطاقة صحيحة أول مرة';

  @override
  String get ledgerCardReview => 'بطاقة في مراجعة';

  @override
  String get ledgerReviewQuestion => 'سؤال مراجعة صحيح';

  @override
  String get ledgerSessionBonus => 'مكافأة إكمال الجلسة';

  @override
  String get ledgerStreakBonus => 'مكافأة المواظبة';

  @override
  String get ledgerWeeklyTest => 'الاختبار الأسبوعي';

  @override
  String get ledgerWelcomeGrant => 'رصيد ترحيبي';

  @override
  String get ledgerParentGrant => 'منحة من الوالد';

  @override
  String get ledgerParentDeduct => 'خصم من الوالد';

  @override
  String get ledgerExpiry => 'انتهاء صلاحية الرصيد';

  @override
  String get weekdayMonday => 'الاثنين';

  @override
  String get weekdayTuesday => 'الثلاثاء';

  @override
  String get weekdayWednesday => 'الأربعاء';

  @override
  String get weekdayThursday => 'الخميس';

  @override
  String get weekdayFriday => 'الجمعة';

  @override
  String get weekdaySaturday => 'السبت';

  @override
  String get weekdaySunday => 'الأحد';

  @override
  String get rejectUntrustedClock => 'ساعة الهاتف غير موثوقة (المادة 6.8)';

  @override
  String get rejectWrongAnswer => 'إجابة خاطئة (المادة 6.1)';

  @override
  String get rejectSolutionRevealed => 'كُشف الحل قبل الإجابة (المادة 6.1)';

  @override
  String get rejectNotFirstAttempt => 'ليست المحاولة الأولى (المادة 6.1)';

  @override
  String get rejectAlreadyCountedToday => 'احتُسبت في اليوم نفسه (المادة 6.2)';

  @override
  String get rejectBelowMinimumTime =>
      'الوقت على البطاقة أقل من الحد الأدنى (المادة 6.3)';

  @override
  String get rejectDailyCeilingReached => 'استُنفد السقف اليومي (المادة 6.4)';

  @override
  String get rejectAlreadyAwardedToday => 'مُنحت هذه المكافأة اليوم';

  @override
  String get rejectSessionIncomplete => 'الجلسة اليومية لم تكتمل (المادة 6.5)';

  @override
  String get rejectStreakTooShort =>
      'المواظبة أقل من يومين متتاليين (المادة 5)';

  @override
  String get accountTitle => 'حساب الوالد';

  @override
  String get accountWhy =>
      'الحساب لازم لتوليد دروس جديدة فقط. الحجب والنجوم والدروس المحفوظة تعمل بدونه.';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get phoneOptional => 'رقم الهاتف (اختياري)';

  @override
  String get noAccountYet => 'ليس لديك حساب؟ أنشئ واحداً';

  @override
  String get haveAccountAlready => 'لديك حساب؟ سجّل الدخول';

  @override
  String signedInAs(String email) {
    return 'مسجَّل الدخول بـ$email';
  }

  @override
  String get signInRequired => 'سجّل الدخول لتوليد درس جديد';

  @override
  String get serverNotConfigured => 'لم يُضبط عنوان الخادم في هذه النسخة.';

  @override
  String get captureFromCamera => 'التقط بالكاميرا';

  @override
  String get captureFromGallery => 'اختر من المعرض';

  @override
  String get captureIntro =>
      'صوّر صفحة واحدة من كتاب طفلك. تُرسَل الصورة للمعالجة ثم تُحذف من الخادم فوراً، ولا تُحفظ إلا على هذا الهاتف.';

  @override
  String get processingHint => 'قد تستغرق بضع ثوانٍ';

  @override
  String get reviewLesson => 'مراجعة الدرس';

  @override
  String get summaryHeading => 'الملخّص';

  @override
  String get cardsHeading => 'بطاقات الحفظ';

  @override
  String get questionsHeading => 'أسئلة المراجعة';

  @override
  String get lessonTitleLabel => 'عنوان الدرس';

  @override
  String get lessonTitleHint => 'مثال: الحروف العربية';

  @override
  String get subjectOptional => 'المادة (اختياري)';

  @override
  String get saveLesson => 'حفظ الدرس';

  @override
  String get discardLesson => 'تجاهل';

  @override
  String lessonSaved(String cards, String questions) {
    return 'حُفظ الدرس: $cards بطاقة و$questions سؤال';
  }

  @override
  String get retakePhoto => 'أعد التصوير';

  @override
  String get lessonsTitle => 'الدروس';

  @override
  String get lessonsEmpty => 'لم يُلتقط أي درس بعد';

  @override
  String lessonCardsCount(String count) {
    return '$count بطاقة';
  }

  @override
  String get imagesDeleted => 'حُذفت الصور';

  @override
  String get untitledLesson => 'درس بلا عنوان';

  @override
  String get purgeDoneTitle => 'حُذفت صور هذا الأسبوع';

  @override
  String get purgeDoneBody =>
      'حُذفت الصور والتمارين من الهاتف. الملخّصات والبطاقات والنتائج محفوظة.';

  @override
  String get weeklyTestDue => 'حان موعد الاختبار الأسبوعي';

  @override
  String get weeklyTestStart => 'ابدأ الاختبار';

  @override
  String get subscriptionPlan => 'الخطة';

  @override
  String get subscriptionDaysLeft => 'الأيام المتبقّية';

  @override
  String get startTrial => 'ابدأ الفترة التجريبية';

  @override
  String get trialOncePerDevice => 'سبعة أيام، مرّة واحدة لكل جهاز';

  @override
  String get activationHelp => 'تحصل على الرمز بعد الدفع على صفحة الويب.';

  @override
  String get renewNotice => 'للتجديد، استعمل صفحة الدفع المرتبطة بحسابك.';

  @override
  String get activationDone => 'تمّ التفعيل';

  @override
  String get planMonthly => 'شهرية';

  @override
  String get planAnnual => 'سنوية';

  @override
  String get planTrial => 'تجريبية';

  @override
  String get aiPausedTitle => 'توليد الدروس الجديدة متوقّف';

  @override
  String get blockingTitle => 'الحجب والألعاب';

  @override
  String get blockingIntro =>
      'يمنع Lunio فتح الألعاب التي تختارها عندما ينفد وقت اللعب. باقي الهاتف يبقى مفتوحًا كالعادة.';

  @override
  String get blockingUnavailable =>
      'الحجب متاح على أندرويد فقط. باقي التطبيق يعمل هنا بشكل كامل.';

  @override
  String get blockingEnableSwitch => 'تفعيل حجب الألعاب';

  @override
  String get blockingReady => 'الحجب يعمل';

  @override
  String get blockingIncomplete => 'ينقص إذن واحد على الأقل';

  @override
  String get blockingOff => 'الحجب موقوف';

  @override
  String get permAccessibility => 'خدمة إمكانية الوصول';

  @override
  String get permAccessibilityBody =>
      'بدونها لا يعرف Lunio أي تطبيق فُتح، ولا يُحجب شيء.';

  @override
  String get permOverlay => 'الرسم فوق التطبيقات';

  @override
  String get permOverlayBody =>
      'بدونها يعود الهاتف إلى الشاشة الرئيسية دون أن يفهم الطفل السبب.';

  @override
  String get permNotifications => 'الإشعارات';

  @override
  String get permNotificationsBody => 'إشعار دائم صامت يبقي محرّك الحجب حيًّا.';

  @override
  String get permAutostart => 'التشغيل التلقائي';

  @override
  String permAutostartBody(String brand) {
    return 'على أجهزة $brand قد يمنع النظام عودة الحجب بعد إعادة التشغيل ما لم تسمح بذلك يدويًا.';
  }

  @override
  String get permGranted => 'مُفعّل';

  @override
  String get permMissing => 'مطلوب';

  @override
  String get permOpen => 'افتح';

  @override
  String get blockingApps => 'الألعاب المحجوبة';

  @override
  String blockingAppsCount(String count) {
    return '$count تطبيق محجوب';
  }

  @override
  String get blockingAppsEmpty => 'لم تختر أي لعبة بعد';

  @override
  String get blockingAppsHint =>
      'اختر التطبيقات التي تريد أن تكلّف نجومًا. البقية تبقى مفتوحة دائمًا.';

  @override
  String get blockingAppsSearch => 'ابحث عن تطبيق';

  @override
  String get blockingAppsLoading => 'جارٍ قراءة التطبيقات المثبّتة';

  @override
  String get blockingProtectedNote =>
      'الإعدادات والهاتف والرسائل ولوحة المفاتيح وLunio نفسه لا يمكن حجبها أبدًا.';

  @override
  String blockingDeviceLine(String brand, String sdk) {
    return '$brand · أندرويد API $sdk';
  }

  @override
  String get setupWelcomeHeadline => 'أهلاً بك في';

  @override
  String get setupWelcomeLine1 => 'حوّل وقت اللعب إلى وقت مفيد وممتع.';

  @override
  String get setupWelcomeLine2 =>
      'مع Lunio، يتعلّم طفلك خطوة بخطوة من خلال أنشطة بسيطة وتفاعلية مناسبة لمستواه العمري.';

  @override
  String get setupWelcomePillarSafe => 'آمن ومناسب';

  @override
  String get setupWelcomePillarProgress => 'تقدّم مستمر';

  @override
  String get setupWelcomePillarGoals => 'أهداف واضحة';

  @override
  String get setupAccountTitle => 'حساب ولي الأمر';

  @override
  String get setupAccountBody =>
      'الحساب لولي الأمر وحده، ويُستعمل لشيئين فقط: توليد الدروس الجديدة من الصور، والاشتراك. لا يُنشأ للطفل أي حساب، ولا تُرسل أي من بياناته إلى الخادم.';

  @override
  String get setupAccountRequired => 'الحساب مطلوب لإتمام الإعداد.';

  @override
  String get setupTrialStarted => 'بدأت فترتك التجريبية: 7 أيام بكل المزايا.';

  @override
  String get setupTrialAlready =>
      'استُعملت الفترة التجريبية على هذا الجهاز من قبل.';

  @override
  String get serverUnreachable => 'لا يمكن الوصول إلى الخادم';

  @override
  String get serverRetry => 'أعد المحاولة';

  @override
  String serverAddress(String url) {
    return 'العنوان: $url';
  }

  @override
  String get serverDegraded => 'الخادم يعمل لكن قاعدة بياناته لا تستجيب';

  @override
  String get oneAccountPerDevice =>
      'حساب واحد لكل هاتف. لتغييره، احذف بيانات التطبيق.';

  @override
  String get dialogWelcomeTitle => 'أهلاً بك في Lunio';

  @override
  String get dialogWelcomeBackTitle => 'مرحبًا بعودتك';

  @override
  String get dialogSetupRemains =>
      'يبقى على هذا الهاتف خطوتان: المستوى الدراسي ورمز ولي الأمر. لا يُحفظان على الخادم أبدًا، لذا يُضبطان على كل جهاز.';

  @override
  String get dialogContinue => 'متابعة';

  @override
  String get dialogStartNow => 'ابدأ الآن';

  @override
  String get cardRemembered => 'أحسنت، تذكّرتها';

  @override
  String get cardNotYet => 'لا بأس — ستعود إليك قريبًا';

  @override
  String get cardRevealedNote => 'انظر إليها جيّدًا، وستراها مرّة أخرى';

  @override
  String get questionRight => 'إجابة صحيحة';

  @override
  String get questionShowsAnswer => 'الإجابة الصحيحة هي المعلَّمة بالأخضر';

  @override
  String get buyActivationCode => 'احصل على رمز تفعيل';

  @override
  String get buyOpensBrowser =>
      'يفتح صفحة الدفع في المتصفّح. الدفع يتمّ خارج التطبيق على صفحة Chargily الآمنة، ويعود إليك رمز تُدخله هنا.';

  @override
  String get permBattery => 'تشغيل غير مقيّد';

  @override
  String get permBatteryBody =>
      'بدونه يُجمّد النظام التطبيق أثناء اللعب، فيتوقّف العدّاد ولا تُغلق اللعبة في وقتها.';

  @override
  String signedInSubscription(String state) {
    return 'اشتراكك الحالي: $state';
  }

  @override
  String get signedInNothingNew => 'لم يتغيّر شيء في حسابك — سجّلنا دخولك فقط.';

  @override
  String get blockingNotRunningTitle => 'الحجب مُفعَّل لكنّه لا يعمل';

  @override
  String get blockingNotRunningBody =>
      'خدمة إمكانية الوصول متوقّفة، فلا يُحجب شيء ولا يُحسب وقت اللعب. يحدث هذا بعد كل تحديث للتطبيق.';

  @override
  String get blockingNotRunningAction => 'أعد تفعيلها';

  @override
  String get lessonIntroHeading => 'قبل أن نبدأ';

  @override
  String get lessonIntroRead =>
      'اقرأ ملخّص الدرس جيّدًا، ثمّ انتقل إلى البطاقات';

  @override
  String lessonIntroWait(String seconds) {
    return 'يمكنك المتابعة بعد $seconds ثانية';
  }

  @override
  String get lessonIntroStart => 'ابدأ البطاقات';

  @override
  String get cardPickAnswer => 'اختر الإجابة الصحيحة';

  @override
  String get myLessons => 'دروسي';

  @override
  String get activatedTitle => 'تمّ تفعيل اشتراكك';

  @override
  String activatedUntil(String date) {
    return 'سارٍ حتى $date';
  }

  @override
  String get activatedBody =>
      'صار بإمكانك تصوير دروس جديدة وتوليدها. أمّا الحجب والنجوم والدروس المحفوظة فتعمل دائماً، باشتراك أو بدونه.';

  @override
  String get questionAgain => 'سؤال تعيده';

  @override
  String get parentFreePlayTitle => 'وقت لعب حرّ';

  @override
  String get parentFreePlayBody =>
      'امنح طفلك وقت لعب مباشرة. يُضاف إلى رصيده دون أن يمنحه نجومًا، وينتهي بانتهاء اليوم.';

  @override
  String parentFreePlayGranted(String duration) {
    return 'الممنوح اليوم: $duration';
  }

  @override
  String parentFreePlayAdded(String duration) {
    return 'أُضيف $duration لعبًا حرًّا';
  }

  @override
  String get parentPlayRemaining => 'المتبقّي من وقت اللعب';

  @override
  String get sectionComplete => 'أحسنت! أنهيتَ هذا القسم';

  @override
  String lessonProgress(String done, String total) {
    return '$done من $total';
  }

  @override
  String get lessonAllDone => 'أنهيتَه';

  @override
  String lessonQuestionsCount(String count) {
    return '$count سؤال';
  }

  @override
  String get sectionLocked => 'أنهِ بطاقات الحفظ أوّلًا';

  @override
  String cardStayWith(String seconds) {
    return 'تأمّلها $seconds ثانية';
  }

  @override
  String get forgotPasswordLink => 'نسيت كلمة المرور؟';

  @override
  String get forgotTitle => 'استعادة كلمة المرور';

  @override
  String get forgotAskTitle => 'لا بأس، يحدث للجميع';

  @override
  String get forgotAskBody =>
      'اكتب بريدك الإلكتروني وسنرسل لك رمزاً من ستة أرقام لتختار كلمة مرور جديدة.';

  @override
  String get forgotAskAction => 'أرسل الرمز';

  @override
  String get forgotCodeTitle => 'تفقّد بريدك';

  @override
  String forgotCodeBody(String email) {
    return 'أرسلنا رمزاً من ستة أرقام إلى $email. إن لم تجده، انظر في مجلّد الرسائل غير المرغوبة.';
  }

  @override
  String get forgotCodeLabel => 'الرمز';

  @override
  String get forgotCodeAction => 'تأكيد الرمز';

  @override
  String get forgotCodeResend => 'لم يصلك شيء؟ أعد الإرسال';

  @override
  String forgotCodeResendIn(String seconds) {
    return 'يمكنك إعادة الإرسال بعد $seconds ثانية';
  }

  @override
  String get forgotCodeWrongEmail => 'غيّر البريد الإلكتروني';

  @override
  String get forgotNewTitle => 'اختر كلمة مرور جديدة';

  @override
  String get forgotNewBody =>
      'ستُنهى جلساتك على الأجهزة الأخرى. لن يتأثّر شيء عند طفلك: النجوم والحجب والدروس المحفوظة كلها على هذا الهاتف.';

  @override
  String get forgotNewLabel => 'كلمة المرور الجديدة';

  @override
  String get forgotNewConfirmLabel => 'أعد كتابتها';

  @override
  String get forgotNewMismatch => 'الكلمتان غير متطابقتين.';

  @override
  String get forgotNewAction => 'حفظ كلمة المرور';

  @override
  String get forgotDoneTitle => 'تم تغيير كلمة المرور';

  @override
  String get forgotDoneBody =>
      'سجّلنا دخولك بالكلمة الجديدة. احتفظ بها في مكان آمن.';

  @override
  String get forgotDoneAction => 'متابعة';

  @override
  String get setupAppsTitle => 'اختر ألعاب طفلك';

  @override
  String get setupAppsBody =>
      'حدّد التطبيقات التي تريد أن يكسب طفلك الوقت لفتحها. يمكنك تغيير القائمة في أي وقت من لوحة الوالد.';

  @override
  String get setupAppsOpen => 'اختر التطبيقات';

  @override
  String setupAppsChosen(String count) {
    return '$count تطبيق مُختار';
  }

  @override
  String get setupAppsNoneYet => 'لم تختر أي تطبيق بعد';

  @override
  String get setupAppsWhyLater =>
      'إن تخطّيتها الآن، لن يُحجب أي تطبيق حتى تختار.';

  @override
  String get guardSwitch => 'اطلب الرمز السري قبل حذف التطبيق';

  @override
  String get guardBody =>
      'عندما يفتح أحدهم شاشة حذف Lunio أو مسح بياناته، سيُطلب منه الرمز السري أولاً.';

  @override
  String get guardNeedsAccessibility =>
      'يحتاج إذن إمكانية الوصول، وهو نفس الإذن الذي يحتاجه الحجب.';

  @override
  String get guardHonestLimit =>
      'هذا يوقف الحذف العَرَضي. لا يوقف من يشغّل الهاتف في «الوضع الآمن»، لأن خدمات إمكانية الوصول لا تعمل هناك.';

  @override
  String get guardPinTitle => 'أدخل الرمز السري';

  @override
  String get guardPinBody =>
      'طُلب حذف Lunio أو مسح بياناته. أدخل رمزك السري للمتابعة.';
}
