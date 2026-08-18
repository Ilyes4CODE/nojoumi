// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppL10nAr extends AppL10n {
  AppL10nAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'نجومي';

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
  String get setupTitle => 'إعداد نجومي';

  @override
  String get setupWelcomeTitle => 'أهلاً بك في نجومي';

  @override
  String get setupWelcomeBody =>
      'نجومي يحوّل وقت اللعب إلى شيء يكسبه طفلك بالمذاكرة، لا إلى شيء تسحبه منه. الإعداد ثلاث خطوات، ويمكنك تغيير كل شيء لاحقاً.';

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
  String get setupEnableLauncher => 'جعل نجومي الشاشة الرئيسية';

  @override
  String get setupSkipProtection => 'أكمل بدونهما الآن';

  @override
  String get setupDisclosureTitle => 'إفصاح مهم قبل منح الإذن';

  @override
  String get setupDisclosureBody =>
      'لتفعيل الحجب، يحتاج نجومي إلى خدمة إمكانية الوصول (Accessibility). يستعملها التطبيق لغرض واحد فقط: معرفة أي تطبيق ظهر على الشاشة الآن، ليغلق الألعاب المحجوبة عند نفاد وقت اللعب.\n\nلا يقرأ نجومي محتوى الشاشة، ولا كلمات المرور، ولا الرسائل، ولا يسجّل ما تكتبه، ولا يرسل أي شيء من هذا إلى أي خادم. يمكنك إيقاف الخدمة في أي وقت من إعدادات الهاتف.';

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
}
