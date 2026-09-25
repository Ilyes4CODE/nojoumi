import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n? of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n);
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// The app name, shown in the launcher and headers.
  ///
  /// In ar, this message translates to:
  /// **'Lunio'**
  String get appName;

  /// No description provided for @starsBalance.
  ///
  /// In ar, this message translates to:
  /// **'رصيدك'**
  String get starsBalance;

  /// No description provided for @starsUnit.
  ///
  /// In ar, this message translates to:
  /// **'نجمة'**
  String get starsUnit;

  /// No description provided for @minutesUnit.
  ///
  /// In ar, this message translates to:
  /// **'دقيقة'**
  String get minutesUnit;

  /// No description provided for @playTimeRemaining.
  ///
  /// In ar, this message translates to:
  /// **'وقت اللعب المتبقّي'**
  String get playTimeRemaining;

  /// No description provided for @todayTasks.
  ///
  /// In ar, this message translates to:
  /// **'مهام اليوم'**
  String get todayTasks;

  /// No description provided for @taskMemorize.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get taskMemorize;

  /// No description provided for @taskReview.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة'**
  String get taskReview;

  /// No description provided for @taskExercise.
  ///
  /// In ar, this message translates to:
  /// **'تمرين'**
  String get taskExercise;

  /// No description provided for @sessionComplete.
  ///
  /// In ar, this message translates to:
  /// **'أنهيتَ مهام اليوم كلها'**
  String get sessionComplete;

  /// No description provided for @sessionBonusEarned.
  ///
  /// In ar, this message translates to:
  /// **'مكافأة الإكمال: {stars} نجوم'**
  String sessionBonusEarned(String stars);

  /// No description provided for @cardShowAnswer.
  ///
  /// In ar, this message translates to:
  /// **'أظهر الجواب'**
  String get cardShowAnswer;

  /// No description provided for @cardIKnewIt.
  ///
  /// In ar, this message translates to:
  /// **'أعرفها'**
  String get cardIKnewIt;

  /// No description provided for @cardIDidNot.
  ///
  /// In ar, this message translates to:
  /// **'لم أعرفها'**
  String get cardIDidNot;

  /// No description provided for @answerCorrect.
  ///
  /// In ar, this message translates to:
  /// **'إجابة صحيحة'**
  String get answerCorrect;

  /// No description provided for @answerWrong.
  ///
  /// In ar, this message translates to:
  /// **'إجابة خاطئة. ستعود إليها لاحقاً.'**
  String get answerWrong;

  /// No description provided for @tryAgainMessage.
  ///
  /// In ar, this message translates to:
  /// **'حاول مرة أخرى'**
  String get tryAgainMessage;

  /// No description provided for @needStarsToPlay.
  ///
  /// In ar, this message translates to:
  /// **'تحتاج {stars} نجمة لتفتح هذه اللعبة'**
  String needStarsToPlay(String stars);

  /// No description provided for @blockedTitle.
  ///
  /// In ar, this message translates to:
  /// **'وقت اللعب انتهى'**
  String get blockedTitle;

  /// No description provided for @blockedBody.
  ///
  /// In ar, this message translates to:
  /// **'أنجز مهامك لتكسب نجوماً جديدة'**
  String get blockedBody;

  /// No description provided for @earnStarsNow.
  ///
  /// In ar, this message translates to:
  /// **'اكسب نجوماً الآن'**
  String get earnStarsNow;

  /// No description provided for @playPausedByParent.
  ///
  /// In ar, this message translates to:
  /// **'اللعب موقوف مؤقتاً من طرف الوالد'**
  String get playPausedByParent;

  /// No description provided for @weeklyTest.
  ///
  /// In ar, this message translates to:
  /// **'الاختبار الأسبوعي'**
  String get weeklyTest;

  /// No description provided for @weeklyTestResult.
  ///
  /// In ar, this message translates to:
  /// **'نتيجتك: {percent}%'**
  String weeklyTestResult(String percent);

  /// No description provided for @parentArea.
  ///
  /// In ar, this message translates to:
  /// **'لوحة الوالد'**
  String get parentArea;

  /// No description provided for @enterPin.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز السري'**
  String get enterPin;

  /// No description provided for @wrongPin.
  ///
  /// In ar, this message translates to:
  /// **'الرمز غير صحيح'**
  String get wrongPin;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @starValueMinutes.
  ///
  /// In ar, this message translates to:
  /// **'قيمة النجمة بالدقائق'**
  String get starValueMinutes;

  /// No description provided for @dailyStarCeiling.
  ///
  /// In ar, this message translates to:
  /// **'السقف اليومي للنجوم'**
  String get dailyStarCeiling;

  /// No description provided for @minimumCardSeconds.
  ///
  /// In ar, this message translates to:
  /// **'الحد الأدنى للوقت على البطاقة'**
  String get minimumCardSeconds;

  /// No description provided for @dailySessionSize.
  ///
  /// In ar, this message translates to:
  /// **'حجم الجلسة اليومية'**
  String get dailySessionSize;

  /// No description provided for @balanceExpiry.
  ///
  /// In ar, this message translates to:
  /// **'انتهاء صلاحية الرصيد'**
  String get balanceExpiry;

  /// No description provided for @expiryDaily.
  ///
  /// In ar, this message translates to:
  /// **'نهاية اليوم'**
  String get expiryDaily;

  /// No description provided for @expiryWeekly.
  ///
  /// In ar, this message translates to:
  /// **'نهاية الأسبوع'**
  String get expiryWeekly;

  /// No description provided for @grantStars.
  ///
  /// In ar, this message translates to:
  /// **'منح نجوم'**
  String get grantStars;

  /// No description provided for @deductStars.
  ///
  /// In ar, this message translates to:
  /// **'خصم نجوم'**
  String get deductStars;

  /// No description provided for @pausePlay.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف اللعب مؤقتاً'**
  String get pausePlay;

  /// No description provided for @managedApps.
  ///
  /// In ar, this message translates to:
  /// **'الألعاب والتطبيقات المشتّتة'**
  String get managedApps;

  /// No description provided for @captureLesson.
  ///
  /// In ar, this message translates to:
  /// **'التقاط درس'**
  String get captureLesson;

  /// No description provided for @captureHintFlat.
  ///
  /// In ar, this message translates to:
  /// **'ضع الصفحة مستوية'**
  String get captureHintFlat;

  /// No description provided for @captureHintLight.
  ///
  /// In ar, this message translates to:
  /// **'إضاءة جيدة، بلا فلاش'**
  String get captureHintLight;

  /// No description provided for @captureHintStraight.
  ///
  /// In ar, this message translates to:
  /// **'الكاميرا موازية للصفحة'**
  String get captureHintStraight;

  /// No description provided for @processing.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ المعالجة…'**
  String get processing;

  /// No description provided for @imageUnclear.
  ///
  /// In ar, this message translates to:
  /// **'الصورة غير واضحة. أعد التصوير بإضاءة أفضل وصفحة مستوية.'**
  String get imageUnclear;

  /// No description provided for @subscription.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك'**
  String get subscription;

  /// No description provided for @subscriptionTrial.
  ///
  /// In ar, this message translates to:
  /// **'تجريبي'**
  String get subscriptionTrial;

  /// No description provided for @subscriptionActive.
  ///
  /// In ar, this message translates to:
  /// **'فعّال'**
  String get subscriptionActive;

  /// No description provided for @subscriptionGrace.
  ///
  /// In ar, this message translates to:
  /// **'مهلة سماح'**
  String get subscriptionGrace;

  /// No description provided for @subscriptionExpired.
  ///
  /// In ar, this message translates to:
  /// **'منتهٍ'**
  String get subscriptionExpired;

  /// No description provided for @subscriptionRefunded.
  ///
  /// In ar, this message translates to:
  /// **'مسترجع'**
  String get subscriptionRefunded;

  /// No description provided for @expiresOn.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي في {date}'**
  String expiresOn(String date);

  /// No description provided for @enterActivationCode.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز التفعيل'**
  String get enterActivationCode;

  /// No description provided for @activate.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get activate;

  /// No description provided for @freeModeNotice.
  ///
  /// In ar, this message translates to:
  /// **'توليد الدروس الجديدة متوقّف. الحجب والنجوم والدروس المحفوظة تعمل كما هي.'**
  String get freeModeNotice;

  /// No description provided for @continueAction.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get continueAction;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @offlineNotice.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت'**
  String get offlineNotice;

  /// No description provided for @setupTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعداد Lunio'**
  String get setupTitle;

  /// No description provided for @setupWelcomeTitle.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك في Lunio'**
  String get setupWelcomeTitle;

  /// No description provided for @setupWelcomeBody.
  ///
  /// In ar, this message translates to:
  /// **'Lunio يحوّل وقت اللعب إلى شيء يكسبه طفلك بالمذاكرة، لا إلى شيء تسحبه منه. الإعداد ثلاث خطوات، ويمكنك تغيير كل شيء لاحقاً.'**
  String get setupWelcomeBody;

  /// No description provided for @setupStepOf.
  ///
  /// In ar, this message translates to:
  /// **'الخطوة {current} من {total}'**
  String setupStepOf(String current, String total);

  /// No description provided for @setupGradeTitle.
  ///
  /// In ar, this message translates to:
  /// **'المستوى الدراسي'**
  String get setupGradeTitle;

  /// No description provided for @setupGradeBody.
  ///
  /// In ar, this message translates to:
  /// **'يُستعمل لتوليد دروس مناسبة للعمر. لا نطلب اسم الطفل ولا صورته ولا تاريخ ميلاده.'**
  String get setupGradeBody;

  /// No description provided for @setupGradeHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: السنة الرابعة ابتدائي'**
  String get setupGradeHint;

  /// No description provided for @setupPinTitle.
  ///
  /// In ar, this message translates to:
  /// **'رمز الوالد'**
  String get setupPinTitle;

  /// No description provided for @setupPinBody.
  ///
  /// In ar, this message translates to:
  /// **'أربعة أرقام على الأقل. يحمي الإعدادات ومنح النجوم. لا يُخزَّن الرمز نفسه، ولا يمكن استرجاعه إلا عبر حسابك على الخادم.'**
  String get setupPinBody;

  /// No description provided for @setupPinCreate.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمزاً جديداً'**
  String get setupPinCreate;

  /// No description provided for @setupPinConfirm.
  ///
  /// In ar, this message translates to:
  /// **'أعد إدخال الرمز'**
  String get setupPinConfirm;

  /// No description provided for @setupPinMismatch.
  ///
  /// In ar, this message translates to:
  /// **'الرمزان غير متطابقين'**
  String get setupPinMismatch;

  /// No description provided for @setupPinTooShort.
  ///
  /// In ar, this message translates to:
  /// **'الرمز أربعة أرقام على الأقل'**
  String get setupPinTooShort;

  /// No description provided for @setupProtectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحجب ووضع الشاشة الرئيسية'**
  String get setupProtectionTitle;

  /// No description provided for @setupProtectionBody.
  ///
  /// In ar, this message translates to:
  /// **'هاتان الميزتان اختياريتان تماماً، والتطبيق يعمل بكامل مزاياه بدونهما: الدروس والبطاقات والنجوم والاختبار الأسبوعي ولوحة الوالد كلها تعمل.'**
  String get setupProtectionBody;

  /// No description provided for @setupEnableBlocking.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل حجب الألعاب'**
  String get setupEnableBlocking;

  /// No description provided for @setupEnableLauncher.
  ///
  /// In ar, this message translates to:
  /// **'جعل Lunio الشاشة الرئيسية'**
  String get setupEnableLauncher;

  /// No description provided for @setupSkipProtection.
  ///
  /// In ar, this message translates to:
  /// **'أكمل بدونهما الآن'**
  String get setupSkipProtection;

  /// No description provided for @setupDisclosureTitle.
  ///
  /// In ar, this message translates to:
  /// **'إفصاح مهم قبل منح الإذن'**
  String get setupDisclosureTitle;

  /// No description provided for @setupDisclosureBody.
  ///
  /// In ar, this message translates to:
  /// **'لتفعيل الحجب، يحتاج Lunio إلى خدمة إمكانية الوصول (Accessibility). يستعملها التطبيق لغرض واحد فقط: معرفة أي تطبيق ظهر على الشاشة الآن، ليغلق الألعاب المحجوبة عند نفاد وقت اللعب.\n\nلا يقرأ Lunio محتوى الشاشة، ولا كلمات المرور، ولا الرسائل، ولا يسجّل ما تكتبه، ولا يرسل أي شيء من هذا إلى أي خادم. يمكنك إيقاف الخدمة في أي وقت من إعدادات الهاتف.'**
  String get setupDisclosureBody;

  /// No description provided for @setupDisclosureConsent.
  ///
  /// In ar, this message translates to:
  /// **'قرأت الإفصاح وأوافق كوليّ أمر'**
  String get setupDisclosureConsent;

  /// No description provided for @setupDisclosureDecline.
  ///
  /// In ar, this message translates to:
  /// **'لا، أكمل بدون حجب'**
  String get setupDisclosureDecline;

  /// No description provided for @setupFinish.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ'**
  String get setupFinish;

  /// No description provided for @setupDoneTitle.
  ///
  /// In ar, this message translates to:
  /// **'كل شيء جاهز'**
  String get setupDoneTitle;

  /// No description provided for @setupDoneBody.
  ///
  /// In ar, this message translates to:
  /// **'منحنا طفلك {stars} نجمة ترحيبية ليبدأ.'**
  String setupDoneBody(String stars);

  /// No description provided for @homeGreeting.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً'**
  String get homeGreeting;

  /// No description provided for @startSession.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ مهام اليوم'**
  String get startSession;

  /// No description provided for @noTasksYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مهام بعد. اطلب من والدك التقاط درس.'**
  String get noTasksYet;

  /// No description provided for @tasksRemaining.
  ///
  /// In ar, this message translates to:
  /// **'بقيت {count} مهمة'**
  String tasksRemaining(String count);

  /// No description provided for @dailyCeilingReached.
  ///
  /// In ar, this message translates to:
  /// **'بلغتَ سقف اليوم. عد غداً.'**
  String get dailyCeilingReached;

  /// No description provided for @streakDays.
  ///
  /// In ar, this message translates to:
  /// **'مواظبة {days} يوم'**
  String streakDays(String days);

  /// No description provided for @clockUntrustedTitle.
  ///
  /// In ar, this message translates to:
  /// **'ساعة الهاتف غير موثوقة'**
  String get clockUntrustedTitle;

  /// No description provided for @clockUntrustedBody.
  ///
  /// In ar, this message translates to:
  /// **'تغيّر تاريخ الهاتف أو ساعته. لا يمكن كسب نجوم جديدة حتى تعود الساعة إلى الضبط التلقائي. النجوم المكسوبة سابقاً ووقت اللعب المتبقّي لم يتأثّرا.'**
  String get clockUntrustedBody;

  /// No description provided for @fixClockAction.
  ///
  /// In ar, this message translates to:
  /// **'افتح إعدادات التاريخ والوقت'**
  String get fixClockAction;

  /// No description provided for @next.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get next;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @skip.
  ///
  /// In ar, this message translates to:
  /// **'تخطٍّ'**
  String get skip;

  /// No description provided for @notNow.
  ///
  /// In ar, this message translates to:
  /// **'ليس الآن'**
  String get notNow;

  /// No description provided for @pinLockedFor.
  ///
  /// In ar, this message translates to:
  /// **'محاولات كثيرة. أعد المحاولة بعد {seconds} ثانية.'**
  String pinLockedFor(String seconds);

  /// No description provided for @parentOverview.
  ///
  /// In ar, this message translates to:
  /// **'نظرة عامة'**
  String get parentOverview;

  /// No description provided for @parentStarsToday.
  ///
  /// In ar, this message translates to:
  /// **'نجوم اليوم'**
  String get parentStarsToday;

  /// No description provided for @parentEarnedToday.
  ///
  /// In ar, this message translates to:
  /// **'كسبها الطفل'**
  String get parentEarnedToday;

  /// No description provided for @parentGrantedToday.
  ///
  /// In ar, this message translates to:
  /// **'منحتَها أنت'**
  String get parentGrantedToday;

  /// No description provided for @parentCeilingUsed.
  ///
  /// In ar, this message translates to:
  /// **'من السقف اليومي'**
  String get parentCeilingUsed;

  /// No description provided for @parentPlayUsed.
  ///
  /// In ar, this message translates to:
  /// **'وقت اللعب المستهلك'**
  String get parentPlayUsed;

  /// No description provided for @parentStreak.
  ///
  /// In ar, this message translates to:
  /// **'المواظبة'**
  String get parentStreak;

  /// No description provided for @parentAdjustTitle.
  ///
  /// In ar, this message translates to:
  /// **'منح أو خصم'**
  String get parentAdjustTitle;

  /// No description provided for @parentAdjustBody.
  ///
  /// In ar, this message translates to:
  /// **'سلطتك فوق النظام: المنح والخصم لا يخضعان للسقف اليومي، ويعملان حتى لو كانت ساعة الهاتف غير موثوقة.'**
  String get parentAdjustBody;

  /// No description provided for @parentAdjustAmount.
  ///
  /// In ar, this message translates to:
  /// **'عدد النجوم'**
  String get parentAdjustAmount;

  /// No description provided for @parentAdjustNote.
  ///
  /// In ar, this message translates to:
  /// **'السبب (اختياري)'**
  String get parentAdjustNote;

  /// No description provided for @parentGrantDone.
  ///
  /// In ar, this message translates to:
  /// **'مُنحت {stars} نجمة'**
  String parentGrantDone(String stars);

  /// No description provided for @parentDeductDone.
  ///
  /// In ar, this message translates to:
  /// **'خُصمت {stars} نجمة'**
  String parentDeductDone(String stars);

  /// No description provided for @parentDeductTooMuch.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن خصم أكثر من الرصيد الحالي'**
  String get parentDeductTooMuch;

  /// No description provided for @parentSettingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأرقام التي تتحكّم فيها'**
  String get parentSettingsTitle;

  /// No description provided for @parentSettingsBody.
  ///
  /// In ar, this message translates to:
  /// **'كل قيمة هنا لها مدى محدّد في ملحق العقد. القيم خارج المدى تُرفض ولا تُقرّب.'**
  String get parentSettingsBody;

  /// No description provided for @parentRangeHint.
  ///
  /// In ar, this message translates to:
  /// **'من {min} إلى {max}'**
  String parentRangeHint(String min, String max);

  /// No description provided for @parentDailyPlayMinutes.
  ///
  /// In ar, this message translates to:
  /// **'دقائق اللعب اليومية'**
  String get parentDailyPlayMinutes;

  /// No description provided for @parentDailyPlayHint.
  ///
  /// In ar, this message translates to:
  /// **'السقف اليومي × قيمة النجمة'**
  String get parentDailyPlayHint;

  /// No description provided for @parentQuestionsPerDay.
  ///
  /// In ar, this message translates to:
  /// **'عدد أسئلة المراجعة يومياً'**
  String get parentQuestionsPerDay;

  /// No description provided for @parentWelcomeBalance.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد الترحيبي'**
  String get parentWelcomeBalance;

  /// No description provided for @parentExpiryWeekday.
  ///
  /// In ar, this message translates to:
  /// **'يوم الاختبار الأسبوعي'**
  String get parentExpiryWeekday;

  /// No description provided for @parentPlayPausedOn.
  ///
  /// In ar, this message translates to:
  /// **'اللعب موقوف الآن'**
  String get parentPlayPausedOn;

  /// No description provided for @parentPlayPausedOff.
  ///
  /// In ar, this message translates to:
  /// **'اللعب مسموح'**
  String get parentPlayPausedOff;

  /// No description provided for @parentBlockingSection.
  ///
  /// In ar, this message translates to:
  /// **'الحجب والشاشة الرئيسية'**
  String get parentBlockingSection;

  /// No description provided for @parentLedgerTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجلّ النجوم'**
  String get parentLedgerTitle;

  /// No description provided for @parentLedgerEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا حركات بعد'**
  String get parentLedgerEmpty;

  /// No description provided for @parentWhyNoStar.
  ///
  /// In ar, this message translates to:
  /// **'لماذا لم تُمنح نجمة؟'**
  String get parentWhyNoStar;

  /// No description provided for @parentSaved.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ'**
  String get parentSaved;

  /// No description provided for @parentInvalidValue.
  ///
  /// In ar, this message translates to:
  /// **'قيمة غير مقبولة: {reason}'**
  String parentInvalidValue(String reason);

  /// No description provided for @ledgerCardFirstTime.
  ///
  /// In ar, this message translates to:
  /// **'بطاقة صحيحة أول مرة'**
  String get ledgerCardFirstTime;

  /// No description provided for @ledgerCardReview.
  ///
  /// In ar, this message translates to:
  /// **'بطاقة في مراجعة'**
  String get ledgerCardReview;

  /// No description provided for @ledgerReviewQuestion.
  ///
  /// In ar, this message translates to:
  /// **'سؤال مراجعة صحيح'**
  String get ledgerReviewQuestion;

  /// No description provided for @ledgerSessionBonus.
  ///
  /// In ar, this message translates to:
  /// **'مكافأة إكمال الجلسة'**
  String get ledgerSessionBonus;

  /// No description provided for @ledgerStreakBonus.
  ///
  /// In ar, this message translates to:
  /// **'مكافأة المواظبة'**
  String get ledgerStreakBonus;

  /// No description provided for @ledgerWeeklyTest.
  ///
  /// In ar, this message translates to:
  /// **'الاختبار الأسبوعي'**
  String get ledgerWeeklyTest;

  /// No description provided for @ledgerWelcomeGrant.
  ///
  /// In ar, this message translates to:
  /// **'رصيد ترحيبي'**
  String get ledgerWelcomeGrant;

  /// No description provided for @ledgerParentGrant.
  ///
  /// In ar, this message translates to:
  /// **'منحة من الوالد'**
  String get ledgerParentGrant;

  /// No description provided for @ledgerParentDeduct.
  ///
  /// In ar, this message translates to:
  /// **'خصم من الوالد'**
  String get ledgerParentDeduct;

  /// No description provided for @ledgerExpiry.
  ///
  /// In ar, this message translates to:
  /// **'انتهاء صلاحية الرصيد'**
  String get ledgerExpiry;

  /// No description provided for @weekdayMonday.
  ///
  /// In ar, this message translates to:
  /// **'الاثنين'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In ar, this message translates to:
  /// **'الثلاثاء'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In ar, this message translates to:
  /// **'الأربعاء'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In ar, this message translates to:
  /// **'الخميس'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In ar, this message translates to:
  /// **'الجمعة'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In ar, this message translates to:
  /// **'السبت'**
  String get weekdaySaturday;

  /// No description provided for @weekdaySunday.
  ///
  /// In ar, this message translates to:
  /// **'الأحد'**
  String get weekdaySunday;

  /// No description provided for @rejectUntrustedClock.
  ///
  /// In ar, this message translates to:
  /// **'ساعة الهاتف غير موثوقة (المادة 6.8)'**
  String get rejectUntrustedClock;

  /// No description provided for @rejectWrongAnswer.
  ///
  /// In ar, this message translates to:
  /// **'إجابة خاطئة (المادة 6.1)'**
  String get rejectWrongAnswer;

  /// No description provided for @rejectSolutionRevealed.
  ///
  /// In ar, this message translates to:
  /// **'كُشف الحل قبل الإجابة (المادة 6.1)'**
  String get rejectSolutionRevealed;

  /// No description provided for @rejectNotFirstAttempt.
  ///
  /// In ar, this message translates to:
  /// **'ليست المحاولة الأولى (المادة 6.1)'**
  String get rejectNotFirstAttempt;

  /// No description provided for @rejectAlreadyCountedToday.
  ///
  /// In ar, this message translates to:
  /// **'احتُسبت في اليوم نفسه (المادة 6.2)'**
  String get rejectAlreadyCountedToday;

  /// No description provided for @rejectBelowMinimumTime.
  ///
  /// In ar, this message translates to:
  /// **'الوقت على البطاقة أقل من الحد الأدنى (المادة 6.3)'**
  String get rejectBelowMinimumTime;

  /// No description provided for @rejectDailyCeilingReached.
  ///
  /// In ar, this message translates to:
  /// **'استُنفد السقف اليومي (المادة 6.4)'**
  String get rejectDailyCeilingReached;

  /// No description provided for @rejectAlreadyAwardedToday.
  ///
  /// In ar, this message translates to:
  /// **'مُنحت هذه المكافأة اليوم'**
  String get rejectAlreadyAwardedToday;

  /// No description provided for @rejectSessionIncomplete.
  ///
  /// In ar, this message translates to:
  /// **'الجلسة اليومية لم تكتمل (المادة 6.5)'**
  String get rejectSessionIncomplete;

  /// No description provided for @rejectStreakTooShort.
  ///
  /// In ar, this message translates to:
  /// **'المواظبة أقل من يومين متتاليين (المادة 5)'**
  String get rejectStreakTooShort;

  /// No description provided for @accountTitle.
  ///
  /// In ar, this message translates to:
  /// **'حساب الوالد'**
  String get accountTitle;

  /// No description provided for @accountWhy.
  ///
  /// In ar, this message translates to:
  /// **'الحساب لازم لتوليد دروس جديدة فقط. الحجب والنجوم والدروس المحفوظة تعمل بدونه.'**
  String get accountWhy;

  /// No description provided for @signIn.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOut;

  /// No description provided for @emailLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get passwordLabel;

  /// No description provided for @phoneOptional.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف (اختياري)'**
  String get phoneOptional;

  /// No description provided for @noAccountYet.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟ أنشئ واحداً'**
  String get noAccountYet;

  /// No description provided for @haveAccountAlready.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب؟ سجّل الدخول'**
  String get haveAccountAlready;

  /// No description provided for @signedInAs.
  ///
  /// In ar, this message translates to:
  /// **'مسجَّل الدخول بـ{email}'**
  String signedInAs(String email);

  /// No description provided for @signInRequired.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول لتوليد درس جديد'**
  String get signInRequired;

  /// No description provided for @serverNotConfigured.
  ///
  /// In ar, this message translates to:
  /// **'لم يُضبط عنوان الخادم في هذه النسخة.'**
  String get serverNotConfigured;

  /// No description provided for @captureFromCamera.
  ///
  /// In ar, this message translates to:
  /// **'التقط بالكاميرا'**
  String get captureFromCamera;

  /// No description provided for @captureFromGallery.
  ///
  /// In ar, this message translates to:
  /// **'اختر من المعرض'**
  String get captureFromGallery;

  /// No description provided for @captureIntro.
  ///
  /// In ar, this message translates to:
  /// **'صوّر صفحة واحدة من كتاب طفلك. تُرسَل الصورة للمعالجة ثم تُحذف من الخادم فوراً، ولا تُحفظ إلا على هذا الهاتف.'**
  String get captureIntro;

  /// No description provided for @processingHint.
  ///
  /// In ar, this message translates to:
  /// **'قد تستغرق بضع ثوانٍ'**
  String get processingHint;

  /// No description provided for @reviewLesson.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة الدرس'**
  String get reviewLesson;

  /// No description provided for @summaryHeading.
  ///
  /// In ar, this message translates to:
  /// **'الملخّص'**
  String get summaryHeading;

  /// No description provided for @cardsHeading.
  ///
  /// In ar, this message translates to:
  /// **'بطاقات الحفظ'**
  String get cardsHeading;

  /// No description provided for @questionsHeading.
  ///
  /// In ar, this message translates to:
  /// **'أسئلة المراجعة'**
  String get questionsHeading;

  /// No description provided for @lessonTitleLabel.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الدرس'**
  String get lessonTitleLabel;

  /// No description provided for @lessonTitleHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: الحروف العربية'**
  String get lessonTitleHint;

  /// No description provided for @subjectOptional.
  ///
  /// In ar, this message translates to:
  /// **'المادة (اختياري)'**
  String get subjectOptional;

  /// No description provided for @saveLesson.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الدرس'**
  String get saveLesson;

  /// No description provided for @discardLesson.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل'**
  String get discardLesson;

  /// No description provided for @lessonSaved.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ الدرس: {cards} بطاقة و{questions} سؤال'**
  String lessonSaved(String cards, String questions);

  /// No description provided for @retakePhoto.
  ///
  /// In ar, this message translates to:
  /// **'أعد التصوير'**
  String get retakePhoto;

  /// No description provided for @lessonsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الدروس'**
  String get lessonsTitle;

  /// No description provided for @lessonsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لم يُلتقط أي درس بعد'**
  String get lessonsEmpty;

  /// No description provided for @lessonCardsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} بطاقة'**
  String lessonCardsCount(String count);

  /// No description provided for @imagesDeleted.
  ///
  /// In ar, this message translates to:
  /// **'حُذفت الصور'**
  String get imagesDeleted;

  /// No description provided for @untitledLesson.
  ///
  /// In ar, this message translates to:
  /// **'درس بلا عنوان'**
  String get untitledLesson;

  /// No description provided for @purgeDoneTitle.
  ///
  /// In ar, this message translates to:
  /// **'حُذفت صور هذا الأسبوع'**
  String get purgeDoneTitle;

  /// No description provided for @purgeDoneBody.
  ///
  /// In ar, this message translates to:
  /// **'حُذفت الصور والتمارين من الهاتف. الملخّصات والبطاقات والنتائج محفوظة.'**
  String get purgeDoneBody;

  /// No description provided for @weeklyTestDue.
  ///
  /// In ar, this message translates to:
  /// **'حان موعد الاختبار الأسبوعي'**
  String get weeklyTestDue;

  /// No description provided for @weeklyTestStart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الاختبار'**
  String get weeklyTestStart;

  /// No description provided for @subscriptionPlan.
  ///
  /// In ar, this message translates to:
  /// **'الخطة'**
  String get subscriptionPlan;

  /// No description provided for @subscriptionDaysLeft.
  ///
  /// In ar, this message translates to:
  /// **'الأيام المتبقّية'**
  String get subscriptionDaysLeft;

  /// No description provided for @startTrial.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الفترة التجريبية'**
  String get startTrial;

  /// No description provided for @trialOncePerDevice.
  ///
  /// In ar, this message translates to:
  /// **'سبعة أيام، مرّة واحدة لكل جهاز'**
  String get trialOncePerDevice;

  /// No description provided for @activationHelp.
  ///
  /// In ar, this message translates to:
  /// **'تحصل على الرمز بعد الدفع على صفحة الويب.'**
  String get activationHelp;

  /// No description provided for @renewNotice.
  ///
  /// In ar, this message translates to:
  /// **'للتجديد، استعمل صفحة الدفع المرتبطة بحسابك.'**
  String get renewNotice;

  /// No description provided for @activationDone.
  ///
  /// In ar, this message translates to:
  /// **'تمّ التفعيل'**
  String get activationDone;

  /// No description provided for @planMonthly.
  ///
  /// In ar, this message translates to:
  /// **'شهرية'**
  String get planMonthly;

  /// No description provided for @planAnnual.
  ///
  /// In ar, this message translates to:
  /// **'سنوية'**
  String get planAnnual;

  /// No description provided for @planTrial.
  ///
  /// In ar, this message translates to:
  /// **'تجريبية'**
  String get planTrial;

  /// No description provided for @aiPausedTitle.
  ///
  /// In ar, this message translates to:
  /// **'توليد الدروس الجديدة متوقّف'**
  String get aiPausedTitle;

  /// No description provided for @blockingTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحجب والألعاب'**
  String get blockingTitle;

  /// No description provided for @blockingIntro.
  ///
  /// In ar, this message translates to:
  /// **'يمنع Lunio فتح الألعاب التي تختارها عندما ينفد وقت اللعب. باقي الهاتف يبقى مفتوحًا كالعادة.'**
  String get blockingIntro;

  /// No description provided for @blockingUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الحجب متاح على أندرويد فقط. باقي التطبيق يعمل هنا بشكل كامل.'**
  String get blockingUnavailable;

  /// No description provided for @blockingEnableSwitch.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل حجب الألعاب'**
  String get blockingEnableSwitch;

  /// No description provided for @blockingReady.
  ///
  /// In ar, this message translates to:
  /// **'الحجب يعمل'**
  String get blockingReady;

  /// No description provided for @blockingIncomplete.
  ///
  /// In ar, this message translates to:
  /// **'ينقص إذن واحد على الأقل'**
  String get blockingIncomplete;

  /// No description provided for @blockingOff.
  ///
  /// In ar, this message translates to:
  /// **'الحجب موقوف'**
  String get blockingOff;

  /// No description provided for @permAccessibility.
  ///
  /// In ar, this message translates to:
  /// **'خدمة إمكانية الوصول'**
  String get permAccessibility;

  /// No description provided for @permAccessibilityBody.
  ///
  /// In ar, this message translates to:
  /// **'بدونها لا يعرف Lunio أي تطبيق فُتح، ولا يُحجب شيء.'**
  String get permAccessibilityBody;

  /// No description provided for @permOverlay.
  ///
  /// In ar, this message translates to:
  /// **'الرسم فوق التطبيقات'**
  String get permOverlay;

  /// No description provided for @permOverlayBody.
  ///
  /// In ar, this message translates to:
  /// **'بدونها يعود الهاتف إلى الشاشة الرئيسية دون أن يفهم الطفل السبب.'**
  String get permOverlayBody;

  /// No description provided for @permNotifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get permNotifications;

  /// No description provided for @permNotificationsBody.
  ///
  /// In ar, this message translates to:
  /// **'إشعار دائم صامت يبقي محرّك الحجب حيًّا.'**
  String get permNotificationsBody;

  /// No description provided for @permAutostart.
  ///
  /// In ar, this message translates to:
  /// **'التشغيل التلقائي'**
  String get permAutostart;

  /// No description provided for @permAutostartBody.
  ///
  /// In ar, this message translates to:
  /// **'على أجهزة {brand} قد يمنع النظام عودة الحجب بعد إعادة التشغيل ما لم تسمح بذلك يدويًا.'**
  String permAutostartBody(String brand);

  /// No description provided for @permGranted.
  ///
  /// In ar, this message translates to:
  /// **'مُفعّل'**
  String get permGranted;

  /// No description provided for @permMissing.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب'**
  String get permMissing;

  /// No description provided for @permOpen.
  ///
  /// In ar, this message translates to:
  /// **'افتح'**
  String get permOpen;

  /// No description provided for @blockingApps.
  ///
  /// In ar, this message translates to:
  /// **'الألعاب المحجوبة'**
  String get blockingApps;

  /// No description provided for @blockingAppsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} تطبيق محجوب'**
  String blockingAppsCount(String count);

  /// No description provided for @blockingAppsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لم تختر أي لعبة بعد'**
  String get blockingAppsEmpty;

  /// No description provided for @blockingAppsHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر التطبيقات التي تريد أن تكلّف نجومًا. البقية تبقى مفتوحة دائمًا.'**
  String get blockingAppsHint;

  /// No description provided for @blockingAppsSearch.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن تطبيق'**
  String get blockingAppsSearch;

  /// No description provided for @blockingAppsLoading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ قراءة التطبيقات المثبّتة'**
  String get blockingAppsLoading;

  /// No description provided for @blockingProtectedNote.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات والهاتف والرسائل ولوحة المفاتيح وLunio نفسه لا يمكن حجبها أبدًا.'**
  String get blockingProtectedNote;

  /// No description provided for @blockingDeviceLine.
  ///
  /// In ar, this message translates to:
  /// **'{brand} · أندرويد API {sdk}'**
  String blockingDeviceLine(String brand, String sdk);

  /// No description provided for @setupWelcomeHeadline.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك في'**
  String get setupWelcomeHeadline;

  /// No description provided for @setupWelcomeLine1.
  ///
  /// In ar, this message translates to:
  /// **'حوّل وقت اللعب إلى وقت مفيد وممتع.'**
  String get setupWelcomeLine1;

  /// No description provided for @setupWelcomeLine2.
  ///
  /// In ar, this message translates to:
  /// **'مع Lunio، يتعلّم طفلك خطوة بخطوة من خلال أنشطة بسيطة وتفاعلية مناسبة لمستواه العمري.'**
  String get setupWelcomeLine2;

  /// No description provided for @setupWelcomePillarSafe.
  ///
  /// In ar, this message translates to:
  /// **'آمن ومناسب'**
  String get setupWelcomePillarSafe;

  /// No description provided for @setupWelcomePillarProgress.
  ///
  /// In ar, this message translates to:
  /// **'تقدّم مستمر'**
  String get setupWelcomePillarProgress;

  /// No description provided for @setupWelcomePillarGoals.
  ///
  /// In ar, this message translates to:
  /// **'أهداف واضحة'**
  String get setupWelcomePillarGoals;

  /// No description provided for @setupAccountTitle.
  ///
  /// In ar, this message translates to:
  /// **'حساب ولي الأمر'**
  String get setupAccountTitle;

  /// No description provided for @setupAccountBody.
  ///
  /// In ar, this message translates to:
  /// **'الحساب لولي الأمر وحده، ويُستعمل لشيئين فقط: توليد الدروس الجديدة من الصور، والاشتراك. لا يُنشأ للطفل أي حساب، ولا تُرسل أي من بياناته إلى الخادم.'**
  String get setupAccountBody;

  /// No description provided for @setupAccountRequired.
  ///
  /// In ar, this message translates to:
  /// **'الحساب مطلوب لإتمام الإعداد.'**
  String get setupAccountRequired;

  /// No description provided for @setupTrialStarted.
  ///
  /// In ar, this message translates to:
  /// **'بدأت فترتك التجريبية: 7 أيام بكل المزايا.'**
  String get setupTrialStarted;

  /// No description provided for @setupTrialAlready.
  ///
  /// In ar, this message translates to:
  /// **'استُعملت الفترة التجريبية على هذا الجهاز من قبل.'**
  String get setupTrialAlready;

  /// No description provided for @serverUnreachable.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن الوصول إلى الخادم'**
  String get serverUnreachable;

  /// No description provided for @serverRetry.
  ///
  /// In ar, this message translates to:
  /// **'أعد المحاولة'**
  String get serverRetry;

  /// No description provided for @serverAddress.
  ///
  /// In ar, this message translates to:
  /// **'العنوان: {url}'**
  String serverAddress(String url);

  /// No description provided for @serverDegraded.
  ///
  /// In ar, this message translates to:
  /// **'الخادم يعمل لكن قاعدة بياناته لا تستجيب'**
  String get serverDegraded;

  /// No description provided for @oneAccountPerDevice.
  ///
  /// In ar, this message translates to:
  /// **'حساب واحد لكل هاتف. لتغييره، احذف بيانات التطبيق.'**
  String get oneAccountPerDevice;

  /// No description provided for @dialogWelcomeTitle.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك في Lunio'**
  String get dialogWelcomeTitle;

  /// No description provided for @dialogWelcomeBackTitle.
  ///
  /// In ar, this message translates to:
  /// **'مرحبًا بعودتك'**
  String get dialogWelcomeBackTitle;

  /// No description provided for @dialogSetupRemains.
  ///
  /// In ar, this message translates to:
  /// **'يبقى على هذا الهاتف خطوتان: المستوى الدراسي ورمز ولي الأمر. لا يُحفظان على الخادم أبدًا، لذا يُضبطان على كل جهاز.'**
  String get dialogSetupRemains;

  /// No description provided for @dialogContinue.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get dialogContinue;

  /// No description provided for @dialogStartNow.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الآن'**
  String get dialogStartNow;

  /// No description provided for @cardRemembered.
  ///
  /// In ar, this message translates to:
  /// **'أحسنت، تذكّرتها'**
  String get cardRemembered;

  /// No description provided for @cardNotYet.
  ///
  /// In ar, this message translates to:
  /// **'لا بأس — ستعود إليك قريبًا'**
  String get cardNotYet;

  /// No description provided for @cardRevealedNote.
  ///
  /// In ar, this message translates to:
  /// **'انظر إليها جيّدًا، وستراها مرّة أخرى'**
  String get cardRevealedNote;

  /// No description provided for @questionRight.
  ///
  /// In ar, this message translates to:
  /// **'إجابة صحيحة'**
  String get questionRight;

  /// No description provided for @questionShowsAnswer.
  ///
  /// In ar, this message translates to:
  /// **'الإجابة الصحيحة هي المعلَّمة بالأخضر'**
  String get questionShowsAnswer;

  /// No description provided for @buyActivationCode.
  ///
  /// In ar, this message translates to:
  /// **'احصل على رمز تفعيل'**
  String get buyActivationCode;

  /// No description provided for @buyOpensBrowser.
  ///
  /// In ar, this message translates to:
  /// **'يفتح صفحة الدفع في المتصفّح. الدفع يتمّ خارج التطبيق على صفحة Chargily الآمنة، ويعود إليك رمز تُدخله هنا.'**
  String get buyOpensBrowser;

  /// No description provided for @permBattery.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل غير مقيّد'**
  String get permBattery;

  /// No description provided for @permBatteryBody.
  ///
  /// In ar, this message translates to:
  /// **'بدونه يُجمّد النظام التطبيق أثناء اللعب، فيتوقّف العدّاد ولا تُغلق اللعبة في وقتها.'**
  String get permBatteryBody;

  /// No description provided for @signedInSubscription.
  ///
  /// In ar, this message translates to:
  /// **'اشتراكك الحالي: {state}'**
  String signedInSubscription(String state);

  /// No description provided for @signedInNothingNew.
  ///
  /// In ar, this message translates to:
  /// **'لم يتغيّر شيء في حسابك — سجّلنا دخولك فقط.'**
  String get signedInNothingNew;

  /// No description provided for @blockingNotRunningTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحجب مُفعَّل لكنّه لا يعمل'**
  String get blockingNotRunningTitle;

  /// No description provided for @blockingNotRunningBody.
  ///
  /// In ar, this message translates to:
  /// **'خدمة إمكانية الوصول متوقّفة، فلا يُحجب شيء ولا يُحسب وقت اللعب. يحدث هذا بعد كل تحديث للتطبيق.'**
  String get blockingNotRunningBody;

  /// No description provided for @blockingNotRunningAction.
  ///
  /// In ar, this message translates to:
  /// **'أعد تفعيلها'**
  String get blockingNotRunningAction;

  /// No description provided for @lessonIntroHeading.
  ///
  /// In ar, this message translates to:
  /// **'قبل أن نبدأ'**
  String get lessonIntroHeading;

  /// No description provided for @lessonIntroRead.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ ملخّص الدرس جيّدًا، ثمّ انتقل إلى البطاقات'**
  String get lessonIntroRead;

  /// No description provided for @lessonIntroWait.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك المتابعة بعد {seconds} ثانية'**
  String lessonIntroWait(String seconds);

  /// No description provided for @lessonIntroStart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ البطاقات'**
  String get lessonIntroStart;

  /// No description provided for @cardPickAnswer.
  ///
  /// In ar, this message translates to:
  /// **'اختر الإجابة الصحيحة'**
  String get cardPickAnswer;

  /// No description provided for @myLessons.
  ///
  /// In ar, this message translates to:
  /// **'دروسي'**
  String get myLessons;

  /// No description provided for @activatedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تمّ تفعيل اشتراكك'**
  String get activatedTitle;

  /// No description provided for @activatedUntil.
  ///
  /// In ar, this message translates to:
  /// **'سارٍ حتى {date}'**
  String activatedUntil(String date);

  /// No description provided for @activatedBody.
  ///
  /// In ar, this message translates to:
  /// **'صار بإمكانك تصوير دروس جديدة وتوليدها. أمّا الحجب والنجوم والدروس المحفوظة فتعمل دائماً، باشتراك أو بدونه.'**
  String get activatedBody;

  /// No description provided for @questionAgain.
  ///
  /// In ar, this message translates to:
  /// **'سؤال تعيده'**
  String get questionAgain;

  /// No description provided for @parentFreePlayTitle.
  ///
  /// In ar, this message translates to:
  /// **'وقت لعب حرّ'**
  String get parentFreePlayTitle;

  /// No description provided for @parentFreePlayBody.
  ///
  /// In ar, this message translates to:
  /// **'امنح طفلك وقت لعب مباشرة. يُضاف إلى رصيده دون أن يمنحه نجومًا، وينتهي بانتهاء اليوم.'**
  String get parentFreePlayBody;

  /// No description provided for @parentFreePlayGranted.
  ///
  /// In ar, this message translates to:
  /// **'الممنوح اليوم: {duration}'**
  String parentFreePlayGranted(String duration);

  /// No description provided for @parentFreePlayAdded.
  ///
  /// In ar, this message translates to:
  /// **'أُضيف {duration} لعبًا حرًّا'**
  String parentFreePlayAdded(String duration);

  /// No description provided for @parentPlayRemaining.
  ///
  /// In ar, this message translates to:
  /// **'المتبقّي من وقت اللعب'**
  String get parentPlayRemaining;

  /// No description provided for @sectionComplete.
  ///
  /// In ar, this message translates to:
  /// **'أحسنت! أنهيتَ هذا القسم'**
  String get sectionComplete;

  /// No description provided for @lessonProgress.
  ///
  /// In ar, this message translates to:
  /// **'{done} من {total}'**
  String lessonProgress(String done, String total);

  /// No description provided for @lessonAllDone.
  ///
  /// In ar, this message translates to:
  /// **'أنهيتَه'**
  String get lessonAllDone;

  /// No description provided for @lessonQuestionsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} سؤال'**
  String lessonQuestionsCount(String count);

  /// No description provided for @sectionLocked.
  ///
  /// In ar, this message translates to:
  /// **'أنهِ بطاقات الحفظ أوّلًا'**
  String get sectionLocked;

  /// No description provided for @cardStayWith.
  ///
  /// In ar, this message translates to:
  /// **'تأمّلها {seconds} ثانية'**
  String cardStayWith(String seconds);

  /// The link under the sign-in form.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get forgotPasswordLink;

  /// No description provided for @forgotTitle.
  ///
  /// In ar, this message translates to:
  /// **'استعادة كلمة المرور'**
  String get forgotTitle;

  /// No description provided for @forgotAskTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا بأس، يحدث للجميع'**
  String get forgotAskTitle;

  /// No description provided for @forgotAskBody.
  ///
  /// In ar, this message translates to:
  /// **'اكتب بريدك الإلكتروني وسنرسل لك رمزاً من ستة أرقام لتختار كلمة مرور جديدة.'**
  String get forgotAskBody;

  /// No description provided for @forgotAskAction.
  ///
  /// In ar, this message translates to:
  /// **'أرسل الرمز'**
  String get forgotAskAction;

  /// No description provided for @forgotCodeTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفقّد بريدك'**
  String get forgotCodeTitle;

  /// No description provided for @forgotCodeBody.
  ///
  /// In ar, this message translates to:
  /// **'أرسلنا رمزاً من ستة أرقام إلى {email}. إن لم تجده، انظر في مجلّد الرسائل غير المرغوبة.'**
  String forgotCodeBody(String email);

  /// No description provided for @forgotCodeLabel.
  ///
  /// In ar, this message translates to:
  /// **'الرمز'**
  String get forgotCodeLabel;

  /// No description provided for @forgotCodeAction.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الرمز'**
  String get forgotCodeAction;

  /// No description provided for @forgotCodeResend.
  ///
  /// In ar, this message translates to:
  /// **'لم يصلك شيء؟ أعد الإرسال'**
  String get forgotCodeResend;

  /// No description provided for @forgotCodeResendIn.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك إعادة الإرسال بعد {seconds} ثانية'**
  String forgotCodeResendIn(String seconds);

  /// No description provided for @forgotCodeWrongEmail.
  ///
  /// In ar, this message translates to:
  /// **'غيّر البريد الإلكتروني'**
  String get forgotCodeWrongEmail;

  /// No description provided for @forgotNewTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر كلمة مرور جديدة'**
  String get forgotNewTitle;

  /// Art. 7.1 — the parent must be told that nothing the child depends on is server-side.
  ///
  /// In ar, this message translates to:
  /// **'ستُنهى جلساتك على الأجهزة الأخرى. لن يتأثّر شيء عند طفلك: النجوم والحجب والدروس المحفوظة كلها على هذا الهاتف.'**
  String get forgotNewBody;

  /// No description provided for @forgotNewLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة'**
  String get forgotNewLabel;

  /// No description provided for @forgotNewConfirmLabel.
  ///
  /// In ar, this message translates to:
  /// **'أعد كتابتها'**
  String get forgotNewConfirmLabel;

  /// No description provided for @forgotNewMismatch.
  ///
  /// In ar, this message translates to:
  /// **'الكلمتان غير متطابقتين.'**
  String get forgotNewMismatch;

  /// No description provided for @forgotNewAction.
  ///
  /// In ar, this message translates to:
  /// **'حفظ كلمة المرور'**
  String get forgotNewAction;

  /// No description provided for @forgotDoneTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم تغيير كلمة المرور'**
  String get forgotDoneTitle;

  /// No description provided for @forgotDoneBody.
  ///
  /// In ar, this message translates to:
  /// **'سجّلنا دخولك بالكلمة الجديدة. احتفظ بها في مكان آمن.'**
  String get forgotDoneBody;

  /// No description provided for @forgotDoneAction.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get forgotDoneAction;

  /// No description provided for @setupAppsTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر ألعاب طفلك'**
  String get setupAppsTitle;

  /// No description provided for @setupAppsBody.
  ///
  /// In ar, this message translates to:
  /// **'حدّد التطبيقات التي تريد أن يكسب طفلك الوقت لفتحها. يمكنك تغيير القائمة في أي وقت من لوحة الوالد.'**
  String get setupAppsBody;

  /// No description provided for @setupAppsOpen.
  ///
  /// In ar, this message translates to:
  /// **'اختر التطبيقات'**
  String get setupAppsOpen;

  /// No description provided for @setupAppsChosen.
  ///
  /// In ar, this message translates to:
  /// **'{count} تطبيق مُختار'**
  String setupAppsChosen(String count);

  /// No description provided for @setupAppsNoneYet.
  ///
  /// In ar, this message translates to:
  /// **'لم تختر أي تطبيق بعد'**
  String get setupAppsNoneYet;

  /// No description provided for @setupAppsWhyLater.
  ///
  /// In ar, this message translates to:
  /// **'إن تخطّيتها الآن، لن يُحجب أي تطبيق حتى تختار.'**
  String get setupAppsWhyLater;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppL10nAr();
    case 'en':
      return AppL10nEn();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
