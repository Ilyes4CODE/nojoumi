import 'package:flutter/material.dart';

import 'theme.dart';

/// Every illustration the app can show, named once.
///
/// **Why a catalogue and not a path in each widget.** Seven assets are being
/// drawn by a third party and will arrive in batches, be redrawn, and be renamed.
/// A path typed into a widget means a search-and-replace every time, and a
/// missing file means a red error box in front of a child. Here the filenames
/// live in one list, and [Illustration.show] degrades to a calm placeholder when
/// the file is not there yet — so **the app runs correctly before any of the
/// artwork exists**, which is the state it is in today.
///
/// The set is the one in `docs/design-v4.md` §6, taken from the client's second
/// design pass. It is deliberately small: everything the client's mockups draw as
/// a small glyph inside a rounded tinted square is a Material icon here, not a
/// commissioned asset. That halves the budget Article 13 constrains.
///
/// **App icons in the game grid are not in this list.** They come from the device
/// through `PackageManager` — they belong to the installed apps, not to us.
enum Illustration {
  /// The friendly padlock — **the most important asset in the app**.
  ///
  /// It is what a child sees at the moment they are refused something they
  /// wanted, and it repeats on every locked game tile. It has to read as *not
  /// yet*, never as *forbidden*: soft violet, a small smile, no red and no
  /// warning mark. Article 1 calls this a motivation tool, and this drawing is
  /// where that is either true or obviously false.
  lockFriendly('lock_friendly.webp'),

  /// The currency, large. Rewards, the end of a session, setup milestones.
  /// Faceless on purpose — a star with a personality competes with the star as
  /// a counter.
  starBig('star_big.webp'),

  /// A violet backpack with books and pencils. The school-grade step.
  backpack('backpack.webp'),

  /// A rocket with a small astronaut waving. The welcome step.
  rocket('rocket.webp'),

  /// A small round astronaut. The greeting on the child's home, and empty
  /// states.
  ///
  /// **A guide, never a profile picture.** Article 14 forbids an identifier of
  /// the child, so this never appears beside a name and the parent never picks
  /// or uploads one.
  astronaut('astronaut.webp'),

  /// A violet shield with a check mark. The disclosure step and the parent gate.
  shield('shield.webp'),

  /// A sparse, low-contrast star field. Sits behind the blocked card and the
  /// balance card, and must never compete with the number on top of it.
  starfield('starfield.webp'),

  /// **The client's own logo mark** — the capped book with the sparkle, cut out
  /// of `illustrators and logo/logo.jpeg` and put on transparency.
  ///
  /// The mark only, not the full lockup. The wordmark and the tagline
  /// «رفيقك في التعلم» are cropped away because the one screen this appears on
  /// already says «أهلاً بك في Lunio» directly beneath it, and a wordmark eighty
  /// pixels above that title says the brand name twice.
  ///
  /// This is the one asset in the list that is not interchangeable. The others
  /// are decoration and can be redrawn; this is identity, and it is the client's
  /// choice, so it is never restyled, retinted, or cropped further.
  logoMark('logo_mark.webp'),

  /// A gold ticket with stars — the activation code of Article 7.3 step 5.
  ///
  /// The **same** drawing appears on the payment web page next to the code the
  /// parent has just been given. That repetition is the point: the code is the
  /// only thing that crosses from the browser into the app (Art. 7.2 keeps
  /// everything else outside), and a parent carrying a short string between two
  /// screens should be able to see that they are the same errand.
  codeTicket('code_ticket.webp'),

  /// An open book with stars — the memorization card.
  cardBook('card_book.webp'),

  /// A smiling question mark — the review question.
  cardQuestion('card_question.webp'),

  /// The faint pattern behind the daily session.
  ///
  /// **Not cut out, and never tinted.** It is texture rather than a subject: a
  /// pale lavender field with stars, dots and squiggles at very low contrast and
  /// **nothing in the middle**, because Arabic sentences are laid over it and a
  /// busy centre would make them hard to read. A child who already reads slowly
  /// will simply stop trying.
  ///
  /// Drawn at low opacity on top of that, so the pattern is felt rather than
  /// looked at. If it is ever visible enough to notice, it is wrong.
  sessionBackground('session_bg.webp'),

  /// The tile for one lesson in the child's picker.
  ///
  /// A friendly object, not a document. The picker is the first thing the child
  /// sees when they open their work, and a grid of grey pages is a grid of
  /// homework — the tile has to make opening one feel like taking a toy off a
  /// shelf. It is tinted differently per tile by the picker, so the drawing
  /// itself must be tint-neutral.
  lessonTile('lesson_tile.webp'),

  /// The playful backdrop behind the picker and the lesson page.
  ///
  /// Distinct from [sessionBackground], and louder on purpose. That one sits
  /// under sentences a child is trying to read and must be invisible; this one
  /// sits under tiles and headings, where a flat canvas reads as a form to fill
  /// in. Still nothing dark or busy in the middle.
  ///
  /// **Drawn at 0.9, not at the 0.35 default.** The delivered artwork is already
  /// a finished pale wallpaper rather than a texture to be dimmed — washing it
  /// out a second time would leave a blank near-white screen and throw the
  /// drawing away. The opacity belongs to the pairing of file and screen, which
  /// is why it is passed at the call site rather than defaulted here.
  lessonBackground('lesson_bg.webp'),

  /// The memorization half of a lesson.
  sectionMemorize('section_memorize.webp'),

  /// The review half of a lesson.
  sectionQuestions('section_questions.webp'),

  /// The moment the parent's activation code is accepted.
  ///
  /// **A receipt, not a celebration.** The parent has just paid money outside
  /// the app, typed a code they carried back from a browser, and needs to know
  /// it landed — so this reads as confirmation rather than as a prize. No
  /// confetti, no fireworks: they are not the child, and a store-front tone is
  /// exactly what Article 7.2 keeps out of this app.
  subscriptionDone('subscription_done.webp');

  const Illustration(this.file);

  final String file;

  String get assetPath => 'assets/illustrations/$file';

  /// Render it, or a quiet placeholder if the artwork has not arrived.
  ///
  /// The placeholder is deliberately plain and on-palette rather than a warning:
  /// a missing asset is a scheduling fact, not a user's problem, and a child
  /// looking at a half-finished build should see a calm shape rather than a
  /// broken-image glyph.
  Widget show({double size = 96, Color? placeholderTint}) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) => _Placeholder(
        size: size,
        tint: placeholderTint ?? LunioTheme.tintLavender,
      ),
    );
  }
}

/// An illustration used as a full-bleed backdrop.
///
/// Three things it must do, and each of them was a bug first:
///
///  * **never take a tap.** It fills the screen, and a decoration that swallows
///    a tap meant for an answer is indistinguishable from a frozen app.
///  * **never show a broken image.** The artwork arrives in batches; a missing
///    file must leave a clean canvas in front of a child, not a red glyph.
///  * **stay quiet.** Opacity is the whole design here. Anything legible enough
///    to look at is competing with the Arabic laid over it, and a child who
///    already reads slowly will stop trying rather than squint.
class Backdrop extends StatelessWidget {
  const Backdrop(this.illustration, {super.key, this.opacity = 0.35});

  final Illustration illustration;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Image.asset(
          illustration.assetPath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stack) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// A Material icon inside a rounded tinted square.
///
/// This is the client's own pattern for every small glyph on the parent
/// dashboard, and copying it saves seven commissioned assets. Material ships the
/// star, gift, clock, calendar, book and trophy already.
class TintedIcon extends StatelessWidget {
  const TintedIcon(
    this.icon, {
    super.key,
    this.tint = LunioTheme.tintLavender,
    this.color,
    this.size = 40,
  });

  final IconData icon;
  final Color tint;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        icon,
        size: size * 0.55,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.size, required this.tint});

  final double size;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Icon(
        Icons.image_outlined,
        size: size * 0.4,
        color: LunioTheme.blocked,
      ),
    );
  }
}
