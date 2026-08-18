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
  /// **'نجومي'**
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
  /// **'إعداد نجومي'**
  String get setupTitle;

  /// No description provided for @setupWelcomeTitle.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك في نجومي'**
  String get setupWelcomeTitle;

  /// No description provided for @setupWelcomeBody.
  ///
  /// In ar, this message translates to:
  /// **'نجومي يحوّل وقت اللعب إلى شيء يكسبه طفلك بالمذاكرة، لا إلى شيء تسحبه منه. الإعداد ثلاث خطوات، ويمكنك تغيير كل شيء لاحقاً.'**
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
  /// **'جعل نجومي الشاشة الرئيسية'**
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
  /// **'لتفعيل الحجب، يحتاج نجومي إلى خدمة إمكانية الوصول (Accessibility). يستعملها التطبيق لغرض واحد فقط: معرفة أي تطبيق ظهر على الشاشة الآن، ليغلق الألعاب المحجوبة عند نفاد وقت اللعب.\n\nلا يقرأ نجومي محتوى الشاشة، ولا كلمات المرور، ولا الرسائل، ولا يسجّل ما تكتبه، ولا يرسل أي شيء من هذا إلى أي خادم. يمكنك إيقاف الخدمة في أي وقت من إعدادات الهاتف.'**
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
