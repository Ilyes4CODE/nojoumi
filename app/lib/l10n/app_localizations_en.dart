// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Nojoumi';

  @override
  String get starsBalance => 'Your balance';

  @override
  String get starsUnit => 'stars';

  @override
  String get minutesUnit => 'minutes';

  @override
  String get playTimeRemaining => 'Play time remaining';

  @override
  String get todayTasks => 'Today\'s tasks';

  @override
  String get taskMemorize => 'Memorize';

  @override
  String get taskReview => 'Review';

  @override
  String get taskExercise => 'Exercise';

  @override
  String get sessionComplete => 'You finished all of today\'s tasks';

  @override
  String sessionBonusEarned(String stars) {
    return 'Completion bonus: $stars stars';
  }

  @override
  String get cardShowAnswer => 'Show answer';

  @override
  String get cardIKnewIt => 'I knew it';

  @override
  String get cardIDidNot => 'I did not';

  @override
  String get answerCorrect => 'Correct';

  @override
  String get answerWrong => 'Wrong. This card will come back later.';

  @override
  String get tryAgainMessage => 'Try again';

  @override
  String needStarsToPlay(String stars) {
    return 'You need $stars stars to unlock this game';
  }

  @override
  String get blockedTitle => 'Play time is over';

  @override
  String get blockedBody => 'Finish your tasks to earn more stars';

  @override
  String get earnStarsNow => 'Earn stars now';

  @override
  String get playPausedByParent => 'Play is paused by your parent';

  @override
  String get weeklyTest => 'Weekly test';

  @override
  String weeklyTestResult(String percent) {
    return 'Your score: $percent%';
  }

  @override
  String get parentArea => 'Parent area';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get wrongPin => 'Incorrect PIN';

  @override
  String get settings => 'Settings';

  @override
  String get starValueMinutes => 'Minutes per star';

  @override
  String get dailyStarCeiling => 'Daily star ceiling';

  @override
  String get minimumCardSeconds => 'Minimum time on a card';

  @override
  String get dailySessionSize => 'Daily session size';

  @override
  String get balanceExpiry => 'Balance expiry';

  @override
  String get expiryDaily => 'End of day';

  @override
  String get expiryWeekly => 'End of week';

  @override
  String get grantStars => 'Grant stars';

  @override
  String get deductStars => 'Deduct stars';

  @override
  String get pausePlay => 'Pause play';

  @override
  String get managedApps => 'Games and distracting apps';

  @override
  String get captureLesson => 'Capture a lesson';

  @override
  String get captureHintFlat => 'Press the page flat';

  @override
  String get captureHintLight => 'Good light, no flash';

  @override
  String get captureHintStraight => 'Hold the camera parallel to the page';

  @override
  String get processing => 'Processing…';

  @override
  String get imageUnclear =>
      'The photo is not clear. Retake it with better light and a flat page.';

  @override
  String get subscription => 'Subscription';

  @override
  String get subscriptionTrial => 'Trial';

  @override
  String get subscriptionActive => 'Active';

  @override
  String get subscriptionGrace => 'Grace period';

  @override
  String get subscriptionExpired => 'Expired';

  @override
  String get subscriptionRefunded => 'Refunded';

  @override
  String expiresOn(String date) {
    return 'Expires on $date';
  }

  @override
  String get enterActivationCode => 'Enter activation code';

  @override
  String get activate => 'Activate';

  @override
  String get freeModeNotice =>
      'New lesson generation is paused. Blocking, stars and saved lessons keep working.';

  @override
  String get continueAction => 'Continue';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get retry => 'Retry';

  @override
  String get offlineNotice => 'No internet connection';

  @override
  String get setupTitle => 'Set up Nojoumi';

  @override
  String get setupWelcomeTitle => 'Welcome to Nojoumi';

  @override
  String get setupWelcomeBody =>
      'Nojoumi turns play time into something your child earns by studying, rather than something you take away. Setup is three steps, and everything can be changed later.';

  @override
  String setupStepOf(String current, String total) {
    return 'Step $current of $total';
  }

  @override
  String get setupGradeTitle => 'School grade';

  @override
  String get setupGradeBody =>
      'Used to generate age-appropriate lessons. We never ask for the child\'s name, photo or date of birth.';

  @override
  String get setupGradeHint => 'For example: fourth year primary';

  @override
  String get setupPinTitle => 'Parent PIN';

  @override
  String get setupPinBody =>
      'At least four digits. It protects the settings and the granting of stars. The PIN itself is never stored and can only be reset through your server account.';

  @override
  String get setupPinCreate => 'Enter a new PIN';

  @override
  String get setupPinConfirm => 'Re-enter the PIN';

  @override
  String get setupPinMismatch => 'The two PINs do not match';

  @override
  String get setupPinTooShort => 'The PIN must be at least four digits';

  @override
  String get setupProtectionTitle => 'Blocking and home-screen mode';

  @override
  String get setupProtectionBody =>
      'Both are entirely optional, and the app is fully usable without them: lessons, cards, stars, the weekly test and the parent dashboard all work.';

  @override
  String get setupEnableBlocking => 'Turn on game blocking';

  @override
  String get setupEnableLauncher => 'Make Nojoumi the home screen';

  @override
  String get setupSkipProtection => 'Continue without them for now';

  @override
  String get setupDisclosureTitle =>
      'Important disclosure before granting permission';

  @override
  String get setupDisclosureBody =>
      'To enable blocking, Nojoumi needs the Accessibility service. The app uses it for one purpose only: to know which app has just appeared on screen, so that it can close blocked games when play time runs out.\n\nNojoumi does not read screen content, passwords or messages, does not log what you type, and sends none of this to any server. You can turn the service off at any time in your phone\'s settings.';

  @override
  String get setupDisclosureConsent =>
      'I have read this disclosure and consent as a parent';

  @override
  String get setupDisclosureDecline => 'No, continue without blocking';

  @override
  String get setupFinish => 'Start';

  @override
  String get setupDoneTitle => 'Everything is ready';

  @override
  String setupDoneBody(String stars) {
    return 'We gave your child $stars welcome stars to begin with.';
  }

  @override
  String get homeGreeting => 'Hello';

  @override
  String get startSession => 'Start today\'s tasks';

  @override
  String get noTasksYet => 'No tasks yet. Ask your parent to capture a lesson.';

  @override
  String tasksRemaining(String count) {
    return '$count tasks left';
  }

  @override
  String get dailyCeilingReached =>
      'You have reached today\'s ceiling. Come back tomorrow.';

  @override
  String streakDays(String days) {
    return '$days-day streak';
  }

  @override
  String get clockUntrustedTitle => 'The phone\'s clock cannot be trusted';

  @override
  String get clockUntrustedBody =>
      'The phone\'s date or time has changed. No new stars can be earned until the clock is back on automatic. Stars already earned and the remaining play time are unaffected.';

  @override
  String get fixClockAction => 'Open date and time settings';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get skip => 'Skip';

  @override
  String get notNow => 'Not now';
}
