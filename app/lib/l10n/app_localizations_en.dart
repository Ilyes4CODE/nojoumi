// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Lunio';

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
  String get setupTitle => 'Set up Lunio';

  @override
  String get setupWelcomeTitle => 'Welcome to Lunio';

  @override
  String get setupWelcomeBody =>
      'Lunio turns play time into something your child earns by studying, rather than something you take away. Setup is three steps, and everything can be changed later.';

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
  String get setupEnableLauncher => 'Make Lunio the home screen';

  @override
  String get setupSkipProtection => 'Continue without them for now';

  @override
  String get setupDisclosureTitle =>
      'Important disclosure before granting permission';

  @override
  String get setupDisclosureBody =>
      'To enable blocking, Lunio needs the Accessibility service. The app uses it for one purpose only: to know which app has just appeared on screen, so that it can close blocked games when play time runs out.\n\nLunio does not read screen content, passwords or messages, does not log what you type, and sends none of this to any server. You can turn the service off at any time in your phone\'s settings.';

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

  @override
  String pinLockedFor(String seconds) {
    return 'Too many attempts. Try again in $seconds seconds.';
  }

  @override
  String get parentOverview => 'Overview';

  @override
  String get parentStarsToday => 'Stars today';

  @override
  String get parentEarnedToday => 'Earned by the child';

  @override
  String get parentGrantedToday => 'Granted by you';

  @override
  String get parentCeilingUsed => 'of the daily ceiling';

  @override
  String get parentPlayUsed => 'Play time used';

  @override
  String get parentStreak => 'Streak';

  @override
  String get parentAdjustTitle => 'Grant or deduct';

  @override
  String get parentAdjustBody =>
      'Your authority is above the system: grants and deductions ignore the daily ceiling, and work even when the phone\'s clock cannot be trusted.';

  @override
  String get parentAdjustAmount => 'Number of stars';

  @override
  String get parentAdjustNote => 'Reason (optional)';

  @override
  String parentGrantDone(String stars) {
    return '$stars stars granted';
  }

  @override
  String parentDeductDone(String stars) {
    return '$stars stars deducted';
  }

  @override
  String get parentDeductTooMuch =>
      'Cannot deduct more than the current balance';

  @override
  String get parentSettingsTitle => 'The numbers you control';

  @override
  String get parentSettingsBody =>
      'Every value here has a range fixed by the contract appendix. Out-of-range values are rejected, never rounded.';

  @override
  String parentRangeHint(String min, String max) {
    return 'from $min to $max';
  }

  @override
  String get parentDailyPlayMinutes => 'Daily play minutes';

  @override
  String get parentDailyPlayHint => 'daily ceiling × star value';

  @override
  String get parentQuestionsPerDay => 'Review questions per day';

  @override
  String get parentWelcomeBalance => 'Welcome balance';

  @override
  String get parentExpiryWeekday => 'Weekly test day';

  @override
  String get parentPlayPausedOn => 'Play is paused';

  @override
  String get parentPlayPausedOff => 'Play is allowed';

  @override
  String get parentBlockingSection => 'Blocking and home screen';

  @override
  String get parentLedgerTitle => 'Star ledger';

  @override
  String get parentLedgerEmpty => 'No movements yet';

  @override
  String get parentWhyNoStar => 'Why was no star granted?';

  @override
  String get parentSaved => 'Saved';

  @override
  String parentInvalidValue(String reason) {
    return 'Unacceptable value: $reason';
  }

  @override
  String get ledgerCardFirstTime => 'Card correct first time';

  @override
  String get ledgerCardReview => 'Card in a later review';

  @override
  String get ledgerReviewQuestion => 'Correct review question';

  @override
  String get ledgerSessionBonus => 'Session completion bonus';

  @override
  String get ledgerStreakBonus => 'Attendance bonus';

  @override
  String get ledgerWeeklyTest => 'Weekly test';

  @override
  String get ledgerWelcomeGrant => 'Welcome balance';

  @override
  String get ledgerParentGrant => 'Parent grant';

  @override
  String get ledgerParentDeduct => 'Parent deduction';

  @override
  String get ledgerExpiry => 'Balance expired';

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get rejectUntrustedClock =>
      'The phone\'s clock cannot be trusted (Art. 6.8)';

  @override
  String get rejectWrongAnswer => 'Wrong answer (Art. 6.1)';

  @override
  String get rejectSolutionRevealed =>
      'The solution was revealed before answering (Art. 6.1)';

  @override
  String get rejectNotFirstAttempt => 'Not the first attempt (Art. 6.1)';

  @override
  String get rejectAlreadyCountedToday =>
      'Already counted the same day (Art. 6.2)';

  @override
  String get rejectBelowMinimumTime =>
      'Less than the minimum time on the card (Art. 6.3)';

  @override
  String get rejectDailyCeilingReached =>
      'The daily ceiling is exhausted (Art. 6.4)';

  @override
  String get rejectAlreadyAwardedToday =>
      'This bonus was already granted today';

  @override
  String get rejectSessionIncomplete =>
      'The daily session is not complete (Art. 6.5)';

  @override
  String get rejectStreakTooShort => 'Fewer than two consecutive days (Art. 5)';

  @override
  String get accountTitle => 'Parent account';

  @override
  String get accountWhy =>
      'The account is only needed to generate new lessons. Blocking, stars and saved lessons work without it.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create an account';

  @override
  String get signOut => 'Sign out';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get phoneOptional => 'Phone number (optional)';

  @override
  String get noAccountYet => 'No account yet? Create one';

  @override
  String get haveAccountAlready => 'Already have an account? Sign in';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get signInRequired => 'Sign in to generate a new lesson';

  @override
  String get serverNotConfigured =>
      'No server address is configured in this build.';

  @override
  String get captureFromCamera => 'Take a photo';

  @override
  String get captureFromGallery => 'Choose from the gallery';

  @override
  String get captureIntro =>
      'Photograph one page of your child\'s book. The image is sent for processing, dropped by the server immediately, and kept only on this phone.';

  @override
  String get processingHint => 'This takes a few seconds';

  @override
  String get reviewLesson => 'Review the lesson';

  @override
  String get summaryHeading => 'Summary';

  @override
  String get cardsHeading => 'Memorization cards';

  @override
  String get questionsHeading => 'Review questions';

  @override
  String get lessonTitleLabel => 'Lesson title';

  @override
  String get lessonTitleHint => 'For example: the Arabic letters';

  @override
  String get subjectOptional => 'Subject (optional)';

  @override
  String get saveLesson => 'Save the lesson';

  @override
  String get discardLesson => 'Discard';

  @override
  String lessonSaved(String cards, String questions) {
    return 'Saved: $cards cards and $questions questions';
  }

  @override
  String get retakePhoto => 'Take another photo';

  @override
  String get lessonsTitle => 'Lessons';

  @override
  String get lessonsEmpty => 'No lesson captured yet';

  @override
  String lessonCardsCount(String count) {
    return '$count cards';
  }

  @override
  String get imagesDeleted => 'Images deleted';

  @override
  String get untitledLesson => 'Untitled lesson';

  @override
  String get purgeDoneTitle => 'This week\'s images have been deleted';

  @override
  String get purgeDoneBody =>
      'The photographs and the exercises were deleted from the phone. The summaries, the cards and your results are kept.';

  @override
  String get weeklyTestDue => 'The weekly test is due';

  @override
  String get weeklyTestStart => 'Start the test';

  @override
  String get subscriptionPlan => 'Plan';

  @override
  String get subscriptionDaysLeft => 'Days remaining';

  @override
  String get startTrial => 'Start the trial';

  @override
  String get trialOncePerDevice => 'Seven days, once per device';

  @override
  String get activationHelp =>
      'You receive the code after paying on the website.';

  @override
  String get renewNotice =>
      'To renew, use the payment page linked to your account.';

  @override
  String get activationDone => 'Activated';

  @override
  String get planMonthly => 'Monthly';

  @override
  String get planAnnual => 'Annual';

  @override
  String get planTrial => 'Trial';

  @override
  String get aiPausedTitle => 'New lesson generation is paused';

  @override
  String get blockingTitle => 'Blocking and games';

  @override
  String get blockingIntro =>
      'Lunio stops the games you choose from opening once play time runs out. The rest of the phone stays open as usual.';

  @override
  String get blockingUnavailable =>
      'Blocking is Android-only. The rest of the app works fully here.';

  @override
  String get blockingEnableSwitch => 'Turn on game blocking';

  @override
  String get blockingReady => 'Blocking is working';

  @override
  String get blockingIncomplete => 'At least one permission is missing';

  @override
  String get blockingOff => 'Blocking is off';

  @override
  String get permAccessibility => 'Accessibility service';

  @override
  String get permAccessibilityBody =>
      'Without it Lunio cannot tell which app opened, and nothing is blocked.';

  @override
  String get permOverlay => 'Draw over other apps';

  @override
  String get permOverlayBody =>
      'Without it the phone goes home without telling the child why.';

  @override
  String get permNotifications => 'Notifications';

  @override
  String get permNotificationsBody =>
      'A silent ongoing notification keeps the blocking engine alive.';

  @override
  String get permAutostart => 'Auto-start';

  @override
  String permAutostartBody(String brand) {
    return 'On $brand devices the system may stop blocking coming back after a restart unless you allow it by hand.';
  }

  @override
  String get permGranted => 'Granted';

  @override
  String get permMissing => 'Required';

  @override
  String get permOpen => 'Open';

  @override
  String get blockingApps => 'Blocked games';

  @override
  String blockingAppsCount(String count) {
    return '$count apps blocked';
  }

  @override
  String get blockingAppsEmpty => 'No games chosen yet';

  @override
  String get blockingAppsHint =>
      'Pick the apps that should cost stars. Everything else stays open.';

  @override
  String get blockingAppsSearch => 'Search apps';

  @override
  String get blockingAppsLoading => 'Reading installed apps';

  @override
  String get blockingProtectedNote =>
      'Settings, the phone, messages, the keyboard and Lunio itself can never be blocked.';

  @override
  String blockingDeviceLine(String brand, String sdk) {
    return '$brand · Android API $sdk';
  }

  @override
  String get setupWelcomeHeadline => 'Welcome to';

  @override
  String get setupWelcomeLine1 => 'Turn play time into time well spent.';

  @override
  String get setupWelcomeLine2 =>
      'With Lunio your child learns step by step, through simple interactive activities suited to their age.';

  @override
  String get setupWelcomePillarSafe => 'Safe and suitable';

  @override
  String get setupWelcomePillarProgress => 'Steady progress';

  @override
  String get setupWelcomePillarGoals => 'Clear goals';

  @override
  String get setupAccountTitle => 'Parent account';

  @override
  String get setupAccountBody =>
      'The account belongs to the parent alone and is used for two things only: generating new lessons from photos, and the subscription. No account is created for the child, and none of their data ever reaches the server.';

  @override
  String get setupAccountRequired => 'An account is required to finish setup.';

  @override
  String get setupTrialStarted =>
      'Your free trial has started: 7 days, all features.';

  @override
  String get setupTrialAlready =>
      'The free trial has already been used on this device.';

  @override
  String get serverUnreachable => 'Cannot reach the server';

  @override
  String get serverRetry => 'Try again';

  @override
  String serverAddress(String url) {
    return 'Address: $url';
  }

  @override
  String get serverDegraded =>
      'The server is up but its database is not responding';

  @override
  String get oneAccountPerDevice =>
      'One account per phone. To change it, clear the app\'s data.';

  @override
  String get dialogWelcomeTitle => 'Welcome to Lunio';

  @override
  String get dialogWelcomeBackTitle => 'Welcome back';

  @override
  String get dialogSetupRemains =>
      'Two steps remain on this phone: the school level and the parent PIN. Neither is ever stored on the server, so both are set on each device.';

  @override
  String get dialogContinue => 'Continue';

  @override
  String get dialogStartNow => 'Start now';

  @override
  String get cardRemembered => 'Well done — you remembered it';

  @override
  String get cardNotYet => 'That\'s fine — it will come back to you';

  @override
  String get cardRevealedNote => 'Take a good look; you will see it again';

  @override
  String get questionRight => 'Correct';

  @override
  String get questionShowsAnswer => 'The correct answer is marked in green';

  @override
  String get buyActivationCode => 'Get an activation code';

  @override
  String get buyOpensBrowser =>
      'Opens the payment page in your browser. Payment happens outside the app on Chargily\'s secure page, and returns a code you enter here.';

  @override
  String get permBattery => 'Unrestricted background';

  @override
  String get permBatteryBody =>
      'Without it the system freezes the app while the child plays, so the timer stops and the game is not closed on time.';

  @override
  String signedInSubscription(String state) {
    return 'Your subscription: $state';
  }

  @override
  String get signedInNothingNew =>
      'Nothing about your account changed — you are simply signed in.';

  @override
  String get blockingNotRunningTitle => 'Blocking is on but not running';

  @override
  String get blockingNotRunningBody =>
      'The accessibility service is off, so nothing is blocked and play time is not counted. This happens after every app update.';

  @override
  String get blockingNotRunningAction => 'Turn it back on';

  @override
  String get lessonIntroHeading => 'Before we start';

  @override
  String get lessonIntroRead =>
      'Read the lesson summary carefully, then move on to the cards';

  @override
  String lessonIntroWait(String seconds) {
    return 'You can continue in ${seconds}s';
  }

  @override
  String get lessonIntroStart => 'Start the cards';

  @override
  String get cardPickAnswer => 'Choose the right answer';

  @override
  String get myLessons => 'My lessons';

  @override
  String get activatedTitle => 'Your subscription is active';

  @override
  String activatedUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get activatedBody =>
      'You can now photograph and generate new lessons. Blocking, stars and saved lessons keep working either way.';

  @override
  String get questionAgain => 'One more time';

  @override
  String get parentFreePlayTitle => 'Free play time';

  @override
  String get parentFreePlayBody =>
      'Give your child play time directly. It is added to their balance, grants no stars, and ends with the day.';

  @override
  String parentFreePlayGranted(String duration) {
    return 'Given today: $duration';
  }

  @override
  String parentFreePlayAdded(String duration) {
    return 'Added $duration of free play';
  }

  @override
  String get parentPlayRemaining => 'Play time left';

  @override
  String get sectionComplete => 'Well done! This part is finished';

  @override
  String lessonProgress(String done, String total) {
    return '$done of $total';
  }

  @override
  String get lessonAllDone => 'Finished';

  @override
  String lessonQuestionsCount(String count) {
    return '$count questions';
  }

  @override
  String get sectionLocked => 'Finish the memory cards first';

  @override
  String cardStayWith(String seconds) {
    return 'Look at it for ${seconds}s';
  }

  @override
  String get forgotPasswordLink => 'Forgot your password?';

  @override
  String get forgotTitle => 'Reset your password';

  @override
  String get forgotAskTitle => 'It happens to everyone';

  @override
  String get forgotAskBody =>
      'Type your email address and we will send you a six-digit code so you can choose a new password.';

  @override
  String get forgotAskAction => 'Send the code';

  @override
  String get forgotCodeTitle => 'Check your inbox';

  @override
  String forgotCodeBody(String email) {
    return 'We sent a six-digit code to $email. If it is not there, look in the spam folder.';
  }

  @override
  String get forgotCodeLabel => 'Code';

  @override
  String get forgotCodeAction => 'Confirm the code';

  @override
  String get forgotCodeResend => 'Nothing arrived? Send it again';

  @override
  String forgotCodeResendIn(String seconds) {
    return 'You can send another in $seconds seconds';
  }

  @override
  String get forgotCodeWrongEmail => 'Change the email address';

  @override
  String get forgotNewTitle => 'Choose a new password';

  @override
  String get forgotNewBody =>
      'Your sessions on other devices will end. Nothing changes for your child: stars, blocking and saved lessons all live on this phone.';

  @override
  String get forgotNewLabel => 'New password';

  @override
  String get forgotNewConfirmLabel => 'Type it again';

  @override
  String get forgotNewMismatch => 'The two do not match.';

  @override
  String get forgotNewAction => 'Save the password';

  @override
  String get forgotDoneTitle => 'Password changed';

  @override
  String get forgotDoneBody =>
      'We signed you in with the new one. Keep it somewhere safe.';

  @override
  String get forgotDoneAction => 'Continue';
}
